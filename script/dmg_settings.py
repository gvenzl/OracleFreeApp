import os
import plistlib

application = defines["app"]  # noqa: F821
background = defines["background"]  # noqa: F821
appname = os.path.basename(application)


def icon_from_app(app_path):
    plist_path = os.path.join(app_path, "Contents", "Info.plist")
    with open(plist_path, "rb") as plist_file:
        plist = plistlib.load(plist_file)

    icon_name = plist["CFBundleIconFile"]
    icon_root, icon_extension = os.path.splitext(icon_name)
    if not icon_extension:
        icon_extension = ".icns"

    return os.path.join(
        app_path,
        "Contents",
        "Resources",
        icon_root + icon_extension,
    )


format = "UDZO"
filesystem = "HFS+"
compression_level = 9
files = [(application, "Oracle Free App.app")]
symlinks = {"Applications": "/Applications"}
badge_icon = icon_from_app(application)

window_rect = ((200, 120), (640, 360))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False

icon_size = 128
text_size = 14
label_pos = "bottom"
icon_locations = {
    "Oracle Free App.app": (160, 160),
    "Applications": (480, 160),
}
