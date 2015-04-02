local version = 0.36

local changeLog = {
	"0.36 - rsControl can be inverted",
	"0.35 - font size",
	"0.34 - refactoring code",
	"0.3  - update function",
	"0.2  - remote control, display",
	"0.1  - tankDisplay, rsControl"
}

-- TODO:
-- check for new version every day & auto update restart
-- list of critical updates where persistent data is changed (confirmation whether to update)

--PERSISTENT DATA
local monitorConfig = "all"
local fontSize = 0.5 --persistent data
local refreshRateS = 10

function init()
  --visibility: 2=public, 1=on demand, 0=private
  
--TODO: implement the following
  --createItemProductionService(name,fromSide,toSide,visibility)
--createItemProductionService("Production","right","left",2)

--TODO: implement the following
  --createAnimalCountService(name,{sensorSide,sensor={x,z},X={min,max},Z={min,max}},{animalName1,...},visibility)
  -- big cow farm on pinkyeti.ch
  --createAnimalCountService("Cow Farm",{"right",S={-202,271},X={-209.5,-188.5},Z={265.5,271.5}},{"Cow"})

  --createTankService(name,side,tanks,visibility)
  --createTankService("Water","back",2,2) 
  --createRsControlService(name,side,initial,visibility,[inverted=false])
  --createRsControlService("Floor","back",true,2)
  createRemoteControl()
end
--END OF PERSISTENT DATA

local arg= { ... }
local popUpShowtime = 2
local running=true
local serverUrlAndDir = "http://www.however.ch/tekkit-cc/" --persistent data
local curTimer=os.startTimer(refreshRateS)
local remoteControl=false --false when service is hosted, otherwise this is a remote control & display
local monitors={} --all wrapped monitors
local buttons={} --list of functions to call on mouse click {f1(mx,my),...}
local services = {}
--contains [id,name,method,value,timeout]
--timeout increments whenever the services are refreshed and descrements when the information arrives
--        any service with timeout==3 is removed on refresh
local localServices = {}
--contains tables of the following form:
-- {id, typ, name, method, func, vis, subscriber, subscribers}
-- id = computer_id

-- type = get/set
-- method = how information is displayed, what return value is expected
-- func = callBack for get and set
-- vis = visibility

-- visibility: 0=private, 1=on demand, 2=public
-- funcRef has to return table {"per" = value,"max" =value}
-- subscriber = true/false {store all users who asked for this service, and update them on changes}
function createLocalService(nameS,typ1,methodType,funcRef,visibility,subscriberList)
	local ownId=os.computerID()
	local s={id=ownId,typ=typ1,name=nameS,method=methodType,func=funcRef,vis=visibility,subscriber=subscriberList,
		subscribers={}}
	if visibility>0 then openModems() end
	table.insert(localServices,s)
	return s
end

