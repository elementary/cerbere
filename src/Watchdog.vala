/* -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*- */
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
    // Contains ALL the processes that are being monitored
    private Gee.HashMap<string, ProcessInfo> processes;
    private GLib.Mutex data_lock;

    public Watchdog () {
        this.processes = new Gee.HashMap<string, ProcessInfo> ();
    }

    public async void add_process_async (string command) {
        this.add_process (command);
    }

    public void add_process (string command) {
        if (command.strip () == "") // whitespace check
            return;

        // Check if a process for this command has already been created
        if (this.processes.has_key (command))
            return;

        // Create new process
        var process = new ProcessInfo (command);

        // Add it to the table
        this.data_lock.lock ();
        this.processes[command] = process;
        this.data_lock.unlock ();

        // Exit handler. Respawning occurs here
        process.exited.connect ( (normal_exit) => {
            if (normal_exit) {
                // Reset crash count. We only want to count consecutive crashes, so if a normal exit
                // is detected, we should reset the counter.
                process.reset_crash_count ();
            }

            // if still in the list, relaunch if possible
            if (command in Cerbere.settings.process_list) {
                // Check if the process is still present in the table since it could have been removed.
                if (processes.has_key (command)) {
                    // Check if the process already exceeded the maximum number of allowed crashes.
                    uint max_crashes = Cerbere.settings.max_crashes;
                    if (process.crash_count <= max_crashes) {
                        message ("RELAUNCHING: %s", command);
                        process.run (); // Reload right away
                    }
                    else {
                        message ("'%s' exceeded the maximum number of crashes allowed (%s). It won't be launched again", command, max_crashes.to_string ());
                    }
                }
                else {
                    // If a process is not in the table, it means it wasn't re-launched after it exited, so
                    // in theory this code is never reached.
                    message ("You should NEVER get this message. If you're getting it, contact the developers.");
                }
            }
            else {
                // Remove from the list. At this point the reference count should
                // drop to 0 and free the process.
                message ("'%s' is no longer on settings. It will not be monitored anymore", command);
                this.data_lock.lock ();
                this.processes.unset (command);
                this.data_lock.unlock ();
            }
        });

        // Run
        process.run_async ();
    }
}
