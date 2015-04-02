local version = 1.2
-- you need to call 
--	button.init(monitorSide,textScale)
-- first!
-- original author: direwolf20, modified by judos_ch
local buttons={}
local mon

function init(monitorSide,textScale)
	mon = peripheral.wrap(monitorSide)
	mon.setTextColor(colors.white)
	mon.setBackgroundColor(colors.black)
	mon.setTextScale(textScale)
end

function initTerm()
	mon = term.native()
	mon.setTextColor(colors.white)
	mon.setBackgroundColor(colors.black)
end

function clearTable()
   buttons = {}
end
               
function setTable(name, func, param, xmin, xmax, ymin, ymax)
   buttons[name] = {}
   buttons[name]["func"] = func
   buttons[name]["active"] = false
   buttons[name]["param"] = param
   buttons[name]["xmin"] = xmin
   buttons[name]["ymin"] = ymin
   buttons[name]["xmax"] = xmax
   buttons[name]["ymax"] = ymax
end

function fill(text, color, bData)
   mon.setBackgroundColor(color)
   local yspot = math.floor((bData["ymin"] + bData["ymax"]) /2)
   local xspot = math.floor((bData["xmax"] - bData["xmin"] - string.len(text)) /2) +1
   for j = bData["ymin"], bData["ymax"] do
      mon.setCursorPos(bData["xmin"], j)
      if j == yspot then
         for k = 0, bData["xmax"] - bData["xmin"] - string.len(text) +1 do
            if k == xspot then
               mon.write(text)
            else
               mon.write(" ")
            end
         end
      else
         for i = bData["xmin"], bData["xmax"] do
            mon.write(" ")
         end
      end
   end
   mon.setBackgroundColor(colors.black)
end
     
function screen()
   local currColor
   for name,data in pairs(buttons) do
      local on = data["active"]
      if on == true then currColor = colors.lime else currColor = colors.red end
      fill(name, currColor, data)
   end
end

function toggleButton(name)
   buttons[name]["active"] = not buttons[name]["active"]
   screen()
end     

function flash(name)
   toggleButton(name)
   screen()
   sleep(0.15)
   toggleButton(name)
   screen()
end
                                             
function checkxy(x, y)
   for name, data in pairs(buttons) do
      if y>=data["ymin"] and  y <= data["ymax"] then
         if x>=data["xmin"] and x<= data["xmax"] then
            if data["param"] == "" then
              data["func"]()
            else
              data["func"](data["param"])
            end
            return true
            --data["active"] = not data["active"]
            --print(name)
         end
      end
   end
   return false
end
     
function heading(text)
   w, h = mon.getSize()
   mon.setCursorPos((w-string.len(text))/2+1, 1)
   mon.write(text)
end
     
function label(w, h, text)
   mon.setCursorPos(w, h)
   mon.write(text)
end