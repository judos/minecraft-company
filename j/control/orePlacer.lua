-- for turtles
-- takes out ressources of a chest and places them to the left

local monitorsAside = 4
os.startTimer(0)
c=peripheral.wrap("top") --chest
m=peripheral.wrap("right") --monitor

items={}
function showOnMonitor(name)
  m.clear()
  local w,h=m.getSize()
  local y= #items
  for i=1,#items do
    m.setCursorPos(1+(w/monitorsAside)*(i-1), ((y -1) % (h-1)) + 1)
	m.write(items[i])
	y=y-1
  end
  print("new item: "..name)
  table.insert(items,name)
  if #items > 4 then table.remove(items,1) end
end
function getFirstStackInChest()
  for i=0,c.getSizeInventory()-1 do
    if c.getStackInSlot(i)~=nil then
      return c.getStackInSlot(i)
    end
  end
end

while true do
  event=os.pullEvent()
  if event=="char" or event=="key" then
    break
  elseif event=="timer" then
	repeat
		local s=getFirstStackInChest()
		local item
		if s~=nil then 
			item=s["name"]
			turtle.suckUp()
			while turtle.getItemCount(1)>0 do
			  showOnMonitor(item)
			  rs.setOutput("left", true)
			  os.sleep(0.1)
			  rs.setOutput("left",false)
			  os.sleep(0.1)
			  turtle.placeDown()
			end
		end
	until s==nil
    os.startTimer(5)
  else
    print("unknown event: "..event)
  end
end