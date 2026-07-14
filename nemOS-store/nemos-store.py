#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
nemOS Store — Boutique d'applications légère pour nemOS
Interface GTK3 style macOS App Store, thème sombre.
"""

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GdkPixbuf', '2.0')
gi.require_version('Gio', '2.0')
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, Pango, GObject, Gio

import json
import os
import subprocess
import threading
import re
import sys

# ─── Constantes de style ─────────────────────────────────────────────────────

BG_DARK      = "#1E1E2E"
BG_CARD      = "#282840"
BG_SIDEBAR   = "#16161E"
BG_HEADER    = "#181825"
ACCENT       = "#1A73E8"
ACCENT_HOVER = "#2B82EA"
TEXT_PRIMARY  = "#CDD6F4"
TEXT_SECONDARY = "#A6ADC8"
TEXT_DIMMED   = "#6C7086"
GREEN        = "#A6E3A1"
RED          = "#F38BA8"
ORANGE       = "#FAB387"
BORDER_COLOR = "#313244"
RADIUS       = 12
ICON_SIZE    = 48

CATALOG_PATHS = [
    "/usr/share/nemos-store/package-catalog.json",
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "package-catalog.json"),
]

# ─── Fournisseur de thème CSS ─────────────────────────────────────────────────

CSS = """
#main-window {
    background-color: {bg};
}
#header-bar {
    background-color: {header_bg};
    border-bottom: 1px solid {border};
    padding: 6px 12px;
}
#header-bar GtkLabel {
    color: {text};
    font-weight: bold;
    font-size: 15px;
}
#search-entry {
    background-color: {card};
    color: {text};
    border: 1px solid {border};
    border-radius: 8px;
    padding: 6px 12px;
    font-size: 13px;
}
#search-entry:focus {
    border-color: {accent};
}
#search-entry::placeholder {
    color: {dimmed};
}
#sidebar {
    background-color: {sidebar_bg};
    border-right: 1px solid {border};
}
#sidebar-row {
    padding: 10px 16px;
    border-radius: 8px;
    margin: 2px 6px;
    transition: all 150ms ease;
}
#sidebar-row:hover {
    background-color: {card};
}
#sidebar-row:selected {
    background-color: {accent};
    color: white;
}
#sidebar-row GtkLabel {
    color: {text};
    font-size: 13px;
}
#sidebar-row:selected GtkLabel {
    color: white;
}
#content-area {
    background-color: {bg};
}
#package-card {
    background-color: {card};
    border-radius: {radius}px;
    border: 1px solid {border};
    padding: 14px;
    transition: all 200ms ease;
}
#package-card:hover {
    border-color: {accent};
    box-shadow: 0 2px 12px rgba(26, 115, 232, 0.15);
}
#pkg-name {
    color: {text};
    font-weight: 600;
    font-size: 13px;
}
#pkg-desc {
    color: {secondary};
    font-size: 11px;
}
#pkg-version {
    color: {dimmed};
    font-size: 10px;
}
#pkg-size {
    color: {dimmed};
    font-size: 10px;
}
#btn-install {
    background-color: {accent};
    color: white;
    border-radius: 6px;
    border: none;
    padding: 5px 14px;
    font-size: 11px;
    font-weight: 600;
    transition: all 150ms ease;
}
#btn-install:hover {
    background-color: {accent_hover};
}
#btn-remove {
    background-color: {red};
    color: white;
    border-radius: 6px;
    border: none;
    padding: 5px 14px;
    font-size: 11px;
    font-weight: 600;
    transition: all 150ms ease;
}
#btn-remove:hover {
    background-color: #e06c90;
}
#btn-installed {
    background-color: {card};
    color: {green};
    border-radius: 6px;
    border: 1px solid {green};
    padding: 5px 14px;
    font-size: 11px;
    font-weight: 600;
}
#btn-progress {
    background-color: {orange};
    color: #1E1E2E;
    border-radius: 6px;
    border: none;
    padding: 5px 14px;
    font-size: 11px;
    font-weight: 600;
}
#status-bar {
    background-color: {header_bg};
    border-top: 1px solid {border};
    padding: 4px 12px;
    color: {dimmed};
    font-size: 11px;
}
#featured-box {
    background-color: {card};
    border-radius: {radius}px;
    border: 1px solid {border};
    padding: 20px;
    margin-bottom: 16px;
}
#featured-title {
    color: {text};
    font-size: 18px;
    font-weight: bold;
}
#featured-subtitle {
    color: {secondary};
    font-size: 12px;
    margin-bottom: 12px;
}
#featured-card {
    background-color: {bg};
    border-radius: 8px;
    padding: 12px;
    border: 1px solid {border};
}
#scroll-area {
    background-color: transparent;
}
#scroll-area GtkViewport {
    background-color: transparent;
}
#empty-state {
    color: {dimmed};
    font-size: 14px;
    padding: 40px;
}
#updates-badge {
    background-color: {red};
    color: white;
    border-radius: 10px;
    padding: 1px 6px;
    font-size: 10px;
    font-weight: bold;
}
#section-label {
    color: {text};
    font-size: 16px;
    font-weight: 600;
    margin: 8px 0px 8px 4px;
}
#loading-spinner {
    color: {accent};
}
#error-box {
    background-color: {card};
    border-radius: 8px;
    border: 1px solid {red};
    padding: 16px;
    margin: 12px;
}
#error-label {
    color: {red};
    font-size: 13px;
}
""".format(
    bg=BG_DARK, card=BG_CARD, sidebar_bg=BG_SIDEBAR, header_bg=BG_HEADER,
    accent=ACCENT, accent_hover=ACCENT_HOVER, text=TEXT_PRIMARY,
    secondary=TEXT_SECONDARY, dimmed=TEXT_DIMMED, border=BORDER_COLOR,
    radius=RADIUS, green=GREEN, red=RED, orange=ORANGE,
)


# ─── Chargement du catalogue ─────────────────────────────────────────────────

def load_catalog():
    """Charge le catalogue JSON depuis les chemins connus."""
    for path in CATALOG_PATHS:
        if os.path.exists(path):
            with open(path, 'r', encoding='utf-8') as f:
                return json.load(f)
    # Fallback : catalogue embarqué minimal
    return {"categories": [], "paquets": []}


# ─── Utilitaires pacman / pamac ───────────────────────────────────────────────

def run_command(cmd, timeout=30):
    """Exécute une commande et retourne (returncode, stdout, stderr)."""
    try:
        proc = subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout
        )
        return proc.returncode, proc.stdout.strip(), proc.stderr.strip()
    except subprocess.TimeoutExpired:
        return -1, "", "Délai d'attente dépassé"
    except FileNotFoundError:
        return -2, "", "Commande introuvable"
    except Exception as e:
        return -3, "", str(e)


def get_pacman_info(pkg_name):
    """Récupère les infos d'un paquet via pacman -Si."""
    rc, out, err = run_command(["pacman", "-Si", pkg_name], timeout=15)
    if rc != 0:
        return None
    info = {}
    for line in out.splitlines():
        if ":" in line:
            key, val = line.split(":", 1)
            info[key.strip().lower()] = val.strip()
    return info


