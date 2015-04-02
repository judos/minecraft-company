os.loadAPI("ocs/apis/sensor")
s=sensor.wrap("back")
timeout=1
while true do

t=s.getTargets()
local cows=0
for k,v in pairs(t) do
  if v["Name"]=="Cow" then
    local x=v["Position"]["X"]
    local z=v["Position"]["Z"]
    if x>=-14 and z>-2.5 and z<2.5 then
      cows=cows+1
    end
  end
end
if cows>8 then
  rs.setOutput("front",false)
  timeout=2
else
  rs.setOutput("front",true)
  timeout=timeout+1
end
print("Adults:"..cows.."  checking again in "..timeout.."s")

if timeout>60 then timeout=60 end
os.sleep(timeout)
end