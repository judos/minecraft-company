-- author: judos_ch
-- version: 0.2

-- setup:
-- me interface below turtle
-- autospawner above turtle

-- config
-- items [item name=safari slot nr,amount wanted,floorNeeded]
local inv = { ["Ender Pearl"]={1,64,true},
	["Blaze Rod"]={2,64,true},
	["Ghast Tear"]={3,64,true},
	["Wool"]={4,64,true},
	["Ink Sac"]={5,64,false},
	["Feather"]={6,64,true}}
local update = 10 --update every X seconds
-- end of config

-- do not change the following
local me = peripheral.wrap("bottom")
local spawner = peripheral.wrap("top")
local workingOn = nil --name of the item which is generated
local modem
local floorWaterId = nil --persistent data
local floorWaterServiceName = "Floor"


function initRedstoneServiceComputerId()
	if floorWaterId~=nil then return end
	print("What's the id of the service computer to handle")
	print("redstone signals to change the floor ? ")
	floorWaterId = tonumber(read())
	setPersistentValue("floorWaterId",floorWaterId)
end

-- send a request to a service to set a new value
function callAndSetService(id,serviceName,serviceValue)
	local call={type="service",cmd="set",name=serviceName,value=serviceValue}
	rednet.send(id,textutils.serialize(call))
end

local function output(msg)
	print(msg)
	rednet.broadcast(msg)
end

local function resolveIdAndDmg()
	for name in pairs(inv) do
		for nr,t in pairs(me.getAvailableItems()) do
			if t["name"]==name then
				inv[name]["id"]=t["id"]
				inv[name]["dmg"]=t["dmg"]
			end
		end
		if inv[name]["id"]==nil then
			output("Did not found "..name.." in ME.")
			output("Please enter id for this item:")
			inv[name]["id"]=read()
			output("Metadata or dmg:")
			inv[name]["dmg"]=read()
		end
	end
end

local function needItemByName(name)
	local data=inv[name]
	local want = data[2]
	local have = me.countOfItemType(data["id"],data["dmg"])
	return have<want,have,want
end

local function checkAndPlaceSafariNet()
	for name,data in pairs(inv) do
		local boolNeed,have,want = needItemByName(name)
		if needItemByName(name) then
			output("Too few "..name.." ("..have.."/"..want..")")
			turtle.select(data[1])
			turtle.dropUp()
			callAndSetService(floorWaterId,floorWaterServiceName,data[3])
			workingOn = name
			break
		end
	end
	if workingOn==nil then
		output("Idle...")
	end
end

local function checkAndRemoveSafariNet()
	local boolNeed,have,want = needItemByName(workingOn)
	if not boolNeed then
		turtle.select(1)
		turtle.suckUp()
		output("enough "..workingOn.." ("..have.."/"..want..")")
		workingOn=nil
	else
		output("Still too few "..workingOn.." ("..have.."/"..want..")")
	end
end

function main()
	assumeSetup({["top"]="tile_mfr_machine_autospawner_name",["bottom"]="me_interface"})
	initRedstoneServiceComputerId()
	startMeUp()
	modem = detectDevices("modem")
	for nr,side in pairs(modem) do rednet.open(side) end
	
	resolveIdAndDmg()
	local timer = os.startTimer(0)
	while true do
		local event,id=os.pullEvent()
		if event=="char" or event=="key" then
			break
		elseif event=="timer" and id==timer then
			--output(event..", "..tostring(id)..", "..tostring(b)..", "..tostring(c)..", "..tostring(d))
			if workingOn~=nil then
				checkAndRemoveSafariNet()
			end
			if workingOn==nil then
				checkAndPlaceSafariNet()
			end
			timer = os.startTimer(update)
		end
	end
end


-- INTERNAL API --


--author: judos_ch
--version: 1.1
function startMeUp()
	local ownName = shell.getRunningProgram()
	shell.run("rm","startup")
	fWrite = fs.open("startup","w")
	fWrite.writeLine("shell.run(\""..ownName.."\",\"\")")
	fWrite.close()
end


--author: judos_ch
--version: 1.1
-- returns {side, ..}
function detectDevices(name)
	local devices={}
	for nr,side in pairs(peripheral.getNames()) do
		if peripheral.getType(side) == name then
			table.insert(devices,side)
		end
	end
	return devices
end

function detectDevicesAndWrap(name)
	local devices={}
	for nr,side in pairs(peripheral.getNames()) do
		if peripheral.getType(side) == name then
			table.insert(devices,peripheral.wrap(side))
		end
	end
	return devices
end


--author: judos_ch
--version: 1
-- params: { [side]=deviceType, ...}
-- displays error message if setup is incorrect
function assumeSetup(setup)
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


--author: judos_ch
--version: 1.1
--your program must have a:
--"local name = xxx --peristent data"
--inside otherwise the data cannot be saved
function setPersistentValue(name,value)
	local ownName = shell.getRunningProgram()
	local tempName = "temp"..math.random() --has no meaning, file is deleted afterwards
	shell.run("cp",ownName.." "..tempName)
	fRead = fs.open(ownName,"r")
	fWrite = fs.open(tempName,"w")
	repeat
		x=fRead.readLine()
		if x==nil then break end
		if string.match(x,"^local "..name.." = .+ --persistent data$")~=nil then
			x="local "..name.." = "..textutils.serialize(value).." --persistent data"
		end
		fWrite.writeLine(x)
	until false
	fWrite.close()
	fRead.close()
	shell.run("rm",ownName)
	shell.run("cp",tempName.." "..ownName)
	shell.run("rm",tempName)
end



main()