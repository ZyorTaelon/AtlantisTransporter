local os = require('os');
local url = os.getenv('SERVER_LOCATION') .. '/';
local filenames = {}
filenames["reactor.lua"] = "reactor.lua"
filenames[".shrc"] = ".shrc"

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