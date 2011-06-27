/*
 * cerbere.vala
 * This file is part of cerbere
 *
 * Copyright (C) 2011 - Allen Lowe
 *
 * cerbere is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * cerbere is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with cerbere; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor,
 * Boston, MA  02110-1301  USA
 *
 * Authors: Allen Lowe <allen@elementaryos.org>
 *          ammonkey <am.monkeyd@gmail.com>
 */
using GLib;

Gee.HashMap<string, int> pids;
string[] desktop_bins;
 
void on_watchdog_exit (Pid pid, int status, string name) {
    Process.close_pid (pid);
    pids.unset (name, null);
    //message ("%s exited with a status of %i\n", name, status);
    if (status < 30) {
        watchdog_process (name);
    }
}

void on_launched_exit (Pid pid, int status, string name) {
    Process.close_pid (pid);
    //message ("%s exited with a status of %i\n", name, status);
}

void watchdog_process (string bin_name) {
    Pid pid;
    GLib.Process.spawn_async (null, {bin_name, null}, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD | SpawnFlags.STDOUT_TO_DEV_NULL | SpawnFlags.STDERR_TO_DEV_NULL, null, out pid);
    int pidint = (int)pid;
    pids.set (bin_name, pidint);
    ChildWatch.add (pid, (a,b) => {on_watchdog_exit (a, b, bin_name);});
    //message ("%s %s childwatch added\n", bin_name, pidint.to_string ());
}

void launch_process (string bin_name) {
    Pid pid;
    GLib.Process.spawn_async (null, {bin_name, null}, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD | SpawnFlags.STDOUT_TO_DEV_NULL | SpawnFlags.STDERR_TO_DEV_NULL, null, out pid);
    int pidint = (int)pid;
    ChildWatch.add (pid, (a,b) => {on_launched_exit (a, b, bin_name);});
    //message ("%s %s childwatch added\n", bin_name, pidint.to_string ());
}

void load_config () {
    var settings = new Settings ("org.elementary.cerbere.settings");
    desktop_bins = settings.get_strv ("desktop-components");
}

void start_desktop () {
    foreach (string bin in desktop_bins) {
        if (bin != null) {
            watchdog_process (bin);
        }
    }
}

namespace Cerbere {
    public class Cerbere : Application {
        construct {
                application_id = "org.elementary.cerbere";
                flags = GLib.ApplicationFlags.IS_SERVICE;
        }

        /*protected override void activate () {
            stdout.printf ("activate\n");
        }*/
        
        protected override void startup () {
            pids = new Gee.HashMap<string, int> ();
            load_config ();
            start_desktop ();
            
            var main_loop = new MainLoop ();
            main_loop.run ();
        }
        
        
        public static int main (string[] args) {
            var app = new Cerbere ();
            app.run (args);

            return 0;
        }
    }
}

