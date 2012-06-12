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

public class ProcessInfo : GLib.Object {

    public signal void exited (bool normal_exit);
    //public signal void started ();

    public enum Status {
        INACTIVE,  // not yet spawned
        RUNNING,   // active (already spawned)
        TERMINATED // killed/exited
    }

    private string command = "";
    private GLib.Pid pid = -1;

    public Status status = Status.INACTIVE;
    public int exit_count { get; private set; default = 0; }
    public int crash_count { get; private set; default = 0; }

    private GLib.Timer? timer = null;

    public ProcessInfo (string command) {
        this.command = command;
    }

    public void reset_crash_count () {
        debug ("RESETTING crash count of '%s' to 0 (normal exit)", this.command);
        this.crash_count = 0;
    }

    public async void run_async () {
        this.run ();
    }

    public void run () {
        message ("STARTING process: %s", command);

        if (this.status == Status.RUNNING) {
            message ("PROCESS %s is already running", command);
            return;
        }

        GLib.Pid process_id;

        var flags = GLib.SpawnFlags.SEARCH_PATH |
                     GLib.SpawnFlags.DO_NOT_REAP_CHILD |
                     GLib.SpawnFlags.STDOUT_TO_DEV_NULL; // discard process output

        // parse args
        string[] argvp = null;
        try {
            GLib.Shell.parse_argv (this.command, out argvp);
        }
        catch (GLib.ShellError error) {
            warning ("Not passing any args to %s : %s", this.command, error.message);
            argvp = {this.command, null}; // fix value in case it's corrupted
        }

        if (argvp == null)
            return;

        // Spawn process asynchronously
        try {
            GLib.Process.spawn_async (null, argvp, null, flags, null, out process_id);
        }
        catch (GLib.Error err) {
            warning (err.message);
            return;
        }

        // time starts counting here
        this.timer = new GLib.Timer ();

        this.pid = process_id;
        this.status = Status.RUNNING;

        // Emit signal
        //this.started ();

        // Add watch
        GLib.ChildWatch.add (this.pid, (pid, status) => {
            if (pid != this.pid)
                return;

            message ("Process '%s' has been closed (ChildWatch exit)", command);
            // Check exit status
            if (GLib.Process.if_exited (status) || GLib.Process.if_signaled (status) ||
                GLib.Process.core_dump (status))
            {
                this.terminate ();
            }
        });
    }

    public void terminate () {
        if (this.status != Status.RUNNING)
            return;

        message ("Process %s is being terminated", command);

        GLib.Process.close_pid (this.pid);

        bool is_crash = false;

        if (this.timer != null) {
            this.timer.stop ();

            double ellapsed_secs = this.timer.elapsed ();
            double crash_time_interval_secs = (double)Cerbere.settings.crash_time_interval / 1000.0;

            debug ("Elapsed time = %f secs", ellapsed_secs);
            debug ("Min allowed time = %f secs", crash_time_interval_secs);

            if (ellapsed_secs <= crash_time_interval_secs) // process crashed
                is_crash = true;
        }

        if (is_crash) {
            this.crash_count ++;
            message ("Process '%s' crashed", this.command);
        }

        this.exit_count ++;
        this.status = Status.TERMINATED;

        this.timer = null;

        // Emit signal
        this.exited (!is_crash);
    }   
}
