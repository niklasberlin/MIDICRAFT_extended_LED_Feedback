---------------------------------------------------------------
-------------------------- CONFIG -----------------------------
---------------------------------------------------------------

-- you can choose the feedback behavior for an active Sequence
-- (ledModeSeqOn) and for an inactive Sequence (ledModeSeqOff)
-- possible values:
--
-- 'off'
--
-- the following values will use the color that is set to the
-- executor via the appearance keyword, if no color is defined
-- the color set inside the Midicraft Controller will be used:
--
-- 'static dark'
-- 'static bright'
-- 'flashing bright'
-- 'flashing dark'
--
-- the following values will use the color defined inside the 
-- Midicraft Controller:
--
-- 'static dark controller'
-- 'static bright controller'
-- 'flashing bright controller'
-- 'flashing dark controller'
--
-- the following values will use the Feedback-Mode 
-- defined in the Midicraft Controller, Flash and Toggle 
-- Options in the Midicraft Controller will be ignored
-- Color is defined by the appearance
--
-- 'feedback'
--
-- the following values will use the color and Feedback-Mode 
-- defined in the Midicraft Controller, Flash and Toggle 
-- Options in the Midicraft Controller will be ignored
--
-- 'feedback controller'
--
-- you can also set the controller to a specific color wich
-- will ignore the appearance Color as well as the Color that
-- is set inside the controller
--
-- 'user color dark'
-- 'user color bright'
-- 'user color flashing bright'
-- 'user color flashing dark'

ledModeSeqOn = 'static bright'
ledModeSeqOff = 'static dark'
ledModeEmpty = 'off'
ledModeNotEmpty = 'user color dark'

-- possible colors: 'white', 'red', 'orange', 'yellow', 
-- 'ferngreen', 'green', 'seagreen', 'cyan', 'lavender',
-- 'blue', 'violet', 'magenta', 'pink', 'CTO', 'CTB' 
userColor = 'red'

-- this value sets how often the scripts checks for an color update, 
-- smaller number -> faster updates but more System load
-- bigger number -> slower update but less System load
-- keep in mind that the console needs to perform an export for each checked 
-- executor, therefor it is not recomended to change the value below 20
-- default is 20 which results in an color update about once every 1.2 seconds
-- value of 50 results in an update about every 4.5 seconds
-- value of 200 results in an update about every 12 seconds
updateInterval = 200


-- set this to true to prevent the continious update of colors
updateOnlyOnStart = false


-- if set to true, the script will monitor the current page and reload the colors
-- on a page change
updateOnPageChange = true







---------------------------------------------------------------
------------------------ CONFIG END ---------------------------
---------------------------------------------------------------

---------------------------------------------------------------
------------- MidiFeedbackLoop by GLAD - 2016 -----------------
---- Modified for Midicraft Controllers by Niklas Aumüller ----
----------------------- Version 1.2 ---------------------------
-------- sends Midi note-velocity combinations based ----------
----------- on Lua accessible executor information: -----------
---- empty / non-empty / sequence (off) / sequence (on) -------
---------------------------------------------------------------

------- start v3.2.x  bug warning  - delete when fixed ---------
local function warning()
  local version = gma.show.getvar('VERSION') 
  if version:find('^3.2.') then
    local funcName = debug.getinfo(1).source
    local txt = [[ 
      V%s may not properly terminate infinite loops.
      To terminate this plugin, use OffOffEverythingOff,
      or activate its cleanup-procedure manually via cmdline: 
      Lua "%s_cleanup()"
    ]]
    return gma.gui.confirm('WARNING!!',txt:format(version, funcName))
  else 
    return true
  end
end
------- end v3.2.x  bug warning  - delete when fixed  ---------

local function inTable(value, table)

  for i,v in ipairs(table) do

    if v == value then
      return true
    end

  end
  return false
end

