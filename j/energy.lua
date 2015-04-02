-- every X seconds, the graph is updated
local updateEveryXSec=5
-- may be "all" or a side defining which monitor to use
local monitorConfig
-- special monitor to show overall energy (side)
local monitorSumUp
-- how to detect remote devices:
-- "all" = all sides + all network devices (no wlan)
-- "sides" = only sides
-- "left" = only use this modem to find devices
-- "wlan" = only use wlModem to ask server for information
local deviceDiscovery
local deviceDiscoveryServer
-- if set to true, all devices with same name will be summed up
local sumUp
-- displays total amount of storage
-- when false only displays cur instead of cur/total
local displayTotalStorage
-- <<side>> of wireless modem to distribute information
local wlModem

-- <<side>> emit redstone signal when under certain energy storage amount
local emitRedstoneWhenUnder = {["side"]="bottom" , ["per"]=0.5}


-- add key=value to overwrite a name of a device
-- e.g. [1]="Super duper Energy Plant"
local forcedNames={
}

local fontSize=0.5


-- used to save different configurations
local function display()
	monitorConfig="all"
	monitorSumUp=nil
	deviceDiscovery="wlan"
	deviceDiscoveryServer=35
	sumUp=false
	displayTotalStorage = true
	wlModem="top"
	forcedNames={[1]="Energy Plant"}
end
local function server1()
	monitorConfig="all"
	monitorSumUp= nil
	deviceDiscovery="all"
	sumUp=true
	displayTotalStorage = false
	wlModem = nil
	forcedNames={}
end
local callConfig=server1

-- other variables no to configure
-- used to calculate inout (delta energy)
local lastTotalAmount={}
-- list of computers to notify about current storage info
local subscribedWirelessReceiver={}

-- draws the whole graph on the screen
-- info e.g. { [1] = { ["cur"]=123,["max"]=123,["title"]="abc",["inout"]=1 } , ...}
local function drawGraph(info)

	-- simple round function
	--   rounds a number to the given amount of digits
	function roundTo(num,dec)
	  local e=math.pow(10,dec)
	  return math.floor(num*e+0.5)/e
	end
	-- writes a string into the given space
	--   shortens the string if needed
	function drawTitle(str,width)
		-- functions used to shorten the string (in order)
		local fnc={
		-- remove spaces
		[1]=function(bla) return string.gsub(bla," ","") end,
		-- remove digits after the comma
		[2]=function(bla) return string.gsub(bla,"(%.%d%d)%d","%1") end,
		[3]=function(bla) return string.gsub(bla,"(%.%d)%d","%1") end,
		[4]=function(bla) return string.gsub(bla,"%.%d","") end
		}
		local i=1
		while #str > width do
			str=fnc[i](str)
			i=i+1
			if fnc[i]==nil or i==100 then break end
		end
		local l=#str
		if l+2 <= width then
			write(" "..str)
		elseif l<=width then
			write(str)
		else
			write(string.sub(str,1,width-1)..".")
		end
	end
	-- draws a text centered
	function drawTextCentered(str,x,y,width)
		local n=#str
		term.setCursorPos(x+width/2-n/2,y)
		term.write(str)
	end
	-- brings a number to a readable length
	--   with units like k and M
	function numberToK(number)
		number=tonumber(number)
		if number==nil then number=0 end
		local lvl
		if number>1 then
			lvl=math.floor(math.log10(number)/3)
		else
			lvl=0
		end
		local units={"","k","M","G","T"}
		local result=number / math.pow(10,3*lvl)
		if result<10 then
			result=roundTo(result,2)
		elseif result<=100 then
			result=roundTo(result,1)
		else
			result=roundTo(result,0)
		end
		return result..units[lvl+1]
	end
	-- draws a rectangle
	--   accepts negative heights
	function drawRectangle(x,y,w,h,farbe)
		if h==0 then return end
		local step=h/math.abs(h)
		h=h-step
		for yCur=y,y+h,step do
			for xCur=x,x+w-1 do
				paintutils.drawPixel(xCur,yCur,farbe)
			end
		end
		term.setBackgroundColor(colors.black)
	end

	-- main graph function starts here
	term.clear()
	local w,h=term.getSize()
	local anz=table.getn(info)
	wiPerEntry = (w - (anz-1))/anz
	if anz==0 then
		if deviceDiscovery~="wlan" then
			drawTextCentered(" no devices found ",0,h/2,w)
		else
			drawTextCentered(" wlan server timeout ",0,h/2,w)
		end
	end

	for i=1,anz do
		-- Draw Titles
		local x=(i-1)*(wiPerEntry+1)+1
		term.setCursorPos(x,1)
		drawTitle(info[i]["title"],wiPerEntry)
		
		-- Draw Stored Energy
		local sub=numberToK(info[i]["cur"])
		if displayTotalStorage then
			sub=sub.." / "
			sub=sub..numberToK(info[i]["max"])
		end
		term.setCursorPos(x,2)
		drawTitle(sub,wiPerEntry)
		local titleHeight = 2
		
		-- Draw delta Energy
		if info[i]["inout"]~=nil then
			local sub="IN/OUT: "..numberToK(info[i]["inout"]).." MJ / s"
			if info[i]["inout"] < 0 then
				term.setTextColor(colors.red)
			else
				term.setTextColor(colors.lime)
			end
			term.setCursorPos(x,3)
			drawTitle(sub,wiPerEntry)
			term.setTextColor(colors.white)
			titleHeight = 3
		end
		
		-- Percentage
		local per=0
		local col=colors.white
		if info[i]["max"]>0 then
			per=info[i]["cur"]/info[i]["max"]
			if per<0.25 then
				col=colors.red
			elseif per<0.5 then
				col=colors.yellow
			else
				col=colors.lime
			end
		else
			per=0.2
			col=colors.blue
		end
		local acHeight = math.floor((h-titleHeight)*per)
		local displayedPer = acHeight / (h-titleHeight)
		local deltaPer=(per - displayedPer)*(h-titleHeight)
		-- draw actual block
		drawRectangle(x,h,wiPerEntry,-acHeight,col)
		-- draw percentage block
		drawRectangle(x,h-acHeight,wiPerEntry*deltaPer,1,col)
		term.setBackgroundColor(colors.gray)
		drawTextCentered(" "..roundTo(per*100,0).."% ",x,h-1,wiPerEntry)
		term.setBackgroundColor(colors.black)

		-- Draw Separator lines
		local x=(wiPerEntry+1)*i
		for y=1,h do
			term.setCursorPos(x,y)
			term.write("|")
		end
	end
