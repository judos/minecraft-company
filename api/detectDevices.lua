




-- API --

--author: judos_ch
--version: 1.1
-- returns {side, ..}
function detectDevices(name)
	local devices={}
	for nr,side in pairs(peripheral.getNames()) do
		if peripheral.getType(side) == name then
			table.insert(devices,side)
		end
	end
	return devices
end

function detectDevicesAndWrap(name)
	local devices={}
	for nr,side in pairs(peripheral.getNames()) do
		if peripheral.getType(side) == name then
			table.insert(devices,peripheral.wrap(side))
		end
	end
	return devices
end