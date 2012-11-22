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

namespace Cerbere.SessionManager {

    public errordomain ConnectionError {
        CONNECTION_FAILED,
        CLIENT_REGISTRATION_FAILED
    }

    /**
     * GNOME Session Manager DBus API
     *
     * API Reference: [[http://www.gnome.org/~mccann/gnome-session/docs/gnome-session.html]]
     * (Consulted on July 4, 2012.)
     */
    private const string DBUS_NAME = "org.gnome.SessionManager";
    private const string DBUS_PATH = "/org/gnome/SessionManager";

    [DBus (name = "org.gnome.SessionManager")]
    private interface SessionManagerIface : Object {
        // Many API methods have been left out. Feel free to add them when required.
        public abstract void RegisterClient (string app_id, string client_startup_id,
                                             out ObjectPath client_id) throws IOError;
        public abstract void UnregisterClient (ObjectPath client_id) throws IOError;
    }

    [DBus (name = "org.gnome.SessionManager.ClientPrivate")]
    private interface ClientPrivateIface : Object {
        public abstract void EndSessionResponse (bool is_ok, string reason) throws IOError;
        public signal void QueryEndSession (uint flags);
        public signal void EndSession (uint flags);
        public signal void CancelEndSession ();
        public signal void Stop ();
    }


    /**
     * CLIENT
     *
     * This class handles both the registration of the service,
     * and action requests coming from the session-manager side.
     */
    public class Client : Object {
        public signal void stop_service ();

        private SessionManagerIface? session_manager = null;
        private ClientPrivateIface? client = null;
        private ObjectPath? client_id = null;
        public string? app_id { get; private set; default = null; }

        public Client (string app_id) {
            this.app_id = app_id;
        }

        public void register () throws ConnectionError {
            bool connected = true;

            if (session_manager == null) {
                connected = connect_session ();

                if (!connected)
                    throw new ConnectionError.CONNECTION_FAILED ("Could not connect to session manager");
            }

            // NOTE: if you're planning to use this code in other app, pass your app's name
            // to register_client() instead of the value of DESKTOP_AUTOSTART_ID, unless the
            // app is a desktop component as well (e.g. panel, dock, etc.)
            string? startup_id = Environment.get_variable ("DESKTOP_AUTOSTART_ID");

            if (startup_id == null) {
                critical ("Could not get value of environment variable DESKTOP_AUTOSTART_ID");
                startup_id = app_id;
            }

            connected = register_client (startup_id);

            if (!connected) {
                // Disconnect from SM
                session_manager = null;
                throw new ConnectionError.CLIENT_REGISTRATION_FAILED ("Unable to register client with session manager");
            }
        }

        public void unregister () {
            return_if_fail (session_manager != null && client_id != null);

            debug ("Unregistering client: %s", client_id);

            try {
                session_manager.UnregisterClient (client_id);
            } catch (IOError e) {
                critical (e.message);
            }
        }

        private bool connect_session () {
            if (session_manager == null) {
                try {
                    session_manager = Bus.get_proxy_sync (BusType.SESSION, DBUS_NAME, DBUS_PATH);
                } catch (IOError e) {
                    critical (e.message);
                }
            }

            return session_manager != null;
        }

        private bool register_client (string startup_id) {
            return_val_if_fail (session_manager != null && app_id != null, false);

            // Register client
            if (client == null) {
                try {
                    session_manager.RegisterClient (app_id, startup_id, out client_id);
                } catch (IOError e) {
                    critical ("Could not register client: %s", e.message);
                }

                return_val_if_fail (client_id != null, false);

                debug ("Registered session manager client: %s", client_id);

                // Get client
                try {
                    client = Bus.get_proxy_sync (BusType.SESSION, DBUS_NAME, client_id);
                } catch (IOError e) {
                    critical ("Could not get client: %s", e.message);
                    return_val_if_reached (false);
                }

                debug ("Obtained gnome-session client proxy");

                // Connect signals
                client.QueryEndSession.connect (on_client_query_end_session);
                client.EndSession.connect (on_client_end_session);
                client.CancelEndSession.connect (on_client_cancel_end_session);
                client.Stop.connect (on_client_stop);
            }

            return client != null;
        }


        /** ClientPrivateIface Signal handlers **/

        private void on_client_query_end_session (uint flags) {
            debug ("Client query end session");
            return_if_fail (client != null);

            send_end_session_response (true);
        }

        private void on_client_end_session (uint flags) {
            debug ("Client end session");
            return_if_fail (client != null);

            send_end_session_response (true);
        }

        private void on_client_cancel_end_session () {
            debug ("Client: Received EndSessionCanceled signal");
            // There's nothing we should do here
        }

        private void on_client_stop () {
            debug ("Client: Received Stop signal");
            terminate_service ();
        }

        /* Convenient functions */

        private void send_end_session_response (bool is_okay, string reason = "")  {
            return_if_fail (client != null);

            // Tell the session manager whether it's okay to logout, shut down, etc.
            try {
                debug ("Sending is_okay = %s to session manager", is_okay.to_string ());
                client.EndSessionResponse (is_okay, reason);
            } catch (IOError e) {
                warning ("Couldn't reply to session manager: %s", e.message);
            }
        }

        private void terminate_service () {
            unregister ();
            stop_service ();
        }
    }
}
