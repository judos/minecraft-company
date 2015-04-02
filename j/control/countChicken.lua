local sensorSide = "left"
local targetAnimal = "Chicken"
local monitorSide = "top"
local updateEveryXSec = 30

local sensorCoordX = -190
local sensorCoordZ = 260
local cageMinX = -209.5
local cageMaxX = -189.5
local cageMinZ = 259.5
local cageMaxZ = 265.5

-- table with actions to take:
-- compare: "<" or ">"
-- amount: any integer
-- action: "rs" emiting a redstone signal
-- side: the side on which to take action
local action = { {compare=">", amount=0, action="rs", side="bottom"}}

-------------------------------

os.loadAPI("ocs/apis/sensor")
local s=sensor.wrap(sensorSide)
local monitor=nil
if monitorSide~=nil then
	monitor=peripheral.wrap(monitorSide)
end

local curTimer=os.startTimer(updateEveryXSec)

while true do

	local t=s.getTargets()
	local count=0
	for _,v in pairs(t) do
	  if v["Name"]==targetAnimal then
		local x=v["Position"]["X"] + sensorCoordX
		local z=v["Position"]["Z"] + sensorCoordZ
		local i=false
		if x>=cageMinX and x<=cageMaxX then
		  if z>=cageMinZ and z<=cageMaxZ then
			count=count+1
			i=true
		  end
		end
		if i==false then
		  --tv(v) --for debugging
		end
	  end
	end

	for _,t in pairs(action) do
		local result = false
		if t["compare"]=="<" and count<t["amount"] then result=true end
		if t["compare"]==">" and count>t["amount"] then result=true end
		
		if t["action"]=="rs" then rs.setOutput(t["side"],result) end
	end

	--monitor display
	if monitor~=nil then
		monitor.clear()
		monitor.setCursorPos(1,1)
		monitor.setTextScale(1)
		monitor.write(targetAnimal..": "..count)
		monitor.setCursorPos(1,2)
		monitor.write("dispenser off")
	end

	local quit=false
	repeat
		local br=true
		event,p1=os.pullEvent()
		if event=="key" or event=="char" then
			quit=true
			break
		elseif event=="timer" and p1==curTimer then
			curTimer=os.startTimer(updateEveryXSec)
		elseif event=="redstone" then 
		    --don't refresh (dispenser behind always triggers this)
			br=false
		end
	until br
	
	if quit then break end
end