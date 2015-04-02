local mon=peripheral.wrap("left")
mon.setTextScale(0.5)
term.redirect(mon)
local am,dev=0,0
for _,d in pairs(peripheral.getNames()) do
  dev=dev+1
  if peripheral.getType(d)=="computer" then
    am=am+1
    local c=peripheral.wrap(d)
    c.turnOn()
  end
end
while true do
  term.clear()
  term.setCursorPos(1,1)
  term.write("devices: "..dev)
  term.setCursorPos(1,2)
  term.write("computers: "..am)
  
  term.setCursorPos(1,5)
  term.write("press any key")
  term.setCursorPos(1,6)
  term.write("to end")
  local event=os.pullEvent()
  if event=="key" or event=="char" then
    break
  end
end

term.restore()