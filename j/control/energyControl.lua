-- config:
local title="Gold Laser Control"
local monitorSide="top"

------------------------------
print("version 0.32")
local currentPer = 0
local run=true
os.loadAPI("button")
button.init(monitorSide,1)
local monitor=peripheral.wrap(monitorSide)

function fillTable()
  button.setTable("Off",changePer,-100,2,6,3,4)
  button.setTable("-",changePer,-5,2,6,6,7)
  button.setTable("--",changePer,-20,2,6,9,10)
  button.setTable("On",changePer,100,24,28,3,4)
  button.setTable("+",changePer,5,24,28,6,7)
  button.setTable("++",changePer,20,24,28,9,10)
end

function getClick()
  event,side,x,y = os.pullEvent()
  if event=="monitor_touch" then
    button.checkxy(x,y)
  elseif event=="char" or event=="key" then
    print("ending program...")
    run=false
  end
end

function setInputOfCells(per)
	local devices=peripheral.getNames()
	for _,id in pairs(devices) do
		if peripheral.getType(id)=="redstone_energy_cell" then
			local d=peripheral.wrap(id)
			d.setEnergyReceive(per)
		end
	end
end

function changePer(per)
  if per==-100 then button.flash("Off")
  elseif per==-5 then button.flash("-")
  elseif per==-20 then button.flash("--")
  elseif per==100 then button.flash("On")
  elseif per==5 then button.flash("+")
  elseif per==20 then button.flash("++")
  end
  currentPer=currentPer+per
  if currentPer<0 then currentPer=0 end
  if currentPer>100 then currentPer=100 end
  setInputOfCells(currentPer)
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

function drawPercentage()
	local w,h=monitor.getSize()
	local curH = h-3
	curH = curH * currentPer / 100
	drawRectangle(10,h,12,-curH,colors.lime)
end

fillTable()
changePer(currentPer)
term.redirect(monitor)
while run do
  monitor.clear()
  button.heading(title)
  button.screen()
  button.label(10,3,"Input: "..currentPer.." %")
  drawPercentage()
  getClick()
end
term.restore()
monitor.clear()