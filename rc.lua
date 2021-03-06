-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")

-- Widget and layout library
local wibox = require("wibox")

-- Theme handling library
local beautiful = require("beautiful")

-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")

local selected_theme = "xresources"

-- #region Error handling

-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify(
        {
            preset = naughty.config.presets.critical,
            title = "Oops, there were errors during startup!",
            text = awesome.startup_errors
        }
    )
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal(
        "debug::error",
        function(err)
        -- Make sure we don't go into an endless error loop
            if in_error then
                return
            end
            in_error = true
            naughty.notify(
                {
                    preset = naughty.config.presets.critical,
                    title = "Oops, an error happened!",
                    text = tostring(err)
                }
            )
            in_error = false
        end
    )
end
-- #endregion

-- #region Variable definitions

-- Themes define colours, icons, font and wallpapers.
-- beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
local theme_path = (
    gears.filesystem.get_dir("config") .. "themes/" .. selected_theme .. "/theme.lua"
)
beautiful.init(theme_path)

-- Custom functions

local rounded_shape = function (cr, width, height)
    gears.shape.rounded_rect(cr, width, height, 4)
end

local launch_rofi = function()
    awful.spawn(
        "rofi -modi drun -show-icons -lines 20 -scroll-method 1 "
        .. "-display-drun \"Open\" -show drun"
    )
end

local confirm = function(title, icon, image, text, func)
    local f = function()
        awful.spawn.easy_async(
            "yad --center --on-top --fixed --close-on-unfocus "..
            "--button-align=center --window-icon="..icon.." "..
            "--title='"..title.."' --image="..image.." "..
            "--text-align=center --text='"..text.."' "..
            "--button='No!dialog-no:1' --button='Yes!dialog-yes:0'",
            function(_, _, _, exit_code)
                if exit_code == 0 then
                    func()
                end
            end
        )
    end
    return f
end

-- This is used later as the default terminal and editor to run.
local terminal = "alacritty"
-- local editor = os.getenv("EDITOR") or "vim"
local editor = "code"

-- Default modkey.
local modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.floating,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- #endregion

-- #region Menu

-- #region Launcher widget and main menu

local mysystemmenu = {
    {
        "logout",
        confirm(
            "Log Out",
            "system-log-out",
            "system-log-out-symbolic",
            "Are you sure you want to log out?",
            function()
                awesome.quit()
            end
        ),
        -- "/usr/share/icons/Papirus-Dark/16x16/panel/dialog-password-panel.svg"
        "/usr/share/icons/Papirus/16x16/apps/system-log-out.svg"
    },
    {
        "restart",
        confirm(
            "Restart",
            "system-restart",
            "system-restart-symbolic",
            "Are you sure you want to restart?",
            function()
                awful.spawn("reboot")
            end
        ),
        "/usr/share/icons/Papirus/16x16/apps/system-restart.svg"
    },
    {
        "shutdown",
        confirm(
            "Restart",
            "system-shutdown",
            "system-shutdown-symbolic",
            "Are you sure you want to shutdown?",
            function()
                awful.spawn("poweroff")
            end
        ),
        "/usr/share/icons/Papirus/16x16/apps/system-shutdown.svg"
    },
}

local myappmenu = {
    {
        "file browser",
        "pcmanfm",
        "/usr/share/icons/Papirus/16x16/places/folder-blue.svg"
    },
    {
        "web browser",
        "brave",
        "/usr/share/icons/Papirus/16x16/apps/brave.svg"
    },
    {
        "app launcher",
        function()
            -- For some reason, the click is registered at the exact same time
            -- that Rofi is launched, so we need to wait for click to be released
            -- before launching Rofi
            gears.timer.start_new(
                0.05,
                function()
                    if mouse.coords().buttons[1] then
                        return true
                    end
                    launch_rofi()
                    return false
                end
            )
        end,
        "/usr/share/icons/Papirus/16x16/apps/app-launcher.svg"
    },
    {
        "terminal",
        terminal,
        "/usr/share/icons/Papirus/16x16/apps/com.alacritty.Alacritty.svg"
    }
}

