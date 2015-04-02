print("press any key to show scancode")
print("press down to quit program")
local anz=1

while true do
 event,param=os.pullEvent()
 if event=="key" then
  anz=anz 1
  if anz==20 then
   print("press down to quit program")
   anz=0
  end
  print(param)
  if param==208 then
   return
  end
 end
end