end

local function getPowerDeviceDetails(details)
	if details==nil then
		return nil,nil,nil
	end
	local rawName=details["RawName"]
	local name,stored,max
	name=nil
	if string.find(rawName,"tile.energycube.")==1 then
		stored=details["Stored"]
		max=details["MaxStorage"]
		if max==2000000 then
			name="Basic Energy Cube"
		elseif max==8000000 then
			name="Advanced Energy Cube"
		elseif max==32000000 then
			name="Elite Energy Cube"
		elseif max==128000000 then
			name="Ultimate Energy Cube"
		end
	else
		local name=details["Name"]
		local stored=details["Stored"]
		local max=details["MaxStorage"]
		if stored==nil or max==nil then
			print("Unknown device: "..name.. " (in getPowerDeviceDetails)")
			name=nil
		end
	end
	return name,stored,max
end

-- adds the openCC Sensor as detector for more devices
local function addSensorPowerDevices(info,sensorSide)
	os.loadAPI("ocs/apis/sensor")
	local sen = sensor.wrap(sensorSide)
	local name,stored,max
	for key,_ in pairs(sen.getTargets()) do
		local details=sen.getTargetDetails(key)
		name,stored,max = getPowerDeviceDetails(details)
		if name~=nil then
			table.insert(info,{["title"]=name,["cur"]=stored,["max"]=max})
		end
	end
	return info
end

-- merge table 2 into table 1
local function concatTableValues(t1,t2)
	for k,d in pairs(t2) do
		table.insert(t1,d)
	end
	return t1
end

-- tests if table contains the value
local function tableContains(tab,value)
	for _, elem in pairs(tab) do
		if value == elem then
			return true
		end
	end
	return false
end

