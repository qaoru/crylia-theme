--------------------------------------------------------------------------------------------------------------
-- This is the statusbar, every widget, module and so on is combined to all the stuff you see on the screen --
--------------------------------------------------------------------------------------------------------------
-- Awesome Libs
local awful = require("awful")
local color = require("src.theme.colors")
local dpi = require("beautiful").xresources.apply_dpi
local gears = require("gears")
local wibox = require("wibox")

return function(screen, programs)

    local function create_dock_element(program, name, is_steam, size)
        is_steam = is_steam or false

        if program:match("com.*%a.Client") ~= nil then
            program = program:gsub("com.", ""):gsub(".Client", ""):gsub("flatpak", ""):gsub("run", ""):gsub(" ", "")
        end

        local function create_indicator()
            local col = "#fff"
            local indicators = { layout = wibox.layout.flex.horizontal, spacing = dpi(5) }
            for i, c in ipairs(client.get()) do
                if string.lower(c.class):match(program or name) then
                    if c == client.focus then
                        col = color["YellowA200"]
                    elseif c.urgent then
                        col = color["RedA200"]
                    elseif c.maximized then
                        col = color["GreenA200"]
                    elseif c.minimized then
                        col = color["BlueA200"]
                    elseif c.fullscreen then
                        col = color["PinkA200"]
                    else
                        col = color["Grey600"]
                    end
                    local indicator = wibox.widget {
                        widget = wibox.container.background,
                        shape = gears.shape.rounded_rect,
                        forced_height = dpi(3),
                        spacing_widget = dpi(5),
                        spacing = dpi(5),
                        bg = col
                    }
                    indicators[i] = indicator
                end
            end
            return indicators
        end

        local dock_element = wibox.widget {
            {
                {
                    {
                        {
                            resize = true,
                            forced_width = size,
                            forced_height = size,
                            image = Get_icon(user_vars.icon_theme, program, is_steam),
                            widget = wibox.widget.imagebox,
                            id = "icon"
                        },
                        create_indicator(),
                        layout = wibox.layout.align.vertical,
                        id = "dock_layout"
                    },
                    margins = dpi(5),
                    widget = wibox.container.margin,
                    id = "margin"
                },
                shape = function(cr, width, height)
                    gears.shape.rounded_rect(cr, width, height, 10)
                end,
                bg = color["Grey900"],
                widget = wibox.container.background,
                id = "background"
            },
            margins = dpi(5),
            widget = wibox.container.margin
        }

        for k, c in ipairs(client.get()) do
            if string.lower(c.class):match(program) and c == client.focus then
                dock_element.background.bg = color["Grey800"]
            end
        end

        Hover_signal(dock_element.background, color["Grey800"], color["White"])

        dock_element:connect_signal(
            "button::press",
            function()
                if is_steam then
                    awful.spawn("steam steam://rungameid/" .. program)
                else
                    awful.spawn(program)
                end
            end
        )

        awful.tooltip {
            objects = { dock_element },
            text = name,
            mode = "outside",
            preferred_alignments = "middle",
            margins = dpi(10)
        }

        return dock_element
    end

    local dock = awful.popup {
        widget = wibox.container.background,
        ontop = true,
        bg = color["Grey900"],
        visible = true,
        screen = screen,
        type = "dock",
        height = user_vars.dock_icon_size + 10,
        placement = function(c) awful.placement.bottom(c, { margins = dpi(10) }) end,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, 15)
        end
    }

    local fakedock = awful.popup {
        widget = wibox.container.background,
        ontop = true,
        bg = '#00000000',
        visible = true,
        screen = screen,
        type = "dock",
        id = "fakedock",
        height = dpi(10),
        placement = function(c) awful.placement.bottom(c, { margins = dpi(0) }) end,
    }

    local function get_dock_elements(pr)
        local dock_elements = { layout = wibox.layout.fixed.horizontal }

        for i, p in ipairs(pr) do
            dock_elements[i] = create_dock_element(p[1], p[2], p[3], user_vars.dock_icon_size)
        end

        return dock_elements
    end

    local function get_fake_elements(amount)
        local fake_elements = { layout = wibox.layout.fixed.horizontal }

        for i = 0, amount, 1 do
            fake_elements[i] = wibox.widget {
                bg = '00000000',
                forced_width = user_vars.dock_icon_size + dpi(20),
                forced_height = dpi(10),
                widget = wibox.container.background
            }
        end
        return fake_elements
    end

    dock:setup {
        get_dock_elements(programs),
        layout = wibox.layout.fixed.vertical
    }

    fakedock:setup {
        get_fake_elements(#programs),
        type = 'dock',
        layout = wibox.layout.fixed.vertical
    }

    local function check_for_dock_hide(s)
        if #s:get_clients() < 1 then
            dock.visible = true
            return
        end
        if s == mouse.screen then
            if mouse.current_widget then
                dock.visible = true
                return
            end
            for j, c in ipairs(screen.selected_tag:clients()) do
                local y = c:geometry().y
                local h = c.height
                if (y + h) >= screen.geometry.height - user_vars.dock_icon_size - 35 then
                    dock.visible = false
                else
                    dock.visible = true
                end
            end
        else
            dock.visible = false
        end
    end

    client.connect_signal(
        "manage",
        function()
            check_for_dock_hide(screen)
            dock:setup {
                get_dock_elements(programs),
                layout = wibox.layout.fixed.vertical
            }
        end
    )

    client.connect_signal(
        "unmanage",
        function()
            check_for_dock_hide(screen)
            dock:setup {
                get_dock_elements(programs),
                layout = wibox.layout.fixed.vertical
            }
        end
    )

    client.connect_signal(
        "focus",
        function()
            check_for_dock_hide(screen)
            dock:setup {
                get_dock_elements(programs),
                layout = wibox.layout.fixed.vertical
            }
        end
    )

    local dock_intelligent_hide = gears.timer {
        timeout = 1,
        autostart = true,
        call_now = true,
        callback = function()
            check_for_dock_hide(screen)
        end
    }

    dock:connect_signal(
        "mouse::enter",
        function()
            dock_intelligent_hide:stop()
        end
    )

    dock:connect_signal(
        "mouse::leave",
        function()
            dock_intelligent_hide:again()
        end
    )
end