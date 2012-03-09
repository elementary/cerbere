/*
 * Cerbere.vala
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
 */

using GLib;

namespace Cerbere {

    public class Cerbere : Application {

    private Watchdog watchdog;

        private double crash_time;
        private int max_crashes;

        private string[] desktop_bins;

        construct {
            application_id = "org.elementary.cerbere";
            flags = GLib.ApplicationFlags.IS_SERVICE;
        }

        protected override void startup () {
            load_config ();

            // Start watchdog
            watchdog = new Watchdog (crash_time, max_crashes);

            start_desktop ();

            var main_loop = new MainLoop ();
            main_loop.run ();
        }

        void load_config () {
            var settings = new Settings ("org.elementary.cerbere.settings");
            desktop_bins = settings.get_strv ("desktop-components");
            max_crashes = settings.get_int ("max-crashes");
            crash_time = settings.get_double ("crash-time");
        }

        void start_desktop () {
            foreach (string bin in desktop_bins) {
                if (bin != null) {
                    watchdog.watch_process (bin);
                }
            }
        }

        public static int main (string[] args) {
            var app = new Cerbere ();
            app.run (args);

            return 0;
        }
    }
}

