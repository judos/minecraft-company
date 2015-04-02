-- author: judos_ch
-- version: 1.1

-- automatically detects monitors and modems on all sides

--id of sender computer/turtle will be asked on the first run
local acceptedId = nil --persistent data
local monitors

function initMonitors()
	for nr,m in pairs(monitors) do
		m.clear()
		m.setTextScale(0.5)
		local w,h = m.getSize()
		m.setCursorPos(1,h)
	end
end

function printMonitor(msg)
	for nr,m in pairs(monitors) do
		local w,h = m.getSize()
		m.write(msg)
		m.scroll(1)
		m.setCursorPos(1,h)
	end
end

function changeId()
	print("Please enter id of sender computer/turtle:")
	acceptedId = read()
	setPersistentValue("acceptedId",acceptedId)
end

function main()
	placeMeInStartup()
	monitors = detectDevicesAndWrap("monitor")
	initMonitors()
	local modemSides = detectDevices("modem")
	for i,side in pairs(modemSides) do rednet.open(side) end
	if acceptedId ==nil then changeId() end
	
	print("Wireless display Initialized")
	print("Press i to change sender id.")
	printMonitor("Wireless display initialized")
	
	while true do
		local event,a,b,c=os.pullEvent()
		if event=="key" then
			if keys.getName(a)=="i" then
				changeId()
			else
				printMonitor("Wireless display shut down")
				print("Wireless display shut down")
				break
			end
		elseif event=="rednet_message" then
			if tostring(a)==tostring(acceptedId) then
				printMonitor(b)
			end
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



--author: judos_ch
--version: 1.1
--your program must have a:
--"local name = xxx --peristent data"
--inside otherwise the data cannot be saved
function setPersistentValue(name,value)
	local ownName = shell.getRunningProgram()
	local tempName = "temp"..math.random() --has no meaning, file is deleted afterwards
	shell.run("cp",ownName.." "..tempName)
	fRead = fs.open(ownName,"r")
	fWrite = fs.open(tempName,"w")
	repeat
		x=fRead.readLine()
		if x==nil then break end
		if string.match(x,"^local "..name.." = .+ --persistent data$")~=nil then
			x="local "..name.." = "..textutils.serialize(value).." --persistent data"
		end
		fWrite.writeLine(x)
	until false
	fWrite.close()
	fRead.close()
	shell.run("rm",ownName)
	shell.run("cp",tempName.." "..ownName)
	shell.run("rm",tempName)
end


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

main()