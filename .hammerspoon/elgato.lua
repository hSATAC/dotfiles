-- Elgato Key Light Mini Control
-- API: http://<IP>:9123/elgato/lights

local log = hs.logger.new('elgato', 'info')

local LIGHTS = {
    "192.168.20.64",
    "192.168.20.93",
}

local PORT = 9123
local BRIGHTNESS_STEP = 10  -- adjust by 10% each step
local DEFAULT_BRIGHTNESS = 70

-- Local state cache (shared across all lights for simplicity)
local cachedBrightness = DEFAULT_BRIGHTNESS
local cachedLightOn = false

-- Helper: build URL for a light
local function lightUrl(ip)
    return string.format("http://%s:%d/elgato/lights", ip, PORT)
end

-- Helper: execute curl PUT with JSON body
local function curlPut(url, body)
    local jsonBody = hs.json.encode(body)
    local cmd = string.format("curl -s -X PUT '%s' -H 'Content-Type: application/json' -d '%s'", url, jsonBody)
    local output, status = hs.execute(cmd)
    return status
end

-- Turn off light
local function turnOffLight(ip)
    local url = lightUrl(ip)
    local body = {
        lights = {
            { on = 0 }
        }
    }
    curlPut(url, body)
    log.i(string.format("Light %s turned OFF", ip))
end

-- Set brightness (also turns light on)
local function setBrightness(ip, brightness)
    local url = lightUrl(ip)
    local body = {
        lights = {
            { on = 1, brightness = brightness }
        }
    }
    curlPut(url, body)
    log.i(string.format("Light %s brightness set to %d", ip, brightness))
end

-- Turn off all lights
local function turnOffAllLights()
    for _, ip in ipairs(LIGHTS) do
        turnOffLight(ip)
    end
    cachedLightOn = false
end

-- Raise brightness for all lights
local function raiseBrightness()
    -- Skip only if light is on AND already at max
    if cachedLightOn and cachedBrightness >= 100 then
        log.i("Brightness already at max (100), skipping")
        return
    end

    cachedBrightness = math.min(100, cachedBrightness + BRIGHTNESS_STEP)
    for _, ip in ipairs(LIGHTS) do
        setBrightness(ip, cachedBrightness)
    end
    cachedLightOn = true
end

-- Lower brightness for all lights
local function lowerBrightness()
    -- Skip only if light is on AND already at min
    if cachedLightOn and cachedBrightness <= 0 then
        log.i("Brightness already at min (0), skipping")
        return
    end

    cachedBrightness = math.max(0, cachedBrightness - BRIGHTNESS_STEP)
    for _, ip in ipairs(LIGHTS) do
        setBrightness(ip, cachedBrightness)
    end
    cachedLightOn = true
end

-- Knob pressed: turn off the elgato key light mini
hs.hotkey.bind({}, "F18", function()
    log.i("F18 pressed - turning off lights")
    turnOffAllLights()
end)

-- Knob turned clockwise: raise the light level
hs.hotkey.bind({}, "F17", function()
    log.i("F17 pressed - raising brightness")
    raiseBrightness()
end)

-- Knob turned counterclockwise: lower the light level
hs.hotkey.bind({}, "F16", function()
    log.i("F18 pressed - lowering brightness")
    lowerBrightness()
end)

log.i("Elgato Key Light control loaded")
