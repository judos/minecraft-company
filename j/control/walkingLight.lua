local c={colors.orange,colors.magenta,colors.lightBlue}
local index=1
while true do

rs.setBundledOutput("left",c[index])
os.sleep(0.5)
index=index+1
if index > #c then index=1 end


end