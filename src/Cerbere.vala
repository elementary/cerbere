/* -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*- */
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
 *          Victor Eduardo <victoreduardm@gmail.com>
 */

public class Cerbere : Application {

    public static SettingsManager settings { get; private set; default = null; }
    private Watchdog? watchdog = null;
    private SessionManager.ClientService? sm_client = null;

    construct {
        application_id = "org.pantheon.cerbere";
        flags = ApplicationFlags.IS_SERVICE;
        Log.set_handler (null, LogLevelFlags.LEVEL_MASK, log_handler);
    }

    private static void log_handler (string? domain, LogLevelFlags level, string message) {
#if DEBUG
        if (level >= LogLevelFlags.LEVEL_INFO)
            level = LogLevelFlags.LEVEL_MESSAGE;
#endif
        Log.default_handler (domain, level, message);
    }

    protected override void startup () {
        // Try to register Cerbere with the session manager.
        register_session_client_async ();

        this.settings = new SettingsManager ();
        start_processes (this.settings.process_list);

        // Monitor changes to the process list
        this.settings.process_list_changed.connect (this.start_processes);

        var main_loop = new MainLoop ();
        main_loop.run ();
    }

    private async void register_session_client_async () {
        if (this.sm_client != null)
            return;

        this.sm_client = new SessionManager.ClientService (this.application_id);

        try {
            this.sm_client.register ();
        } catch (SessionManager.ConnectionError e) {
            critical (e.message);
            return_if_reached ();
        }

        if (this.sm_client != null) {
            // The session manager may ask us to quit the service, and so we do.
            this.sm_client.stop_service.connect ( () => {
                message ("Exiting...");
                this.quit_mainloop ();
            });
        }
    }

    private void start_processes (string[] process_list) {
        if (this.watchdog == null) {
            this.watchdog = new Watchdog ();
        }

        foreach (string cmd in process_list) {
            this.watchdog.add_process_async (cmd);
        }
    }

    public static int main (string[] args) {
        var app = new Cerbere ();
        return app.run (args);
    }
}
