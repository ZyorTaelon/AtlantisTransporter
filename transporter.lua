local event = require("event") -- load event table and store the pointer to it in event
local thread = require("thread")
local ctifview = require("ctifview")
local component = require("component")
local unicode = require("unicode")
local gpu = component.gpu;

function unknownEvent()
  -- do nothing if the event wasn't relevant
end

continueLoop = true;

local cleanup_thread = thread.create(function()
  event.pull("interrupted")
  continueLoop = false
  print("Interrupt received. Exiting")
  ctifview.clear();
end)

local lastX=nil
local lastY=nil
local lastLen=nil
function debugLocation(x, y)
  if lastX ~= nil then
    ctifview.drawImageSection(lastX-1, lastX+lastLen, lastY-1, lastY+1)
  end   

  lastX = x
  lastY = y
  local msg = "user clicked (" .. x .. "," .. y .. ")";
  lastLen = unicode.wlen(msg)
  gpu.setForeground(0xFFFFFF)
  gpu.setBackground(0x0)
  gpu.set(x, y, msg)
end

local main_thread = thread.create(function()
  ctifview.show('lib/TransporterDisplay_320.ctif')
  while continueLoop do
    local id, _, x, y = event.pullMultiple("touch", "interrupted")
    if id == "touch" then
      debugLocation(x,y)
    end
  end
end)