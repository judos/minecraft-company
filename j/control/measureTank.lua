--measure production with a redstone transport pipe (buildcraft)
-- Config:
local tankSide = "back" --where the computer can access the tank
local monitorSide ="top" --where the computer should display the production

 -- side where computer emits rs signal until tanks are empty
 -- action: "rs" or "bundled" (needs "color"= number)
 -- side: <<side>> specified
local tankEmpty = {action="bundled", side="bottom",color=colors.white}
local timeOut=30

--------------------------------

local anz=0 --total produced milli Buckets

local tStart=os.clock()
local run=true
local tank = peripheral.wrap(tankSide)
os.startTimer(timeOut)

function getTankInfo()
	local t1=tank.getTanks("")
	return t1[1]
end

local t=getTankInfo()
local lastAmount= t["amount"]

function emptyTanks()
  clear()
  wt("Tank is being emptied")
  if tankEmpty["action"]=="rs" then
	rs.setOutput(tankEmpty["side"],true)
  elseif tankEmpty["action"]=="bundled" then
    rs.setBundledOutput(tankEmpty["side"],tankEmpty["color"])
  end
  while true do
  local info = getTankInfo()
  if info["amount"]==nil then break end
  os.sleep(1)
  end
  if tankEmpty["action"]=="rs" then
	rs.setOutput(tankEmpty["side"],false)
  elseif tankEmpty["action"]=="bundled" then
    rs.setBundledOutput(tankEmpty["side"],0)
  end
  lastAmount = 0
  clear()
end

function handleEvent(e,p1,p2,p3)
    local t=getTankInfo()
	if t["amount"]~=nil then
		anz=anz+ t["amount"] - lastAmount
		lastAmount = t["amount"]
		if t["amount"]==t["capacity"] then
			emptyTanks()
		end
	end

	monitor.setTextColor(colors.black)
  wt("Current Time: "..textutils.formatTime(os.time(),false))
  nl()
  wt("Cur.Amount: "..anz.." mB")
  nl()
  spent= os.clock()-tStart
  min= math.floor(spent/60)
  sec=math.floor(spent%60)
  wt("Time spent: "..min.."m"..sec.."s")
  nl()
  
  production= math.floor(anz*60 / spent)
  wt("Production: "..production.." mB / min")
  nl()
  local x,y=moveCursor(2,1)
  monitor.setBackgroundColor(colors.gray)
  monitor.setTextColor(colors.red)
  wt(" Quit program ")
  monitor.setBackgroundColor(colors.white)
  if e=="monitor_touch" then
    if p2>=x and p2<=x+14 and p3==y then
      run=false
    end
  end
  if e=="timer" then
    os.startTimer(timeOut)
  end
end

function moveCursor(x,y)
  local x2,y2=monitor.getCursorPos()
  monitor.setCursorPos(x2+x,y2+y)
  return monitor.getCursorPos()
end
function initMonitor()
  monitor=peripheral.wrap(monitorSide)
  monitor.setBackgroundColor(colors.white)
  monitor.setTextScale(0.5)
end

function clear()
  monitor.clear()
  monitor.setCursorPos(1,1)
end

function nl()
  x,y=monitor.getCursorPos()
  monitor.setCursorPos(1,y+1)
end

function wt(textLine)
  monitor.write(textLine)
end

initMonitor()
run=true
local event=""
local p1,p2,p3
p1=""
p2=""
p3=""
while run do
  clear()
  handleEvent(event,p1,p2,p3)
  if not run then break end   
  event,p1,p2,p3=os.pullEvent()
  if event=="char" and p1=="e" then
    break
  end
end

monitor.setBackgroundColor(colors.black)
monitor.clear()