def get_local_info(pkg_name):
    """Récupère les infos du paquet installé via pacman -Qi."""
    rc, out, err = run_command(["pacman", "-Qi", pkg_name], timeout=10)
    if rc != 0:
        return None
    info = {}
    for line in out.splitlines():
        if ":" in line:
            key, val = line.split(":", 1)
            info[key.strip().lower()] = val.strip()
    return info


def is_installed(pkg_name):
    """Vérifie si un paquet est installé."""
    rc, _, _ = run_command(["pacman", "-Q", pkg_name], timeout=5)
    return rc == 0


def get_installed_packages():
    """Retourne la liste des paquets installés."""
    rc, out, _ = run_command(["pacman", "-Qq"], timeout=10)
    if rc != 0:
        return set()
    return set(out.splitlines())


def get_updates():
    """Retourne la liste des mises à jour disponibles."""
    # D'abord vérifier le lock
    rc, _, err = run_command(["pacman", "-Qu"], timeout=15)
    if rc == 0:
        lines = [l.strip() for l in err.splitlines() if l.strip()]
        lines += [l.strip() for l in out.splitlines() if l.strip()]
        return lines
    # Essayer checkupdates
    rc2, out2, _ = run_command(["checkupdates"], timeout=30)
    if rc2 == 0 and out2.strip():
        return out2.strip().splitlines()
    return []


def install_package(pkg_name, callback=None):
    """Installe un paquet via pamac ou pacman avec polkit."""
    # Essayer pamac d'abord
    cmd = ["pamac", "install", "--no-confirm", pkg_name]
    rc, out, err = run_command(cmd, timeout=300)
    if rc == 0:
        if callback:
            GLib.idle_add(callback, True, "Installation terminée")
        return
    # Fallback : pkexec pacman
    cmd2 = ["pkexec", "pacman", "-S", "--noconfirm", pkg_name]
    rc2, out2, err2 = run_command(cmd2, timeout=300)
    if callback:
        GLib.idle_add(callback, rc2 == 0, err2 if rc2 != 0 else "Installation terminée")


