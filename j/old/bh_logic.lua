cross1 = 0
cross2 = 1
abfahrtBelegt = 0
ziel0,ziel1 = 0,0
ziel0alt,ziel1alt = 0,0
ziel0ausfahrt,ziel1ausfahrt = 0,0

function controlBH()
 print("Abfahrtbelegt: "..abfahrtBelegt)
 input=rs.getBundledInput("front")
 output=0
 -- einfahrt kreuzungen
 if colors.test(input,colors.green) then
  cross1=1
  print("Place 1 is now occupied")
 end
 if colors.test(input,colors.blue) then
  cross2=0
  print("Place 2 is now occupied")
 end

 -- abfahrt
 if colors.test(input,colors.purple) then
  if abfahrtBelegt == 0 then
   abfahrtBelegt = 1
   output = colors.combine(output,colors.purple)
   cross1 = 0
   print("Car 1 left, Place 1 is now free")
  else
   print("Car 1 can't leave")
  end
 end
 if colors.test(input,colors.brown) and abfahrtBelegt==0 then
  abfahrtBelegt = 1
  output = colors.combine(output,colors.brown)
  cross2 = 1
  print("Car 2 left, Place 2 is now free")
 end
 if colors.test(input,colors.black) and abfahrtBelegt==0 then
  abfahrtBelegt = 1
  output = colors.combine(output,colors.black)
  print("Car 3 just left")
 end
 if colors.test(input,colors.gray) and abfahrtBelegt==0 then
  abfahrtBelegt = 1
  output = colors.combine(output,colors.gray)
  print("Train 1 just left")
 end
 
 -- ziel ändern
 ziel0alt=ziel0
 ziel1alt=ziel1
 ziel0 = colors.test(input,colors.white)
 ziel1 = colors.test(input,colors.yellow)
 if ziel0alt~=ziel0 or ziel1alt~=ziel1 then
  local zielNr = 0
  if ziel0 then zielNr = zielNr 1 end
  if ziel1 then zielNr = zielNr 2 end
  print("Destination "..zielNr.." chosen")
 end

 -- einfahrt kreuzungen
 if cross1==1 then
  output=colors.combine(output,colors.green)
 end
 if cross2==1 then
  output=colors.combine(output,colors.blue)
 end

 -- ausfahrt gelungen
 if colors.test(input,colors.red) then
  abfahrtBelegt = 0
 end
 
 -- ausfahrts kreuzungen
 if abfahrtBelegt == 0 then
  ziel0ausfahrt = ziel0
  ziel1ausfahrt = ziel1
 end
 if ziel0ausfahrt then
  output=colors.combine(output,colors.white)
 end
 if ziel1ausfahrt then
  output=colors.combine(output,colors.yellow)
 end

 -- ausfahrts licht
 if abfahrtBelegt==1 then
  output=colors.combine(output,colors.red)
 end

 rs.setBundledOutput("right",output)
end