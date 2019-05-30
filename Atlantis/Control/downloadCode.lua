local os = require('os');
local url = os.getenv('SERVER_LOCATION') .. '/';
local filenames = {}
filenames["Atlantis/shared/ctifview.lua"] = "lib/ctifview.lua"
filenames["Atlantis/Control/CitySchematic.ctif"] = "lib/CitySchematic.ctif"
filenames["Atlantis/Control/StargateDiagnostics.ctif"] = "lib/StargateDiagnostics.ctif"
filenames["Atlantis/Control/screensaver.lua"] = "screensaver.lua"
filenames["Atlantis/Control/.shrc"] = ".shrc"

local M = {};

function M.downloadAll()
  print("Starting file downloads...")
  for src, dest in pairs(filenames) do
    M.download(src, dest);
  end
end

-- rapid reuse may result in receiving cached pages
function M.download(src, dest)
  os.execute('wget -f ' .. url .. src .. ' /home/' .. dest);
end

return M;