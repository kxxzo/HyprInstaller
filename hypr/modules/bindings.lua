local Colors = require("modules.colors")

local mainMod = "SUPER"

-----------
-- Miscs --
-----------

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("~/wallpaper_random.sh"))

--------------
-- Launcher --
--------------

local launcher = "qs -p ~/.config/quickshell/launcher.qml ipc call launcher toggle"
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(launcher))

--------------
-- Terminal --
--------------

local terminal = "kitty"
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(terminal))

----------------------
-- Resource Manager --
----------------------

local resourceManager = terminal .. " btop"
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(resourceManager))

------------------
-- Music Player --
------------------

local musicPlayer = terminal .. " rmpc"
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(musicPlayer))

-------------------
-- File Explorer --
-------------------

local fileExplorer = terminal .. " superfile"
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileExplorer))

-----------------
-- Audio Mixer --
-----------------

local audioMixer = terminal .. " wiremix"
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(audioMixer))

-----------------
-- Screenshots --
-----------------

local screenshotsDirectory = os.getenv("HOME") .. "/pictures/screenshots"
local lockFile = "/tmp/hyprland-screenshot.lock"

local selectionColors = [[ -b ]] .. Colors.bg_strip .. [[80 -c ]] .. Colors.surface_strip

local function screenshot(selectionCommand)
    return [[(
    flock -n 9 || exit 0
    geometry=$( ]] .. selectionCommand .. [[ ) || exit 0
    filename="]] .. screenshotsDirectory .. [[/$(date +%Y-%m-%d-%H%M%S).png"
    grim -g "$geometry" "$filename" &&
    wl-copy --type image/png < "$filename"
    ) 9>"]] .. lockFile .. [["]]
end

local regionSelection = [[slurp]] .. selectionColors

local windowSelection = [[
    hyprctl -j clients |
    jq -r '.[] | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' |
    slurp -r]] .. selectionColors

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(screenshot(regionSelection)))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(screenshot(windowSelection)))

-------------
-- Windows --
-------------

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left", group_aware = true }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right", group_aware = true }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up", group_aware = true }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down", group_aware = true }))

hl.bind(mainMod .. " + Z", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ "fullscreen", "toggle" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

----------------
-- Workspaces --
----------------

for i = 1, 5 do
  local key = i
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

local max = 5
local min = 1
local ZOOM_TOGGLE_FACTOR = 2.0

local function zoom(offset)
    local current = hl.get_config("cursor.zoom_factor")
    if offset ~= nil then
        current = current + offset
    elseif current ~= min then
        current = min
    else
        current = ZOOM_TOGGLE_FACTOR
    end
    current = math.max(min, math.min(max, current))
    hl.config({ cursor = { zoom_factor = current } })
end

-----------------------
-- Magnifiying Glass --
-----------------------

hl.bind(mainMod .. " + C", zoom)
hl.bind(mainMod .. " + equal", function()
    zoom(0.5)
end)
hl.bind(mainMod .. " + minus", function()
    zoom(-0.5)
end)
