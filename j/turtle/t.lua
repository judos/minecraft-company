# turtle programm to use with short codes

local arg={...}

local dir=arg[1]
local steps=arg[2]

if dir==nil then
  print("Usage:")
  print(" f [steps] = forward")
  print(" b [steps] = backward")
  print(" l [turns] = turn left")
  print(" r [turns] = turn right")
  print(" u [steps] = move up")
  print(" d [steps] = move down")
	print(" dd/ff/uu [steps] = dig there")
  print(" fuel = show fuel level")
else
  if dir=="fuel" then
    print(turtle.getFuelLevel())
	return
  end

  if steps==nil then steps=1 end
  for i=1,steps do
	if dir=="f" then
		turtle.forward()
	elseif dir=="ff" then
		turtle.dig()
		turtle.forward()
	elseif dir=="b" then
		turtle.back()
	elseif dir=="l" then
		turtle.turnLeft()
	elseif dir=="r" then
		turtle.turnRight()
	elseif dir=="u" then
		turtle.up()
	elseif dir=="uu" then
		turtle.digUp()
		turtle.up()
	elseif dir=="d" then
		turtle.down()
	elseif dir=="dd" then
		turtle.digDown()
		turtle.down()
	else
		print("Unknown direction")
	end
  end
end
  