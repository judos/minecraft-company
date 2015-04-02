local version = 0.272
local folder = "/CTF/"
local serverUrlAndDir = "http://www.however.ch/tekkit-cc/"

local changelog = {
	"0.27 update shows changelog",
	"0.26 adapted tps, changelog added"
}
local arg= { ... }
os.loadAPI("button")

if fs.exists("adminCfg") then
	shell.run("adminCfg")
end

-- API --
local function assumeSetup(setup,message)
--author: judos_ch
--version: 1.1
-- params:
--		setup: { [side]=deviceType, ...}
--		message: error (show incase setup is incorrect)
-- displays error message if setup is incorrect
	local ok=true
	for side,devType in pairs(setup) do
		local is = peripheral.getType(side)
		if is~=devType then
			if ok then
				print("Setup incorrect:")
				ok=false
			end
			print("  side: "..side)
			print("  device assumed: "..devType)
			if is==nil then is="Air" end
			print("  found on this side: "..is)
		end
	end
	if not ok then
		if message==nil then
			error("Your setup is incorrect!")
		else
			error(message)
		end
	end
end
local function setPersistentValue(name,value,configName)
--author: judos_ch
--version: 1.4
--your program must have a:
--"local name = xxx --persistent data"
--inside otherwise the data cannot be saved
--if configName is set, it will try to change the value there,
--   if not found it will add it at the end of the file
	local ownName = shell.getRunningProgram()
	if configName~=nil then
		ownName = configName
		if not fs.exists(ownName) then
			local fW = fs.open(ownName,"w")
			fW.close()
		end
	end
	local tempName = "temp"..math.random() --has no meaning, file is deleted afterwards
	shell.run("cp",ownName.." "..tempName)
	local fRead = fs.open(ownName,"r")
	local fWrite = fs.open(tempName,"w")
	local found=false --used only for configFile
	local nValue = textutils.serialize(value)
	nValue,_ = string.gsub(nValue,"\n","")
	local loc = "local "
	if configName~=nil then loc ="" end --don't use local space in config file
	local newLine=loc..name.." = "..nValue.." --persistent data"
	repeat
		x=fRead.readLine()
		if x==nil then break end
		if string.match(x,"^"..loc..name.." = .+ --persistent data$")~=nil then
			x=newLine
			found=true
		end
		fWrite.writeLine(x)
	until false
	if not found then fWrite.writeLine(newLine) end
	fWrite.close()
	fRead.close()
	shell.run("rm",ownName)
	shell.run("cp",tempName.." "..ownName)
	shell.run("rm",tempName)
end
local function updateProgram(restart)
--author: judos_ch
--version: 0.11
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
					return true,"New version: "..versionRemote.." downloaded\nold: "..version,colors.lime
				else
					return false,"haha server has older version than you got :)\nlocal: "..version.."\nremote: "..versionRemote, colors.lime
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
	for _,mon in pairs(monitors) do
		mon.setBackgroundColor(colors.black)
		mon.clear()
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
local function startMeUp()
--author: judos_ch
--version: 1.1
	local ownName = shell.getRunningProgram()
	shell.run("rm","startup")
	fWrite = fs.open("startup","w")
	fWrite.writeLine("shell.run(\""..ownName.."\",\"\")")
	fWrite.close()
end
---------

local function readYN(question)
	local trials = 0
	while true do
		local i = read()
		if i=="y" or i=="n" then return i end
		trials = trials+1
		if trials%3 ==0 then print(question) end
	end
end
local function receiveMessageFrom(data,from)
	local typ=data["typ"]
	--TODO: implement
end
local function startGameClicked()
	button.flash("StartGame")
	local data= {["typ"]="start_game"}
	rednet.broadcast(data)
end
local function quitClicked()
	term.clear()
	term.setCursorPos(1,1)
	error()
end
local function updateScreen()
	clearMonitors()
	term.setTextColor(colors.white)
	button.screen()
	button.heading("CTF - Admin")
	button.label(2,20,"v"..version)
end
local function tpSpawn()
	button.flash("Tp spawn")
	local data={["typ"]="tp",["player"]=playerName,["x"]=181,["y"]=20,["z"]=-111}
	rednet.broadcast(data)
end
local function tpBlueBase()
	button.flash("tp blue base")
	local data={["typ"]="tp",["player"]=playerName,["x"]=161,["y"]=18,["z"]=-160}
	rednet.broadcast(data)
end
local function tpRedBase()
	button.flash("tp red base")
	local data={["typ"]="tp",["player"]=playerName,["x"]=161,["y"]=18,["z"]=-63}
	rednet.broadcast(data)
end
local function tpMiddle()
	button.flash("tp middle")
	local data={["typ"]="tp",["player"]=playerName,["x"]=160,["y"]=12,["z"]=-111}
	rednet.broadcast(data)
end
local function getChangelogString()
	local s="Changelog:\n"..changelog[1]
	for i=2,#changelog do s = s.."\n"..changelog[i] end
	return s
end
local function onUpdatedShowChangelog()
	if #arg==1 then
		if arg[1]=="update_restart" then
			displayPopup(getChangelogString(),colors.white,colors.gray)
			os.sleep(2)
			startMeUp()
--		else
--			print("invalid argument: "..arg[1])
		end
--	elseif #arg>1 then
--		print("invalid arguments: "..textutils.serialize(arg))
	end
end
local function update()
	button.flash("update")
	local canUpdate,reply,color = updateProgram();
	if canUpdate then
		displayPopup(reply.."\n\nWill now reboot the machine",color,colors.gray)
		os.sleep(1.5)
		updateProgram(true)
	else
		displayPopup(reply.."\n\n"..getChangelogString(),color,colors.gray)
		os.sleep(5)
	end
	updateScreen()
end
local function fillTable()
	button.setTable("StartGame",startGameClicked,"",8,18,3,5)
	button.setTable("Quit",quitClicked,"",8,18,7,9)
	button.setTable("Tp spawn",tpSpawn,"",1,15,12,12)
	button.setTable("tp blue base",tpBlueBase,"",1,15,14,14)
	button.setTable("tp red base",tpRedBase,"",1,15,16,16)
	button.setTable("tp middle",tpMiddle,"",1,15,18,18)
	button.setTable("update",update,"",8,15,20,20)
end
local function initialize()
	if playerName ==nil then
		print("Please enter your PlayerName for tp functions:")
		playerName = read()
		setPersistentValue("playerName",playerName,"adminCfg")
	end
	button.initTerm()
	rednet.open("back") --listen on the network
	fillTable()
	os.sleep(0.2)
	onUpdatedShowChangelog()
	updateScreen()
end

assumeSetup({["back"]="modem"},"You should use a Wireless Pocket computer for this app")
initialize()

while true do
  local event, par1,par2,par3 = os.pullEvent()
	if event=="mouse_click" or event=="monitor_touch" then
		button.checkxy(par2,par3)
  elseif event == "key" then
		if keys.getName(par1)=="e" then break end
	elseif event == "rednet" then
		local data = textutils.unserialize(par2)
		receiveMessageFrom(data,par1)
	else
		--print("received event: "..event)
		--print("parameters:")
		--print(par1..", "..par2..", "..par3)
		--os.sleep(2)
		--button.screen()
  end
end