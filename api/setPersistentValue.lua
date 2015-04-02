--this line mustn't be changed: (even the comment has it's function in order to get the persistence to work)
local name = nil --persistent data

--main is called at the end of the program...
function main()
	if name==nil then
		write("Enter your name: ")
		name = read()
		setPersistentValue("name",name)
		print("Ok I saved that. Now rerun me again!")
	else
		print("I already know your name: "..name)
	end
end

-- API --

function setPersistentValue(name,value,configName)
--author: judos_ch
--version: 1.4
--your program must have a:
--"local name = xxx --persistent data"
--inside otherwise the data cannot be saved
--if configName is set, it will try to change the value there,
--   if not found it will add it at the end of the file
	local ownName = shell.getRunningProgram()
	if configName~=nil then
		ownName = configName
		if not fs.exists(ownName) then
			local fW = fs.open(ownName,"w")
			fW.close()
		end
	end
	local tempName = "temp"..math.random() --has no meaning, file is deleted afterwards
	shell.run("cp",ownName.." "..tempName)
	local fRead = fs.open(ownName,"r")
	local fWrite = fs.open(tempName,"w")
	local found=false --used only for configFile
	local nValue = textutils.serialize(value)
	nValue,_ = string.gsub(nValue,"\n","")
	local loc = "local "
	if configName~=nil then loc ="" end --don't use local space in config file
	local newLine=loc..name.." = "..nValue.." --persistent data"
	repeat
		x=fRead.readLine()
		if x==nil then break end
		if string.match(x,"^"..loc..name.." = .+ --persistent data$")~=nil then
			x=newLine
			found=true
		end
		fWrite.writeLine(x)
	until false
	if not found then fWrite.writeLine(newLine) end
	fWrite.close()
	fRead.close()
	shell.run("rm",ownName)
	shell.run("cp",tempName.." "..ownName)
	shell.run("rm",tempName)
end




main()