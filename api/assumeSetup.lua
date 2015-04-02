

-- API --

function assumeSetup(setup,message)
--author: judos_ch
--version: 1.1
-- params:
--		setup: { [side]=deviceType, ...}
--		message: error (show incase setup is incorrect)
-- displays error message if setup is incorrect
	local ok=true
	for side,devType in pairs(setup) do
		local is = peripheral.getType(side)
		if is~=devType then
			if ok then
				print("Setup incorrect:")
				ok=false
			end
			print("  side: "..side)
			print("  device assumed: "..devType)
			if is==nil then is="Air" end
			print("  found on this side: "..is)
		end
	end
	if not ok then
		if message==nil then
			error("Your setup is incorrect!")
		else
			error(message)
		end
	end
end


assumeSetup({["right"]="modem",["front"]="chest"})