-- wait for an modem message
local function modemReceive(waitDelay)
	local t=os.startTimer(waitDelay)
	while true do
		local event,p1,p2,p3,p4=os.pullEvent()
		if event=="timer" and p1==t then
			break
		elseif event=="modem_message" then
			local id=p1
			local msg=p4
			return id,msg
		else
			print("modemRec event: "..event)
		end
	end
	return nil,nil
end

-- overwrites the names in info with the forcedNames from config
local function forceNames(info)
	for k,d in pairs(info) do
		if forcedNames[k]~=nil then
			d["title"]=forcedNames[k]
		end
	end
	return info
end

-- makes a summary of all energy information
local function sumUpInformation(info)
	local result={}
	local temp={}
	-- group info by title
	for _,d in pairs(info) do
		local t=d["title"]
		if temp[t]==nil then
			temp[t]={["cur"]=d["cur"],["max"]=d["max"],["title"]=t}
		else
			temp[t]["cur"] = temp[t]["cur"] + d["cur"]
			temp[t]["max"] = temp[t]["max"] + d["max"]
		end
	end
	-- calc delta Energy and store cur amount
	for _,d in pairs(temp) do
		local title=d["title"]
		if lastTotalAmount[title]~=nil then
			d["inout"]=(d["cur"]-lastTotalAmount[title])/updateEveryXSec
		end
		lastTotalAmount[title]=d["cur"]
		table.insert(result,d)
	end
	return result
end

local function getAllInformation(excludePcIds)
	if excludePcIds==nil then excludePcIds={} end
	info={}
	local devices
	if deviceDiscovery=="all" then
		devices=peripheral.getNames()
	elseif deviceDiscovery=="sides" then
		devices=redstone.getSides()
	else --assume side given, find remote devices for modem on this side
		local m=peripheral.wrap(deviceDiscovery)
		devices=m.getNamesRemote()
	end
	for _,perName in pairs(devices) do
		local t=peripheral.getType(perName)
		if t=="sensor" then
			info=addSensorPowerDevices(info,perName)
		elseif t=="energycell" then --(Big Dig)
			local p=peripheral.wrap(perName)
			local cur=p.getEnergy()
			local max=p.getMaxEnergy()
			table.insert(info,{["title"]="Redstone Energy Cell",["cur"]=cur,["max"]=max})
		elseif t=="redstone_energy_cell" then --(Tekkit)
			local p=peripheral.wrap(perName)
			local cur=p.getEnergyStored()
			local max=p.getMaxEnergyStored()
			table.insert(info,{["title"]="Redstone Energy Cell",["cur"]=cur,["max"]=max})
		elseif t=="Energy Cube" then
			local p=peripheral.wrap(perName)
			local cur=p.getStored()
			local max=p.getMaxEnergy()
			table.insert(info,{["title"]=t,["cur"]=cur,["max"]=max})
		elseif t=="computer" then
			local c=peripheral.wrap(perName)
			c.turnOn()
		elseif t=="monitor" or t=="modem" then
		else
			print("unknown device: "..tostring(t))
		end
	end
	
	if forcedNames~=nil then info=forceNames(info) end
	return info
end

local function openModems()
	local opened=0
	for _,side in pairs(peripheral.getNames()) do
		if peripheral.getType(side)=="modem" then
			peripheral.call(side,"open",0)
			opened=opened+1
		end
	end
	if wlModem~=nil then
		rednet.open(wlModem)
	end
	return opened
end

-- detects all monitors available for output
local function findMonitors(monitorConfig)
	if monitorConfig=="all" then
		local dev=peripheral.getNames()
		local monitors={}
		for k,d in pairs(dev) do
			local t=peripheral.getType(d)
			if t=="monitor" and d~=monitorSumUp then
				local monitor=peripheral.wrap(d)
				table.insert(monitors,monitor)
			end
		end
		return monitors
	elseif monitorConfig~=nil and monitorConfig~="" then
		return {peripheral.wrap(monitorConfig)}
	else
		print("No monitor specified, use <<side>> or \"all\" as value")
		return nil
	end
end

