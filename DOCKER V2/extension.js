import St from 'gi://St';
import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import Graphene from 'gi://Graphene';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

// ---- geometry --------------------------------------------------------
const SIZE = 860, C = SIZE / 2;
const R_CENTER = 112;          // centre disc
const R1 = 126, R2 = 250;      // main ring
const R3 = 262, R4 = 352;      // sub ring
const TAU = Math.PI * 2;
const SUB_STEP = 0.36;         // radians per sub item
const PAD = 0.018;

// ---- default items (override with ~/.config/radial-dock/items.json) ---
// cmd "shell:apps" opens the GNOME app grid.
const DEFAULT_ITEMS = [
    {label: 'TERMINAL', icon: 'utilities-terminal-symbolic', color: '#22d3ee', cmd: 'ptyxis'},
    {label: 'FILES', icon: 'folder-symbolic', color: '#a78bfa', cmd: 'nautilus'},
    {label: 'DEV', icon: 'applications-engineering-symbolic', color: '#ff2d95', children: [
        {label: 'VS CODE', icon: 'text-editor-symbolic', cmd: 'code'},
        {label: 'TERMINAL', icon: 'utilities-terminal-symbolic', cmd: 'ptyxis'},
        {label: 'GITHUB', icon: 'network-workgroup-symbolic', cmd: 'xdg-open https://github.com/Edwinshajan2006'},
        {label: 'LOCALHOST', icon: 'web-browser-symbolic', cmd: 'xdg-open http://localhost:3000'},
    ]},
    {label: 'BROWSER', icon: 'web-browser-symbolic', color: '#38bdf8', cmd: 'firefox'},
    {label: 'MEDIA', icon: 'applications-multimedia-symbolic', color: '#f59e0b', cmd: 'showtime'},
    {label: 'APPS', icon: 'view-app-grid-symbolic', color: '#34d399', cmd: 'shell:apps'},
    {label: 'CONFIG', icon: 'preferences-system-symbolic', color: '#94a3b8', cmd: 'gnome-control-center'},
    {label: 'POWER', icon: 'system-shutdown-symbolic', color: '#22d3ee', children: [
        {label: 'LOCK', icon: 'system-lock-screen-symbolic', cmd: 'loginctl lock-session'},
        {label: 'SUSPEND', icon: 'media-playback-pause-symbolic', cmd: 'systemctl suspend'},
        {label: 'RESTART', icon: 'system-reboot-symbolic', cmd: 'systemctl reboot'},
        {label: 'POWER OFF', icon: 'system-shutdown-symbolic', cmd: 'systemctl poweroff'},
    ]},
];

function hexToRgb(h) {
    const n = parseInt(h.replace('#', ''), 16);
    return [(n >> 16 & 255) / 255, (n >> 8 & 255) / 255, (n & 255) / 255];
}

function loadItems() {
    try {
        const path = GLib.build_filenamev([GLib.get_user_config_dir(), 'radial-dock', 'items.json']);
        if (GLib.file_test(path, GLib.FileTest.EXISTS)) {
            const [, bytes] = GLib.file_get_contents(path);
            const items = JSON.parse(new TextDecoder().decode(bytes));
            if (Array.isArray(items) && items.length >= 2) return items;
        }
    } catch (e) {
        console.error(`radial-dock: bad items.json: ${e}`);
    }
    return DEFAULT_ITEMS;
}

class Dock {
    constructor() {
        this._overlay = null;
        this._timer = 0;
        this._prevCpu = null;
        this._cpu = 0;
        this._ram = 0;
    }

    get isOpen() { return this._overlay !== null; }
    toggle() { this.isOpen ? this.hide() : this.show(); }

