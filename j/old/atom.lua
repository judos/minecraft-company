local updateEveryXSec = 1
local lanDiscovery = true -- find sensors on lan?
local fontSize = 0.5
local monitorConfig = "all" -- may be only one side
local warning=false

local function findMonitors()
	if monitorConfig=="all" then
		local dev=peripheral.getNames()
		local monitors={}
		for k,d in pairs(dev) do
			local t=peripheral.getType(d)
			if t=="monitor" then
				local monitor=peripheral.wrap(d)
				table.insert(monitors,monitor)
			end
		end
		return monitors
	elseif monitorConfig~=nil and monitorConfig~="" then
		return {peripheral.wrap(monitorConfig)}
	else
		print("No monitor specified, use side or all as value")
		return nil
	end
end

local function moveCursor(dx,dy)
	local x,y= term.getCursorPos()
	local nx,ny
	if dx==nil then
		nx=1
	else
		nx=x+dx
	end
	if dy==nil then
		ny=1
	else
		ny=y+dy
	end
	
	term.setCursorPos(nx,ny)
end

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

local function updateView(info)
	term.clear()
	if warning then
		local w,h=term.getSize()
		drawRectangle(1,1,w,h,colors.red)
	end
	term.setCursorPos(1,1)
	
	local danger=false
	
	for _,d in pairs(info) do
		term.write(d["title"])
		if d["dmg"]~=nil then
		  moveCursor(nil,1)
		  moveCursor(2,0)
		  term.write(d["dmg"].." / "..d["total"])
		  local per=d["dmg"] / d["total"] * 100
		  term.write(" = "..per.." %")
		  
		  if per>=95 then danger=true end
		end
		moveCursor(nil,1)
	end
	
	if danger and warning==false then
		warning=true
		redstone.setOutput("back",true)
	end
	if danger==false and warning then
		warning=false
		redstone.setOutput("back",false)
	end
	
	if warning then
		term.setBackgroundColor(colors.black)
	end
end

local function updateAllView(info)
	local monitors=findMonitors()
	if monitors==nil or #monitors==0 then 
		print("No monitors found to output information.")
	end
	
	for _,monitor in pairs(monitors) do
		monitor.setTextScale(fontSize)
		term.redirect(monitor)
		updateView(info)
		term.restore()
	end
end

local function addSensorDevices(info,perName)
	os.loadAPI("ocs/apis/sensor")
	local sen = sensor.wrap(perName)
	for key,_ in pairs(sen.getTargets()) do
		local details=sen.getTargetDetails(key)
		if details["Name"]=="Fission Reactor" then
			local s=details["Slots"][1]
			if s["Name"]=="Fissile Fuel Rod" then
				local dmg=s["DamageValue"]
				table.insert(info,{["title"]="Fissile Fuel Rod",["dmg"]=dmg,["total"]=50000})
			else
				table.insert(info,{["title"]=s["Name"]})
			end
		end
	end
	return info
end

local function getAllInfo()
	if lanDiscovery then
		devices=peripheral.getNames()
	else
		devices=redstone.getSides()
	end
	local info={}
	for _,perName in pairs(devices) do
		local t=peripheral.getType(perName)
		if t=="sensor" then
			info=addSensorDevices(info,perName)
		end
	end
	return info
end


local function main(updateEveryXSec)
	local curTimer=os.startTimer(updateEveryXSec)
	while true do
		local event,p1,p2,p3,p4,p5=os.pullEvent()
		if event=="timer" and curTimer==p1 then
			local info=getAllInfo()
			updateAllView(info)
			curTimer=os.startTimer(updateEveryXSec)
		elseif event=="key" or event=="char" then
			break
		end
	end
end

main(updateEveryXSec)
redstone.setOutput("back",false)
term.redirect(term.native)