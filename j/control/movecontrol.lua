term.setBackgroundColor(colors.black)
term.clear()

local buttons={}

function toggleRs(color)
	local out=color
	rs.setBundledOutput("top",out)
	os.sleep(0.05)
	rs.setBundledOutput("top",0)
end
function createButton(text,x,y,color)
	term.setCursorPos(x,y)
	term.setBackgroundColor(colors.lightGray)
	term.setTextColor(color)
	term.write(text)
	local hit=function(mx,my)
		if mx<x or mx>=x+ #text then return end
		if my<y or my>y then return end
		toggleRs(color)
		term.setCursorPos(x,y)
		term.setBackgroundColor(colors.green)
		term.setTextColor(colors.white)
		term.write(text)
	end
	table.insert(buttons,hit)
end

function checkButtonPressed(x,y)
	for _,hit in pairs(buttons) do
		hit(x,y)
	end
end

function createAllButtons()
	createButton("<- West",11,2,colors.green)
	createButton("East ->",11,4,colors.red)

	createButton("/\\ Up",11,8,colors.blue)
	createButton("Down \\/",11,10,colors.yellow)

	createButton("OO South",2,8,colors.purple)
	createButton("North XX",2,10,colors.lime)
end

createAllButtons()
while true do
	event,p1,p2,p3,p4=os.pullEvent()
	if event=="monitor_touch" then
		--checkButtonPressed(p2,p3)
	elseif event=="mouse_click" then
		checkButtonPressed(p2,p3)
	elseif event=="key" or event=="char" then
		break
	elseif event=="redstone" then
		--do nothing
	else
		print("Event not handled: "..event)
	end
end

term.clear()
