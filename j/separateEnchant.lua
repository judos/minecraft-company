-- author: judos_ch
-- version: 1

-- automatically sorts a chest's items, enchanted on one side
-- and the rest on the other side

--config:
local enchantedSide = "south"
local notEnchantedSide ="north"
local chestSide = "bottom"
--end of config


local chest=peripheral.wrap(chestSide)
local timer=os.startTimer(3)

function checkInv()
	local s=chest.getInventorySize()
	print("checking inv..")
	local stacks=0
	for i=1,s do
		local s = chest.getStackInSlot(i)
		if s ~= nil then
			if # (s["ench"]) >0 then
				chest.pushItem(enchantedSide,i,64)
			else
				chest.pushItem(notEnchantedSide,i,64)
			end
			stacks=stacks+1
		end
	end
	if stacks>0 then
		print("sorted "..stacks.." stacks")
	end
end

function main()
	placeMeInStartup()
	
	while true do
	local event=os.pullEvent()
	if event=="char" or event=="key" then
		break
	elseif event=="timer" then
		checkInv()
		os.startTimer(3)
	end
end
end


-- INTERNAL API --


--author: judos_ch
--version: 1
function placeMeInStartup()
	local ownName = shell.getRunningProgram()
	shell.run("rm","startup")
	fWrite = fs.open("startup","w")
	fWrite.writeLine("shell.run(\""..ownName.."\",\"\")")
	fWrite.close()
end



main()