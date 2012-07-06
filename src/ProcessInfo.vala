/* -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*- */
/*
 * Copyright (C) 2012 Victor Eduardo <victoreduardm@gmail.com>
 *
 * Cerbere is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Cerbere is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Cerbere; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor,
 * Boston, MA  02110-1301  USA
 *
 * Authors: Victor Eduardo <victoreduardm@gmail.com>
 */

public class ProcessInfo : Object {

    public signal void exited (bool normal_exit);

    public enum Status {
        INACTIVE,  // not yet spawned
        RUNNING,   // active (already spawned)
        TERMINATED // killed/exited
    }

    public uint crash_count { get; private set; default = 0; }

    private string command = "";
    private Pid pid = -1;
    private Status status = Status.INACTIVE;
    private Timer? timer = null;

    public ProcessInfo (string command) {
        this.command = command;
    }

    public void reset_crash_count () {
        this.crash_count = 0;
        message ("Crash count of '%s' has been reset", this.command);
    }

    public async void run_async () {
        this.run ();
    }

    private void run () {
        debug ("STARTING process: %s", command);

        if (this.status == Status.RUNNING) {
            warning ("Process %s is already running. Not starting it again...", command);
            return;
        }

        Pid process_id = -1;

        // parse args
        string[] argvp = null;
        try {
            Shell.parse_argv (this.command, out argvp);
        }
        catch (ShellError error) {
            warning ("Not passing any args to %s : %s", this.command, error.message);
            argvp = {this.command, null}; // fix value in case it's corrupted
        }

        if (argvp == null)
            return;

        // Spawn process asynchronously
        try {
            var flags = SpawnFlags.SEARCH_PATH |
                         SpawnFlags.DO_NOT_REAP_CHILD |
                         SpawnFlags.STDOUT_TO_DEV_NULL; // discard process output

            Process.spawn_async (null, argvp, null, flags, null, out process_id);
        }
        catch (Error err) {
            // TODO: Discuss how to handle spawn failures. Currently, Cerbere will give up
            // and stop trying. We could, however, add a call to terminate() in order to let the
            // Watchdog try again.
            warning (err.message);
            return;
        }

        // time starts counting here
        this.timer = new Timer ();
        this.status = Status.RUNNING;
        this.pid = process_id;

        // Add watch
        ChildWatch.add (this.pid, this.on_process_watch_exit);
    }

    private void on_process_watch_exit (Pid pid, int status) {
        if (pid != this.pid)
            return;

        message ("Process '%s' watch exit", command);

        // Check exit status
        if (Process.if_exited (status) || Process.if_signaled (status) || Process.core_dump (status)) {
            this.terminate ();
        }
    }

    private void terminate () {
        if (this.status != Status.RUNNING)
            return;

        message ("Process %s is being terminated", command);

        Process.close_pid (this.pid);

        bool normal_exit = true;

        if (this.timer != null) {
            this.timer.stop ();

            double elapsed_secs = this.timer.elapsed ();
            double crash_time_interval_secs = (double)Cerbere.settings.crash_time_interval / 1000.0;

            message ("ET = %f secs\tMin allowed time = %f", elapsed_secs, crash_time_interval_secs);

            if (elapsed_secs <= crash_time_interval_secs) { // process crashed
                this.crash_count ++;
                normal_exit = false;
                warning ("PROCESS '%s' CRASHED (#%u)", this.command, this.crash_count);
            }

            // Remove the current timer
            this.timer = null;
        }

        this.status = Status.TERMINATED;

        // Emit signal
        this.exited (normal_exit);
    }
}
