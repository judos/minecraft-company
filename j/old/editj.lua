-- version 1

local tArgs = { ... }
if #tArgs == 0 then
	print( "Usage: edit <path>" )
	return
end

local sPath = shell.resolve( tArgs[1] )
local bReadOnly = fs.isReadOnly( sPath )
if fs.exists( sPath ) and fs.isDir( sPath ) then
	print( "Cannot edit a directory" )
	return
end

local w,h = term.getSize()
local x,y = 1,1
local scrollX, scrollY = 0,0

local bMenu = false
local nMenuItem = 1

local sStatus = ""
local tLines = {}

local function load()
	tLines = {}
	if fs.exists( sPath ) then
		local file = io.open( sPath, "r" )
		local sLine = file:read()
		while sLine do
			table.insert( tLines, sLine )
			sLine = file:read()
		end
		file:close()
	else
		table.insert( tLines, "" )
	end
end

local function save()
	local file = io.open( sPath, "w" )
	if file then
		for n, sLine in ipairs( tLines ) do
			file:write( sLine .. "\n" )
		end
		file:close()
		return true
	end
	return false
end

local function redrawText()
	for y=1,h-1 do
		term.setCursorPos( 1 - scrollX, y )
		term.clearLine()

		local sLine = tLines[ y + scrollY ]
		if sLine ~= nil then
			term.write( sLine )
		end
	end
	term.setCursorPos( x - scrollX, y - scrollY )
end

local function redrawLine()
	local sLine = tLines[y]
	term.setCursorPos( 1 - scrollX, y - scrollY )
	term.clearLine()
	term.write( sLine )
	term.setCursorPos( x - scrollX, y - scrollY )
end

local tMenuItems = { "Go to", "Find", "Save", "Exit" }

