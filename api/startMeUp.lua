local ranBefore = false --persistent data

-- API --

local function startMeUp()
--author: judos_ch
--version: 1.1
	local ownName = shell.getRunningProgram()
	shell.run("rm","startup")
	fWrite = fs.open("startup","w")
	fWrite.writeLine("shell.run(\""..ownName.."\",\"\")")
	fWrite.close()
end



-- Other API --


--author: judos_ch
--version: 1.1
--your program must have a:
--"local name = xxx --peristent data"
--inside otherwise the data cannot be saved
local function setPersistentValue(name,value)
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

-- demonstration programm
local function main()
	if not ranBefore then
		startMeUp()
		print("This programm will now execute when the computer boots.")
		os.sleep(2)
		print("I will now reboot...")
		setPersistentValue("ranBefore",true)
		os.sleep(2)
		os.reboot()
	else
		print("This programm did execute when the computer booted up.")
		shell.run("rm","startup")
		os.sleep(2)
		print("startup was now again deactivated")
		os.sleep(2)
		print("When I reboot now, the programm will not be started.")
		setPersistentValue("ranBefore",false)
		os.sleep(2)
		os.reboot()
	end
end


main()


