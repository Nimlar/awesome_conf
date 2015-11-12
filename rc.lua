-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

-- Load Debian menu entries
require("debian.menu")

vicious = require("vicious")

local keydoc = require("keydoc")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.add_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}



function dbg(vars)
	local text = ""
	if type(vars) == "table" then
		for i=1, #vars do text = text .. vars[i] .. " | " end
	elseif type(vars) == "string" then
		text = vars
	end
	naughty.notify({ text = text, timeout = 0 })
end

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init( awful.util.getdir("config") .. "/themes/awesome-solarized/dark/theme.lua" )

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = "gvim"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"
altkey = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.floating
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
 tags = { 
 { names  = { "main", "2", "3", "4", "5", "6", "7", "8", "www" },
   layout = { layouts[1], layouts[1], layouts[1], layouts[1], layouts[1],
              layouts[1], layouts[1], layouts[1], layouts[1] }
 },
 { names  = { "1", "2", "3", "4", "5", "6", "7", "8", "im" },
   layout = { layouts[1], layouts[1], layouts[1], layouts[1], layouts[1],
              layouts[1], layouts[1], layouts[1], layouts[1] }
 },
}
 for s = 1, screen.count() do
     -- Each screen has its own tag table.
     tags[s] = awful.tag(tags[s].names, s, tags[s].layout)
 end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" }, "%a %b %d, %H:%M")
-- Create a systray
mysystray = widget({ type = "systray" })

-- {{{ Reusable separator

separator = widget({ type = "imagebox" })
separator.image = image("/usr/share/icons/hicolor/16x16/apps/gnome-panel-separator.png")

spacer = widget({ type = "textbox" })
spacer.width = 3
-- }}}

-- {{{ File system usage
fsicon = widget({ type = "imagebox" })
fsicon.image = image(beautiful.widget_fs)
-- Initialize widgets
fs = {
  r = awful.widget.progressbar(),
  l = awful.widget.progressbar(),
  mh = awful.widget.progressbar(),
}
-- Progressbar properties
for _, w in pairs(fs) do
  w:set_vertical(true):set_ticks(true)
  w:set_height(16):set_width(5):set_ticks_size(2)
  w:set_border_color(beautiful.border_widget)
  w:set_background_color(beautiful.fg_off_widget)
  w:set_gradient_colors({ "#AECF96", "#88A175", "#FF5656"
--  beautiful.fg_widget,
--     beautiful.fg_center_widget, beautiful.fg_end_widget
  })
  -- Register buttons
  w.widget:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.util.spawn("nautilus") end)
  ))
end -- Enable caching
vicious.cache(vicious.widgets.fs)
-- Register widgets
vicious.register(fs.r,  vicious.widgets.fs, "${/ used_p}",            599)
vicious.register(fs.l,  vicious.widgets.fs, "${/local used_p}", 599)
vicious.register(fs.mh, vicious.widgets.fs, "${/media/home used_p}", 599)
-- }}}


-- mpd widget
-- Initialize widget
mpdwidget = widget({ type = "textbox" })
-- Register widget
vicious.register(mpdwidget, vicious.widgets.mpd,
    function (widget, args)
        if args["{state}"] == "Stop" then 
            return " - "
        else
            return args["{Artist}"]..' - '.. args["{Title}"]
        end
    end, 10)
mpdwidget:buttons(awful.util.table.join(
    awful.button({ }, 1, function()
        awful.util.spawn("mpc seek -00:00:10")
        vicious.force({ mpdwidget })
    end),
    awful.button({ }, 3, function()
        awful.util.spawn("mpc seek +00:00:10")
        vicious.force({ mpdwidget })
    end),
    awful.button({ }, 2, function()
        awful.util.spawn("mpc toggle")
        vicious.force({ mpdwidget })
    end),

    awful.button({ }, 4, function()
        awful.util.spawn("mpc volume +5")
        vicious.force({ mpdwidget })
    end),
    awful.button({ }, 5, function()
        awful.util.spawn("mpc volume -5")
        vicious.force({ mpdwidget })
    end)
))


