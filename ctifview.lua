--[[
ctif-oc: OpenComputers viewer for CTIF image files
Copyright (c) 2016, 2017, 2018 asie

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

java -jar CTIFConverter-0.2.2.jar -m oc-tier3 -P preview_320.png -o TransporterDisplay_320.ctif TransporterDisplay_320.png
]]

local args = {...}
local component = require("component")
local event = require("event")
local gpu = component.gpu
local unicode = require("unicode")
local keyboard = require("keyboard")
local text = require("text")
local os = require("os")
local pal = {}
local w, h = gpu.getResolution()
local WIDTH = w
local HEIGHT = h
local loadedImage = {}

local M = {};

local q = {}
function M.init()
  for i=0,255 do
    local dat = (i & 0x01) << 7
    dat = dat | (i & 0x02) >> 1 << 6
    dat = dat | (i & 0x04) >> 2 << 5
    dat = dat | (i & 0x08) >> 3 << 2
    dat = dat | (i & 0x10) >> 4 << 4
    dat = dat | (i & 0x20) >> 5 << 1
    dat = dat | (i & 0x40) >> 6 << 3
    dat = dat | (i & 0x80) >> 7
    q[i + 1] = unicode.char(0x2800 | dat)
  end
end

M.init()

function M.error(msg)
  if type(msg) == 'string' then
    print("ERROR: " .. msg)
    os.exit()
  end
end

function M.resetPalette(data)
 for i=0,255 do
  if (i < 16) then
    if data == nil or data[3] == nil or data[3][i] == nil then
      pal[i] = (i * 15) << 16 | (i * 15) << 8 | (i * 15)
    else
      pal[i] = data[3][i]
      gpu.setPaletteColor(i, data[3][i])
    end
  else
    local j = i - 16
    local b = math.floor((j % 5) * 255 / 4.0)
    local g = math.floor((math.floor(j / 5.0) % 8) * 255 / 7.0)
    local r = math.floor((math.floor(j / 40.0) % 6) * 255 / 5.0)
    pal[i] = r << 16 | g << 8 | b
  end
 end
end

M.resetPalette(nil)

function M.r8(file)
  local byte = file:read(1)
  if byte == nil then
    return 0
  else
    return string.byte(byte) & 255
  end
end

function M.r16(file)
  local x = M.r8(file)
  return x | (M.r8(file) << 8)
end

function M.loadImage(filename)
  local data = {}
  local file = io.open(filename, 'rb')
  local hdr = {67,84,73,70}

  for i=1,4 do
    if M.r8(file) ~= hdr[i] then
      M.error("Invalid header!")
    end
  end

  local hdrVersion = M.r8(file)
  local platformVariant = M.r8(file)
  local platformId = M.r16(file)

  if hdrVersion > 1 then
    M.error("Unknown header version: " .. hdrVersion)
  end

  if platformId ~= 1 or platformVariant ~= 0 then
    M.error("Unsupported platform ID: " .. platformId .. ":" .. platformVariant)
  end

  data[1] = {}
  data[2] = {}
  data[3] = {}
  data[2][1] = M.r8(file)
  data[2][1] = (data[2][1] | (M.r8(file) << 8))
  data[2][2] = M.r8(file)
  data[2][2] = (data[2][2] | (M.r8(file) << 8))

  local pw = M.r8(file)
  local ph = M.r8(file)
  if not (pw == 2 and ph == 4) then
    M.error("Unsupported character width: " .. pw .. "x" .. ph)
  end

  data[2][3] = M.r8(file)
  if (data[2][3] ~= 4 and data[2][3] ~= 8) or data[2][3] > gpu.getDepth() then
    M.error("Unsupported bit depth: " .. data[2][3])
  end

  local ccEntrySize = M.r8(file)
  local customColors = M.r16(file)
  if customColors > 0 and ccEntrySize ~= 3 then
    M.error("Unsupported palette entry size: " .. ccEntrySize)
  end
  if customColors > 16 then
    M.error("Unsupported palette entry amount: " .. customColors)
  end

  for p=0,customColors-1 do
    local w = M.r16(file)
    data[3][p] = w | (M.r8(file) << 16)
  end

  WIDTH = data[2][1]
  HEIGHT = data[2][2]

  for y=0,HEIGHT-1 do
    for x=0,WIDTH-1 do
      local j = (y * WIDTH) + x + 1
      local w = M.r16(file)
      if data[2][3] > 4 then
        data[1][j] = w | (M.r8(file) << 16)
      else
        data[1][j] = w
      end
    end
  end

  io.close(file)
  
  gpu.setResolution(WIDTH, HEIGHT)
  M.resetPalette(data)
  loadedImage = data