def remove_package(pkg_name, callback=None):
    """Supprime un paquet via pkexec pacman."""
    cmd = ["pkexec", "pacman", "-Rns", "--noconfirm", pkg_name]
    rc, out, err = run_command(cmd, timeout=120)
    if callback:
        GLib.idle_add(callback, rc == 0, err if rc != 0 else "Suppression terminée")


def refresh_repos(callback=None):
    """Rafraîchit les dépôts pacman."""
    cmd = ["pkexec", "pacman", "-Sy"]
    rc, out, err = run_command(cmd, timeout=120)
    if callback:
        GLib.idle_add(callback, rc == 0, err if rc != 0 else "Dépôts mis à jour")


# ─── Widget carte de paquet ───────────────────────────────────────────────────

class PackageCard(Gtk.Box):
    """Carte d'un paquet affichée dans la grille."""

    __gtype_name__ = "PackageCard"

    def __init__(self, app, catalog_entry, pacman_info=None):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.app = app
        self.pkg_name = catalog_entry["nom"]
        self.catalog = catalog_entry
        self.pacman = pacman_info or {}
        self.set_name("package-card")
        self.set_margin_bottom(8)

        # ── Rangée du haut : icône + texte ──
        top_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        top_row.set_hexpand(True)

        # Icône
        icon_theme = Gtk.IconTheme.get_default()
        icon_name = catalog_entry.get("icone", self.pkg_name)
        pixbuf = None
        try:
            if icon_theme.has_icon(icon_name):
                pixbuf = icon_theme.load_icon(icon_name, ICON_SIZE, 0)
            elif icon_theme.has_icon(self.pkg_name):
                pixbuf = icon_theme.load_icon(self.pkg_name, ICON_SIZE, 0)
        except Exception:
            pass

        if pixbuf is None:
            pixbuf = self._generate_fallback_icon(catalog_entry.get("categorie", ""))

        icon_img = Gtk.Image.new_from_pixbuf(pixbuf)
        icon_img.set_pixel_size(ICON_SIZE)
        top_row.pack_start(icon_img, False, False, 0)

        # Texte
        text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        text_box.set_valign(Gtk.Align.CENTER)

        lbl_name = Gtk.Label(label=catalog_entry["nom"])
        lbl_name.set_name("pkg-name")
        lbl_name.set_xalign(0)
        lbl_name.set_ellipsize(Pango.EllipsizeMode.END)
        text_box.pack_start(lbl_name, False, False, 0)

        lbl_desc = Gtk.Label(label=catalog_entry.get("description", ""))
        lbl_desc.set_name("pkg-desc")
        lbl_desc.set_xalign(0)
        lbl_desc.set_lines(2)
        lbl_desc.set_ellipsize(Pango.EllipsizeMode.END)
        lbl_desc.set_line_wrap(True)
        lbl_desc.set_max_width_chars(30)
        text_box.pack_start(lbl_desc, False, False, 0)

        # Version et taille
        meta_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        version = self.pacman.get("version", "—")
        size = self.pacman.get("download size", "—")
        lbl_ver = Gtk.Label(label=f"v{version}")
        lbl_ver.set_name("pkg-version")
        meta_box.pack_start(lbl_ver, False, False, 0)
        lbl_size = Gtk.Label(label=size)
        lbl_size.set_name("pkg-size")
        meta_box.pack_start(lbl_size, False, False, 0)
        text_box.pack_start(meta_box, False, False, 0)

        top_row.pack_start(text_box, True, True, 0)

        # Bouton installer/désinstaller
        self.btn = Gtk.Button(label="Installer")
        self.btn.set_name("btn-install")
        self.btn.set_valign(Gtk.Align.CENTER)
        self.btn.connect("clicked", self._on_button_clicked)
        self._update_button_state()
        top_row.pack_end(self.btn, False, False, 0)

        self.pack_start(top_row, False, False, 0)

    def _generate_fallback_icon(self, category):
        """Génère une icône de secours colorée selon la catégorie."""
        colors = {
            "internet": "#1A73E8",
            "bureautique": "#A6E3A1",
            "multimedia": "#F38BA8",
            "outils": "#FAB387",
            "developpement": "#CBA6F7",
            "systeme": "#89B4FA",
            "jeux": "#F9E2AF",
        }
        color = colors.get(category, ACCENT)
        w, h = ICON_SIZE, ICON_SIZE
        try:
            import cairo
            surface = Gdk.cairo_surface_create_from_pixbuf(
                GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, w, h), 1, None
            )
            ctx = cairo.Context(surface)
            # Fond arrondi
            ctx.set_source_rgb(
                int(color[1:3], 16) / 255,
                int(color[3:5], 16) / 255,
                int(color[5:7], 16) / 255,
            )
            ctx.arc(w / 2, h / 2, w / 2 - 2, 0, 2 * 3.14159)
            ctx.fill()
            # Première lettre
            ctx.set_source_rgb(1, 1, 1)
            ctx.set_font_size(w * 0.5)
            ctx.select_font_face("Sans", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
            extents = ctx.text_extents(self.pkg_name[0].upper())
            ctx.move_to(
                (w - extents.width) / 2 - extents.x_bearing,
                (h - extents.height) / 2 - extents.y_bearing
            )
            ctx.show_text(self.pkg_name[0].upper())
            return Gdk.pixbuf_get_from_surface(surface)
        except (ImportError, Exception):
            # Fallback sans cairo : icône Pixbuf colorée
            r = int(color[1:3], 16)
            g = int(color[3:5], 16)
            b = int(color[5:7], 16)
            argb = (255 << 24) | (r << 16) | (g << 8) | b
            pb = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, w, h)
            pb.fill(argb)
            return pb

    def _update_button_state(self):
        """Met à jour l'état du bouton selon l'installation."""
        if self.pkg_name in self.app._busy_packages:
            self.btn.set_name("btn-progress")
            self.btn.set_label("Chargement…")
            self.btn.set_sensitive(False)
        elif is_installed(self.pkg_name):
            self.btn.set_name("btn-remove")
            self.btn.set_label("Supprimer")
            self.btn.set_sensitive(True)
        else:
            self.btn.set_name("btn-install")
            self.btn.set_label("Installer")
            self.btn.set_sensitive(True)

    def refresh_state(self):
        """Rafraîchit l'état d'installation de la carte."""
        self._update_button_state()

    def _on_button_clicked(self, _widget):
        """Gère le clic sur le bouton installer/supprimer."""
        if self.pkg_name in self.app._busy_packages:
            return

        if is_installed(self.pkg_name):
            self._do_remove()
        else:
            self._do_install()

    def _do_install(self):
        """Lance l'installation dans un thread."""
        self.app._busy_packages.add(self.pkg_name)
        self._update_button_state()
        self.app.update_status_bar()

        def worker():
            def cb(success, msg):
                self.app._busy_packages.discard(self.pkg_name)
                if not success:
                    self.app.show_error(
                        f"Erreur lors de l'installation de {self.pkg_name} : {msg}"
                    )
                else:
                    self.app.refresh_all_cards()
                    self.app.update_status_bar()
                self._update_button_state()

            install_package(self.pkg_name, callback=cb)

        threading.Thread(target=worker, daemon=True).start()

    def _do_remove(self):
        """Lance la suppression dans un thread."""
        self.app._busy_packages.add(self.pkg_name)
        self._update_button_state()
        self.app.update_status_bar()

        def worker():
            def cb(success, msg):
                self.app._busy_packages.discard(self.pkg_name)
                if not success:
                    self.app.show_error(
                        f"Erreur lors de la suppression de {self.pkg_name} : {msg}"
                    )
                else:
                    self.app.refresh_all_cards()
                    self.app.update_status_bar()
                self._update_button_state()

            remove_package(self.pkg_name, callback=cb)

        threading.Thread(target=worker, daemon=True).start()


