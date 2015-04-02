-- version3
-- b=boarding track, d=detector tracks, = means normal track
-- X unloader or loader with bording track on it, that gets
--   powered directly
-- colors: 1=white,2=yellow,3=red,4=green,5=blue,6=brown
--         7=black
-- setup:
--    23456     (output)
-- d=Xbbbbb=d
-- 1        7   (input)
-- 

print("Where is bundled cable connected to?")
for k,v in pairs(rs.getSides()) do
 print(k .. " = " .. v)
end
local side = tonumber(io.read())
print(type(side))
local sideN=rs.getSides()[side]
print("SideN: " .. sideN)

print("Current Nr of Cars:")
local cars_stored=tonumber(io.read())

function check()
inp=rs.getBundledInput(sideN)
out=0

-- car enters
if colors.test(inp,colors.black) then
 if cars_stored<1 then
  out=colors.combine(out,colors.yellow)
 end
 if cars_stored<2 then
  out=colors.combine(out,colors.red)
 end
 if cars_stored<3 then
  out=colors.combine(out,colors.green)
 end
 if cars_stored<4 then
  out=colors.combine(out,colors.blue)
 end
 if cars_stored<5 then
  out=colors.combine(out,colors.brown)
 end
 cars_stored=cars_stored 1
 print("Cars:"..cars_stored)
 rs.setBundledOutput(sideN,out)
 os.sleep(1)
end

-- car leaves
if colors.test(inp,colors.white) then
 out=colors.combine(colors.yellow,colors.red)
 out=colors.combine(out,colors.green,colors.blue,colors.brown)
 rs.setBundledOutput(sideN,out)
 os.sleep(0.15)
 cars_stored=cars_stored-1
 print("Cars:"..cars_stored)
 rs.setBundledOutput(sideN,0)
 os.sleep(1)
end 

end

peripheral.wrap("top").clear()
print("E = end")
print("Cars:"..cars_stored)
while true do
 local a,b,c=os.pullEvent()
 if a=="key" and b==18 then
  return
 end
 if a=="redstone" then
  check()
 end
end