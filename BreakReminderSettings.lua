local BR = BreakReminder

BreakReminder.settings = {}
local settings = {}

function settings.__index(self, key)
  local sets = BR.getSettings()
  return sets[key]
end

function settings.__newindex(self, key, value)
  local sets = BR.getSettings()
  sets[key] = value
end

setmetatable(BR.settings, settings)

function BR.getSettings()
  if(BR.accountSettings.accountWide) then
    return BR.accountSettings
  else
    return BR.localSettings
  end
end

function BreakReminder:CreateAddonMenu()
    local LAM = LibAddonMenu2
    local i = 0

    LAM:RegisterAddonPanel(BR.name .. "Options", BR.options)

    local optionsData = {
        {
            type = "description",
            title = nil,
            text = GetString(BREAKREMINDER_OPTION_DESCRIPTION),
            width = "full",
        },
        {
            type = "header",
            name = "",
            width = "full",
        },
        {
            type = "checkbox",
            name = GetString(BREAKREMINDER_OPTION_ACCOUNT_WIDE),
            warning = GetString(BREAKREMINDER_OPTION_ACCOUNT_WIDE_TOOLTIP),
            getFunc = function() return BR.accountSettings.accountWide end,
            setFunc = function(value) 
              BR.accountSettings.accountWide, BR.localSettings.accountWide = value, value
              if(BR.accountSettings.accountWide) then
                for k,v in pairs(BR.defaultSettings) do
                  BR.accountSettings[k] = BR.localSettings[k]
                end
              else
                for k,v in pairs(BR.defaultSettings) do
                  BR.localSettings[k] = BR.accountSettings[k]
                end
              end
              ReloadUI()
            end,
            width = "full"
        },
        {
            type = "slider",
            min = 5,
            max = 240,
            step = 5,
            name = GetString(BREAKREMINDER_OPTION_NOTIFICATION_DELAY_DESCRIPTION),
            tooltip = GetString(BREAKREMINDER_OPTION_NOTIFICATION_DELAY_TOOLTIP),
            getFunc = function() return BR.settings.notificationDelay end,
            setFunc = function(value) 
              BR.settings.notificationDelay = value
              BR.ResetTimer()
            end,
            width = "full"
        },
        {
            type = "colorpicker",
            name = GetString(BREAKREMINDER_OPTION_NOTIFICATION_COLOR_DESCRIPTION),
            tooltip = GetString(BREAKREMINDER_OPTION_NOTIFICATION_COLOR_TOOLTIP),
            getFunc = function() return unpack(BR.settings.notificationColour) end,
            setFunc = function(r, g, b, a) BR.settings.notificationColour = {r, g, b, a} end,
            width = "full"
        },
        {
            type = "slider",
            min = 1,
            max = 60,
            name = GetString(BREAKREMINDER_OPTION_NOTIFICATION_DURATION_DESCRIPTION),
            tooltip = GetString(BREAKREMINDER_OPTION_NOTIFICATION_DURATION_TOOLTIP),
            getFunc = function() return BR.settings.notificationDuration end,
            setFunc = function(value) BR.settings.notificationDuration = value end,
            width = "full"
        },
        {
          type = "checkbox",
          name = GetString(BREAKREMINDER_OPTION_NOTIFICATION_COMBAT_DESCRIPTION),
          tooltip = GetString(BREAKREMINDER_OPTION_NOTIFICATION_COMBAT_TOOLTIP),
          getFunc = function() return BR.settings.notificationDuringFights end,
          setFunc = function(value) BR.settings.notificationDuringFights = value end,
          width = "full"
      },
        {
            type = "button",
            name = GetString(BREAKREMINDER_OPTION_NOTIFICATION_RESET_DESCRIPTION),
            tooltip = GetString(BREAKREMINDER_OPTION_NOTIFICATION_RESET_TOOLTIP),
            width = "full",
            func = function() BR.ResetTimer()  end,
        }
    }

    LAM:RegisterOptionControls(BR.name .. "Options", optionsData)
end