local mymainmenu = awful.menu({
    items = {
        {
            "applications",
            myappmenu,
            -- "/usr/share/icons/Papirus-Dark/16x16/actions/document-open.svg"
            "/usr/share/icons/Papirus/16x16/apps/applications-all.svg"
        },
        {
            "system",
            mysystemmenu,
            "/usr/share/icons/Papirus/16x16/apps/systemsettings.svg"
        },
        {
            "hotkeys",
            function()
                hotkeys_popup.show_help(nil, awful.screen.focused())
            end,
            "/usr/share/icons/Papirus/16x16/apps/preferences-desktop-keyboard-shortcuts.svg"
        },
        {
            "edit config",
            editor .. " " .. gears.filesystem.get_dir("config"),
            "/usr/share/icons/Papirus/16x16/mimetypes/text-x-lua.svg"
        },
        {
            "reload",
            awesome.restart,
            "/usr/share/icons/Papirus/16x16/apps/system-restart.svg"
        },
    }
})

local mylauncher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu = mymainmenu
})

-- Menubar configuration
-- Set the terminal for applications that require it
menubar.utils.terminal = terminal
-- #endregion

-- #region Wibar
-- Create a textclock widget
local mytextclock = wibox.widget {
    {
        widget = wibox.widget.textclock("%a %b %d %l:%M %p")
    },
    left = 10,
    right = 10,
    layout = wibox.container.margin
}

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
    awful.button(
        { },
        1,
        function(t)
            t:view_only()
        end
    ),
    awful.button(
        { modkey },
        1,
        function(t)
            if client.focus then
                client.focus:move_to_tag(t)
            end
        end
    ),
    awful.button(
        { },
        3,
        awful.tag.viewtoggle
    ),
    awful.button(
        { modkey },
        3,
        function(t)
            if client.focus then
                client.focus:toggle_tag(t)
            end
        end
    )
)

local tasklist_buttons = gears.table.join(
    awful.button(
        { },
        1,
        function(c)
            if c == client.focus then
                c.minimized = true
            else
                c:emit_signal(
                    "request::activate",
                    "tasklist",
                    { raise = true }
                )
            end
        end
    ),
    awful.button(
        { },
        2,
        function(c)
            c:kill()
        end
    ),
    awful.button(
        { },
        3,
        function(c)
            c.minimized = not c.minimized
        end
    )
)

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        if wallpaper ~= nil then
            gears.wallpaper.maximized(wallpaper, s, true)
        end
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    beautiful.systray_icon_spacing = 8

    -- Each screen has its own tag table.
    awful.tag(
        { "1", "2", "3", "4" },
        s, awful.layout.layouts[1]
    )

    -- Create an imagebox widget which will contain an icon
    -- indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button(
            { },
            1,
            function()
                awful.layout.inc( 1)
            end
        ),
        awful.button(
            { },
            3,
            function()
                awful.layout.inc(-1)
            end
        )
    ))

    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = wibox.widget {
        layout = wibox.container.margin,
        left = 10,
        {
            widget = awful.widget.tasklist {
        	    screen  = s,
        	    filter  = awful.widget.tasklist.filter.currenttags,
        	    buttons = tasklist_buttons,
                layout = {
                    max_widget_size = 320,
                    layout = wibox.layout.flex.horizontal,
                },
                style = {
                    shape = rounded_shape
                },
                widget_template = {
                    {
                        {
                            {
                                {
                                    id = 'icon_role',
                                    widget = wibox.widget.imagebox,
                                },
                                top = 2,
                                bottom = 2,
                                right = 8,
                                widget = wibox.container.margin,
                            },
                            {
                                id = 'text_role',
                                widget = wibox.widget.textbox,
                            },
                            layout = wibox.layout.fixed.horizontal,
                        },
                        left = 10,
                        right = 10,
                        widget = wibox.container.margin
                    },
                    id = 'background_role',
                    widget = wibox.container.background,
                },
	        }
	    },
    }

    -- Create systray widget
    local mysystray = wibox.widget {
        layout = wibox.container.margin,
        left = 10,
        {
            widget = wibox.widget.systray()
        },
    }

    -- Create the wibox
    s.mywibox = awful.wibar(
        {
            position = "top",
            screen = s,
        }
    )

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            mysystray,
            mytextclock,
            s.mylayoutbox,
        },
    }
