local prog = nil --persistent data
local vars=""

function main()
	if prog==nil or prog=="" then
		print("Enter the name of the program that should be called when os is starting up:")
		prog=read()
		setPersistentValue("prog",prog)
	end
	shell.run(prog,vars)
end

--must have a "local name = xxx --peristent data" inside
function setPersistentValue(name,value)
	local function typeToDeclaration(value)
		if type(value)=="string" then
			return '"'..value..'"'
		elseif type(value)=="table" then
			local r="{"
			local comma=false
			for k,d in pairs(value) do
				if comma then r=r.."," end
				r=r.."["..typeToDeclaration(k).."]="..typeToDeclaration(d)
				comma=true
			end
			r=r.."}"
			return r
		elseif type(value)=="number" then return value
		elseif type(value)=="boolean" then return value
		elseif type(value)=="nil" then return value
		else
			print("Warning: type "..type(value).." can't be translated into a declaration!",1)
			return nil
		end
	end
	local ownName = shell.getRunningProgram()
	local tempName = "appsTempXYfoqw" --has no meaning, just a random sequence, file is deleted afterwards
	shell.run("rm",tempName)
	shell.run("cp",ownName.." "..tempName)
	fRead = fs.open(tempName,"r")
	fWrite = fs.open(ownName,"w")
	repeat
		x=fRead.readLine()
		if x==nil then break end
		if string.match(x,"^local "..name.." = .+ --persistent data$")~=nil then
			x="local "..name.." = "..typeToDeclaration(value).." --persistent data"
		end
		fWrite.writeLine(x)
	until false
	fWrite.close()
	fRead.close()
	shell.run("rm",tempName)
end
main()


