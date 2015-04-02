local version = 0.22
local folder = "/api/"
local serverUrlAndDir = "http://www.however.ch/tekkit-cc/"

--PERSISTENT DATA
-- this will be left untouched
--END OF PERSISTENT DATA

-- API --
local function updateProgram(restart)
--author: judos_ch
--version: 0.1
--your program must have a:
--"local version = 0.1" at the first line
--optionally: "--PERSISTENT DATA" and "--END OF PERSISTENT DATA" 
-- to mark a constant segment that should not be updated
--@returns: newVersion
	local function splitStr(str,sep)
		-- split a string based on a separator, result will be stored in a table
		local fields = {}
		string.gsub(str,"([^"..sep.."]*)"..sep, function(c) table.insert(fields, c) end)
		_,_,last = string.find(str,sep.."([^"..sep.."]*)$")
		if last~="" then table.insert(fields,last) end
		return fields
	end
	local function assertPath(str)
		if str:sub(1,1)~="/" then str="/"..str end
		if str:sub(-1,-1)~="/" then str=str.."/" end
		return str
	end
	local function pullEventTimeout(expectedEvent,timeout)
		-- waits until a certain event occurs, ignores all other events.
		os.startTimer(timeout+0.1)
		local tStart=os.clock()
		while true do
			local event,url,ans=os.pullEvent()
			if event==expectedEvent then
				return url,ans
			elseif os.clock()-tStart>timeout then
				return nil,nil
			end
		end
	end
	local function doUpdate()
		local source = updateProgramSource
		local ownName = shell.getRunningProgram()
		local tempName = "temp"..math.random() --has no meaning, file is deleted afterwards
		shell.run("cp",ownName.." "..tempName)
		local fRead = fs.open(tempName,"r")
		local fWrite = fs.open(ownName,"w")
		local writeIt=true
		-- go through new source code and write all lines
		for _,line in pairs(splitStr(source,"\n")) do
			--except for persistent data
			--start writing again on the end of that part
			if string.match(line,"^--END OF PERSISTENT DATA$")~=nil then
				writeIt=true
			end
			if writeIt then fWrite.writeLine(line) end
			--when persistent data starts, stop writing
			if string.match(line,"^--PERSISTENT DATA$")~=nil then
				writeIt=false
				--insert per.d. part of old source
				repeat
					local x=fRead.readLine()
					if x==nil then
						writeIt=true
						break
					end
					if string.match(x,"^--END OF PERSISTENT DATA$")~=nil then
						writeIt=false
						break
					end
					if writeIt then fWrite.writeLine(x) end
					if string.match(x,"^--PERSISTENT DATA$")~=nil then writeIt=true end
				until false
			end
		end
		fWrite.close()
		fRead.close()
		shell.run("rm",tempName)
		-- trigger restart of os to run new program
		fWrite=fs.open("startup","w")
		fWrite.writeLine("shell.run(\""..ownName.."\",\"update_restart\")")
		fWrite.close()
		running=false
		os.reboot()
	end
	local function tryUpdate()
		-- finds source online, compares version, displays popup
		local ownName = shell.getRunningProgram()
		http.request(serverUrlAndDir.."download.php","name="..ownName.."&folder="..assertPath(folder))
		local url,ans=pullEventTimeout("http_success",4)
		if ans~=nil then
			local source=ans.readAll()
			if source=="404" then
				return false,"Error - script not found online",colors.red
			else
				local versionRemote = string.match(source,"^local version = (%d+%.?%d*)\n")
				--print("remote: "..tostring(versionRemote).."-")
				--print("current: "..tostring(version).."-")
				--print(source)
				if tonumber(versionRemote) == version then
					return false,"No new version available (current: "..version..")",colors.white
				elseif tonumber(versionRemote)>version then
					updateProgramSource = source
					return true,"New version: "..versionRemote.." downloaded (old: "..version..")",colors.lime
				else
					return false,"haha server has older version than you got :) local: "..version..", remote: "..versionRemote, colors.lime
				end
			end
		else
			return false,"Error - Timeout, http failed",colors.red
		end
	end
	local canUpdate,reply,color
	if updateProgramSource==nil then canUpdate,reply,color = tryUpdate() end
	if restart~=nil then doUpdate() end
	return canUpdate,reply,color
end

-- Other API --
local function getMonitors()
	monitors={term}
	for _,side in pairs(peripheral.getNames()) do
		if peripheral.getType(side) == "monitor" then
			table.insert(monitors,peripheral.wrap(side))
		end
	end
	return monitors
end
local function clearMonitors()
	monitors = monitors or getMonitors()
	for _,monitor in pairs(monitors) do
		monitor.setBackgroundColor(colors.black)
		monitor.clear()
	end
end
local function writeTextIntoBox(msg,x,y,w,h) --v 1.0
	-- uses the available space on the terminal to write the text inside
	-- wrap monitor and use term.redirect(monitor) to do this on a monitor screen
	local originalY = y
	msg = msg.." "
	repeat
		term.setCursorPos(x,y)
		local msgMax = string.sub(msg,1,w)
		local lineBreakPos = string.find(msgMax.."","\n")
		local splitPos = string.find(msgMax," [^ ]*$") --search for last space
		
		local from,to
		if type(lineBreakPos)=="number" then
			to=lineBreakPos-1
			from=lineBreakPos+1
		elseif type(splitPos)~="number" then
			to=w
			from=w+1
		else
			to=splitPos-1
			from=splitPos+1
		end
		term.write(string.sub(msg,1,to))
		msg=string.sub(msg,from,#msg)
		y=y+1
	until msg=="" or originalY+h<=y
end
local function displayPopup(msg,strColor,bgColor,onMonitors) --v 1.0
	-- displays a popup on all monitors with the given msg and colors
	strColor = strColor or colors.white
	bgColor = bgColor or colors.lightGray
	popUpShowTime = popUpShowTime or 3
	onMonitors = onMonitors or getMonitors()
	clearMonitors()
	for _,monitor in pairs(onMonitors) do
		if monitor~=term then term.redirect(monitor) end
		local w,h=monitor.getSize()
		paintutils.drawFilledBox(2,2,w-2,h-2,bgColor)
		term.setBackgroundColor(bgColor)
		term.setTextColor(strColor)
		writeTextIntoBox(msg,3,3,w-4,h-4)
		term.setCursorPos(1,1)
		if monitor~=term then term.restore() end
	end
end

-- demonstration programm
local function main()
	print("this is version: "..version)
	print("Will now try to update...")
	os.sleep(2)
	local canUpdate,reply,color = updateProgram();
	displayPopup(reply,color,colors.gray)
	os.sleep(2)
	if canUpdate then
		displayPopup("Will now reboot the machine",colors.lime,colors.gray)
		os.sleep(2)
		updateProgram(true)
	else
		clearMonitors()
	end
end


main()