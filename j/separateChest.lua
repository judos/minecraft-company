local inputChest = "bottom" --chest you want to separate
local slotsDispense = 9 --last X slots used as dispose slots
local pushDir = "down" --into what direction items are pushed out of the chest

local chest=peripheral.wrap(inputChest)
local timer=os.startTimer(3)

local function checkInv()
	local s=chest.getInventorySize()
	print("checking inv..")
	local stacksTot=0
 local stacks
 repeat
  stacks =0
	 for i=s,s-slotsDispense+1,-1 do
	 	if chest.getStackInSlot(i) ~=nil then
		 	chest.pushItem(pushDir,i,64)
		 	stacks=stacks+1
		 end
  end
  stacksTot = stacksTot + stacks
 until stacks==0
	if stacksTot>0 then
		print("pushed "..stacksTot.." stacks away")
	end
end

while true do
	local event=os.pullEvent()
	if event=="char" or event=="key" then
		break
	elseif event=="timer" then
		checkInv()
		os.startTimer(3)
	end
end