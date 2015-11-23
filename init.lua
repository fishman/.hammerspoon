-- Hammerspoon configuration, heavily influenced by sdegutis default configuration

require "pomodoor"
local bluetooth   = require("hs._asm.undocumented.bluetooth")

-- init grid
hs.grid.MARGINX 	= 0
hs.grid.MARGINY 	= 0
hs.grid.GRIDWIDTH 	= 7
hs.grid.GRIDHEIGHT 	= 3

-- disable animation
hs.window.animationDuration = 0


-- hotkey mash
local mash       = {"ctrl", "alt"}
local mash_app 	 = {"cmd", "alt", "ctrl"}
local mash_shift = {"ctrl", "alt", "shift"}
local mash_test	 = {"cntrl", "shift"}	

--------------------------------------------------------------------------------
appCuts = {
  d = 'Dictionary',
  i = 'iterm',
  c = 'Google chrome',
  t = 'Trello X',
  -- 4 reserved for dash shortcut 
  q = 'Quiver',
  e = 'emacs'
}

-- Launch applications
for key, app in pairs(appCuts) do
  hs.hotkey.bind(mash_app, key, function () hs.application.launchOrFocus(app) end)
end

-- global operations
hs.hotkey.bind(mash, ';', function() hs.grid.snap(hs.window.focusedWindow()) end)
hs.hotkey.bind(mash, "'", function() hs.fnutils.map(hs.window.visibleWindows(), hs.grid.snap) end)

-- adjust grid size
hs.hotkey.bind(mash, '=', function() hs.grid.adjustWidth( 1) end)
hs.hotkey.bind(mash, '-', function() hs.grid.adjustWidth(-1) end)
hs.hotkey.bind(mash, ']', function() hs.grid.adjustHeight( 1) end)
hs.hotkey.bind(mash, '[', function() hs.grid.adjustHeight(-1) end)

-- change focus
hs.hotkey.bind(mash_shift, 'H', function() hs.window.focusedWindow():focusWindowWest() end)
hs.hotkey.bind(mash_shift, 'L', function() hs.window.focusedWindow():focusWindowEast() end)
hs.hotkey.bind(mash_shift, 'K', function() hs.window.focusedWindow():focusWindowNorth() end)
hs.hotkey.bind(mash_shift, 'J', function() hs.window.focusedWindow():focusWindowSouth() end)

hs.hotkey.bind(mash, 'M', hs.grid.maximizeWindow)

-- multi monitor
hs.hotkey.bind(mash, 'N', hs.grid.pushWindowNextScreen)
hs.hotkey.bind(mash, 'P', hs.grid.pushWindowPrevScreen)

-- move windows
hs.hotkey.bind(mash, 'H', hs.grid.pushWindowLeft)
hs.hotkey.bind(mash, 'J', hs.grid.pushWindowDown)
hs.hotkey.bind(mash, 'K', hs.grid.pushWindowUp)
hs.hotkey.bind(mash, 'L', hs.grid.pushWindowRight)

-- resize windows
hs.hotkey.bind(mash, 'Y', hs.grid.resizeWindowThinner)
hs.hotkey.bind(mash, 'U', hs.grid.resizeWindowShorter)
hs.hotkey.bind(mash, 'I', hs.grid.resizeWindowTaller)
hs.hotkey.bind(mash, 'O', hs.grid.resizeWindowWider)

-- Window Hints
-- hs.hotkey.bind(mash, '.', function() hs.hints.windowHints(hs.window.allWindows()) end)
hs.hotkey.bind(mash, '.', hs.hints.windowHints)

-- pomodoro key binding
hs.hotkey.bind(mash, '9', function() pom_enable() end)
hs.hotkey.bind(mash, '0', function() pom_disable() end)
hs.hotkey.bind(mash_shift, '0', function() pom_reset_work() end)

-- snap all newly launched windows
local function auto_tile(appName, event)
	if event == hs.application.watcher.launched then
		local app = hs.appfinder.appFromName(appName)
		-- protect against unexpected restarting windows
		if app == nil then
			return
		end
		hs.fnutils.map(app:allWindows(), hs.grid.snap)
	end
end

-- start app launch watcher
hs.application.watcher.new(auto_tile):start()

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "H", function()

  hs.application.launchOrFocus("iTerm")
  hs.application.launchOrFocus("Safari")

  local laptopScreen = "Color LCD"
  local windowLayout = {
      -- {"Sublime Text",  nil,  laptopScreen, {x=0,y=0,w=0.5,h=0.80}, nil, nil},
      -- {"Safari",        nil,  laptopScreen, hs.layout.right50,      nil, nil},
      -- {"Terminal",      nil,  laptopScreen, {x=0,y=0.80,w=0.5,h=0.20}, nil, nil},
      {"iTerm2",        nil,  laptopScreen, {x=0,y=0,w=0.6,h=1},      nil, nil},
      {"Safari",        nil,  laptopScreen, {x=0.6,y=0,w=0.4,h=1}, nil, nil},
  }
  hs.layout.apply(windowLayout)
end)


local wifiWatcher = nil
local homeSSID = "o2-WLAN08"
local lastSSID = hs.wifi.currentNetwork()

function ssidChangedCallback()
    newSSID = hs.wifi.currentNetwork()

    if newSSID == homeSSID and lastSSID ~= homeSSID then
        -- We just joined our home WiFi network
        hs.audiodevice.defaultOutputDevice():setVolume(25)
        hs.alert.show("Set the volume to 25")
    elseif newSSID ~= homeSSID and lastSSID == homeSSID then
        -- We just departed our home WiFi network
        hs.audiodevice.defaultOutputDevice():setVolume(0)
        hs.alert.show("Set the volume to 0")
    end

    lastSSID = newSSID
end

wifiWatcher = hs.wifi.watcher.new(ssidChangedCallback)
wifiWatcher:start()

function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end
hs.hotkey.bind(mash_shift, "b", function()
    hs.alert("Bluetooth is power is now: "..
        (bluetooth.power(not bluetooth.power()) and "On" or "Off"))
    end, nil)
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

-------------------------------------------------------------------------------------
-- Battery Low warnings
-------------------------------------------------------------------------------------
local batWatcher = nil
local lastBatVal = hs.battery.percentage()
function batPercentageChangedCallback()
  currentPercent = hs.battery.percentage()
  if currentPercent == 10 and lastBatVal > 10 then
    hs.alert.show("Getting low on juice...")
  end
  if currentPercent == 5 and lastBatVal > 5 then
    hs.alert.show("Captain, she can't take any more!")
  end
  lastBatVal = currentPercent
end
batWatcher = hs.battery.watcher.new(batPercentageChangedCallback)
batWatcher:start()


--status, data, headers = hs.http.get("http://example.com")
--hs.alert.show(status)
--hs.alert.show(data)

hs.alert.show("Config loaded")