end)
-- #endregion

-- #region Key bindings
local globalkeys = gears.table.join(
    -- #region Awesome group
    awful.key(
        { modkey, "Control" },
        "r",
        awesome.restart,
        {
            description = "reload awesome",
            group = "0. awesome"
        }
    ),
    awful.key(
        { modkey, "Control" },
        "q",
        confirm(
            "Log Out",
            "system-log-out",
            "system-log-out-symbolic",
            "Are you sure you want to log out?",
            function()
                awesome.quit()
            end
        ),
        {
            description = "quit awesome",
            group = "0. awesome"
        }
    ),
    awful.key(
        { modkey, "Control" },
        "Escape",
        awesome.quit,
        {
            description = "force quit awesome",
            group = "0. awesome"
        }
    ),
    awful.key(
        { modkey, "Shift" },
        "/",
        hotkeys_popup.show_help,
        {
            description="show help",
            group= "0. awesome"
        }
    ),
    awful.key(
        { modkey },
        "F12",
        function()
          awful.spawn.with_shell("$HOME/.local/bin/osrskeys")
        end,
        {
            description="toggle OSRS hotkeys",
            group= "1. system"
        }
    ),
    -- #endregion

    -- #region System group
    awful.key(
        { },
        "XF86AudioRaiseVolume",
        function()
            awful.spawn.with_shell("amixer -q -D pulse sset Master unmute && amixer -q -D pulse sset Master 5%+")
        end,
        {
            description="raise volume",
            group="1. system"
        }
    ),
    awful.key(
        { },
        "XF86AudioLowerVolume",
        function()
            awful.spawn.with_shell("amixer -q -D pulse sset Master unmute && amixer -q -D pulse sset Master 5%-")
        end,
        {
            description="lower volume",
            group="1. system"
        }
    ),
    awful.key(
        { },
        "XF86AudioMute",
        function()
            awful.spawn("amixer -q -D pulse set Master toggle")
        end,
        {
            description="toggle volume mute",
            group="1. system"
        }
    ),
    -- #endregion

    -- #region Launcher group
    awful.key(
        { modkey },
        "Return",
        function()
            awful.spawn(terminal)
        end,
        {
            description = "open a terminal",
            group = "2. launcher"
        }
    ),
    awful.key(
        { modkey },
        "r",
        function()
            awful.spawn("rofi -modi run -lines 20 -scroll-method 1 -show run")
        end,
        {
            description = "run prompt",
            group = "2. launcher"
        }
    ),
    awful.key(
        { modkey }, "o",
        launch_rofi,
        {
            description = "run app",
            group = "2. launcher"
        }
    ),
    awful.key(
        { modkey }, "space",
        function()
            mymainmenu:show({coords={x=0, y=0}})
        end,
        {
            description = "open menu",
            group = "2. launcher"
        }
    ),
    awful.key(
	{ modkey },
	"Print",
	function()
	    awful.spawn.with_shell("flameshot gui")
	end,
	{
	    description = "run screenshot utility",
	    group = "2. launcher"
	}
    ),
    awful.key(
	{ },
	"Print",
	function()
	    awful.spawn.with_shell("flameshot screen -p ~/Pictures")
	end,
	{
	    description = "capture entire screen",
	    group = "2. launcher"
	}
    ),
    awful.key(
    { modkey, "Control" },
    "Print",
    function()
        awful.spawn.with_shell("$HOME/.local/bin/wincapture")
    end,
    {
        description = "capture selected window",
        group = "2. launcher"
    }
    ),
    -- #endregion

    -- #region Workspace group
    awful.key(
        { modkey },
        "w",
        awful.tag.viewprev,
        {
            description = "previous workspace",
            group = "3. workspace"
        }
    ),
    awful.key(
        { modkey },
        "s",
        awful.tag.viewnext,
        {
            description = "next workspace",
            group = "3. workspace"
        }
    ),
    -- #endregion

    -- #region Layout group
    awful.key(
        { modkey },
        "d",
        function()
            awful.client.focus.byidx( 1)
        end,
        {
            description = "focus next window",
            group = "4. layout"
        }
    ),
    awful.key(
        { modkey },
        "a",
        function()
            awful.client.focus.byidx(-1)
        end,
        {
            description = "focus previous window",
            group = "4. layout"
        }
    ),
    awful.key(
        { modkey, "Shift" },
        "d",
        function()
            awful.client.swap.byidx(1)
        end,
        {
            description = "swap with next window",
            group = "4. layout"
        }
    ),
    awful.key(
        { modkey, "Shift" },
        "a",
        function()
            awful.client.swap.byidx(-1)
        end,
        {
            description = "swap with previous window",
            group = "4. layout"
        }
    ),
    awful.key(
        { modkey, "Control" },
        "d",
        function()
            awful.tag.incmwfact(0.05)
        end,
        {
            description = "increase master width",
            group = "4. layout"
        }
    ),
    awful.key(
        { modkey, "Control" },
        "a",
        function()
            awful.tag.incmwfact(-0.05)
        end,
        {
            description = "decrease master width",
            group = "4. layout"
        }
    ),
    awful.key(
        { modkey, "Control" },
        "w",
        function()
            awful.tag.incnmaster(1, nil, true)
        end,
        {
            description = "increase the number of master clients",
            group = "4. layout"
        }
    ),
    awful.key(
        { modkey, "Control" },
        "s",
        function()
            awful.tag.incnmaster(-1, nil, true)
        end,
        {
            description = "decrease the number of master clients",
            group = "4. layout"
        }
    ),
    awful.key(
        { modkey, "Control" },
        "c",
        function()
            awful.tag.incncol( 1, nil, true)
        end,
        {
            description = "increase the number of columns",
            group = "4. layout"
        }
    ),
    awful.key(
        { modkey, "Control" },
        "z",
        function()
            awful.tag.incncol(-1, nil, true)
        end,
        {
            description = "decrease the number of columns",
            group = "4. layout"
        }
    ),
    awful.key(
        { modkey, "Shift" },
        "f",
        function()
            awful.layout.set(awful.layout.suit.floating)
        end,
        {
            description = "enable floating layout",
            group = "4. layout"
        }
    ),
    awful.key(
        { modkey, "Shift" },
        "m",
        function()
            awful.layout.set(awful.layout.suit.tile)
        end,
        {
            description = "enable master layout",
            group = "4. layout"
        }
    ),
    awful.key(
        { modkey, "Shift" },
        "g",
        function()
            awful.layout.set(awful.layout.suit.fair)
        end,
        {
            description = "enable grid layout",
            group = "4. layout"
        }
    ),
    awful.key(
        { modkey, "Shift" },
        "r",
        function()
            awful.layout.set(awful.layout.suit.spiral.dwindle)
        end,
        {
            description = "enable ratio layout",
            group = "4. layout"
        }
    ),
    awful.key(
        { modkey, "Control" },
        "n",
        function()
            local c = awful.client.restore()
            -- Focus restored client
            if c then
                c:emit_signal(
                    "request::activate", "key.unminimize", {raise = true}
                )
            end
        end,
        {
            description = "restore minimized",
            group = "4. layout"
        }
    )
    -- #endregion
)

