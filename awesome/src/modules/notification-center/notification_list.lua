-------------------------------------
-- This is the notification-center --
-------------------------------------

-- Awesome Libs
local awful = require("awful")
local color = require("src.theme.colors")
local dpi = require("beautiful").xresources.apply_dpi
local gears = require("gears")
local wibox = require("wibox")
local naughty = require("naughty")

-- Icon directory path
local icondir = awful.util.getdir("config") .. "src/assets/icons/notifications/"

local nl = {}

nl.notification_list = { layout = wibox.layout.fixed.vertical, spacing = dpi(20) }

-- @param {table} notification
-- @return {widget} notifications_list
function nl.create_notification(n)

  n.time = os.time()

  local time_ago_text = "- ago"

  local timer_widget = wibox.widget {
    {
      {
        text = time_ago_text,
        widget = wibox.widget.textbox,
        id = "txt"
      },
      id = "background",
      fg = color["Teal200"],
      widget = wibox.container.background
    },
    margins = dpi(10),
    widget = wibox.container.margin,
  }

  gears.timer {
    timeout = 1,
    autostart = true,
    call_now = true,
    callback = function()
      local time_ago = math.floor(os.time() - n.time)
      local timer_text = timer_widget.background.txt
      if time_ago < 5 then
        timer_text:set_text("now")
      elseif time_ago < 60 then
        timer_text:set_text(time_ago .. "s ago")
      elseif time_ago < 3600 then
        timer_text:set_text(math.floor(time_ago / 60) .. "m ago")
      elseif time_ago < 86400 then
        timer_text:set_text(math.floor(time_ago / 3600) .. "h ago")
      else
        timer_text:set_text(math.floor(time_ago / 86400) .. "d ago")
      end
    end
  }

  local close_widget = wibox.widget {
    {
      {
        {
          {
            font = user_vars.font.specify .. ", 10",
            text = "✕",
            align = "center",
            valign = "center",
            widget = wibox.widget.textbox
          },
          start_angle = 4.71239,
          thickness = dpi(2),
          min_value = 0,
          max_value = 360,
          value = 360,
          widget = wibox.container.arcchart,
          id = "arc_chart"
        },
        id = "background",
        fg = color["Teal200"],
        widget = wibox.container.background
      },
      strategy = "exact",
      width = dpi(20),
      height = dpi(20),
      widget = wibox.container.constraint,
      id = "const"
    },
    margins = dpi(10),
    widget = wibox.container.margin,
    id = "arc_margin"
  }

  local timer_close_widget = timer_widget

  local notification = wibox.widget {
    {
      {
        {
          {
            {
              {
                {
                  {
                    {
                      {
                        image = gears.color.recolor_image(icondir .. "notification-outline.svg", color["Teal200"]),
                        resize = false,
                        widget = wibox.widget.imagebox
                      },
                      right = dpi(5),
                      widget = wibox.container.margin
                    },
                    {
                      markup = n.app_name or 'System Notification',
                      align = "center",
                      valign = "center",
                      widget = wibox.widget.textbox
                    },
                    layout = wibox.layout.fixed.horizontal
                  },
                  fg = color["Teal200"],
                  widget = wibox.container.background
                },
                margins = dpi(10),
                widget = wibox.container.margin
              },
              nil,
              {
                timer_widget,
                layout = wibox.layout.fixed.horizontal,
                id = "arc_app_layout_2"
              },
              id = "arc_app_layout",
              layout = wibox.layout.align.horizontal
            },
            id = "arc_app_bg",
            border_color = color["Grey800"],
            border_width = dpi(2),
            widget = wibox.container.background
          },
          {
            {
              {
                {
                  {
                    image = n.icon,
                    resize = true,
                    widget = wibox.widget.imagebox,
                    clip_shape = function(cr, width, height)
                      gears.shape.rounded_rect(cr, width, height, 10)
                    end
                  },
                  width = naughty.config.defaults.icon_size,
                  height = naughty.config.defaults.icon_size,
                  strategy = "exact",
                  widget = wibox.container.constraint
                },
                halign = "center",
                valign = "top",
                widget = wibox.container.place
              },
              id = "margin01",
              left = dpi(20),
              bottom = dpi(15),
              top = dpi(15),
              right = dpi(10),
              widget = wibox.container.margin
            },
            {
              {
                {
                  markup = n.title,
                  widget = wibox.widget.textbox,
                  align = "left"
                },
                {
                  markup = n.message,
                  widget = wibox.widget.textbox,
                  align = "left"
                },
                layout = wibox.layout.fixed.vertical
              },
              left = dpi(10),
              bottom = dpi(10),
              top = dpi(10),
              right = dpi(20),
              widget = wibox.container.margin
            },
            layout = wibox.layout.fixed.horizontal
          },
          id = "widget_layout",
          layout = wibox.layout.fixed.vertical
        },
        id = "min_size",
        strategy = "min",
        width = dpi(100),
        widget = wibox.container.constraint
      },
      id = "max_size",
      strategy = "max",
      width = Theme.notification_max_width or dpi(500),
      widget = wibox.container.constraint
    },
    pk = #nl.notification_list + 1,
    bg = color["Grey900"],
    border_color = color["Grey800"],
    border_width = dpi(4),
    shape = function(cr, width, height)
      gears.shape.rounded_rect(cr, width, height, 8)
    end,
    widget = wibox.container.background
  }

  close_widget:connect_signal(
    "button::press",
    function(_, _, _, button)
      if button == 1 then
        for i, b in pairs(nl.notification_list) do
          if b.pk == notification.pk then
            table.remove(nl.notification_list, i)
            awesome.emit_signal("notification_center:update::needed")
            break
          end
        end
      end
    end
  )

  Hover_signal(close_widget.const.background, color["Grey900"], color["Teal200"])

  notification:connect_signal(
    "mouse::enter",
    function()
      notification:get_children_by_id("arc_app_layout_2")[1]:set(1, close_widget)
    end
  )

  notification:connect_signal(
    "mouse::leave",
    function()
      notification:get_children_by_id("arc_app_layout_2")[1]:set(1, timer_close_widget)
    end
  )

  table.insert(nl.notification_list, notification)
end

naughty.connect_signal(
  "request::display",
  function(n)
    nl.create_notification(n)
    awesome.emit_signal("notification_center:update::needed")
  end
)

return nl