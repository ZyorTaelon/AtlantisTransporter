local event = require("event") -- load event table and store the pointer to it in event
local thread = require("thread")
local ctifview = require("ctifview")
local component = require("component")
local unicode = require("unicode")
local computer = require("computer")
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
  -- computer.shutdown(true)
end)

local toggle = true;
function displayImage()
  if toggle then
    toggle = false
    ctifview.show('lib/CitySchematic.ctif')
  else
    toggle = true
    ctifview.show('lib/StargateDiagnostics.ctif')
  end
  event.timer(10, displayImage, 1)
end

local displayThread = thread.create(function()
  displayImage()
end)

local main_thread = thread.create(function()
  while continueLoop do
    local id, _, x, y = event.pullMultiple("touch", "interrupted")
    if id == "touch" then
      if x > 115 and y > 59 then
        computer.shutdown(true)
      end
    end
  end
end)