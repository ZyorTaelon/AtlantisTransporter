local event = require("event") -- load event table and store the pointer to it in event
local thread = require("thread")
local ctifview = require("ctifview")
local component = require("component")
local unicode = require("unicode")
local gpu = component.gpu;
local dialer = component.rftools_dialing_device
local serialization = require("serialization")
local realX = 2240
local realY = 210
local realWidth = 784
local realHeight = 740

local transmitter = dialer.getTransmitters()[1];
local transporters = {
--  gateRoom = {x=59,y=30,position={z=582.0,x=2621.0,y=167.0},dimension=109.0,name="Gate Room"},
--  westPier = {x=16,y=30,position={z=582.0,x=2621.0,y=167.0},dimension=109.0,name="West Pier"},
--  eastPierHallway = {x=111,y=33,position={z=578.0,x=2908.0,y=8.0},dimension=109.0,name="East Pier Hallway"}
}
for a,receiver in pairs(dialer.getReceivers()) do
  if type(receiver) == 'table' and receiver.dimension == 109.0 then
    local rx = (receiver.position.x - realX) / realWidth * 120
    local ry = (receiver.position.z - realY) / realHeight * 63
    local rec = {x=rx,y=ry,position=receiver.position,dimension=receiver.dimension,name=receiver.name}
    table.insert(transporters, rec)
  end
end


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
   ctifview.drawImageSection(1, 30, 1, 3)  

  lastX = x
  lastY = y
  local msg = "user clicked (" .. x .. "," .. y .. ")";
  lastLen = unicode.wlen(msg)
  gpu.setForeground(0xFFFFFF)
  gpu.setBackground(0x0)
  gpu.set(1, 1, msg)
end

function paintTransporterDots()
  for k, v in pairs(transporters) do
      gpu.setForeground(0xFF0000)
      gpu.setBackground(0xFF0000)
      gpu.set(v.x, v.y, ' ')
  end
end

function activateTransporter(x, y)
--  gpu.setForeground(0x0)
--  gpu.setBackground(0x0)
--  ctifview.drawImageSection(1, 30, 1, 3)
  for k, v in pairs(transporters) do
    if (v.x-3 < x) and  (x < v.x+3) and (v.y-3 < y) and (y < v.y+3) then
--      gpu.setForeground(0xFFFFFF)
--      gpu.setBackground(0x0)
--      gpu.set(2, 2, v.name)
      dialer.dial(transmitter.position, v.position, v.dimension, true)
      return true
    end
  end
  dialer.interrupt(transmitter.position);
  return false;
end

local main_thread = thread.create(function()
  ctifview.show('lib/TransporterDisplay_320.ctif')
  paintTransporterDots()
  while continueLoop do
    local id, _, x, y = event.pullMultiple("touch", "interrupted")
    if id == "touch" then
      if not activateTransporter(x,y) then
        debugLocation(x,y)
      end
    end
  end
--  activateTransporter(59,30)
end)