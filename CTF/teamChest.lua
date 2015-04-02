-- present one team item 
-- after x sec item lost: refill and subtract point
-- when item is retrieved a.k. 2 items in chest -> add point
-- enemy item captured -> add point
--		enemy: item here: add point (revert timeout subtract)
--		enemy: no item: add item

--local teamItem = nil --persistent data
--local enemyItems = nil --persistent data
local teamChest,chestSup
local gameRunning = false
local myTimer = nil

local function readYN(question)
	local trials = 0
	while true do
		local i = read()
		if i=="y" or i=="n" then return i end
		trials = trials+1
		if trials%3 ==0 then print(question) end
	end
end
local function detectTeamItem(chestSup)
	local item = chestSup.getStackInSlot(1)
	if item == nil then
		error("No item in creative Box, team item must be inserted here")
	end
	term.setTextColor(colors.lime)
	write(item["display_name"])
	term.setTextColor(colors.white)
	print(" will be the item of this team")
	return item["display_name"]
end
local function detectEnemyItems(teamChest,ownItem)
	local all = teamChest.getAllStacks()
	local winningItems = {}
	write("Other teams items: ")
	local first = true
	for _,item in ipairs(all) do
		if item["display_name"]~=ownItem then
			table.insert(winningItems,item["display_name"])
			if not first then write(", ") end
			first=false
			term.setTextColor(colors.red)
			write(item["display_name"])
		end
	end
	term.setTextColor(colors.white)
	print()
	return winningItems
end
local function startGame()
	-- clearing chest
	for slot,item in ipairs(teamChest.getAllStacks()) do
		teamChest.pushItem("down",slot)
		turtle.dropDown()
	end
	-- place 1 item in chest
	turtle.suck(1)
	turtle.dropUp()
	gameRunning = true
	myTimer = os.startTimer(1)
	print("ready to start game.")
end
local function receiveMessageFrom(data,from)
	local typ=data["typ"]
	if typ=="start_game" then startGame() end
	--TODO: implement
end
local function initialize()
	if fs.exists("teamChestConfig") then
		shell.run("teamChestConfig")
		print("loaded config. item: "..teamItem)
	end
	turtle.equipLeft() -- sometimes the turtle doesn't detect the modem
	turtle.equipLeft()
	assumeSetup({["top"]="ender_chest",["bottom"]="trashcan",
		["front"]="tile_thermalexpansion_strongbox_creative_name",
		["left"]="modem"})
	teamChest = peripheral.wrap("top")
	chestSup = peripheral.wrap("front")
	if teamItem==nil then
		teamItem = detectTeamItem(chestSup)
		setPersistentValue("teamItem",teamItem,"teamChestConfig")
	end
	if enemyItems==nil then
		enemyItems = detectEnemyItems(teamChest,teamItem)
		setPersistentValue("enemyItems",enemyItems,"teamChestConfig")
	end
	rednet.open("left") --listen on the network
end
local function gameStep()
	print("gamestep")
	local stacks = teamChest.getAllStacks()
	local ownItems = 0
	for slot,items in ipairs(stacks) do
		local name = items["display_name"]
		print("stack "..tostring(slot).." with items: "..tostring(name))
		if name==teamItem then
			ownItems=ownItems+items["qty"]
		end
		if inTable(enemyItems,name) then
			print("score..")
			local points = items["qty"]
			teamChest.pushItem("down",slot,64)
			turtle.dropDown()
			local data= {["typ"]="score",["team"]=teamItem,["points"]=points,["from"]=name}
			rednet.broadcast(data)
		end
	end
	myTimer = os.startTimer(1)
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
			print("  device assumed: "..tostring(devType))
			if is==nil then is="Air" end
			print("  found on this side: "..tostring(is))
		end
	end
	if not ok then
		error("Your setup is incorrect!")
	end
end
function setPersistentValue(name,value,configName)
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
  if event == "timer" and par1 == myTimer then
    if gameRunning then
			gameStep()
		end
	elseif event == "key" then
  elseif event == "char" then
		if par1=="e" then break end
		print("Press e to end programm.")
	elseif event =="modem_message" then --use rednet not modem api
	elseif event == "rednet_message" then
		local data = par2
		receiveMessageFrom(data,par1)
	else
		print("received event: "..tostring(event))
		print("parameters:")
		print(par1)
  end
end

-- remove set variables
teamItem=nil
enemyItems=nil