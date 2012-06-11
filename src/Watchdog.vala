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

    private Gee.HashMap<string, ProcessInfo> processes;

    public Watchdog () {
        this.processes = new Gee.HashMap<string, ProcessInfo> ();
    }

    public void add_process (string command) {
        if (str.strip () == "") // whitespace check
            return;

        // Check if a process for this has already been created
        if (this.processes.has_key (command))
            return;

        // Create new process
        var process = new ProcessInfo (command);

        // Add it to the table
        processes[command] = process;

        // Exit handler. Respawning occurs here
        process.exited.connect ( (normal_exit) => {
            if (normal_exit) {
                // Reset crash count. We only want to count consecutive crashes, so if a normal exit
                // is detected, we should reset the counter.
                message ("RESETTING crash count of '%s'", command);
                process.crash_count = 0;
            }

            // if still in the list, relaunch if possible
            if (process in Cerbere.settings.process_list) {
                // Check if the process already exceeded the maximum number of allowed crashes.
                // Also check if the process is still present in the table since it could have been removed.
                if (process.crash_count < Cerbere.settings.max_crashes && processes.has_key (command))
                {
                    message ("RELAUNCHING: %s", command);
                    process.run (); // Reload right away
                }
            }
            else {
                // Remove from the list. At this point the reference count should
                // drop to 0 and free the process.
                processes.unset (command);
            }
        });

        // Run
        process.run_async ();
    }
}

