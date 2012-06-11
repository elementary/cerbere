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
        if (is_white_space (command))
            return;

        string? args;
        var bin_key = this.get_bin_key (command, out args);

        if (args == null)
            args = "";

        // Check if a process for this bin has already been created
        if (this.processes.has_key (bin_key))
            return;

        // Create new process
        var process = new ProcessInfo (bin_key);
        process.run_async (args);

        process.exited.connect ( (normal_exit) => {
            if (!normal_exit && process.crash_count > Cerbere.settings.max_crashes)
                return;
            // Reload right away
            process.run (args);
        });

        processes[bin_key] = process;
    }

    /**
     * Returns the binary key from a command line string.
     * For example:
     * "slingshot --silent" => "slingshot"
     *
     * TODO: use GLib.Shell.parse_argv() instead
     */
    private string get_bin_key (string command, out string? args = null) {
        string[] keys = command.split (" ", -1);
        string rv = "";

        int i = 0;
        foreach (string key in keys) {
            i += key.length;
            if (!is_white_space (key)) {
                rv = key;
                break;
            }
        }

        args = command.substring (i - 1, command.length - 1);

        return rv;
    }

    private static bool is_white_space (string str) {
        return str.strip () == "";
    }
}

