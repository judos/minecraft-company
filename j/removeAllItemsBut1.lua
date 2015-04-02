-- author: judos_ch
-- version: 1.1

-- config:
local inputChest = "left" --chest you want to empty
local direction = "west" --in which direction to push items
local update = 10 --update every X seconds
-- end of config

local chest=peripheral.wrap(inputChest)
local timer=os.startTimer(0)

local function emptyChestItemsBut1()
	local spared = {} --item id of which at least one was left in the chest
	local s=chest.getInventorySize()
	print("emptying chest..")
	local items=0
	for i=1,s do
		local stack = chest.getStackInSlot(i)
		if stack~=nil then
			local id = stack["rawName"]
			local push = stack["qty"]
			if spared[id]==nil then push=push-1 end
			spared[id]=true
			chest.pushItem(direction,i,push)
			items=items+push
		else
			break
		end
	end
	if items>0 then
		print("moved "..items.." items.")
	end
end

while true do
	local event=os.pullEvent()
	if event=="char" or event=="key" then
		break
	elseif event=="timer" then
		emptyChestItemsBut1()
		os.startTimer(update)
	end
end