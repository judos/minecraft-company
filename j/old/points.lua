-- shows the number of inputs that are on

function show(p)
o=0
if p==0 or p==2 or p==3 or p==5 or p==6 then
 o=bit.bor(o,colors.white)
end
if p~=2 then
 o=bit.bor(o,colors.yellow)
end
if p==0 or p==2 or p==6 then
 o=bit.bor(o,colors.red)
end
if p>=2 and p<=6 then
 o=bit.bor(o,colors.lime)
end
if p<=4 or p==7 then
 o=bit.bor(o,colors.lightBlue)
end
if p==0 or p==4 or p==5 or p==6 then
 o=bit.bor(o,colors.purple)
end
if p~=1 and p~=4 then
 o=bit.bor(o,colors.black)
end
rs.setBundledOutput("front",o)
end

function check()
local points=0
local v=rs.getBundledInput("back")
if not colors.test(v,colors.white) then
 points=points+1
end
if not colors.test(v,colors.yellow) then
 points=points+1
end
if not colors.test(v,colors.red) then
 points=points+1
end
if not colors.test(v,colors.lime) then
 points=points+1
end
if not colors.test(v,colors.lightBlue) then
 points=points+1
end
if not colors.test(v,colors.purple) then
 points=points+1
end
if not colors.test(v,colors.black) then
 points=points+1
end
show(points)
print("Points: ",points)
end

local ende=0
print("Press any key to end")
repeat

local a,b,c=os.pullEvent()
if a=="key" then
 ende=1
end
if a=="redstone" then
 check()
end 

until ende==1