local function CheckConfig()
  --this function will check the user configuration for errors
  local modes = {'off', 'static dark', 'static bright', 'flashing bright', 'flashing dark', 'static dark controller', 'static bright controller', 'flashing bright controller', 'flashing dark controller', 'feedback', 'feedback controller', 'user color dark', 'user color bright', 'user color flashing bright', 'user color flashing dark'}
  local varNames = {['ledModeSeqOn'] = ledModeSeqOn, ['ledModeSeqOff'] = ledModeSeqOff, ['ledModeEmpty'] = ledModeEmpty, ['ledModeNotEmpty'] = ledModeNotEmpty}
  -- check all mode variables
  for k, v in ipairs(varNames) do
    if not inTable(v, modes) then
      gma.echo('Variable '..k..' has a not accepted value')
      gma.feedback('Variable '..k..' has a not accepted value')
      return false
    end
  end

  if not inTable(userColor, {'white', 'red', 'orange', 'yellow', 'ferngreen', 'green', 'seagreen', 'cyan', 'lavender','blue', 'violet', 'magenta', 'pink', 'CTO', 'CTB' }) then
    gma.feedback('Variable userColor has a not accepted color')
    gma.echo('Variable userColor has a not accepted color')
    return false
  end

  if type(updateOnlyOnStart) ~= 'boolean' then
    gma.feedback('Variable updateOnlyOnStart needs to be an boolean (true or false)')
    gma.echo('Variable updateOnlyOnStart needs to be an boolean (true or false)')
    return false
  end

  if type(updateOnPageChange) ~= 'boolean' then
    gma.feedback('Variable updateOnPageChange needs to be an boolean (true or false)')
    gma.echo('Variable updateOnPageChange needs to be an boolean (true or false)')
    return false
  end


  return true
end

local helper = {}
helper.class2txt = function(class)
  local class2txt = { CMD_ROOT = 'CMD_ROOT', CMD_EXEC = 'CMD_EXEC', CMD_SEQUENCE = 'CMD_SEQUENCE', CMD_CUE = 'CMD_CUE' }
  return class2txt[class] or nil
end

helper.get = {}
-- returns offsets for all 15 colors supported by the midicraft controller, Input: String
helper.get.colorOffset = function(color)
  local color2offset = {}
  color2offset['white'] = 0
  color2offset['red'] = 1
  color2offset['orange'] = 2
  color2offset['yellow'] = 3
  color2offset['ferngreen'] = 4
  color2offset['green'] = 5
  color2offset['seagreen'] = 6
  color2offset['cyan'] = 7
  color2offset['lavender'] = 8
  color2offset['blue'] = 9
  color2offset['violet'] = 10
  color2offset['magenta'] = 11
  color2offset['pink'] = 12
  color2offset['CTO'] = 13
  color2offset['CTB'] = 14
  color2offset['black'] = -1
  return color2offset[color] or nil
end

helper.get.modeOffset = function(mode)
  local mode2offset = {}
  mode2offset['off'] = 0
  mode2offset['static dark'] = 1
  mode2offset['static bright'] = 17
  mode2offset['flashing bright'] = 33
  mode2offset['flashing dark'] = 49
  mode2offset['static dark controller'] = 126
  mode2offset['static bright controller'] = 127
  mode2offset['flashing bright controller'] = 124
  mode2offset['flashing dark controller'] = 125
  mode2offset['flashing dark controller'] = 125
  mode2offset['feedback'] = 65
  mode2offset['feedback controller'] = 123
  mode2offset['user color dark'] = 1
  mode2offset['user color bright'] = 17
  mode2offset['user color flashing bright'] = 33
  mode2offset['user color flashing dark'] = 49
  return mode2offset[mode]
  
end

--try to extract the apperance-inforamtion from an xml file, Input-Type: table with all lines of the xml, return String with the Hex-Color
helper.extractColorFromXML = function(xml)
  for i = 1, #xml do
    if xml[i]:find('Appearance Color') then
      local indices
      while true do
        local j = j
        indices = {xml[i]:find('\"%x+\"')}      --find color hex code
        if indices[2]-indices[1]-1 == 6 then  --if length matches hex color code length
          indices[1], indices[2] = indices[1] + 1, indices[2] - 1 --reset index values to start and end of actual hex string
          break
        elseif indices then
          j = indices[2]
        else
           gma.echo('error: appearance function triggered, not found')
           return nil
        end
      end
      color = xml[i]:sub(indices[1], indices[2])
      return color
    end
  end
end

