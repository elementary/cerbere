/*
 * Watchdog.vala
 * This file is part of cerbere, a watchdog for the Pantheon Desktop
 *
 * Copyright (C) 2011-2012 - Allen Lowe
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
 * Authors: Allen Lowe <allen@elementaryos.org>
 *          ammonkey <am.monkeyd@gmail.com>
 *          Victor Eduardo <victoreduardm@gmail.com>
 */

public class Watchdog {

    private double CRASH_TIME;
    private int MAX_CRASHES;

    private Gee.HashMap<string, int> pids;
    private Gee.HashMap<string, ProcessTimer> run_time;
    private Gee.HashMap<string, int> exit_count;
    private Gee.HashMap<string, int> crash_count;

    public Watchdog (double crash_time, int max_crashes) {
        CRASH_TIME = crash_time;
        MAX_CRASHES = max_crashes;
        
        pids = new Gee.HashMap<string, int> ();
        run_time = new Gee.HashMap<string, ProcessTimer> ();
        exit_count = new Gee.HashMap<string, int> ();
        crash_count = new Gee.HashMap<string, int> ();
    }

    public void watch_process (string bin_name) {
        Pid pid;

        try {
            GLib.Process.spawn_async (null, {bin_name, null}, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD | SpawnFlags.STDOUT_TO_DEV_NULL | SpawnFlags.STDERR_TO_DEV_NULL, null, out pid);
        }
        catch (GLib.Error err) {
            warning (err.message);
        }

        stdout.printf("\nPROCESS STARTED:     [ID = %i]  %s", (int)pid, bin_name);

        pids.set (bin_name, (int)pid);

        // Check if we have not created the counters before

        if (!exit_count.has_key(bin_name))
            exit_count.set (bin_name, 0);

        if (!crash_count.has_key(bin_name))
            crash_count.set (bin_name, 0);

        // Add and run timer
        run_time.set(bin_name, new ProcessTimer());

        ChildWatch.add (pid, (a,b) => {
            on_process_exit (a, b, bin_name);
        });
    }


    private void on_process_exit (Pid pid, int status, string name) {
        double elapsed_time = run_time.get(name).elapsed;
        int exit_times = exit_count.get(name), crashes = crash_count.get(name);

        stdout.printf("\nPROCESS TERMINATED:  [ID = %i]  %s [Status = %i]", (int)pid, name, status);
        stdout.printf(" [Elapsed time = %.2fs]", elapsed_time);

        exit_count.set(name, ++exit_times);
        Process.close_pid (pid);

        stdout.printf(" [Exit times = %i]", exit_times);

        run_time.unset(name, null);
        pids.unset (name, null);

        if (elapsed_time <= CRASH_TIME) {
            crash_count.set(name, ++crashes);
            stdout.printf(" [CRASH #%i]", crashes);
        }

        // Skip status check since it's causing problems
        //if (status < 30 && crashes <= MAX_CRASHES)
        if (crashes <= MAX_CRASHES)
            watch_process (name);

        if (crashes == MAX_CRASHES)
            stdout.printf("\n\n-- Process '%s' crashed too many times. It won't be launched again.\n\n", name);
    }
}