-- {{{ pidgin widget
pidgin_status = widget({ type = "textbox" })
 pidgin_status.text = awful.util.pread("purple-remote \"getstatus\"")
 pidgin_timer = timer({ timeout = 30 })
 pidgin_timer:add_signal("timeout", function()
     pidgin_status.text = awful.util.pread("purple-remote \"getstatus\"")
 end)
 pidgin_timer:start()
-- }}}





-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s], separator,
        mytextclock, separator,
	(s == 2) and { fs.mh.widget,
                       fs.l.widget,
                       fs.r.widget,
                       separator,
                       pidgin_status,
                       separator,
                       layout = awful.widget.layout.horizontal.rightleft
                   } or nil,
        mysystray,
        (s == 1) and {
            mpdwidget,
            separator,
            layout = awful.widget.layout.horizontal.rightleft
        }or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Up",   function () awful.screen.focus_relative( 1) end, "Focus next screen"),
    awful.key({ modkey,           }, "Down", function () awful.screen.focus_relative(-1) end, "Focus prev screen"),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       , "prev view"),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       , "next view"),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore, "restore history" ),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end, "next client" ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end, "prev client"),
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end, "open menu TBR"),

    -- Layout manipulation
    keydoc.group("Client manipulation"),
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end, "Swap with next client"),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end, "Swap with prev client"),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end, "Focus next screen"),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end, "Focus prev screen"),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto, "Focus urgent client"),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end, "Focus prev client"),

    awful.key({ modkey, "Control" }, "n", awful.client.restore, "Restore last minimized client"),

    keydoc.group("Layout manipulation"),
    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end,"Increase master width"),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end,"Decrease master width"),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end,"Inc nb of master windows"),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end,"Dec nb of master windows"),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end,"Inc nb col for non master windows"),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end,"Dec nb col for non master windows"),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end,"Next layout"),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end,"Prev layout"),


    -- Standard program
    keydoc.group("Standard program"),
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end, "Launch a terminal"),
    awful.key({ modkey, "Control" }, "r", awesome.restart, "Restart awesome"),
    awful.key({ modkey, "Control", altkey   }, "q", awesome.quit, "Quit awesome"),


    -- Prompt
    keydoc.group("prompt"),
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end,"Run command"),
--    awful.key({ modkey },            "r",     function ()
--            awful.util.spawn("dmenu_run -i -p 'Run command:' -nb '" .. 
--                    beautiful.bg_normal:sub(1,-3) .. "' -nf '" .. beautiful.fg_normal:sub(1,-3) .. 
--                    "' -sb '" .. beautiful.bg_focus:sub(1,-3) .. 
--                    "' -sf '" .. beautiful.fg_focus:sub(1,-3) .. "'") 
--            end, "Run command"),
--                                -- Run or raise applications with dmenu
--    awful.key({ modkey }, "r", function ()
--        local f_reader = io.popen( "dmenu_path | dmenu -b -nb '".. beautiful.bg_normal .."' -nf '".. beautiful.fg_normal .."' -sb '#955'")
--        local command = assert(f_reader:read('*a'))
--        f_reader:close()
--        if command == "" then return end
--
--        -- Check throught the clients if the class match the command
--        local lower_command=string.lower(command)
--        for k, c in pairs(client.get()) do
--            local class=string.lower(c.class)
--            if string.match(class, lower_command) then
--                for i, v in ipairs(c:tags()) do
--                    awful.tag.viewonly(v)
--                    c:raise()
--                    c.minimized = false
--                    return
--                end
--            end
--        end
--        awful.util.spawn(command)
--    end, "Run or raise applications with dmenu"),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end, "Run LUA command"),

    keydoc.group("Mine"),
    awful.key({ modkey, }, "F1", keydoc.display, "Display this help"),
    awful.key({ altkey, "Control"  }, "l", function() awful.util.spawn("mpc pause") ; awful.util.spawn("gnome-screensaver-command --lock") end,
    "Lock screen (and pause music)"),
    keydoc.group("Music"),
