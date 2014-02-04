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

public class Cerbere.Watchdog {

    // Contains ALL the processes that are being monitored
    private Gee.HashMap<string, ProcessWrapper> processes;

    public Watchdog () {
        processes = new Gee.HashMap<string, ProcessWrapper> ();
    }

    public void add_process (string command)
        requires (is_valid_command (command)) {
        
        if (command_is_monitored (command)) {
            warning ("Command '%s' is already being monitored.", command);
            return;
        }
        
        monitor_and_run_command (command);
    }

    private bool is_valid_command (string command) {
        return command.strip () != "";
    }

    private bool command_is_monitored (string command) {
        return processes.has_key (command);
    }
    
    private void monitor_and_run_command (string command) {
        var process = new ProcessWrapper (command);
        processes[command] = process;
        process.exited.connect (on_process_exit);
        process.run_async ();
    }

    /**
     * Respawning occurs here. If the process has crashed more times than
     * max_crashes, it's not respawned again. Otherwise, it is assumed that the
     * process exited normally and the crash count is reset to 0, which means
     * that only consecutive crashes are counted.
     */
    private void on_process_exit (ProcessWrapper process, bool normal_exit) {
        if (normal_exit)
            process.reset_crash_count ();

        string command = process.command;

        if (is_not_in_settings (command)) {
            warning ("'%s' is no longer in settings (not monitored)", command);
            process.reset_crash_count ();
            unmonitor_command (command);
            return;
        }

        if (!command_is_monitored (command)) {
            critical ("Please file a bug at http://launchpad.net/cerbere and " +
                      "attach your .xsession-errors and .xsession-errors.old " +
                      "files.");
            return;
        }

        uint max_crashes = App.settings.max_crashes;

        if (process.crash_count > max_crashes) {
            warning ("'%s' exceeded the maximum number of crashes allowed " +
                     "(%u). It won't be launched again", command, max_crashes);
            unmonitor_command (command);
            return;
        }

        process.run_async ();
    }
    
    private bool is_not_in_settings (string command) {
        return !(command in App.settings.process_list);
    }
    
    private void unmonitor_command (string command) {
        processes.unset (command);
    }
}