end

function M.gpuBG()
  local a, al = gpu.getBackground()
  if al then
    return gpu.getPaletteColor(a)
  else
    return a
  end
end
function M.gpuFG()
  local a, al = gpu.getForeground()
  if al then
    return gpu.getPaletteColor(a)
  else
    return a
  end
end

function M.drawImageSection(_xStart, xEnd, _yStart, yEnd, debug)
  xStart = math.max(0,_xStart)
  xEnd = math.min(WIDTH, xEnd)
  yStart = math.max(0,_yStart)
  yEnd = math.min(HEIGHT, yEnd)
  
  local data = loadedImage
  local bg = 0
  local fg = 0
  local cw = 1
  local noBG = false
  local noFG = false
  local ind = 1

  local gBG = M.gpuBG()
  local gFG = M.gpuFG()

  for y=yStart,yEnd-1 do
    local str = ""
    for x=xStart,xEnd-1 do
      ind = (y * WIDTH) + x + 1
      if data[2][3] > 4 then
        bg = pal[data[1][ind] & 0xFF]
        fg = pal[(data[1][ind] >> 8) & 0xFF]
        cw = ((data[1][ind] >> 16) & 0xFF) + 1
      else
        fg = pal[data[1][ind] & 0x0F]
        bg = pal[(data[1][ind] >> 4) & 0x0F]
        cw = ((data[1][ind] >> 8) & 0xFF) + 1
      end
      noBG = (cw == 256)
      noFG = (cw == 1)
      if (noFG or (gBG == fg)) and (noBG or (gFG == bg)) then
        str = str .. q[257 - cw]
--        str = str .. "I"
      elseif (noBG or (gBG == bg)) and (noFG or (gFG == fg)) then
        str = str .. q[cw]
      else
        if #str > 0 then
          gpu.set(x + 1 - unicode.wlen(str), y + 1, str)
          if debug then
            local tmpfg = gpu.getForeground()
            local tmpbg = gpu.getBackground()
            gpu.setForeground(0xFFFFFF)
            gpu.setBackground(0x0)
            print('x = ' .. (WIDTH + 1 - unicode.wlen(str)) .. 'y = ' .. (y+1))
            print('fg ' .. string.format("%x", tmpfg * 256))
            print('bg ' .. string.format("%x", tmpbg * 256))
            print('str ' .. str)
            gpu.setForeground(tmpfg)
            gpu.setBackground(tmpbg)
          end
        end
        if (gBG == fg and gFG ~= bg) or (gFG == bg and gBG ~= fg) then
          cw = 257 - cw
          local t = bg
          bg = fg
          fg = t
        end
        if gBG ~= bg then
          gpu.setBackground(bg)
          gBG = bg
        end
        if gFG ~= fg then
          gpu.setForeground(fg)
          gFG = fg
        end
        str = q[cw]
--        if (not noBG) and (not noFG) then str = "C" elseif (not noBG) then str = "B" elseif (not noFG) then str = "F" else str = "c" end
      end
    end
    if #str > 0 then
      gpu.set(WIDTH + 1 - unicode.wlen(str), y + 1, str)
      if debug then
        local tmpfg = gpu.getForeground()
        local tmpbg = gpu.getBackground()
        gpu.setForeground(0xFFFFFF)
        gpu.setBackground(0x0)
        print('x = ' .. (WIDTH + 1 - unicode.wlen(str)) .. 'y = ' .. (y+1))
        print('fg ' .. string.format("%x", tmpfg * 256))
        print('bg ' .. string.format("%x", tmpbg * 256))
        print('str ' .. str)
        gpu.setForeground(tmpfg)
        gpu.setBackground(tmpbg)
      end
    end
  end
end

function M.drawImage()
  M.drawImageSection(0, WIDTH, 0, HEIGHT, false)
  M.drawImageSection(85, 87, 47, 49, true)
end

function M.show(path)
  print('Loading image ' .. args[1])
  M.loadImage(path)
  M.drawImage()
end

function M.clear()
  gpu.setBackground(0, false)
  gpu.setForeground(16777215, false)
  gpu.setResolution(w, h)
  gpu.fill(1, 1, w, h, " ")
end

if args[1] == 'ctifview' then
  return M;
else
  M.show(args[1])
  
  while true do
      local name,addr,char,key,player = event.pull("key_down")
      if key == 0x10 then
          break
      end
  end
  M.clear();
end