# ─── Fenêtre principale ───────────────────────────────────────────────────────

class NemOSStore(Gtk.ApplicationWindow):
    """Fenêtre principale de nemOS Store."""

    def __init__(self, application):
        super().__init__(
            application=application,
            title="nemOS Store",
            default_width=900,
            default_height=650,
            resizable=True,
        )
        self.set_name("main-window")
        self.set_position(Gtk.WindowPosition.CENTER)

        # État
        self._catalog = load_catalog()
        self._current_category = "tout"
        self._search_query = ""
        self._show_updates_only = False
        self._show_installed_only = False
        self._installed_set = set()
        self._updates_list = []
        self._busy_packages = set()
        self._cards = []  # type: list[PackageCard]

        # Appliquer le CSS
        self._apply_css()

        # Construire l'interface
        self._build_ui()

        # Chargement initial en arrière-plan
        self._loading = True
        GLib.timeout_add(100, self._initial_load)

    def _apply_css(self):
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS.encode("utf-8"))
        screen = Gdk.Screen.get_default()
        ctx = Gtk.StyleContext()
        ctx.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER)

    def _build_ui(self):
        """Construit toute l'interface."""
        # ── Header bar ──
        header = Gtk.HeaderBar()
        header.set_name("header-bar")
        header.set_show_close_button(True)
        self.set_titlebar(header)

        # Logo + titre
        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        try:
            icon_theme = Gtk.IconTheme.get_default()
            logo = icon_theme.load_icon("nemos-store", 24, 0)
            if logo is None:
                logo = icon_theme.load_icon("nemos-store", 24,
                                           Gtk.IconLookupFlags.GENERIC_FALLBACK)
        except Exception:
            logo = None
        if logo:
            title_box.pack_start(Gtk.Image.new_from_pixbuf(logo), False, False, 0)
        lbl_title = Gtk.Label(label="nemOS Store")
        lbl_title.set_name("header-bar")
        title_box.pack_start(lbl_title, False, False, 0)
        header.pack_start(title_box)

        # Barre de recherche
        self.search_entry = Gtk.SearchEntry()
        self.search_entry.set_name("search-entry")
        self.search_entry.set_placeholder_text("Rechercher des applications…")
        self.search_entry.set_width_chars(28)
        self.search_entry.connect("search-changed", self._on_search_changed)
        self.search_entry.connect("activate", self._on_search_changed)
        header.pack_center(self.search_entry)

        # Bouton mise à jour
        self.btn_updates = Gtk.Button(label="Mises à jour")
        self.btn_updates.set_name("btn-install")
        self.btn_updates.connect("clicked", self._on_updates_clicked)
        header.pack_end(self.btn_updates)

        # Bouton rafraîchir
        btn_refresh = Gtk.Button()
        btn_refresh.set_name("btn-install")
        btn_refresh.set_tooltip_text("Rafraîchir les dépôts")
        btn_refresh.add(Gtk.Image.new_from_icon_name("view-refresh-symbolic", Gtk.IconSize.BUTTON))
        btn_refresh.connect("clicked", self._on_refresh_clicked)
        header.pack_end(btn_refresh)

        # ── Conteneur principal ──
        main_paned = Gtk.Paned(orientation=Gtk.Orientation.HORIZONTAL)
        main_paned.set_wide_handle(False)
        self.add(main_paned)

        # ── Sidebar ──
        sidebar_scroll = Gtk.ScrolledWindow()
        sidebar_scroll.set_name("sidebar")
        sidebar_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        sidebar_scroll.set_size_request(180, -1)
        sidebar_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        sidebar_box.set_margin_top(8)
        sidebar_box.set_margin_bottom(8)

        categories = self._catalog.get("categories", [])
        # Ajouter les catégories spéciales
        all_cats = [
            {"id": "tout", "nom": "Tout", "icone": "view-grid-symbolic"},
            {"id": "updates", "nom": "Mises à jour", "icone": "software-update-available-symbolic"},
            {"id": "installed", "nom": "Installé", "icone": "emblem-default-symbolic"},
        ]
        for c in categories:
            if c["id"] != "tout":
                all_cats.append(c)

        self._sidebar_buttons = {}
        for cat in all_cats:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            row.set_name("sidebar-row")
            img = Gtk.Image.new_from_icon_name(cat.get("icone", "application-x-generic-symbolic"),
                                                Gtk.IconSize.MENU)
            row.pack_start(img, False, False, 0)
            lbl = Gtk.Label(label=cat["nom"])
            row.pack_start(lbl, False, False, 0)

            # Badge pour mises à jour
            if cat["id"] == "updates":
                self._updates_badge = Gtk.Label(label="")
                self._updates_badge.set_name("updates-badge")
                self._updates_badge.set_no_show_all(True)
                row.pack_end(self._updates_badge, False, False, 0)

            btn = Gtk.Button()
            btn.add(row)
            btn.set_relief(Gtk.ReliefStyle.NONE)
            btn.set_can_focus(False)
            cat_id = cat["id"]
            btn.connect("clicked", lambda _w, cid=cat_id: self._on_category_clicked(cid))
            sidebar_box.pack_start(btn, False, False, 0)
            self._sidebar_buttons[cat_id] = btn

        # Sélection par défaut
        self._sidebar_buttons.get("tout", None) and self._sidebar_buttons["tout"].grab_focus()

        sidebar_scroll.add(sidebar_box)
        main_paned.pack1(sidebar_scroll, resize=False, shrink=False)

        # ── Zone de contenu ──
        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        content_box.set_name("content-area")
        content_box.set_hexpand(True)
        content_box.set_vexpand(True)

        # Scroll
        self.content_scroll = Gtk.ScrolledWindow()
        self.content_scroll.set_name("scroll-area")
        self.content_scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)

        self.content_viewport = Gtk.Viewport()
        self.content_viewport.set_shadow_type(Gtk.ShadowType.NONE)

        self.content_inner = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.content_inner.set_margin_start(16)
        self.content_inner.set_margin_end(16)
        self.content_inner.set_margin_top(12)
        self.content_inner.set_margin_bottom(12)

        self.content_viewport.add(self.content_inner)
        self.content_scroll.add(self.content_viewport)
        content_box.pack_start(self.content_scroll, True, True, 0)

        # Barre de statut
        self.status_bar = Gtk.Label(label="Chargement…")
        self.status_bar.set_name("status-bar")
        self.status_bar.set_xalign(Gtk.Align.START)
        content_box.pack_end(self.status_bar, False, False, 0)

        main_paned.pack2(content_box, resize=True, shrink=False)

        # Charger les paquets en vedette
        self._build_featured()

    def _build_featured(self):
        """Construit la section des paquets en vedette."""
        featured = [p for p in self._catalog.get("paquets", []) if p.get("mis_en_avant")]
        if not featured:
            self._featured_box = None
            return

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_name("featured-box")

        lbl_title = Gtk.Label(label="Applications en vedette")
        lbl_title.set_name("featured-title")
        lbl_title.set_xalign(Gtk.Align.START)
        box.pack_start(lbl_title, False, False, 0)

        lbl_sub = Gtk.Label(label="Découvrez les applications recommandées par l'équipe nemOS")
        lbl_sub.set_name("featured-subtitle")
        lbl_sub.set_xalign(Gtk.Align.START)
        box.pack_start(lbl_sub, False, False, 0)

        # Cartes horizontales
        featured_scroll = Gtk.ScrolledWindow()
        featured_scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.NEVER)
        featured_inner = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        featured_inner.set_homogeneous(True)

        for pkg in featured[:4]:
            card = self._make_featured_card(pkg)
            featured_inner.pack_start(card, True, True, 0)

        featured_scroll.add(featured_inner)
        box.pack_start(featured_scroll, False, False, 0)

        self._featured_box = box
        self.content_inner.pack_start(box, False, False, 0)

    def _make_featured_card(self, pkg_entry):
        """Crée une petite carte pour la section vedette."""
        card = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        card.set_name("featured-card")
        card.set_margin_bottom(4)

        icon_theme = Gtk.IconTheme.get_default()
        icon_name = pkg_entry.get("icone", pkg_entry["nom"])
        try:
            if icon_theme.has_icon(icon_name):
                pb = icon_theme.load_icon(icon_name, 36, 0)
            elif icon_theme.has_icon(pkg_entry["nom"]):
                pb = icon_theme.load_icon(pkg_entry["nom"], 36, 0)
            else:
                pb = None
        except Exception:
            pb = None
        if pb is None:
            pb = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, 36, 36)
            pb.fill(0x00000000)

        img = Gtk.Image.new_from_pixbuf(pb)
        img.set_pixel_size(36)
        card.pack_start(img, False, False, 0)

        text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        text.set_valign(Gtk.Align.CENTER)
        lbl = Gtk.Label(label=pkg_entry["nom"])
        lbl.set_name("pkg-name")
        lbl.set_xalign(0)
        text.pack_start(lbl, False, False, 0)
        desc = Gtk.Label(label=pkg_entry.get("description", ""))
        desc.set_name("pkg-desc")
        desc.set_xalign(0)
        desc.set_ellipsize(Pango.EllipsizeMode.END)
        desc.set_max_width_chars(25)
        text.pack_start(desc, False, False, 0)
        card.pack_start(text, True, True, 0)

        # Bouton
        btn = Gtk.Button(label="Installer")
        btn.set_name("btn-install")
        btn.set_valign(Gtk.Align.CENTER)
        pkg_name = pkg_entry["nom"]
        btn.connect("clicked", lambda _w, pn=pkg_name: self._quick_install(pn))
        card.pack_end(btn, False, False, 0)

        return card

    def _quick_install(self, pkg_name):
        """Installation rapide depuis la section vedette."""
        if pkg_name in self._busy_packages or is_installed(pkg_name):
            return
        self._busy_packages.add(pkg_name)
        self.update_status_bar()

        def worker():
            def cb(success, msg):
                self._busy_packages.discard(pkg_name)
                if not success:
                    self.show_error(f"Erreur : {msg}")
                self.refresh_all_cards()
                self._rebuild_content()
                self.update_status_bar()
            install_package(pkg_name, callback=cb)

        threading.Thread(target=worker, daemon=True).start()

    # ─── Événements ───────────────────────────────────────────────────────

    def _on_search_changed(self, _entry=None):
        self._search_query = self.search_entry.get_text().strip().lower()
        self._rebuild_content()

    def _on_category_clicked(self, cat_id):
        self._current_category = cat_id
        self._show_updates_only = (cat_id == "updates")
        self._show_installed_only = (cat_id == "installed")
        self._rebuild_content()
        # Mettre à jour la sélection visuelle
        for cid, btn in self._sidebar_buttons.items():
            ctx = btn.get_style_context()
            if cid == cat_id:
                ctx.set_state(Gtk.StateFlags.SELECTED)
            else:
                ctx.set_state(Gtk.StateFlags.NORMAL)

    def _on_updates_clicked(self, _btn):
        self._on_category_clicked("updates")

    def _on_refresh_clicked(self, _btn):
        self.status_bar.set_text("Rafraîchissement des dépôts…")
        self.btn_updates.set_sensitive(False)

        def worker():
            def cb(success, msg):
                self.btn_updates.set_sensitive(True)
                if not success:
                    self.show_error(f"Erreur de rafraîchissement : {msg}")
                self._load_background_data()
                self._rebuild_content()
            refresh_repos(callback=cb)

        threading.Thread(target=worker, daemon=True).start()

    # ─── Chargement des données ───────────────────────────────────────────

    def _initial_load(self):
        """Premier chargement des données en arrière-plan."""
        def worker():
            installed = get_installed_packages()
            updates = get_updates()
            GLib.idle_add(self._on_data_loaded, installed, updates)
        threading.Thread(target=worker, daemon=True).start()
        return False

    def _load_background_data(self):
        """Recharge les données d'installation et mises à jour."""
        def worker():
            installed = get_installed_packages()
            updates = get_updates()
            GLib.idle_add(self._on_data_loaded, installed, updates)
        threading.Thread(target=worker, daemon=True).start()

    def _on_data_loaded(self, installed, updates):
        self._installed_set = installed
        self._updates_list = updates
        self._loading = False
        self.update_status_bar()
        self._update_updates_badge()
        self._rebuild_content()

    def _update_updates_badge(self):
        n = len(self._updates_list)
        if n > 0:
            self._updates_badge.set_label(str(n))
            self._updates_badge.show()
            self.btn_updates.set_label(f"Mises à jour ({n})")
        else:
            self._updates_badge.hide()
            self.btn_updates.set_label("Mises à jour")

    def update_status_bar(self):
        total = len(self._catalog.get("paquets", []))
        n_updates = len(self._updates_list)
        busy = len(self._busy_packages)
        parts = [f"{total} paquets disponibles"]
        if n_updates > 0:
            parts.append(f"{n_updates} mises à jour")
        if busy > 0:
            parts.append(f"{busy} opération(s) en cours")
        self.status_bar.set_text(" • ".join(parts))

    def show_error(self, message):
        """Affiche un message d'erreur dans le contenu."""
        # Supprimer les anciennes boîtes d'erreur
        for child in list(self.content_inner.get_children()):
            if child.get_name() == "error-box":
                self.content_inner.remove(child)

        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        box.set_name("error-box")
        img = Gtk.Image.new_from_icon_name("dialog-error-symbolic", Gtk.IconSize.LARGE_TOOLBAR)
        box.pack_start(img, False, False, 0)
        lbl = Gtk.Label(label=message)
        lbl.set_name("error-label")
        lbl.set_line_wrap(True)
        lbl.set_max_width_chars(60)
        lbl.set_xalign(0)
        box.pack_start(lbl, True, True, 0)
        btn_close = Gtk.Button(label="Fermer")
        btn_close.set_name("btn-install")
        btn_close.connect("clicked", lambda _w: self.content_inner.remove(box))
        box.pack_end(btn_close, False, False, 0)
        self.content_inner.pack_start(box, False, False, 8)
        self.content_inner.show_all()

    # ─── Construction du contenu filtré ───────────────────────────────────

    def _rebuild_content(self):
        """Reconstruit la grille des paquets selon les filtres."""
        # Supprimer les anciennes cartes et labels de section
        for child in list(self.content_inner.get_children()):
            if child != self._featured_box:
                self.content_inner.remove(child)

        # Déterminer quels paquets afficher
        if self._show_updates_only:
            self._show_updates_content()
            return

        packages = self._catalog.get("paquets", [])

        # Filtrer par catégorie
        if self._current_category != "tout" and not self._show_installed_only:
            packages = [p for p in packages if p["categorie"] == self._current_category]

        # Filtrer par recherche
        if self._search_query:
            packages = [
                p for p in packages
                if self._search_query in p["nom"].lower()
                or self._search_query in p.get("description", "").lower()
            ]

        # Filtrer installés
        if self._show_installed_only:
            packages = [p for p in packages if p["nom"] in self._installed_set]

        if not packages:
            lbl = Gtk.Label(label="Aucune application trouvée")
            lbl.set_name("empty-state")
            self.content_inner.pack_start(lbl, True, True, 40)
            self.content_inner.show_all()
            return

        # Titre de section
        section_names = {
            "internet": "Internet",
            "bureautique": "Bureautique",
            "multimedia": "Multimédia",
            "outils": "Outils",
            "developpement": "Développement",
            "systeme": "Système",
            "jeux": "Jeux",
            "tout": "Toutes les applications",
            "installed": "Applications installées",
        }
        section_name = section_names.get(self._current_category, "Applications")
        lbl_sec = Gtk.Label(label=section_name)
        lbl_sec.set_name("section-label")
        lbl_sec.set_xalign(Gtk.Align.START)
        self.content_inner.pack_start(lbl_sec, False, False, 4)

        # Grille de cartes
        grid = Gtk.FlowBox()
        grid.set_name("content-area")
        grid.set_selection_mode(Gtk.SelectionMode.NONE)
        grid.set_column_spacing(12)
        grid.set_row_spacing(4)
        grid.set_homogeneous(False)

        for pkg in packages:
            card = PackageCard(self, pkg)
            grid.add(card)
            self._cards.append(card)

        self.content_inner.pack_start(grid, True, True, 8)
        self.content_inner.show_all()

    def _show_updates_content(self):
        """Affiche la liste des mises à jour disponibles."""
        if not self._updates_list:
            lbl = Gtk.Label(label="Votre système est à jour !")
            lbl.set_name("empty-state")
            self.content_inner.pack_start(lbl, True, True, 40)
            self.content_inner.show_all()
            return

        lbl_sec = Gtk.Label(label="Mises à jour disponibles")
        lbl_sec.set_name("section-label")
        lbl_sec.set_xalign(Gtk.Align.START)
        self.content_inner.pack_start(lbl_sec, False, False, 4)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        for line in self._updates_list:
            # Format : "paquet version_old -> version_new"
            match = re.match(r'^(\S+)\s+(.+)$', line)
            if match:
                pkg_name = match.group(1)
                versions = match.group(2)
                row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
                row.set_name("featured-card")
                row.set_margin_start(4)
                row.set_margin_end(4)

                lbl_pkg = Gtk.Label(label=pkg_name)
                lbl_pkg.set_name("pkg-name")
                lbl_pkg.set_xalign(0)
                row.pack_start(lbl_pkg, False, False, 8)

                lbl_ver = Gtk.Label(label=versions)
                lbl_ver.set_name("pkg-version")
                lbl_ver.set_xalign(0)
                row.pack_start(lbl_ver, True, True, 0)

                box.pack_start(row, False, False, 0)

        # Bouton tout mettre à jour
        btn_all = Gtk.Button(label="Tout mettre à jour")
        btn_all.set_name("btn-install")
        btn_all.set_margin_top(12)
        btn_all.connect("clicked", self._update_all)
        box.pack_start(btn_all, False, False, 12)

        self.content_inner.pack_start(box, True, True, 8)
        self.content_inner.show_all()

    def _update_all(self, _btn):
        """Lance la mise à jour complète du système."""
        self.status_bar.set_text("Mise à jour du système en cours…")

        def worker():
            def cb(success, msg):
                if success:
                    self.status_bar.set_text("Système mis à jour avec succès !")
                else:
                    self.show_error(f"Erreur de mise à jour : {msg}")
                self._load_background_data()
            cmd = ["pkexec", "pacman", "-Syu", "--noconfirm"]
            rc, out, err = run_command(cmd, timeout=600)
            GLib.idle_add(cb, rc == 0, err if rc != 0 else "")

        threading.Thread(target=worker, daemon=True).start()

    def refresh_all_cards(self):
        """Rafraîchit l'état de toutes les cartes affichées."""
        for card in self._cards:
            try:
                card.refresh_state()
            except Exception:
                pass


# ─── Application ─────────────────────────────────────────────────────────────

class StoreApplication(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="org.nemos.store",
                         flags=Gio.ApplicationFlags.FLAGS_NONE)
        self.window = None

    def do_activate(self):
        if self.window is None:
            self.window = NemOSStore(self)
        self.window.present()


# ─── Point d'entrée ──────────────────────────────────────────────────────────

if __name__ == "__main__":
    app = StoreApplication()
    app.run(sys.argv)