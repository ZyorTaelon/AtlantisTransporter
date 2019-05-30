-- install this file with: wget -f 'https://raw.githubusercontent.com/ZyorTaelon/OpenComputersPrograms/master/Atlantis/Control/setup.lua'
local os = require('os');
local filesystem = require("filesystem")
os.setenv('SERVER_LOCATION', 'https://raw.githubusercontent.com/ZyorTaelon/OpenComputersPrograms/master')
local codeURL = os.getenv('SERVER_LOCATION');
local srcFileName = '/Atlantis/Control/downloadCode.lua'
local fileName = '/downloadCode.lua'

if not filesystem.exists('/home/lib') then
  filesystem.makeDirectory('/home/lib')
end
  
os.execute('wget -f ' .. codeURL .. '/' .. fileName .. ' ' .. '/home/lib' .. fileName);
local dl = require("downloadCode");
dl.downloadAll();
