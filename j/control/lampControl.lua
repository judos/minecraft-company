local currentState=false
local lampCableSide="back"
local sensorSide="right"

function changeLampPower(inp)
local out,fnc,start,dir
if inp then
	out=2^16-1
	fnc=colors.subtract
	start=15
	dir=-1
	print("turning off lights")
else
	out=0
	fnc=colors.combine
	start=0
	dir=1
	print("turning on lights")
end
while start>=0 and start<16 do
	out=fnc(out, 2^start)
	print("color "..(2^start))
	redstone.setBundledOutput(lampCableSide,out)
	os.sleep(math.random())
	start=start+dir
end
end


while true do

event=os.pullEvent()
if event=="redstone" then
	local sensorStrength = rs.getAnalogInput(sensorSide)
	-- is day?
	local newState = sensorStrength>5
	if currentState~=newState then
		changeLampPower(newState)
		currentState=newState
	end
elseif event=="key" or event=="char" then
	break
end

end