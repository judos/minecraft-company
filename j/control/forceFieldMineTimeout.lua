local timeout=20
time = os.clock()
os.startTimer(timeout)
local moving=false

while true do
  event= os.pullEvent()
  
  if rs.getInput("left") then
    time = os.clock()
    os.startTimer(timeout)
  end
  print("Timeout: "..os.clock() - time .." / "..timeout.."s")
  if (os.clock() - time) >= timeout-1 and rs.getInput("left")~=true then
    if moving==false then
		moving=true
		rs.setOutput("back", true)
		os.sleep(1)
		rs.setOutput("back", false)
		os.sleep(3)
		print("moving everything")
		rs.setOutput("front", true)
		os.sleep(0.2)
		rs.setOutput("front", false)
		time = os.clock()
		moving=false
	end
  elseif event=="timer" then
    os.startTimer(timeout)
  end
  
end