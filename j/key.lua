function drawKeyBoard(relX,relY)
	local w,h=term.getSize()
	if relX=="center" then
		relX=w/2 - 27/2
	end
	for i=1,27 do
		x=(i-1) % 9
		y= math.floor((i-1)/9)
		term.setCursorPos(x*3+relX,y+relY)
		if i%2==0 then
			term.setBackgroundColor(colors.black)
		else
			term.setBackgroundColor(colors.gray)
		end
		if i==27 then
			write("<--")
		else
			write(" "..string.char(64+i).." ")
		end
	end
	term.setBackgroundColor(colors.black)
end

function getKeyBoardChar(relX,relY,eventX,eventY)
	local w,h=term.getSize()
	if relX=="center" then
		relX=w/2 - 27/2
	end
	-- outside keyboard --
	if eventX<relX then return "" end
	if eventX>relX+26 then return "" end
	if eventY<relY then return "" end
	if eventY>relY+3 then return "" end
	
	local x=math.floor((eventX-relX)/3)
	local y=eventY-relY
	local i=x+1+y*9
	
	print("x="..x..",  y="..y..", i="..i)
	return string.char(64+i)
end

term.clear()

os.startTimer(0)
repeat
	event,p1,p2,p3=os.pullEvent()
	term.clear()
	drawKeyBoard("center",5)
	term.setCursorPos(1,10)
	if event=="char" then
		break
	elseif event=="mouse_click" then
		local ch=getKeyBoardChar("center",5,p2,p3)
		print("char: "..ch)
	else
		print(event.." "..tostring(p1)..tostring(p2)..tostring(p3))
	end
until false