
local points ={}
local teamColors = {["Sapphire"]="blue",["Ruby"]="red"}

local function readYN(question)
	local trials = 0
	while true do
		local i = read()
		if i=="y" or i=="n" then return i end
		trials = trials+1
		if trials%3 ==0 then print(question) end
	end
end
local function startGame()
	commands.tellraw("@a",{["text"]=" Game has started"})
	points = {}
end
local function score(data)
	local msg = " Team "..data["team"].." has scored "..data["points"].." points!"
	color ="white"
	if teamColors[data["team"]]~=nil then color = teamColors[data["team"]] end
	commands.tellraw("@a",{["text"]=msg,["color"]=color})
end
local function tpPlayer(data)
	print("tp player: ")
	print(data)
	commands.tp(data["player"],data["x"],data["y"],data["z"])
end
local function receiveMessageFrom(data,from)
	local typ=data["typ"]
	if typ=="start_game" then startGame()
	elseif typ=="score" then score(data)
	elseif typ=="tp" then tpPlayer(data)
	end
	--TODO: implement
end
local function initialize()
	assumeSetup({["top"]="modem"})
	rednet.open("top") --listen on the network
end

-- API --
function assumeSetup(setup)
	--author: judos_ch
	--version: 1
	-- params: { [side]=deviceType, ...}
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
		error("Your setup is incorrect!")
	end
end
function setPersistentValue(name,value,configName)
--author: judos_ch
--version: 1.3
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
	local newLine="local "..name.." = "..nValue.." --persistent data"
	repeat
		x=fRead.readLine()
		if x==nil then break end
		if string.match(x,"^local "..name.." = .+ --persistent data$")~=nil then
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
function inTable(array, item)
    for key, value in pairs(array) do
        if value == item then return true end
    end
    return false
end
---------


initialize()

while true do
  local event, par1,par2,par3 = os.pullEvent()
	if event == "key" then
  elseif event == "char" then
		if par1=="e" then break end
		print("Press e to end programm.")
	elseif event =="modem_message" then --use rednet not modem api
	elseif event == "rednet_message" then
		local data = par2
		local from = par1
		receiveMessageFrom(data,from)
	else
		print("received event: "..event)
		print("parameters:")
		print(par1)
  end
end

-- remove set variables
teamItem=nil
enemyItems=nil