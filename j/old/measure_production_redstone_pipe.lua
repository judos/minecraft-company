--measure production with a redstone transport pipe (buildcraft)
-- Config:
local signalIn = "back" --where the computer will receive a signal upon one item
local monitorSide ="top" --where the computer should display the production

--------------------------------

local anz=0
local tStart=os.clock()
local run=true
os.startTimer(5)

function handleEvent(e,p1,p2,p3)
  if e=="redstone" and redstone.getInput(signalIn) then
    anz=anz+1
  end
  monitor.setTextColor(colors.black)
  wt("Current Time: "..textutils.formatTime(os.time(),false))
  nl()
  wt("Cur.Amount: "..anz)
  nl()
  spent= os.clock()-tStart
  min= math.floor(spent/60)
  sec=math.floor(spent%60)
  wt("Time spent: "..min.."m"..sec.."s")
  nl()
  
  production= math.floor(100*anz*60 / spent)/100
  wt("Production per min: "..production)
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
    os.startTimer(5)
  end
end

function moveCursor(x,y)
  local x2,y2=monitor.getCursorPos()
  monitor.setCursorPos(x2 x,y2 y)
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
  monitor.setCursorPos(1,y 1)
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