import Clutter from "gi://Clutter";
import Gio from "gi://Gio";
import St from "gi://St";
import * as Main from "resource:///org/gnome/shell/ui/main.js";
import {Extension} from "resource:///org/gnome/shell/extensions/extension.js";

class NedCard extends St.Button {
    constructor(title, icon, command) {
        super({
            reactive: true,
            can_focus: true,
            track_hover: true,
            style: "background: rgba(255,255,255,0.07); border-radius: 14px; padding: 12px; margin: 4px; min-width: 110px; min-height: 72px;"
        });

        const box = new St.BoxLayout({
            vertical: true,
            x_align: Clutter.ActorAlign.CENTER,
            y_align: Clutter.ActorAlign.CENTER,
            x_expand: true,
            y_expand: true
        });

        box.add_child(new St.Icon({
            icon_name: icon,
            icon_size: 24,
            style: "margin-bottom: 7px;"
        }));

        box.add_child(new St.Label({
            text: title,
            style: "font-size: 11px; font-weight: 600;",
            x_align: Clutter.ActorAlign.CENTER
        }));

        this.set_child(box);

        this.connect("clicked", () => {
            try {
                Gio.Subprocess.new(
                    ["sh", "-c", command],
                    Gio.SubprocessFlags.NONE
                );
            } catch (e) {
                logError(e, "NED-OS command failed");
            }
        });
    }
}

export default class NedControlCenter extends Extension {
    enable() {
        const quickSettings = Main.panel.statusArea.quickSettings;
        const grid = quickSettings?.menu?._grid;

        if (!grid) {
            log("NED-OS: Quick Settings grid unavailable");
            return;
        }

        this._grid = grid;
        this._oldChildren = grid.get_children().slice();
        this._oldChildren.forEach(child => child.hide());

        this._root = new St.BoxLayout({
            vertical: true,
            x_expand: true,
            style: "padding: 8px;"
        });

        const header = new St.BoxLayout({
            vertical: false,
            x_expand: true,
            style: "padding: 6px 10px 12px;"
        });

        header.add_child(new St.Label({
            text: "NED-OS",
            style: "font-size: 20px; font-weight: 800;"
        }));

        header.add_child(new St.Label({
            text: "  SYSTEM CONTROL CENTER",
            style: "font-size: 9px; opacity: 0.55; padding-top: 7px;"
        }));

        this._root.add_child(header);

        const row1 = new St.BoxLayout({
            x_expand: true
        });

        row1.add_child(new NedCard(
            "Wi-Fi",
            "network-wireless-symbolic",
            "nmcli radio wifi off || nmcli radio wifi on"
        ));

        row1.add_child(new NedCard(
            "Bluetooth",
            "bluetooth-active-symbolic",
            "bluetoothctl power on"
        ));

        this._root.add_child(row1);

        const row2 = new St.BoxLayout({
            x_expand: true
        });

        row2.add_child(new NedCard(
            "Settings",
            "emblem-system-symbolic",
            "gnome-control-center"
        ));

        row2.add_child(new NedCard(
            "Lock",
            "system-lock-screen-symbolic",
            "loginctl lock-session"
        ));

        this._root.add_child(row2);

        const row3 = new St.BoxLayout({
            x_expand: true
        });

        row3.add_child(new NedCard(
            "Dark Mode",
            "weather-clear-night-symbolic",
            "gsettings set org.gnome.desktop.interface color-scheme prefer-dark"
        ));

        row3.add_child(new NedCard(
            "Night Light",
            "display-brightness-symbolic",
            "gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true"
        ));

        this._root.add_child(row3);

        this._root.add_child(new St.Label({
            text: "NED-OS  •  Fedora 44",
            style: "font-size: 9px; opacity: 0.45; padding: 10px 0 3px;",
            x_align: Clutter.ActorAlign.CENTER
        }));

        grid.add_child(this._root);

        try {
            grid.layout_manager.child_set_property(
                grid,
                this._root,
                "column-span",
                2
            );
        } catch (e) {
            logError(e, "NED-OS: grid span failed");
        }
    }

    disable() {
        if (this._root) {
            this._root.destroy();
            this._root = null;
        }

        if (this._oldChildren) {
            this._oldChildren.forEach(child => child.show());
            this._oldChildren = null;
        }

        this._grid = null;
    }
}
