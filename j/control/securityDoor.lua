local allowed= {["ksmonkey123"]=0,["ropeko90"]=0, ["judos_ch"]=0, ["sirtobey33"]=0 }
local rsSide="back"

local m=peripheral.wrap("top")
os.loadAPI("ocs/apis/sensor")
local s=sensor.wrap("right")

function pr(text)
  m.write(text)
  local x,y=m.getCursorPos()
  m.setCursorPos(1,y+1)
end

function showSign(color)
m.setBackgroundColor(color)
m.scroll(0,10)
m.clear()
m.setCursorPos(1,1)
pr("  ___")
pr("_ [||\\\\ ")
pr("\\\\\\\\||||")
pr(" \\\\___/")
end

function dist(vec)
  local q=math.pow
  local a=math.abs
  return math.pow(q(a(vec["X"]),2)+q(a(vec["Y"]),2)+q(a(vec["Z"]),2),0.5)
end

function checkEntry()
  local entities=s.getTargets()
  for name,t in pairs(entities) do
    local distance=dist(t["Position"])
	print(name.." d = "..distance)
    if t["Name"]=="Player" and distance<3 then
      if allowed[name]~=nil then
	    return true
	  end
    end
  end
  return false
end

while true do 
showSign(colors.black)
event=os.pullEvent()
if event=="monitor_touch" then
  if checkEntry() then
    showSign(colors.lime)
	rs.setBundledOutput(rsSide,colors.white)
	os.sleep(3)
	rs.setBundledOutput(rsSide,0)
	showSign(colors.black)
  else
    showSign(colors.red)
	os.sleep(3)
	showSign(colors.black)
  end
elseif event=="key" or event=="char" then
  break
end

end