    show() {
        if (this._overlay) return;
        this._items = loadItems();
        this._n = this._items.length;
        this._step = TAU / this._n;
        this._start = -Math.PI / 2 - this._step / 2;
        this._open = -1;
        this._hover = null;
        this._subActors = [];

        const mon = Main.layoutManager.currentMonitor;
        this._overlay = new St.Widget({
            reactive: true, can_focus: true,
            x: mon.x, y: mon.y, width: mon.width, height: mon.height,
            style: 'background-color: rgba(4,4,12,0.55);',
        });
        this._box = new St.Widget({
            width: SIZE, height: SIZE,
            x: Math.round((mon.width - SIZE) / 2), y: Math.round((mon.height - SIZE) / 2),
            pivot_point: new Graphene.Point({x: 0.5, y: 0.5}),
        });
        const scale = Math.min(1, (mon.height - 30) / SIZE);
        this._box.set_scale(scale, scale);
        this._overlay.add_child(this._box);

        this._area = new St.DrawingArea({width: SIZE, height: SIZE});
        this._area.connect('repaint', () => this._draw());
        this._box.add_child(this._area);

        this._buildMain();
        this._buildCenter();

        this._overlay.connect('motion-event', (_a, ev) => this._onMotion(ev));
        this._overlay.connect('button-press-event', (_a, ev) => this._onClick(ev));
        this._overlay.connect('key-press-event', (_a, ev) => {
            if (ev.get_key_symbol() === Clutter.KEY_Escape) { this.hide(); return Clutter.EVENT_STOP; }
            return Clutter.EVENT_PROPAGATE;
        });

        Main.layoutManager.uiGroup.add_child(this._overlay);
        this._grab = Main.pushModal(this._overlay);
        if (!this._grab) { this._overlay.destroy(); this._overlay = null; return; }
        this._overlay.grab_key_focus();

        this._overlay.opacity = 0;
        this._overlay.ease({opacity: 255, duration: 140, mode: Clutter.AnimationMode.EASE_OUT_QUAD});

        this._tick();
        this._timer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => { this._tick(); return GLib.SOURCE_CONTINUE; });
    }

    hide() {
        if (!this._overlay) return;
        if (this._timer) { GLib.source_remove(this._timer); this._timer = 0; }
        if (this._grab) { Main.popModal(this._grab); this._grab = null; }
        const ov = this._overlay;
        this._overlay = null;
        ov.ease({opacity: 0, duration: 110, mode: Clutter.AnimationMode.EASE_IN_QUAD, onComplete: () => ov.destroy()});
    }

    destroy() {
        if (this._timer) { GLib.source_remove(this._timer); this._timer = 0; }
        if (this._grab) { Main.popModal(this._grab); this._grab = null; }
        this._overlay?.destroy();
        this._overlay = null;
    }

    // ---- widgets -------------------------------------------------------
    _mkItem(item, x, y) {
        const box = new St.BoxLayout({vertical: true, width: 112, height: 66, reactive: false});
        const icon = new St.Icon({icon_name: item.icon, icon_size: 30, x_align: Clutter.ActorAlign.CENTER});
        const label = new St.Label({text: item.label, x_align: Clutter.ActorAlign.CENTER});
        box.add_child(icon);
        box.add_child(label);
        box.set_position(Math.round(x - 56), Math.round(y - 33));
        this._box.add_child(box);
        return {box, icon, label};
    }

    _angleOf(i) { return this._start + (i + 0.5) * this._step; }

    _buildMain() {
        this._mainActors = this._items.map((it, i) => {
            const a = this._angleOf(i), r = (R1 + R2) / 2;
            return this._mkItem(it, C + r * Math.cos(a), C + r * Math.sin(a));
        });
        this._refreshStyles();
    }

    _buildSub() {
        this._subActors.forEach(s => s.box.destroy());
        this._subActors = [];
        if (this._open < 0) return;
        const kids = this._items[this._open].children;
        const ac = this._angleOf(this._open);
        const base = ac - kids.length * SUB_STEP / 2;
        this._subActors = kids.map((k, j) => {
            const a = base + (j + 0.5) * SUB_STEP, r = (R3 + R4) / 2;
            return this._mkItem(k, C + r * Math.cos(a), C + r * Math.sin(a));
        });
        this._refreshStyles();
    }

    _buildCenter() {
        const col = new St.BoxLayout({vertical: true, width: 200, height: 150, x: C - 100, y: C - 78});
        this._clock = new St.Label({text: '', x_align: Clutter.ActorAlign.CENTER,
            style: 'color:white;font-size:30pt;font-weight:bold;'});
        this._date = new St.Label({text: '', x_align: Clutter.ActorAlign.CENTER,
            style: 'color:#9ca3af;font-size:8pt;font-weight:bold;'});
        this._cpuLbl = new St.Label({text: '', x_align: Clutter.ActorAlign.CENTER,
            style: 'color:#8b5cf6;font-size:22pt;font-weight:bold;'});
        this._ramLbl = new St.Label({text: '', x_align: Clutter.ActorAlign.CENTER,
            style: 'color:#d1d5db;font-size:8pt;font-weight:bold;'});
        [this._clock, this._date, this._cpuLbl, this._ramLbl].forEach(a => col.add_child(a));
        this._box.add_child(col);
    }

    _refreshStyles() {
        const apply = (actors, items, level) => actors.forEach((a, i) => {
            const it = items[i];
            const hot = this._hover && this._hover.level === level && this._hover.i === i;
            const sel = level === 0 && this._open === i;
            const color = level === 0 ? it.color : this._items[this._open].color;
            const c = (hot || sel) ? color : '#e5e7eb';
            a.icon.set_style(`color:${c};`);
            a.label.set_style(`color:${c};font-size:8pt;font-weight:bold;`);
        });
        apply(this._mainActors, this._items, 0);
        if (this._open >= 0) apply(this._subActors, this._items[this._open].children, 1);
    }

    // ---- stats ---------------------------------------------------------
    _tick() {
        if (!this._overlay) return;
        try {
            const [, b] = GLib.file_get_contents('/proc/stat');
            const f = new TextDecoder().decode(b).split('\n')[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + (f[4] || 0), total = f.reduce((x, y) => x + y, 0);
            if (this._prevCpu) {
                const dt = total - this._prevCpu.total, di = idle - this._prevCpu.idle;
                this._cpu = dt > 0 ? Math.round(100 * (1 - di / dt)) : 0;
            }
            this._prevCpu = {idle, total};
            const [, m] = GLib.file_get_contents('/proc/meminfo');
            const txt = new TextDecoder().decode(m);
            const tot = Number(/MemTotal:\s+(\d+)/.exec(txt)[1]);
            const av = Number(/MemAvailable:\s+(\d+)/.exec(txt)[1]);
            this._ram = Math.round(100 * (1 - av / tot));
        } catch (e) { /* ignore */ }
        const now = GLib.DateTime.new_now_local();
        this._clock.text = now.format('%H:%M');
        this._date.text = now.format('%a, %d %b').toUpperCase();
        this._cpuLbl.text = `${this._cpu}%`;
        this._ramLbl.text = `CPU ${this._cpu}%   RAM ${this._ram}%`;
        this._area.queue_repaint();
    }

    // ---- drawing -------------------------------------------------------
    _sector(cr, r1, r2, a0, a1) {
        cr.newPath();
        cr.arc(C, C, r2, a0, a1);
        cr.arcNegative(C, C, r1, a1, a0);
        cr.closePath();
    }

    _paintSector(cr, r1, r2, a0, a1, rgb, active) {
        this._sector(cr, r1, r2, a0, a1);
        cr.setSourceRGBA(0.07, 0.10, 0.16, 0.92);
        cr.fillPreserve();
        if (active) {
            cr.setSourceRGBA(rgb[0], rgb[1], rgb[2], 0.22);
            cr.fillPreserve();
            cr.setSourceRGBA(rgb[0], rgb[1], rgb[2], 1);
            cr.setLineWidth(3);
        } else {
            cr.setSourceRGBA(rgb[0], rgb[1], rgb[2], 0.35);
            cr.setLineWidth(1.5);
        }
        cr.stroke();
    }

    _draw() {
        const cr = this._area.get_context();

        // centre disc + cpu arc
        cr.arc(C, C, R_CENTER, 0, TAU);
        cr.setSourceRGBA(0.04, 0.04, 0.09, 0.95);
        cr.fillPreserve();
        cr.setSourceRGBA(1, 1, 1, 0.08);
        cr.setLineWidth(2);
        cr.stroke();
        cr.setLineWidth(6);
        cr.setLineCap(1);
        cr.setSourceRGBA(1, 1, 1, 0.07);
        cr.arc(C, C, R_CENTER - 10, 0, TAU);
        cr.stroke();
        cr.setSourceRGBA(0.55, 0.20, 1, 1);
        cr.arc(C, C, R_CENTER - 10, -Math.PI / 2, -Math.PI / 2 + TAU * Math.max(0.01, this._cpu / 100));
        cr.stroke();

        // main ring
        for (let i = 0; i < this._n; i++) {
            const a0 = this._start + i * this._step + PAD, a1 = this._start + (i + 1) * this._step - PAD;
            const active = (this._hover?.level === 0 && this._hover.i === i) || this._open === i;
            this._paintSector(cr, R1, R2, a0, a1, hexToRgb(this._items[i].color), active);
        }

        // sub ring
        if (this._open >= 0) {
            const parent = this._items[this._open];
            const rgb = hexToRgb(parent.color);
            const kids = parent.children, ac = this._angleOf(this._open);
            const base = ac - kids.length * SUB_STEP / 2;
            for (let j = 0; j < kids.length; j++) {
                const active = this._hover?.level === 1 && this._hover.i === j;
                this._paintSector(cr, R3, R4, base + j * SUB_STEP + PAD, base + (j + 1) * SUB_STEP - PAD, rgb, active);
            }
        }
        cr.$dispose();
    }

    // ---- input ---------------------------------------------------------
    _local(ev) {
        const [x, y] = ev.get_coords();
        const [ok, lx, ly] = this._box.transform_stage_point(x, y);
        return ok ? [lx, ly] : [-9999, -9999];
    }

    _hit(x, y) {
        const dx = x - C, dy = y - C, r = Math.hypot(dx, dy), a = Math.atan2(dy, dx);
        if (r >= R1 && r <= R2) {
            let rel = (a - this._start) % TAU; if (rel < 0) rel += TAU;
            return {level: 0, i: Math.floor(rel / this._step) % this._n};
        }
        if (this._open >= 0 && r >= R3 && r <= R4) {
            const kids = this._items[this._open].children;
            const total = kids.length * SUB_STEP;
            let rel = (a - (this._angleOf(this._open) - total / 2)) % TAU; if (rel < 0) rel += TAU;
            if (rel < total) return {level: 1, i: Math.floor(rel / SUB_STEP)};
        }
        return null;
    }

    _setOpen(i) {
        if (i === this._open) return;
        this._open = i;
        this._buildSub();
    }

    _onMotion(ev) {
        const hit = this._hit(...this._local(ev));
        this._hover = hit;
        if (hit?.level === 0)
            this._setOpen(this._items[hit.i].children ? hit.i : -1);
        this._refreshStyles();
        this._area.queue_repaint();
        return Clutter.EVENT_STOP;
    }

    _onClick(ev) {
        const hit = this._hit(...this._local(ev));
        if (!hit) {
            const [x, y] = this._local(ev);
            if (Math.hypot(x - C, y - C) > R4 + 10) this.hide();
            return Clutter.EVENT_STOP;
        }
        const item = hit.level === 0 ? this._items[hit.i] : this._items[this._open].children[hit.i];
        if (item.children) { this._setOpen(hit.i); this._area.queue_repaint(); return Clutter.EVENT_STOP; }
        this.hide();
        this._run(item.cmd);
        return Clutter.EVENT_STOP;
    }

    _run(cmd) {
        if (!cmd) return;
        if (cmd === 'shell:apps') {
            GLib.idle_add(GLib.PRIORITY_DEFAULT, () => { Main.overview.showApps(); return GLib.SOURCE_REMOVE; });
            return;
        }
        try {
            const [, argv] = GLib.shell_parse_argv(cmd);
            Gio.Subprocess.new(argv, Gio.SubprocessFlags.NONE);
        } catch (e) {
            Main.notify('Radial Dock', `Could not run: ${cmd}`);
        }
    }
}

export default class RadialDockExtension extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._dock = new Dock();
        Main.wm.addKeybinding('toggle-dock', this._settings, Meta.KeyBindingFlags.NONE,
            Shell.ActionMode.NORMAL | Shell.ActionMode.OVERVIEW, () => this._dock.toggle());
    }

    disable() {
        Main.wm.removeKeybinding('toggle-dock');
        this._dock?.destroy();
        this._dock = null;
        this._settings = null;
    }
}