local function redrawMenu()
 term.setCursorPos( 1, h )
	term.clearLine()

	if not bMenu then
		term.write( string.rep(" ",w-#sStatus-2) .. sStatus )
	else
  local sMenu = ""
		for n,sItem in ipairs( tMenuItems ) do
			if n == nMenuItem then
    sMenu = sMenu .. "["..sItem.."]"
			else
    sMenu = sMenu .. " "..sItem.." "
			end
		end
  term.write( string.rep(" ",w-#sMenu-2) .. sMenu)
	end
	
    term.setCursorPos( x - scrollX, y - scrollY )
end

local function setStatus( _sText )
	sStatus = _sText
	redrawMenu()
end

local function setCursor( x, y )
 setStatus("/ Ctrl = Menu / line "..y)
	local screenX = x - scrollX
	local screenY = y - scrollY
	
	local bRedraw = false
	if screenX < 1 then
		scrollX = x - 1
		screenX = 1
		bRedraw = true
	elseif screenX > w then
		scrollX = x - w
		screenX = w
		bRedraw = true
	end
	
	if screenY < 1 then
		scrollY = y - 1
		screenY = 1
		bRedraw = true
	elseif screenY > h-1 then
		scrollY = y - (h-1)
		screenY = h-1
		bRedraw = true
	end
	
	if bRedraw then
		redrawText()
	end
	term.setCursorPos( screenX, screenY )
end

load()

term.clear()
term.setCursorPos(x,y)
term.setCursorBlink( true )

redrawText()
setStatus( "/ Ctrl = Menu" )

local tLineHistory = {}

local bRunning = true
local tMenuFunctions = {
	["Exit"] = function()
		bRunning = false
	end,
 ["Go to"] = function()
  term.setCursorPos(1,h)
  term.clearLine()
  write("Enter line number: ")
  local line = read(nil, tLineHistory)
  x = 1
  y = tonumber(line)
  setCursor( x, y )
  table.insert(tLineHistory, line)
  redrawText()
 end,
 ["Find"] = function()
  term.setCursorPos(1,h)
  term.clearLine()
  write("Find: ")
  local sFind = read(nil,"")
  local iLineFound = 0
  for iLine = 1,#tLines do
   if string.find(tLines[iLine],sFind)~=nil then
    iLineFound = iLine
    break
   end
  end
  if iLineFound > 0 then
   x = 1
   y = iLineFound
   scrollY = y-1
--   setStatus("found on line: "..iLineFound)
   setCursor( x, y )
  end
  redrawText()
 end,
	["Save"] = function()
		if save() then
			setStatus( "Saved to "..sPath )
		else
			setStatus( "Access denied" )
		end
	end,
}

local function doMenuItem( _n )
	local fnMenu = tMenuFunctions[ tMenuItems[_n] ]
	if fnMenu then
		fnMenu()
	end

	bMenu = false
	term.setCursorBlink( true )
	redrawMenu()
end

while bRunning do
  local sEvent, param = os.pullEvent()
  if sEvent == "key" then
    if param == 200 then
		-- Up
		if not bMenu then
			-- Move cursor up
			if y > 1 then
				y = y - 1
				x = math.min( x, string.len( tLines[y] ) + 1 )
				setCursor( x, y )
			end
		end
		
	elseif param == 208 then
		-- Down
		if not bMenu then
			-- Move cursor down
			if y < #tLines then
				y = y + 1
				x = math.min( x, string.len( tLines[y] ) + 1 )
				setCursor( x, y )
			end
		end
	
	elseif param == 203 then
		-- Left
		if not bMenu then
			-- Move cursor left
			if x > 1 then
				x = x - 1
				setCursor( x, y )
			end
		else
			-- Move menu left
			nMenuItem = nMenuItem - 1
			if nMenuItem < 1 then
				nMenuItem = #tMenuItems
			end
			redrawMenu()
		end
			
		
	elseif param == 205 then
		-- Right
		if not bMenu then
			-- Move cursor right
   		 	if x < string.len( tLines[y] ) + 1 then
				x = x + 1
				setCursor( x, y )
		  	end
		else
			-- Move menu right
			nMenuItem = nMenuItem + 1
		  	if nMenuItem > #tMenuItems then
				nMenuItem = 1
		  	end
		  	redrawMenu()
		end

 elseif param == 207 then
  -- Home
  if not bMenu then
   -- move cursor to line start
   x = string.len(tLines[y]) + 1
   setCursor(x,y)
  end

 elseif param == 199 then
  -- End
  if not bMenu then
   -- Move cursor to the line end
   x = 1
   setCursor(x,y)
  end
	
 elseif param == 201 then
  -- Page up
  if not bMenu then
   -- Move cursor a page up
   if y > 1 then
    y = math.max( y-h, 1 )
    x = math.min( x, string.len( tLines[y] ) + 1)
    setCursor( x, y )
   end
  end

 elseif param == 209 then
  -- Page down
  if not bMenu then
   -- Move cursor a page down
   if y < #tLines then
    y = math.min( y + h, #tLines )
    x = math.min( x, string.len( tLines[y] ) + 1 )
    setCursor( x, y )
   end
  end

	elseif param == 14 then
		-- Backspace
		if not bMenu then
   		 	if x > 1 then
				-- Remove character
				local sLine = tLines[y]
				tLines[y] = string.sub(sLine,1,x-2) .. string.sub(sLine,x)
				redrawLine()
		
				x = x - 1
				setCursor( x, y )
			
			elseif y > 1 then
				-- Remove newline
				local sPrevLen = string.len( tLines[y-1] )
				tLines[y-1] = tLines[y-1] .. tLines[y]
				table.remove( tLines, y )
				redrawText()
			
				x = sPrevLen + 1
				y = y - 1
				setCursor( x, y )
		  	end
		end

 elseif param == 211 then
  -- Delete
  if not bMenu then
   if x < #tLines[y] + 1 then
    -- Remove character
    local sLine = tLines[y]
    tLines[y] = string.sub(sLine,1,x-1) .. string.sub(sLine,x + 1)
    redrawLine()
   elseif y < #tLines then
    -- remove newline
    local sCurLen = string.len( tLines[y] )
    tLines[y + 1] = tLines[y] .. tLines[y + 1]
    table.remove( tLines, y )
    redrawText()
    x = sCurLen + 1
    setCursor( x, y )
   end
  end
		
	elseif param == 28 then
		-- Enter
		if not bMenu then
			-- Newline
			local sLine = tLines[y]
			tLines[y] = string.sub(sLine,1,x-1)
			table.insert( tLines, y + 1, string.sub(sLine,x) )
			redrawText()
		
			x = 1
			y = y + 1
			setCursor( x, y )		
			
		else
			-- Menu selection
			doMenuItem( nMenuItem )
		end
		
	elseif param == 29 then
		-- Menu toggle
		bMenu = not bMenu
		if bMenu then
			term.setCursorBlink( false )
			nMenuItem = 1
		else
			term.setCursorBlink( true )
		end
		redrawMenu()
	
	end
		
  elseif sEvent == "char" then
	if not bMenu then
    	-- Input text
		local sLine = tLines[y]
		tLines[y] = string.sub(sLine,1,x-1) .. param .. string.sub(sLine,x)
		redrawLine()
	
		x = x + string.len( param )
		setCursor( x, y )
	
	else
		-- Select menu items
		for n,sMenuItem in ipairs( tMenuItems ) do
			if string.lower(string.sub(sMenuItem,1,1)) == string.lower(param) then
				doMenuItem( n )
				break
			end
		end
	end
  end
end

term.clear()
term.setCursorBlink( false )
term.setCursorPos( 1, 1 )