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

public class Cerbere.App : Application {
    public static SettingsManager settings { get; private set; }

    private static int ref_count = 0;
    private Watchdog watchdog;
    private SessionManager.Client sm_client;

    construct {
        application_id = "io.elementary.cerbere";
        flags = ApplicationFlags.IS_SERVICE;
    }

    public override void startup () {
        base.startup ();

        // Try to register Cerbere with the session manager.
        if (!register_session_client ())
            return;

        settings = new SettingsManager ();
        start_processes (settings.process_list);

        // Monitor changes to the process list
        settings.process_list_changed.connect (start_processes);

        // let's keep running
        hold ();
        GLib.AtomicInt.inc (ref ref_count);
    }

    private bool register_session_client () {
        if (sm_client != null)
            return false;

        sm_client = new SessionManager.Client (application_id);

        try {
            sm_client.register ();
            // The session manager may ask us to quit the service, and so we do.
            sm_client.stop_service.connect (quit_service);
            // Cleanly shutdown when receiving SIGTERM or SIGHUP.
            Posix.signal (Posix.Signal.TERM, handle_sigterm);
            Posix.signal (Posix.Signal.HUP, handle_sighup);
            return true;
        } catch (SessionManager.ConnectionError e) {
            critical (e.message);
            return false;
        }
    }

    private void start_processes (string[] process_list) {
        if (watchdog == null)
            watchdog = new Watchdog ();

        foreach (string cmd in process_list)
            watchdog.add_process (cmd);
    }

    private void stop_service (string requestor) {
        if (GLib.AtomicInt.dec_and_test (ref ref_count)) {
            message (@"Closing Cerbere as requested by $requestor");
            release ();
        }
    }

    private void quit_service () {
        stop_service ("SessionManager");
    }

    private void handle_sigterm () {
        stop_service ("SIGTERM");
    }

    private void handle_sighup () {
        stop_service ("SIGHUP");
    }

    public static int main (string[] args) {
        var app = new Cerbere.App ();
        return app.run (args);
    }
}
