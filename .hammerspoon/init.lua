require("hs.ipc")
require "lgtv"
require "elgato"
edgeKiosk = dofile(os.getenv("HOME") .. "/projects/edge-usage-dashboard/hammerspoon/edge-kiosk.lua").start()
