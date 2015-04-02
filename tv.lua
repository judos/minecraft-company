local function indent(nr)
  for x=1,nr do write(" ") end
end

function tv(var,sleepTime,depth)
	if depth==nil then depth=0 end
	if sleepTime==nil then sleepTime=0 end
	if var==nil then
		write("nil")
	elseif type(var)=="table" then
		local x=false
		write("{")
		for k,d in pairs(var) do
			if x then write(", ") end
			x=true
			if d~=nil and type(d)=="table" then
				print("") indent(depth+2)
			end
			tv(k,sleepTime,depth+2)
			write("= ")
			tv(d,sleepTime,depth+2)
			os.sleep(sleepTime)
		end
		write("}")
	elseif type(var)=="function" then
		write("fnc")
	else
		write(tostring(var))
	end
	if depth==0 then
		print("\n")
	end
end