helper.hex2float = function(hex)
  local red = tonumber('0x'..string.sub(hex, 1,2))
  local green = tonumber('0x'..string.sub(hex, 3,4))
  local blue = tonumber('0x'..string.sub(hex, 5,6))
  local array = {red, green, blue} or {}
  table.sort(array)
  max = array[#array]
  if max ~= 0 then
    red = red/max
    green = green/max
    blue = blue/max
  else
    red, green, blue = 0, 0, 0
  end
  return red, green, blue
end

helper.find = function(str, search)
  return string.find(str, search)
end

helper.lookupColor = function(exec)
  local execToken, cueToken = 'Executor %s', 'Executor %s Cue'
  local handle = gma.show.getobj.handle(cueToken:format(exec)) or gma.show.getobj.handle(execToken:format(exec))
  local c = gma.show.getobj.class(handle or 1)
  if helper.class2txt(c) == 'CMD_CUE' then
    handle = gma.show.getobj.parent(handle) --needed to get the handle of the sequence and not of the cue
  end
  if helper.class2txt(c) == 'CMD_SEQUENCE' or helper.class2txt(c) == 'CMD_CUE' then
    seq = gma.show.getobj.number(handle)
    gma.cmd('Export Sequence '..seq..' "LUAtmp'..seq..'" /nc')
  else
    return nil
  end
  path = gma.show.getvar('PATH')..'/importexport/LUAtmp'..seq..'.xml'
  local t = {}  
  for line in io.lines(path) do
    t[#t + 1] = line
  end
  --os.remove(path) --delete the temp file
  local color = helper.extractColorFromXML(t)

  if color == nil then
    --if no color is defined set a value for caching
    return 'undefined'
  end
  red, green, blue = helper.hex2float(color)

  if red == 0 and green == 0 and blue == 0 then
    return 'black'
  end
  -- red,green and blue are scaled to always be between 0 and 1 -> it does not matter if we have a dark or a bright red, both will be scaled to 1 (if green and blue are at 0)
  --primary colors - red, green, blue
  if red == 1 and green < 0.3 and blue < 0.3 then
    return 'red'
  elseif red < 0.3 and green == 1 and blue < 0.3 then
    return 'green'
  elseif red < 0.3 and green < 0.3 and blue == 1 then
    return 'blue'
  --main mix colors - cyan, magenta, yellow
  elseif red > 0.7 and green > 0.7 and blue < 0.3 then
    return 'yellow'
  elseif red < 0.3 and green > 0.7 and blue > 0.7 then
    return 'cyan'
  elseif red > 0.7 and green < 0.3 and blue > 0.7 then
    return 'magenta'
  -- additional mixcolors
  elseif red == 1 and green <= 0.7 and blue < 0.3 then
    return 'orange'
  elseif red <= 0.7 and green == 1 and blue < 0.3 then
    return 'ferngreen'
  elseif red <= 0.7 and green == 1 and blue < 0.3 then
    return 'seagreen'
  elseif red < 0.3 and green <= 0.7 and blue == 1 then
    return 'lavender'
  elseif red <= 0.7 and green < 0.3 and blue == 1 then
    return 'violet'
  elseif red == 1 and green < 0.3 and blue <= 0.7 then
    return 'pink'
  -- whites
  elseif red > 0.85 and green > 0.85 and blue > 0.85 then
    return 'white'
  elseif red > 0.9 and green > 0.65 and blue > 0.35 and blue < green then
    return 'CTO'
  elseif red > 0.35 and green > 0.65 and blue > 0.9 and red < green then
    return 'CTB'
  
  end
  --supported colors: off, white, red, orange, yellow, fern green, green, seagreen, cyan, lavender, blue, violet, magenta, pink, CTO, CTB
  --gma.echo(color)
  return nil
end

local colorCache = {}
helper.updateColors = function(midiNote2exec)
  --midiNote2exec will contain pairs of all execs with all notes
  for note, exec in pairs(midiNote2exec) do
    colorCache[exec] = helper.lookupColor(exec)
  end
end


--will return the current color of an executor, Return-Type: String 
helper.get.color = function(exec)
  if colorCache[exec] == nil then --if no info is stored for exec look it up
    colorCache[exec] = helper.lookupColor(exec)
  end
  if colorCache[exec] == 'undefined' then
    return nil
  end
  --return the currently cached color for exec
  return colorCache[exec]
end

helper.get.ledModeSeqOn = function()
  return ledModeSeqOn
end

helper.get.ledModeSeqOff = function()
  return ledModeSeqOff
end

helper.get.ledModeEmpty = function()
  return ledModeEmpty
end

helper.get.ledModeNotEmpty = function()
  return ledModeNotEmpty
end

helper.get.userColor = function()
  return userColor
end

helper.get.updateOnlyOnStart = function()
  return updateOnlyOnStart
end

helper.get.updateOnPageChange = function()
  return updateOnPageChange
end

helper.get.updateInterval = function()
  return updateInterval
end

helper.removeController = function(str)
  return string.gsub(str, ' controller', '')
end

--local test = _O

local gma = gma
local pairs, tonumber = pairs, tonumber

local isStart = true

local midifeedback = {}
do local _ENV = midifeedback
    
  getHandle = gma.show.getobj.handle
  getClass = gma.show.getobj.class
  getAmount = gma.show.getobj.amount
  getChild = gma.show.getobj.child
  getParent = gma.show.getobj.parent
  getProperty = gma.show.property.get
  getIndex = gma.show.getobj.index
  getName = gma.show.getobj.name
  getLabel = gma.show.getobj.label
  getNumber = gma.show.getobj.number
  
  doCommandline = gma.cmd
  gotoSleep = gma.sleep
  
  -- read midi-remotes to configure the script (we need to send midi notes to the same channels as used in the input config)
  getMidiRemoteSetup = function ()
  
    local midiRemotes = getHandle('Remote "MidiRemotes"')
    local found = {}   
    for currentLine=0, getAmount(midiRemotes)-1 do
      local remoteLine = getChild(midiRemotes,currentLine)
      local type, button = getProperty(remoteLine, 'Type'), getProperty(remoteLine, 'Button')
      --chekc to ony get the lines that trigger an exec button and not a CMD or hardkey
      if type == 'Exec' and (button == 'Button 1' or button == 'Button 2' or button == 'Button 3') then
      
        local executor, page = getProperty(remoteLine, 'Executor'), getProperty(remoteLine, 'Page')
        if tonumber(page) then
          executor = page..'.'..executor
        end 
        
        local note, channel = getProperty(remoteLine, 'Note'), getProperty(remoteLine, 'Channel')
        if tonumber(channel) then
          note = channel..'.'..note
        end
        
        found[note] = executor
      end
    end
    return found 
  end


  
  class2txt = { CMD_ROOT = 'CMD_ROOT', CMD_EXEC = 'CMD_EXEC', CMD_SEQUENCE = 'CMD_SEQUENCE', CMD_CUE = 'CMD_CUE' }
  midiSyntax, execToken, cueToken = 'MidiNote %s %i', 'Executor %s', 'Executor %s Cue'  
  ledModeSeqOn = helper.get.ledModeSeqOn()
  ledModeSeqOff = helper.get.ledModeSeqOff()
  ledModeEmpty = helper.get.ledModeEmpty()
  ledModeNotEmpty = helper.get.ledModeNotEmpty()
  userColor = helper.get.userColor()
  updateInterval = helper.get.updateInterval()
  updateOnPageChange = helper.get.updateOnPageChange()
  updateOnlyOnStart = helper.get.updateOnlyOnStart()

  calculateVelocity = function(n, e)  -- h - handle, n - note, e - executor    
    local  handle = getHandle(cueToken:format(e)) or getHandle(execToken:format(e))
    local c = getClass(handle or 1)
    --gma.echo('class: '..c)
    color = helper.get.color(e)
    if class2txt[c] == 'CMD_CUE' then --sequence is on
      if ledModeSeqOn == 'off' then
        return helper.get.modeOffset(ledModeSeqOn)
      elseif helper.find(ledModeSeqOn, 'user color') then
        return helper.get.modeOffset(ledModeSeqOn) + helper.get.colorOffset(userColor)
      elseif not helper.find(ledModeSeqOn, 'controller') and color then
        --we have a valid color and we have a mode were we set the color
        return helper.get.modeOffset(ledModeSeqOn) + helper.get.colorOffset(color)
      else
        -- we either dont have a color or a mode were we should use the color of the controller
        local mode = helper.removeController(ledModeSeqOn) -- remove the word "controller" so we always have a mode without it
        mode = mode.." controller" -- add the word controller so that we always have a mode where we use the controller defined color
        return helper.get.modeOffset(mode)
      end
    elseif class2txt[c] == 'CMD_SEQUENCE' then --sequence is off
      if ledModeSeqOff == 'off' then
        return helper.get.modeOffset(ledModeSeqOff)
      elseif helper.find(ledModeSeqOff, 'user color') then
        return helper.get.modeOffset(ledModeSeqOff) + helper.get.colorOffset(userColor)
      elseif not helper.find(ledModeSeqOff, 'controller') and color then
        --we have a valid color and we have a mode were we set the color
        return helper.get.modeOffset(ledModeSeqOff) + helper.get.colorOffset(color)
      else
        -- we either dont have a color or a mode were we should use the color of the controller
        local mode = helper.removeController(ledModeSeqOff) -- remove the word "controller" so we always have a mode without it
        mode = mode.." controller" -- add the word controller so that we always have a mode where we use the controller defined color
        return helper.get.modeOffset(mode)
      end
    elseif class2txt[c] == 'CMD_EXEC' then --not empty
      if ledModeNotEmpty == 'off' then
        return helper.get.modeOffset(ledModeNotEmpty)
      elseif helper.find(ledModeNotEmpty, 'user color') then
        return helper.get.modeOffset(ledModeNotEmpty) + helper.get.colorOffset(userColor)
      elseif not helper.find(ledModeNotEmpty, 'controller') and color then
        --we have a valid color and we have a mode were we set the color
        return helper.get.modeOffset(ledModeNotEmpty) + helper.get.colorOffset(color)
      else
        -- we either dont have a color or a mode were we should use the color of the controller
        local mode = helper.removeController(ledModeNotEmpty) -- remove the word "controller" so we always have a mode without it
        mode = mode.." controller" -- add the word controller so that we always have a mode where we use the controller defined color
        return helper.get.modeOffset(mode)
      end
    elseif class2txt[c] == 'CMD_ROOT' then --empty
      if ledModeEmpty == 'off' then
        return helper.get.modeOffset(ledModeEmpty)
      elseif helper.find(ledModeEmpty, 'user color') then
        --gma.echo('ModeConfig: '..ledModeEmpty)
        --gma.echo('Mode: '..helper.get.modeOffset(ledModeEmpty))
        --gma.echo('Color: '..helper.get.colorOffset(userColor))
        return helper.get.modeOffset(ledModeEmpty) + helper.get.colorOffset(userColor)
      elseif not helper.find(ledModeEmpty, 'controller') and color then
        --we have a valid color and we have a mode were we set the color
        return helper.get.modeOffset(ledModeEmpty) + helper.get.colorOffset(color)
      else
        -- we either dont have a color or a mode were we should use the color of the controller
        local mode = helper.removeController(ledModeEmpty) -- remove the word "controller" so we always have a mode without it
        mode = mode.." controller" -- add the word controller so that we always have a mode where we use the controller defined color
        return helper.get.modeOffset(mode)
      end
    end
  end

  start = function()    
    enabled = not warning or warning() 
    midiNote2exec = getMidiRemoteSetup()  
    cache = {}
    gma.echo('MidiFeedbackLoop started')
    loopCounter = 0
    if not CheckConfig() then
      enabled = false
    else
      helper.updateColors(midiNote2exec) 
    end
    oldButtonPage = gma.show.getvar('BUTTONPAGE')
    oldFaderPage = gma.show.getvar('FADERPAGE')
    while enabled do 
      if updateOnPageChange and (oldButtonPage ~= gma.show.getvar('BUTTONPAGE') or oldFaderPage ~=gma.show.getvar('FADERPAGE')) then
        --gma.echo("updating colors thru page change")
        helper.updateColors(midiNote2exec) 
        cache={}
        oldButtonPage = gma.show.getvar('BUTTONPAGE')
        oldFaderPage = gma.show.getvar('FADERPAGE')
      end
      for note, exec in pairs(midiNote2exec) do
        local handle = getHandle(cueToken:format(exec)) or getHandle(execToken:format(exec))
        local class = getClass(handle or 1)
        if class ~= cache[note] then   -- if chached class is not equal to the current reported class for example because the sequence is now on instead of off
          cache[note] = class 
          local velocity = calculateVelocity(note, exec)
          doCommandline(midiSyntax:format(note, velocity))
          if isStart then
            gotoSleep(0.01)
          end
        end
      end
      isStart = false
      gotoSleep(0.05)
      if not updateOnlyOnStart then
        if loopCounter>updateInterval then
          loopCounter = 0
          --gma.echo("updating colors thru loop")
          helper.updateColors(midiNote2exec)    
          cache={}
        else
          loopCounter = loopCounter +1
        end
      end
    end
    
  end

  stop = function()
    enabled = false
    gma.echo('MidiFeedbackLoop terminated')
  end

end 

return midifeedback.start, midifeedback.stop