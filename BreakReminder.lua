BreakReminder = {
    name = "BreakReminder",

    options = {
        type = "panel",
        name = "BreakReminder",
        author = "mouton",
        version = "0.0.3"
    },

    command =  "/break",

    localSettings = {},
    accountSettings = {},
    defaultSettings = {
        useAccountWide = false,
        notificationColour = { 1, 1, 1, 1 },
        notificationDuration = 10,
        notificationDelay = 90, -- minutes
        nextNotification = 0,
        notificationDuringFights = false,
        variableVersion = 1
    }
}

local BR = BreakReminder
local timerCallback = nil

BR.Events = {}
BR.CallbackManager = {}
BR.CallbackManager.callbacks = {}

function BR.Events:AddEvent(eventName)
	BR.CallbackManager.callbacks[eventName] = {}
end

BR.Events:AddEvent("BREAK_REMINDER_RECURRENT")

function BR.CallbackManager:HasCallback(event)
	for _, callback in pairs(self.callbacks[event]) do
		return true
	end
    return false;
end

function BR.CallbackManager:RegisterCallback(event, callback)
	assert(callback)
	assert(event)
	table.insert(self.callbacks[event], callback)
end

function BR.CallbackManager:UnregisterCallback(event, callback)
	for index, entry in pairs(self.callbacks[event]) do
		if entry == callback then
			self.callbacks[event][index] = nil
			return true
		end
	end
	return false
end

function BR.CallbackManager:FireCallbacks(event, ...)
	for _, callback in pairs(self.callbacks[event]) do
		callback(event, ...)
	end
end

function BR.TriggerNotification()
    local settings = BR.getSettings()

    if settings.notificationDuringFights or not IsUnitInCombat("player") then
        local textColor = ZO_ColorDef:New(unpack(settings.notificationColour))
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.BLACKSMITH_CREATE_TOOLTIP_GLOW)
        messageParams:SetText(textColor:Colorize(zo_strformat(BREAKREMINDER_BREAK_TITLE)), textColor:Colorize(zo_strformat(BREAKREMINDER_BREAK_TEXT)))
        -- messageParams:SetIconData(icon, COLLECTIBLE_EMERGENCY_BACKGROUND)
        messageParams:SetLifespanMS(settings.notificationDuration * 1000)
        CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)

        BR.StartTimer()
    else
        -- Try again later if player is in a fight
        zo_callLater(BR.TriggerNotification, 10000);
    end
end

function BR.StartTimer()
    local settings = BR.getSettings()
    -- No notification ongoing. Initialize a new notification 
    if settings.nextNotification <= BR.GetTime() then
        settings.nextNotification = BR.GetDelay() + BR.GetTime()
        CHAT_SYSTEM:AddMessage(zo_strformat(BREAKREMINDER_BREAK_START, settings.notificationDelay))
        timerCallback = zo_callLater(function ()
            timerCallback = nil
            BR.CallbackManager:FireCallbacks("BREAK_REMINDER_RECURRENT")
        end, BR.GetDelay() * 1000)
    -- Game / UI was reloaded during within the delay ?
    elseif not timerCallback then
        CHAT_SYSTEM:AddMessage(zo_strformat(BREAKREMINDER_BREAK_START, math.ceil((settings.nextNotification - BR.GetTime()) / 60 )))
        timerCallback = zo_callLater(function ()
            timerCallback = nil
            BR.CallbackManager:FireCallbacks("BREAK_REMINDER_RECURRENT")
        end, (settings.nextNotification - BR.GetTime()) * 1000 )
    else
        d('Timer for Break Reminder already started');
        -- BR.ResetTimer()
    end
end

function BR.ResetTimer()
    local settings = BR.getSettings()

    if timerCallback then
        zo_removeCallLater(timerCallback)
        timerCallback = nil
    end
    settings.nextNotification = 0
    BR.StartTimer()
end

function BR.GetTime()
    return os.time(os.date("!*t"))
end

function BR.GetDelay()
    local settings = BR.getSettings()

    return settings.notificationDelay * 60
end


-- Initialize
function BR.OnAddOnLoaded(event, addonName)
    if addonName ~= BR.name then return end

    BreakReminder:Initialize()
end

function BreakReminder:Initialize()
    BR.accountSettings = ZO_SavedVars:NewAccountWide(BR.name .. "Variables", BR.defaultSettings.variableVersion, nil, BR.defaultSettings)
    BR.localSettings = ZO_SavedVars:NewCharacterIdSettings(BR.name .. "Variables", BR.defaultSettings.variableVersion, nil, BR.defaultSettings)

    BR:CreateAddonMenu()

    EVENT_MANAGER:UnregisterForEvent(BR.name, EVENT_ADD_ON_LOADED)

    BR.CallbackManager:RegisterCallback("BREAK_REMINDER_RECURRENT", BR.TriggerNotification)
    
    zo_callLater(BR.StartTimer, 2000)
end

EVENT_MANAGER:RegisterForEvent(BR.name, EVENT_ADD_ON_LOADED, BR.OnAddOnLoaded)