-- fetches all information and outputs on the monitors
local function updateView(info,monitorConfig)
	if sumUp then info=sumUpInformation(info) end
	if monitorSumUp~=nil then
		info2=sumUpInformation(info)
		local mon=peripheral.wrap(monitorSumUp)
		mon.setTextScale(fontSize)
		term.redirect(mon)
		drawGraph(info2)
		term.restore()
		for _,id in pairs(subscribedWirelessReceiver) do
			rednet.send(id,textutils.serialize(info2))
		end
	else
		for _,id in pairs(subscribedWirelessReceiver) do
			rednet.send(id,textutils.serialize(info))
		end
	end
	local monitors=findMonitors(monitorConfig)
	if monitors==nil then print("No monitors found to output information.") end
	
	--XXX: might not be fail safe (if there's an empty info table)
	if info[1]~=nil then
		if info[1]["cur"]/info[1]["max"] < emitRedstoneWhenUnder["per"] then
			redstone.setOutput( emitRedstoneWhenUnder["side"] , true)
		else
			redstone.setOutput( emitRedstoneWhenUnder["side"] , false)
		end
	end
	
	for _,monitor in pairs(monitors) do
		monitor.setTextScale(fontSize)
		term.redirect(monitor)
		drawGraph(info)
		term.restore()
	end
end

-- called when a monitor is touched
-- should be able to rename a device
local function touchMonitor(monitorName,x,y)
	local monitor=peripheral.wrap(monitorName)
	local w,h=monitor.getSize()
	local entryWidth = w/ table.getn(info)
	local field= math.floor(x/entryWidth) + 1
	-- TODO: implement gui to set name
	local name="xxx"
	forcedNames[field]=name
end

local function clearMonitor(monitorRef)
	term.redirect(monitorRef)
	term.clear()
	term.setCursorPos(1,1)
	term.restore()
end

-- called when programm terminates
local function ende(monitorConfig)
	local monitors=findMonitors(monitorConfig)
	if monitors~=nil then
		for _,monitor in pairs(monitors) do
			clearMonitor(monitor)
		end
	end
	if monitorSumUp~=nil then
		local mon=peripheral.wrap(monitorSumUp)
		clearMonitor(mon)
	end
	if deviceDiscovery=="wlan" then
		rednet.send(deviceDiscoveryServer,"energy unsubscribe")
	end
	term.redirect(term.native)
	term.clear()
	term.setCursorPos(1,1)
	print("Thank you for using judos' graph system.")
end

-- does everything (main loop)
local function main(updateEveryXSec,monitorConfig)
	local curTimer
	local refreshView=true
	if deviceDiscovery~="wlan" then
		curTimer=os.startTimer(0)
	else
		refreshView=false
	end
	local modemOpenedNr=openModems()
	if deviceDiscovery=="wlan" then
		curTimer=os.startTimer(updateEveryXSec*1.5)
		rednet.send(deviceDiscoveryServer,"energy subscribe")
	end
	print("Press any key to quit program.")
	while true do
		local event,p1,p2,p3,p4,p5=os.pullEvent()
		if event=="timer" and refreshView and curTimer==p1 then
			local info=getAllInformation()
			updateView(info,monitorConfig)
			curTimer=os.startTimer(updateEveryXSec)
		-- test wlan discovery timeout
		elseif event=="timer" and deviceDiscovery=="wlan" and curTimer==p1 then
			local infos={}
			updateView(infos,monitorConfig)
			curTimer=os.startTimer(updateEveryXSec*1.5)
			rednet.send(deviceDiscoveryServer,"energy subscribe")
		elseif event=="monitor_touch" then
			touchMonitor(p1,p2,p3)
			--force monitor update
			curTimer=os.startTimer(0)
		elseif event=="rednet_message" then
			local sender=p1
			if deviceDiscovery~="wlan" then
				if p2=="energy subscribe" then
					table.insert(subscribedWirelessReceiver,sender)
				elseif p2=="energy unsubscribe" then
					table.remove(subscribedWirelessReceiver,sender)
				else
					print("Unknown rednet message from "..sender..": \""..p2.."\"")
				end
			else
				if sender==deviceDiscoveryServer then
					local infos=textutils.unserialize(p2)
					updateView(infos,monitorConfig)
					-- timeout timer
					curTimer=os.startTimer(updateEveryXSec*1.5)
				end
			end
		elseif event=="key" or event=="char" then
			break
		end
	end
	ende(monitorConfig)
end

if callConfig~=nil then callConfig() end
main(updateEveryXSec,monitorConfig)
