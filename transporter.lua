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

local main_thread = thread.create(function()
  ctifview.show('lib/TransporterDisplay_320.ctif')
  print("Waiting for incoming events:")
  
  local lastX=nil
  local lastY=nil
  local lastLen=nil;
  while continueLoop do
    local id, _, x, y = event.pullMultiple("touch", "interrupted")
    if id == "touch" then
      if lastX ~= nil then
        ctifview.drawImageSection(lastX-1, lastX+lastLen+1, lastY-1, lastY+1)
      end   
         
      local msg = "user clicked (" .. x .. "," .. y .. ")"
      gpu.setForeground(0xFFFFFF)
      gpu.set(x, y, msg)
      lastX = x
      lastY = y
      lastLen = unicode.wlen(msg)
    end
  end
end)