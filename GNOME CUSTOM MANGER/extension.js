
import St from 'gi://St';
import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import Shell from 'gi://Shell';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from
    'resource:///org/gnome/shell/extensions/extension.js';

export default class NedOrbit extends Extension {

    enable() {
    Main.getTheme().load_stylesheet(this.getStylesheet());
        this._settings = new Gio.Settings({
            schema_id: 'org.gnome.shell',
        });

        this._dock = new St.BoxLayout({
            style_class: 'ned-orbit',
            vertical: false,
            reactive: true,
        });

        this._loadApps();

        Main.layoutManager.addChrome(this._dock, {
            affectsStruts: false,
        });

        this._positionDock();

        this._monitorSignal =
            Main.layoutManager.connect(
                'monitors-changed',
                () => this._positionDock()
            );
    }

    _loadApps() {
        const favorites =
            this._settings.get_strv('favorite-apps');

        const appSystem =
            Shell.AppSystem.get_default();

        for (const id of favorites) {
            const app = appSystem.lookup_app(id);

            if (!app)
                continue;

            const icon = app.create_icon_texture(42);

            const button = new St.Button({
                child: icon,
                style_class: 'ned-orbit-app',
                reactive: true,
                can_focus: true,
                track_hover: true,
            });

            button.connect('clicked', () => {
                app.activate();
            });

            button.connect('notify::hover', () => {
                button.ease({
                    scale_x: button.hover ? 1.22 : 1.0,
                    scale_y: button.hover ? 1.22 : 1.0,
                    duration: 180,
                    mode: Clutter.AnimationMode.EASE_OUT_QUAD,
                });
            });

            this._dock.add_child(button);
        }
    }

    _positionDock() {
        const monitor =
            Main.layoutManager.primaryMonitor;

        if (!monitor || !this._dock)
            return;

        const width = Math.min(
            this._dock.get_n_children() * 62 + 28,
            monitor.width - 32
        );

        this._dock.set_width(width);

        this._dock.set_position(
            monitor.x + (monitor.width - width) / 2,
            monitor.y + monitor.height - 100
        );
    }

    disable() {
    Main.getTheme().unload_stylesheet(this.getStylesheet());

    if (this._monitorSignal) {
            Main.layoutManager.disconnect(
                this._monitorSignal
            );
            this._monitorSignal = null;
        }

        this._dock?.destroy();
        this._dock = null;

        this._settings = null;
    }
}