-- rythmbox configuration
--    awful.key({modkey, "Control"  }, "F9", function() awful.util.spawn("rhythmbox-client --play-pause") end, "Play-Pause"),
--    awful.key({modkey, "Control"  }, "F10", function() awful.util.spawn("rhythmbox-client --next --no-start") end, "Next"),
--    awful.key({modkey, "Control"  }, "F8", function() awful.util.spawn("rhythmbox-client --previous --no-start") end, "Prev"),
-- mpd conf
    awful.key({modkey, "Control"  }, "F9", function() awful.util.spawn("mpc toggle") ; vicious.force({ mpdwidget }) end, "Play-Pause"),
    awful.key({modkey, "Control"  }, "F10", function() awful.util.spawn("mpc next") ; vicious.force({ mpdwidget }) end, "Next"),
    awful.key({modkey, "Control"  }, "F8", function() awful.util.spawn("mpc prev") ; vicious.force({ mpdwidget }) end, "Prev"),
-- mouse controle
    keydoc.group("Mouse control"),

    awful.key({modkey, "Control", "Shift"  }, "m", function() awful.util.spawn('xinput set-prop 9 "Device Enabled" 1') end, "Enable mouse"),
    awful.key({modkey, "Control"  }, "m", function() awful.util.spawn('xinput set-prop 9 "Device Enabled" 0') end, "Disale mouse")

)

clientkeys = awful.util.table.join(
    keydoc.group("_Client"),
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end, "Set fullscreen"),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end, "Close"),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     , "Set float"),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end, "Set master"),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end, "Redraw"),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end, "Set on top"),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end, "Minimize"),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end, "Maximized"),
    awful.key({ modkey, "Control" }, "Up" ,   function(c) awful.client.movetoscreen(c,c.screen+1) end, "move client to next screen" ),
    awful.key({ modkey, "Control" }, "Down" , function(c) awful.client.movetoscreen(c,c.screen-1) end, "move client to prev screen" ),
    awful.key({ modkey, "Control" }, "Left",
        function (c)
            local tag = awful.tag.selected()
            local curidx = awful.tag.getidx(tag)
            if curidx == 1 then
                curidx = 9
            else
                curidx = curidx-1
            end
--3.5 ??            awful.client.movetotag(tags[client.focus.screen][curidx])
            c:tags({screen[mouse.screen]:tags()[curidx]})
            awful.tag.viewprev()
        end, "move client to prev view"),
    awful.key({ modkey, "Control" }, "Right",
       function (c)
            local tag = awful.tag.selected()
            local curidx = awful.tag.getidx(tag)

            if curidx == 9 then
                curidx = 1
            else
                curidx = curidx + 1
            end
--3.5 ??            awful.client.movetotag(tags[client.focus.screen][curidx])
            c:tags({screen[mouse.screen]:tags()[curidx]})
            io.stderr:write("curidx=" .. curidx .. "\n")
            awful.tag.viewnext()
        end, "move client to next view")
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ GVIM manageemnt
gvim_management=function(c, val)
   gvim_name="%- .+"
--   io.stderr:write("gvim_management name=" .. c.name .. " class=" .. c.class .."\n")
   s,e = string.find(c.name, gvim_name)
--   gvim_server = string.sub(c.name, s+2, e)
--   io.stderr:write("gvim server =" .. gvim_server .. "\n")
end


-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "Gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 9 of screen 1.
    { rule_any = { class = {"Firefox", "Chromium-browser" } },
       properties = { tag = tags[1][9] } },
    { rule_any = { class = {"Thunderbird", "Pidgin"} },
       properties = { tag = tags[2][9] } },
    { rule = { class = "Gvim" },
       properties = {},
       callback=gvim_management },
    { rule = { name = "Terminator Preferences" },
       properties = { floating = true } },
    { rule = { class = "Ghb" },
       properties = { floating = true } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })
--io.stderr:write("manage client name=" .. c.name .. " class=" .. c.class .. "\n")
    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
