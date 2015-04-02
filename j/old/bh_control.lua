version=1
shell.run("bh_help")
shell.run("bh_logic")

function check()
 local a,p1=os.pullEvent()
 if a=="key" then
  if p1==18 then
   return 1
  else
   outputHelp()
  end
 elseif a=="redstone" then
  controlBH()
 else
  print("Unknown event: "..a.." "..p1)
 end 
 return 0
end

controlBH()
repeat
 ende=check()
until ende==1