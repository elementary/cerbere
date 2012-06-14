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

public class SettingsManager : Object {

    public signal void process_list_changed (string[] new_values);

    static const string SETTINGS_PATH = "org.pantheon.cerbere";

    static const string MAX_CRASHES_KEY = "max-crashes";
    static const string CRASH_TIME_INTERVAL_KEY = "crash-time-interval";
    static const string MONITORED_PROCESSES_KEY = "monitored-processes";

    public string[] process_list   { get; set; }
    public uint max_crashes         { get; set; default = 0; }
    public uint crash_time_interval { get; set; default = 0; }

    private Settings? settings = null;

    public SettingsManager () {
        this.settings = new Settings (SETTINGS_PATH);

        this.settings.bind (MAX_CRASHES_KEY, this, "max-crashes", SettingsBindFlags.DEFAULT);
        this.settings.bind (CRASH_TIME_INTERVAL_KEY, this, "crash-time-interval", SettingsBindFlags.DEFAULT);
        this.settings.bind (MONITORED_PROCESSES_KEY, this, "process-list", SettingsBindFlags.DEFAULT);

        this.settings.changed[MONITORED_PROCESSES_KEY].connect (this.on_process_list_changed);
    }

    private void on_process_list_changed () {
        this.process_list_changed (this.settings.get_strv (MONITORED_PROCESSES_KEY));
    }
}