-- #region Client group
local clientkeys = gears.table.join(
    awful.key(
        { modkey }, "q",
        function(c)
            c:kill()
        end,
        {
            description = "close",
            group = "5. client"
        }
    ),
    awful.key(
        { modkey }, "f",
        awful.client.floating.toggle,
        {
            description = "toggle floating",
            group = "5. client"
        }
    ),
    awful.key(
        { modkey, "Shift" },
        "w",
        function()
		    local t = client.focus and client.focus.first_tag or nil
		    if t == nil then
		        return
		    end
	        local tag = awful.screen.focused().tags[(t.index - 2) % #(awful.screen.focused().tags) + 1]
		    client.focus:move_to_tag(tag)
		    awful.tag.viewprev()
        end,
        {
            description = "move to previous workspace",
            group = "5. client"
        }
    ),
    awful.key(
        { modkey, "Shift" },
        "s",
        function()
		    local t = client.focus and client.focus.first_tag or nil
		    if t == nil then
		        return
		    end
            local tag = awful.screen.focused().tags[(t.index % #(awful.screen.focused().tags)) + 1]
		    client.focus:move_to_tag(tag)
		    awful.tag.viewnext()
	    end,
	    {
            description = "move to next workspace",
            group = "5. client"
        }
    ),
    awful.key(
        { modkey },
        "t",
        function(c)
            c.ontop = not c.ontop
        end,
        {
            description = "toggle keep on top",
            group = "5. client"
        }
    ),
    awful.key(
        { modkey },
        "y",
        function(c)
            c.sticky = not c.sticky
        end,
        {
            description = "toggle sticky",
            group = "5. client"
        }
    ),
    awful.key(
        { modkey },
        "n",
        function(c)
            c.minimized = true
        end ,
        {
            description = "minimize",
            group = "5. client"
        }
    ),
    awful.key(
        { modkey },
        "m",
        function(c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {
            description = "toggle maximized",
            group = "5. client"
        }
    )
)
-- #endregion

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 4 do
    globalkeys = gears.table.join(
        globalkeys,
        -- View tag only.
        awful.key(
            { modkey },
            i,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end,
            {
                description = "view tag #" .. i,
                group = "3. workspace"
            }
        ),
        awful.key(
            { modkey, "Shift" },
            i,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                    end
                end
            end,
            {
                description = "move focused client to tag #" .. i,
                group = "3. workspace"
            }
        )
    )
end

-- #region Client group
local clientbuttons = gears.table.join(
    awful.button(
        { },
        1,
        function(c)
            c:emit_signal(
                "request::activate",
                "mouse_click",
                { raise = true }
            )
        end
    ),
    awful.button(
        { modkey },
        1,
        function(c)
            c:emit_signal(
                "request::activate",
                "mouse_click",
                { raise = true }
            )
            awful.mouse.client.move(c)
        end
    ),
    awful.button(
        { modkey },
        3,
        function(c)
            c:emit_signal(
                "request::activate",
                "mouse_click",
                { raise = true }
            )
            awful.mouse.client.resize(c)
        end
    )
)
-- #endregion

-- Set keys
root.keys(globalkeys)

-- #endregion

-- #region Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen
        }
    },

    -- Floating clients.
    {
        rule_any = {
            instance = {
                "DTA",  -- Firefox addon DownThemAll.
                "copyq",  -- Includes session name in class.
                "discord",
                "vlc",
                "nitrogen",
                "obs",
            },
            class = {
                "Arandr",
                "Blueman-manager",
                "Kruler",
                "MessageWin",  -- kalarm.
                "Sxiv",
                "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
                "Wpa_gui",
                "veromix",
                "xtightvncviewer",
                "NordPass",
                "net-runelite-launcher-Launcher",
                "net-runelite-client-RuneLite",
                "Steam",
                "steam_app_253230",  -- Hat In Time
            },
            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name = {
                "Event Tester",  -- xev.
            },
            role = {
                "AlarmWindow",  -- Thunderbird's calendar.
                "ConfigManager",  -- Thunderbird's about:config.
                "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        properties = { floating = true }
    },

    -- Floating clients that need to be centered
    {
        rule_any = {
            instance = {
                "pcmanfm",
                "gpick",
                "flameshot",
                "nvidia-settings",
                "galculator",
                "gimp",
                "timeshift",
                "org.gnome.DejaDup",
                "pavucontrol",
                "xscreensaver-settings",
                "yad",
                "file-roller",
                "eog",
                "zoom",
            },
            class = {
                "libreoffice-startcenter",
                "Gcr-prompter",
                "ftb-app",
                "Gnome-system-monitor",
                "UnityHub",
            },
        },
        properties = { floating = true, placement = awful.placement.centered },
    },

    -- Add titlebars to normal clients and dialogs
    -- {
    --     rule_any = {
    --         class = { "Minecraft 1.7.10" }
    --     },
    --     properties = { titlebars_enabled = true }
    -- },
}
-- #endregion

-- #region Signals
-- Signal function to execute when a new client appears.
client.connect_signal(
    "manage",
    function(c)
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        if not awesome.startup then
            awful.client.setslave(c)
        end
        if awesome.startup
            and not c.size_hints.user_position
            and not c.size_hints.program_position then
                -- Prevent clients from being unreachable after screen count changes.
                awful.placement.no_offscreen(c)
        end
        -- Spotify Fix for null WM_CLASS
        if c.class == nil
            and c.name == nil
            and c.title == nil then
                c.floating = not c.floating
        end
        -- c.shape = rounded_shape
    end
)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal(
    "request::titlebars",
    function(c)
        -- buttons for the titlebar
        local buttons = gears.table.join(
            awful.button(
                { },
                1,
                function()
                    c:emit_signal(
                        "request::activate",
                        "titlebar",
                        { raise = true }
                    )
                    awful.mouse.client.move(c)
                end
            ),
            awful.button(
                { },
                3,
                function()
                    c:emit_signal(
                        "request::activate",
                        "titlebar",
                        { raise = true }
                    )
                    awful.mouse.client.resize(c)
                end
            )
        )
        awful.titlebar(c) : setup {
            { -- Left
                awful.titlebar.widget.iconwidget(c),
                buttons = buttons,
                layout  = wibox.layout.fixed.horizontal
            },
            { -- Middle
                { -- Title
                    align  = "center",
                    widget = awful.titlebar.widget.titlewidget(c)
                },
                buttons = buttons,
                layout  = wibox.layout.flex.horizontal
            },
            { -- Right
                awful.titlebar.widget.floatingbutton(c),
                awful.titlebar.widget.maximizedbutton(c),
                awful.titlebar.widget.stickybutton(c),
                awful.titlebar.widget.ontopbutton(c),
                awful.titlebar.widget.closebutton(c),
                layout = wibox.layout.fixed.horizontal()
            },
            layout = wibox.layout.align.horizontal
        }
    end
)

-- Enable sloppy focus, so that focus follows mouse.
-- client.connect_signal("mouse::enter", function(c)
--     c:emit_signal("request::activate", "mouse_enter", {raise = false})
-- end)

client.connect_signal(
    "focus",
    function(c)
        c.border_color = beautiful.border_focus
    end
)
client.connect_signal(
    "unfocus",
    function(c)
        c.border_color = beautiful.border_normal
    end
)
-- #endregion

-- #region Autostart Programs
local startup_progs = {
    "coffee",
}

for _, prog in ipairs(startup_progs)
do
    awful.spawn.with_shell(prog)
end
-- #endregion
