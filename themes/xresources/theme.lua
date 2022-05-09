---------------------------------------------
-- Awesome theme which follows xrdb config --
--   by Yauhen Kirylau                    --
---------------------------------------------

local awful = require("awful")
local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local xrdb = xresources.get_current_theme()
local gfs = require("gears.filesystem")
local gears = require("gears")
local themes_path = gfs.get_themes_dir()

-- inherit default theme
local theme = dofile(themes_path .. "default/theme.lua")
-- load vector assets' generators for this theme

theme.font          = "Monospace Bold 9"

theme.bg_normal     = xrdb.background
theme.bg_focus      = xrdb.color13
theme.bg_urgent     = xrdb.color9
theme.bg_minimize   = xrdb.color8
theme.bg_systray    = theme.bg_normal

theme.fg_normal     = xrdb.foreground
theme.fg_focus      = theme.bg_normal
theme.fg_urgent     = theme.bg_normal
theme.fg_minimize   = theme.bg_normal

theme.useless_gap   = dpi(3)
theme.border_width  = dpi(2)
theme.border_normal = xrdb.color0
theme.border_focus  = theme.bg_focus
theme.border_marked = xrdb.color10

theme.tasklist_font                     = "Monospace 8"
theme.tasklist_shape_border_color       = xrdb.color7
theme.tasklist_shape_border_width       = dpi(1)
theme.tasklist_spacing                  = dpi(4)
theme.tasklist_font_focus               = "Monospace bold 8"
theme.tasklist_shape_border_width_focus = dpi(1)
theme.tasklist_shape_border_color_focus = xrdb.color3

theme.tooltip_fg = theme.fg_normal
theme.tooltip_bg = theme.bg_normal

theme.menu_submenu_icon = themes_path .. "default/submenu.png"
theme.menu_height = dpi(18)
theme.menu_width  = dpi(160)

theme.notification_icon_size = dpi(32)
theme.notification_max_width = dpi(420)
theme.notification_max_height = dpi(180)
theme.notification_opacity = 0.9
theme.notification_shape = function (cr, width, height)
    gears.shape.rounded_rect(cr, width, height, dpi(4))
end


-- Recolor Layout icons:
theme = theme_assets.recolor_layout(theme, theme.bg_focus)

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
theme.icon_theme = nil

-- Generate Awesome icon:
theme.awesome_icon = theme_assets.awesome_icon(
    theme.menu_height,
    theme.bg_focus,
    theme.fg_focus
)

-- Generate taglist squares:
local taglist_square_size = dpi(4)
theme.taglist_squares_sel = theme_assets.taglist_squares_sel(
    taglist_square_size,
    theme.fg_normal
)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(
    taglist_square_size,
    theme.fg_normal
)

theme.wallpaper = function ()
    awful.spawn.with_shell("nitrogen --set-scaled --random ~/Pictures/wallpapers")
end

return theme

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