function popupChangelog()
	local _,h=term.getSize()
	local msg=""
	for nr,line in pairs(changeLog) do
		if nr>h then break end
		msg=msg..line.."\n"
	end
	msg = string.sub(msg,1, #msg - 1)
	setTextScale(0.5)
	displayPopup(msg)
	setTextScale(fontSize)
end

--must have a "local name = xxx --persistent data" inside
function setPersistentValue(name,value)
	local ownName = shell.getRunningProgram()
	local tempName = "temp"..math.random() --has no meaning, file is deleted afterwards
	shell.run("cp",ownName.." "..tempName)
	fRead = fs.open(tempName,"r")
	fWrite = fs.open(ownName,"w")
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
	shell.run("rm",tempName)
end

-- opens all available modems
function openModems()
	local devs=peripheral.getNames()
	for _,side in pairs(devs) do
		if peripheral.getType(side)=="modem" then
			rednet.open(side) --doesn't matter if called multiple times
		end
	end
end

-- uses the available space on the terminal to write the text inside
-- wrap monitor and use term.redirect(monitor) to do this on a monitor screen
function writeTextIntoBox(msg,x,y,w,h)
	local originalY = y
	repeat
		term.setCursorPos(x,y)
		local msgMax = string.sub(msg,1,w+1)
		local lineBreakPos = string.find(msgMax.."","\n")
		local splitPos = string.find(msgMax," [^ ]*$") --search for last space
		
		local from,to
		if type(lineBreakPos)=="number" and (splitPos==nil or (type(splitPos)=="number" and lineBreakPos<splitPos)) then
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
	until msg=="" or originalY+h==y
end

-- displays the error message on all available screens and kills the program then
function errorMsg(msg)
	for _,side in pairs(peripheral.getNames()) do
		if peripheral.getType(side)=="monitor" then
			local m=peripheral.wrap(side)
			term.redirect(m)
			term.clear()
			term.setCursorPos(1,1)
			term.write("ERROR")
			term.setTextColor(colors.red)
			local y=2
			local w,h=m.getSize()
			writeTextIntoBox(msg,1,y,w,h)
			term.setTextColor(colors.white)
			term.restore()
		end
	end
	-- show on computer terminal and let program die:
	error(msg)
end

function createRsControlService(name,side,initialValue,visibility,inverted)
	inverted = inverted or false
	local set=function(value)
		if inverted then
			rs.setOutput(side,not(value))
		else
			rs.setOutput(side,value)
		end
	end
	set(initialValue)
	s=createLocalService(name,"set","rsDigital",set,visibility,true)
	s["value"]=initialValue
end

function createItemProductionService(name,fromSide,toSide,visibility)
	--TODO: implement
end

--createAnimalCountService(name,{sensorSide,sensor={x,z},X={min,max},Z={min,max}},{animalName1,...},visibility)
function createAnimalCountService(name,sensorTable,animalTable,visibility)
	local animals={}
	for id,name in pairs(animalTable) do
		animals[name]=0
	end
	local get=function()
		os.loadAPI("ocs/apis/sensor")
		local s=sensor.wrap(sensorTable[1])
		if s==nil then errorMsg("Sensor on side \""..sensorTable[1].."\" is missing, remove local service or place sensor.") end
		local t=s.getTargets()
		for _,v in pairs(t) do
			if animals[v["Name"]]~=nil then
				local x=v["Position"]["X"] + sensorTable["sensor"][1]
				local z=v["Position"]["Z"] + sensorTable["sensor"][2]
				local i=false
				if x>=sensorTable["X"][1] and x<=sensorTable["X"][2] then
				if z>=sensorTable["Z"][1] and z<=sensorTable["Z"][2] then
					animals[v["Name"]]=animals[v["Name"]]+1
				end
				end
			end
		end
		return animals
	end
	createLocalService(name,"get","text1",get,visibility,true)
end

--tankCount: if you have multiple tanks with the same level enter the amount of buildcraft tanks aside each other
--note: use liquiducts otherwise the tanks don't share the same liquid amount
function createTankService(name,tankSide,tankCount,visibility)
	local get=function()
		local t=peripheral.wrap(tankSide)
		if t==nil then errorMsg("Tank on side \""..tankSide.."\" is missing, remove local service or reposition tank!") end
		local t2=t.getTanks("unknown")[1]
		local max=(tonumber(t2["capacity"])*tankCount)
		local result={}
		if t2["amount"]~=nil then
			result["footer"]=t2["name"]
			result["per"]=t2["amount"]*tankCount / max
			result["header"]=math.floor(t2["amount"]/1000*tankCount+0.5).." B / "..(max/1000).." B"
			if t2["name"]=="Water" then result["color"]=colors.lightBlue
			elseif t2["name"]=="Milk" then result["color"]=colors.white 
			elseif t2["name"]=="Lava" then result["color"]=colors.orange
			elseif t2["name"]=="Meat" then result["color"]=colors.pink
			elseif t2["name"]=="Sludge" then result["color"]=colors.magenta
			elseif t2["name"]=="Essence" then result["color"]=colors.lime
			elseif t2["name"]=="tile.oilStill" then
				result["color"]=colors.gray
				result["footer"]="Oil"
			elseif t2["name"]=="item.fuel" then
				result["color"]=colors.yellow
				result["footer"]="Fuel"
			elseif t2["name"]=="liquid.redstone" then
				result["footer"]="Destabilized Redstone"
				result["color"]=colors.red
			elseif t2["name"]=="liquid.glowstone" then
				result["footer"]="Energized Glowstone"
				result["color"]=colors.yellow
			elseif t2["name"]=="liquid.ender" then
				result["footer"]="Resonant Ender"
				result["color"]=colors.blue
			else
				result["color"]=colors.brown
			end
		else
			result["header"]="0 B / "..(max/1000).." B"
			result["per"]=0
			result["footer"]="empty"
			result["color"]=colors.gray
		end
		return result
	end
	createLocalService(name,"get","graph1",get,visibility,true)
end


function drawRectangle(x,y,w,h,farbe)
	-- draws a rectangle
	--   accepts negative heights
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

-- writes a string into the given space
--   shortens the string if needed
function writeStringInto(str,width,centered)
	centered=centered or false --this is default if centered is not passed
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
		if i > #fnc then break end
	end
	local l=#str
	if l+2 <= width and centered==false then
		write(" "..str)
	elseif l<=width then
		if centered then
			local x,y=term.getCursorPos()
			term.setCursorPos(x+(width-#str)/2,y)
		end
		term.write(str)
	else
		term.write(string.sub(str,1,width-1)..".")
	end
end

-- marks the edges of the given rectangle with one pixel and the given color
function markEdges(x,y,w,h,c)
	paintutils.drawPixel(x,y,c)
	paintutils.drawPixel(x+w-1,y,c)
	paintutils.drawPixel(x,y+h-1,c)
	paintutils.drawPixel(x+w-1,y+h-1,c)
	term.setBackgroundColor(colors.black)
end

-- visualizes a graph service
function visualizeGraph1In(service,x,y,w,h)
	local value= service["value"]
	local actualHeight = math.floor(value["per"] *h)
	local displayedPer = actualHeight / h
	local deltaPer=(value["per"] - displayedPer)*h
	-- draw percentage block (on top of box, varies width to show small differences)
	drawRectangle(x+(w-w*deltaPer)/2,y+h-1-actualHeight,w*deltaPer,1,value["color"])
	-- draw actual block (varies height)
	drawRectangle(x,y+h-1,w,-actualHeight,value["color"])
	term.setBackgroundColor(colors.black)
	term.setCursorPos(x,y+h-3)
	writeStringInto(value["header"],w,true)
	term.setCursorPos(x,y+h-2)
	writeStringInto(value["footer"],w,true)
end

-- check for whether a mouseclick is inside a button
function isInBox(mx,my,x,y,w,h)
	if mx<x or mx>=x+w then return false end
	if my<y or my>=y+h then return false end
	return true
end

-- send a request to a service to set a new value
function callAndSetService(service)
	local call={type="service",cmd="set",name=service["name"],value=service["value"]}
	rednet.send(service["id"],textutils.serialize(call))
end

-- notify subscriber list of a service about some change
function notifySubscriberList(service)
	for id,_ in pairs(service["subscribers"]) do
		offerServiceTo(service,id)
	end
end

function visualizeRsDigital(service,x,y,w,h)
	local c,text
	local toggle=function(mx,my)
		if isInBox(mx,my,x+1,y+1,w-2,h-2) then
			service["value"]=not service["value"]
			if service["id"]==os.computerID() then
				service["func"](service["value"])
				if service["subscriber"] then
					notifySubscriberList(service)
				end
			else
				callAndSetService(service)
			end
		end
	end
	table.insert(buttons,toggle)
	
	if service["value"] then
		c=colors.lime
		text="ON"
	else
		c=colors.red
		text="OFF"
	end
	drawRectangle(x+1,y+1,w-2,h-2,c)
	term.setBackgroundColor(c)
	term.setCursorPos(x,y+h/2)
	writeStringInto(text,w,true)
	term.setBackgroundColor(colors.black)
end

function visualizeText1(service,x,y,w,h)
	local t=service["value"]
	local i=0 --TODO: implement
	for name,count in pairs(t) do
		term.setCursorPos(x+1,y+i)
		term.write(name..": "..count)
	end
end

--visualizes one service inside a given rectangle on the terminal
-- also draws title
function visualizeServiceIn(service,x,y,w,h)
	local c
	if service["vis"]==nil then c=colors.gray
	elseif service["vis"]==2 then c=colors.green
	elseif service["vis"]==1 then c=colors.brown
	else c=colors.red end
	--markEdges(x,y,w,h,c)
	term.setBackgroundColor(c)
	term.setCursorPos(x,y)
	term.write(string.rep(" ",w))
	term.setCursorPos(x,y)
	term.setTextColor(colors.white)
	writeStringInto(service["name"],w,true)
		
	local m=service["method"]
	if m=="graph1" then visualizeGraph1In(service,x,y+1,w,h-1)
	elseif m=="rsDigital" then visualizeRsDigital(service,x,y+1,w,h-1)
	elseif m=="text1" then visualizeText1(service,x,y+1,w,h-1)
	else
		term.setTextColor(colors.red)
		writeTextIntoBox("can't visualize method: "..m,x,y+1,w,h-1)
		term.setTextColor(colors.white)
	end
end

--argument: screen size in pixel and into how many parts you want to split it
--returns: how many columns,rows you end up with
function findBestGridLayout(w,h,count)
  local curX,curY = 1,1
  while curX * curY < count do
    --size per field before, after
    befX = math.floor(w/curX)
    befY = math.floor(h/curY)
    aftX = math.floor(w/(curX+1))
    aftY = math.floor(h/(curY+1))
    -- how "square" are grids when we enlarge X/Y
    diffX = math.abs(aftX - befY)
    diffY = math.abs(aftY - befX)
    if diffX<diffY then
      curX=curX+1
    else
      curY=curY+1
    end
  end
  return curX,curY
end

-- split a string based on a separator, result will be stored in a table
function splitStr(str,sep)
	local fields = {}
	string.gsub(str,"([^"..sep.."]*)"..sep, function(c) table.insert(fields, c) end)
	_,_,last = string.find(str,sep.."([^"..sep.."]*)$")
	if last~="" then table.insert(fields,last) end
	return fields
end

-- replaces the current source of this program with new code
function updateServiceSoftware(source)
	local ownName = shell.getRunningProgram()
	local tempName = "temp"..math.random() --has no meaning, file is deleted afterwards
	shell.run("cp",ownName.." "..tempName)
	fRead = fs.open(tempName,"r")
	fWrite = fs.open(ownName,"w")
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
	fWrite.writeLine("shell.run(\"service\",\"update_restart\")")
	fWrite.close()
	running=false
	os.reboot()
end

-- displays a popup on all monitors with the given msg and colors
function displayPopup(msg,strColor,bgColor,popUpShowtime,monitors)
	strColor = strColor or colors.white
	bgColor = bgColor or colors.lightGray
	popUpShowTime = popUpShowTime or 3
	monitors = monitors or {term}
	clearMonitors()
	for _,monitor in pairs(monitors) do
		term.redirect(monitor)
		local w,h=monitor.getSize()
		drawRectangle(2,2,w-2,h-2,bgColor)
		term.setBackgroundColor(bgColor)
		term.setTextColor(strColor)
		writeTextIntoBox(msg,3,3,w-4,h-4)
		term.restore()
	end
	os.sleep(popUpShowtime)
end

-- waits until a certain event occurs, ignores all other events.
function pullEventTimeout(expectedEvent,timeout)
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

-- finds source online, compares version, displays popup
function tryUpdate()
  http.request(serverUrlAndDir.."download.php","name=service&folder=/api/")
  local url,ans=pullEventTimeout("http_success",4)
  if ans~=nil then
	local source=ans.readAll()
	if source=="404" then
	  displayPopup("Error - script not found online",colors.red)
	else
	  local _,_,versionRemote = string.find(source,"local version = (%d+%.%d+)")
	  if tonumber(versionRemote) == version then
	    displayPopup("No new version available (current version: "..version..")",colors.white)
	  elseif tonumber(versionRemote)>version then
		displayPopup("New version: "..versionRemote.." downloaded (old version: "..version..")",colors.lime)
		updateServiceSoftware(source)
	  else
	    displayPopup("haha server has older version than you got :) local: "..version..", remote: "..versionRemote)
	  end
	end
  else
    displayPopup("Error - Timeout, http failed",colors.red)
  end
end

-- sets the textscale on all monitors
function setTextScale(size)
	for _,m in pairs(monitors) do
		m.setTextScale(size)
	end
end

-- visualizes the control bar at the bottom line
function visualizeServiceControlPanel(x,y,w,h)
	term.setTextColor(colors.gray)
	term.setCursorPos(x+1,y)
	term.write("Update")
	local updateTrigger = function(mx,my)
		if isInBox(mx,my,x+1,y,6,1) then
			for _,m in pairs(monitors) do
				term.redirect(m)
				term.setBackgroundColor(colors.green)
				term.setTextColor(colors.white)
				term.setCursorPos(x+1,y)
				term.write("Update")
				term.restore()
			end
			tryUpdate()
		end
	end
	table.insert(buttons,updateTrigger)
	
	term.setCursorPos(x+8,y)
	term.write("+-")
	local incTrigger=function(mx,my)
		if isInBox(mx,my,x+8,y,1,1) then
			fontSize=fontSize+0.5
			setPersistentValue("fontSize",fontSize)
			setTextScale(fontSize)
		end
	end
	table.insert(buttons,incTrigger)
	local decTrigger=function(mx,my)
		if isInBox(mx,my,x+9,y,1,1) then
			fontSize=fontSize-0.5
			setPersistentValue("fontSize",fontSize)
			if fontSize<0.5 then fontSize=0.5 end
			setTextScale(fontSize)
		end
	end
	table.insert(buttons,decTrigger)
	
	term.setCursorPos(x+11,y)
	term.write("Changelog")
	local cLogTrigger=function(mx,my)
		if isInBox(mx,my,x+11,y,9,1) then
			popupChangelog()
		end
	end
	table.insert(buttons,cLogTrigger)
end

--visualizes all local services
--TODO: use filterID otherwise visualizeLocalServices won't work correctly
function visualizeServices(monitorSide,filterId)
	buttons={}
	for _,service in pairs(localServices) do
		if service["id"]==os.computerID() and service["typ"]=="get" then
			service["value"] = service["func"]()
		end
	end
	for _,monitor in pairs(monitors) do
		term.redirect(monitor)
		term.setBackgroundColor(colors.black)
		term.clear()
		local w,h=monitor.getSize()
		visualizeServiceControlPanel(1,h,w,1)
		h=h-1
		
		local countServices=#localServices + #services
		if countServices==0 then
			term.setCursorPos(1,h/2)
			writeStringInto("0 services",w,true)
		end
		local gridWidth,gridHeight=findBestGridLayout(w,h,countServices)
		local width,height = math.floor(w/gridWidth), math.floor(h/gridHeight)
		local x,y=0,0
		local rx,ry=0,0
		for _,service in pairs(localServices) do
			if x==gridWidth-1 and (x+1)*width<w then rx=w-(x+1)*width else rx=0 end
			if y==gridHeight-1 and (y+1)*height<h then ry=h-(y+1)*height else ry=0 end
			visualizeServiceIn(service,x*width+1,y*height+1,width+rx,height+ry)
			x=x+1
			if x==gridWidth then x=0 y=y+1 end
		end
		for _,service in pairs(services) do
			if x==gridWidth-1 and (x+1)*width<w then rx=w-(x+1)*width else rx=0 end
			if y==gridHeight-1 and (y+1)*height<h then ry=h-(y+1)*height else ry=0 end
			visualizeServiceIn(service,x*width+1,y*height+1,width+rx,height+ry)
			x=x+1
			if x==gridWidth then x=0 y=y+1 end
		end
		term.restore()
	end
end

function visualizeLocalServices()
	visualizeServices({os.computerID()})
end

function offerServiceTo(service,id)
	local result={
		type="service",cmd="offerService",
		service={
			id=service["id"],
			name=service["name"],typ=service["typ"],
			method=service["method"],value=service["value"]
		}
	}
	rednet.send(id,textutils.serialize(result))
end

function informAboutServices(side,senderChannel,replyChannel)
	for _,service in pairs(localServices) do
		if service["vis"]>0 then
			if service["vis"]==2 or senderChannel==os.computerID() then
				if service["typ"]=="get" then
					service["value"]=service["func"]()
				end
				if service["subscriber"] then
					if service["subscribers"]==nil then service["subscribers"]={} end
					service["subscribers"][replyChannel]=true
				end
				offerServiceTo(service,replyChannel)
			end
		end
	end
end

function serviceHandleModemMsg(side,senderChannel,replyChannel,msg)
	local t=textutils.unserialize(msg)
	if t==nil then return end
	if t["type"]~="service" then return end
	if t["cmd"]=="search" then
		informAboutServices(side,senderChannel,replyChannel)
	elseif t["cmd"]=="offerService" then
		local service=t["service"]
		local rem=nil
		local timeout=0
		for index,s in pairs(services) do
			if s["id"]==service["id"] and s["name"]==service["name"] then
				if s["timeout"]~=nil then timeout=s["timeout"]-1 end
				rem=index
				break
			end
		end
		if rem~=nil then table.remove(services,rem) end
		if timeout<0 then timeout=0 end
		service["timeout"]=timeout
		table.insert(services,service)
		table.sort(services,function(t1,t2) return t1["name"]<t2["name"] end)
	elseif t["cmd"]=="set" then
		for _,s in pairs(localServices) do
			if s["name"]==t["name"] then
				s["func"](t["value"])
				s["value"]=t["value"]
				break
			end
		end
	else
		term.setTextColor(colors.red)
		print("unknown command arrived: "..t["cmd"].." from "..replyChannel)
		term.setTextColor(colors.white)
	end
end

function increaseTimeoutForServices()
	local rem={}
	for index,s in pairs(services) do
		s["timeout"]=s["timeout"]+1
		--after 3rd time not reachable service -> drop out
		if s["timeout"]==3 then
			table.insert(rem,index)
		end
	end
	for _,index in pairs(rem) do
		table.remove(services,index)
	end
end

function searchForPublicServices()
	openModems()
	increaseTimeoutForServices()
	rednet.broadcast(textutils.serialize({type="service",cmd="search"}))
end
function searchForServices(supplierIds)
	openModems()
	increaseTimeoutForServices()
	for _,supplierId in pairs(supplierIds) do
		rednet.send(supplierId,textutils.serialize({type="service",cmd="search"}))
	end
end

function serviceHandleMonitorTouch(x,y)
	for _,button in pairs(buttons) do
		button(x,y)
	end
end

function addMonitorToList(side)
	if peripheral.getType(side)=="monitor" then
		local w=peripheral.wrap(side)
		w.setTextScale(fontSize)
		table.insert(monitors,w)
	end
end

function getMonitors()
	monitors={}
	if monitorConfig=="all" then
		for _,side in pairs(peripheral.getNames()) do
			addMonitorToList(side)
		end
	else
		addMonitorToList(monitorConfig)
	end
	if #monitors == 0 then
		error("Couldn't detect any attached monitors...")
	end
end

function clearMonitors()
	for _,monitor in pairs(monitors) do
		monitor.setBackgroundColor(colors.black)
		monitor.clear()
	end
end

function createRemoteControl()
	remoteControl=true
end


--------------------------------------------------------

function mainOfferService()
	while running do
		visualizeLocalServices()
		event,p1,p2,p3,p4=os.pullEvent()
		if event=="modem_message" then
			--args:side,senderChannel,replyChannel,msg
			serviceHandleModemMsg(p1,p2,p3,p4)
		elseif event=="monitor_touch" then
			--args:x,y
			serviceHandleMonitorTouch(p2,p3)
		elseif event=="timer" and p1==curTimer then
			curTimer=os.startTimer(refreshRateS)
		elseif event=="key" or event=="char" then
			break
		end
	end
end


-- this is a test programm and remote visualizer
function mainRemoteControl()
	searchForPublicServices()
	while running do
		visualizeServices()
		event,p1,p2,p3,p4=os.pullEvent()
		if event=="modem_message" then
			--args:side,senderChannel,replyChannel,msg
			serviceHandleModemMsg(p1,p2,p3,p4)
		elseif event=="monitor_touch" then
			--args:x,y
			serviceHandleMonitorTouch(p2,p3)
			searchForPublicServices()
		elseif event=="key" or event=="char" then
			break
		end
	end
end

-- initialize
getMonitors()
init()

-- read arguments
local resetStartup=false
if #arg==1 then
	if arg[1]=="update_restart" then
		displayPopup("Update installed, software restartet. New version: "..version,colors.lime)
		resetStartup=true
	else
		print("invalid argument: "..arg[1])
	end
elseif #arg>1 then
	print("invalid arguments: "..textutils.serialize(arg))
end
-- reset startup when arguments were passed (because of restart)
if resetStartup then
	fWrite=fs.open("startup","w")
	fWrite.writeLine("shell.run(\"service\",\"\")")
	fWrite.close()
end


if remoteControl then
	mainRemoteControl()
else
	mainOfferService()
end
clearMonitors()