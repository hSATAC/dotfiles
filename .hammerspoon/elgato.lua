-- Elgato Key Light Mini Control
-- API: http://<IP>:9123/elgato/lights

local log = hs.logger.new('elgato', 'info')

local LIGHTS = {
    "192.168.20.64",
    "192.168.20.93",
}

local PORT = 9123
local BRIGHTNESS_STEP = 10  -- adjust by 10% each step

-- Helper: build URL for a light
local function lightUrl(ip)
    return string.format("http://%s:%d/elgato/lights", ip, PORT)
end

-- Helper: execute curl and return parsed JSON
local function curlGet(url)
    local output, status = hs.execute(string.format("curl -s '%s'", url))
    if status and output then
        return hs.json.decode(output)
    end
    return nil
end

-- Helper: execute curl PUT with JSON body
local function curlPut(url, body)
    local jsonBody = hs.json.encode(body)
    local cmd = string.format("curl -s -X PUT '%s' -H 'Content-Type: application/json' -d '%s'", url, jsonBody)
    local output, status = hs.execute(cmd)
    return status
end

-- Toggle light on/off
local function toggleLight(ip)
    local url = lightUrl(ip)
    local data = curlGet(url)
    if data and data.lights and data.lights[1] then
        local currentState = data.lights[1].on
        local newState = (currentState == 1) and 0 or 1
        local body = {
            lights = {
                { on = newState }
            }
        }
        curlPut(url, body)
        log.i(string.format("Light %s toggled to %s", ip, newState == 1 and "ON" or "OFF"))
    else
        log.e("Failed to get light state for " .. ip)
    end
end

-- Adjust brightness
local function adjustBrightness(ip, delta)
    local url = lightUrl(ip)
    local data = curlGet(url)
    if data and data.lights and data.lights[1] then
        local current = data.lights[1].brightness or 50
        local newBrightness = math.max(0, math.min(100, current + delta))
        local body = {
            lights = {
                { brightness = newBrightness }
            }
        }
        curlPut(url, body)
        log.i(string.format("Light %s brightness: %d -> %d", ip, current, newBrightness))
    else
        log.e("Failed to get light state for " .. ip)
    end
end

-- Toggle all lights
local function toggleAllLights()
    for _, ip in ipairs(LIGHTS) do
        toggleLight(ip)
    end
end

-- Raise brightness for all lights
local function raiseBrightness()
    for _, ip in ipairs(LIGHTS) do
        adjustBrightness(ip, BRIGHTNESS_STEP)
    end
end

-- Lower brightness for all lights
local function lowerBrightness()
    for _, ip in ipairs(LIGHTS) do
        adjustBrightness(ip, -BRIGHTNESS_STEP)
    end
end

-- Knob pressed: toggle the elgato key light mini
hs.hotkey.bind({}, "F18", function()
    log.i("F16 pressed - toggling lights")
    toggleAllLights()
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
