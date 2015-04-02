local version = 1.09
-- pastebin code: http://pastebin.com/mD1Wcg7Y
-- pastebin get mD1Wcg7Y apps

local serverUrlAndDir = "http://www.however.ch/tekkit-cc/" --persistent data

local lastDownloads = {} --persistent data
local lastUploads = {} --persistent data
local remoteFolder = "/" --persistent data
local arg= { ... }


local function printChangelog()
	print("1.09   + local functions")
  print("1.086  + fix table serialize multi-line")
	print("1.084  + fixed backslash problems for upload")
	print("1.083  + minor color improvements")
	print("1.08   + added support for turtles, black&white")
	print("1.0735 + colors for most messages")
	print("       + changelog")
end

local function b(color)
	if term.isColor() then term.setBackgroundColor(color)
	else term.setBackgroundColor(colors.black)
	end
end
local function c(color)
	if term.isColor() then term.setTextColor(color)
	else term.setTextColor(colors.white)
	end
end
local function cGood(str,n)
	if term.isColor() then
		term.setTextColor(colors.lime)
		if n~=nil then print(str)
		else term.write(str) end
		term.setTextColor(colors.white)
	else
		if n~=nil then print(str)
		else term.write(str) end
	end
end
local function cBad(str,n)
	if term.isColor() then
		term.setTextColor(colors.red)
		if n~=nil then print(str)
		else term.write(str) end
		term.setTextColor(colors.white)
	else
		if n~=nil then print(str)
		else term.write(str) end
	end
end
local function cHighlight(str,n)
	if term.isColor() then
		term.setBackgroundColor(colors.lightBlue)
		term.setTextColor(colors.white)
		term.write(str)
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)
		if n~=nil then print() end
	else
		if n~=nil then print(str)
		else term.write(str) end
	end
end
local function cUnimportant(str,n)
	if term.isColor() then
		term.setTextColor(colors.gray)
		if n~=nil then print(str)
		else term.write(str) end
		term.setTextColor(colors.white)
	else
		if n~=nil then print(str)
		else term.write(str) end
	end
end

local function changeServerUrl()
	write("Previous server url: ")
	cHighlight(tostring(serverUrlAndDir),1)
	print("Enter new server url:")
	cUnimportant("  e.g. http://www.example.com/tekkit-cc/",1)
	cUnimportant("  enter a empty string if you don't want to change the url",1)
	local inp=read()
	if inp~=nil and inp~="" then
		serverUrlAndDir=inp
		setPersistentValue("serverUrlAndDir",serverUrlAndDir)
	end
end

local function findLast(str,key,startAt)
	str=string.reverse(str)
	key=string.reverse(key)
	pos=string.find(str,key,startAt)
	if pos==nil then return nil end
	pos=pos+ string.len(key)-1
	pos=string.len(str)+1-pos
	return pos
end

local function printUsage()
  print("Usage:")
  print("  apps                - show this page")
  print("  apps list|ls        - shows list of apps")
  print("  apps upload|download|remove name [name2...]")
  print("  apps u|d|r name [name2...] - shortcut")
  print("  apps update         - tries to update")
  print("  apps server         - change server url")
  print("  apps cd folder|..   - change remote folder")
  print("  apps v|version      - displays local version")
  print("  apps changelog")
  print("")
  cUnimportant("e.g.",1)
  cUnimportant(" 1) apps download control buttonAPI",1)
  cUnimportant("  - will download two files",1)
  cUnimportant(" 2) apps upload",1)
  cUnimportant("  - will upload the files you uploaded last time",1)
end

-- API --

--author: judos_ch
--version: 1.2
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
			local nValue = textutils.serialize(value)
			nValue,_ = string.gsub(nValue,"\n","")
			x="local "..name.." = "..nValue.." --persistent data"
		end
		fWrite.writeLine(x)
	until false
	fWrite.close()
	fRead.close()
	shell.run("rm",ownName)
	shell.run("cp",tempName.." "..ownName)
	shell.run("rm",tempName)
end

--------------------------------------------------------

local function pullEventTimeout(expectedEvent,timeout)
  os.startTimer(timeout+0.1)
  local tStart=os.clock()
  while true do
    local event,url,ans=os.pullEvent()
    if event==expectedEvent then
      return url,ans
    elseif os.clock()-tStart>timeout then
      return nil,nil
    end
  end
end
local function downloadFile(file)
  write("Downloading file: "..file.." ...")
  data = "name="..file.."&folder="..remoteFolder
  http.request(serverUrlAndDir.."download.php",data)
  local url,ans=pullEventTimeout("http_success",2)
  if ans~=nil then
	local source=ans.readAll()
	if source=="404" then
	  cBad("Script not found online",1)
	else
	  local file=fs.open(shell.dir().."/"..file,"w")
	  file.write(source)
	  file.close()
	  cGood("Client success")
	end
  else
    cBad("Timeout, http failed",1)
  end
  print()
end
local function deleteFile(file)
  write("Deleting app: "..file.." ...")
  data = "name="..file.."&folder="..remoteFolder
  http.request(serverUrlAndDir.."remove.php",data)
  local url,ans = pullEventTimeout("http_success",2)
  if ans~=nil then
    print("Answer from server: "..ans.readAll() )
    cGood("Success for client")
  else
    cBad("Error has occured",1)
  end
  print()
end
local function uploadFile(file)
  local p1=shell.resolve(file)
  write("Uploading file: "..p1.." ...")

  local f=fs.open(p1,"r")
  local content=f.readAll()
  f.close()
  -- at must be in the first row!
  -- used escape: a,b, p,q, z
  content = string.gsub(content,"@","@z") --at
  
  content = string.gsub(content,'"',"@q") --quote
  content = string.gsub(content,"&","@a") --and
  content = string.gsub(content,"+","@p") --plus
  content = string.gsub(content,"@b@b","@b") --backslash

  data = "name="..file.."&folder="..remoteFolder.."&source="..content
  http.request(serverUrlAndDir.."upload.php",data)
  local url,ans = pullEventTimeout("http_success",2)
  if ans~=nil then
    print("Answer from server: "..ans.readAll() )
    cGood("Success for client")
  else
    cBad("Error has occured",1)
  end
print()
end

local function update()
  print("fetching online version...")
  http.request(serverUrlAndDir.."download.php","name=apps")
  local url,ans=pullEventTimeout("http_success",2)
  if ans~=nil then
	local source=ans.readAll()
	if source=="404" then
	  cBad("Error - script not found online",1)
	else
	  local _,_,versionRemote = string.find(source,"local version = (%d+%.%d+)")
	  if tonumber(versionRemote) == version then
	    cGood("No new version available (current version: "..version..")",1)
	  elseif tonumber(versionRemote)>version then
	    local file=fs.open(shell.dir().."/apps","w")
	    file.write(source)
			file.close()
			cGood("New version: "..versionRemote.." downloaded (old version: "..version..")",1)
	  else
	    cHighlight("haha server has older version than you got :)",1)
		cGood("local: "..version,1)
		cGood("remote: "..versionRemote,1)
	  end
	end
  else
    cBad("Error - Timeout, http failed",1)
  end
  print()
end

local function showListOfApps()
	print("List of apps online: ("..remoteFolder..")")
	http.request(serverUrlAndDir.."apps.php","folder="..remoteFolder)
	local url,ans=pullEventTimeout("http_success",2)
	if ans~=nil then
		local source=ans.readAll()
		local appTable={}
		local maxLength=0
		for app in string.gmatch(source,"%S+") do
			table.insert(appTable,app)
			if #app > maxLength then maxLength=#app end
		end
		local w,h = term.getSize()
		maxLength=maxLength+1
		local appsPerRow = math.floor(w / (maxLength+1))
		local x=0
		for i=1,#appTable do
			local _,cy = term.getCursorPos()
			term.setCursorPos(x*maxLength +1 , cy)
			if (string.sub(appTable[i],#appTable[i],#appTable[i])=="/") then
				c(colors.lime)
			else
				c(colors.lightGray)
			end
			write(appTable[i])
			x=x+1
			if x==appsPerRow then
				x=0
				print()
			end
		end
		if x>0 then print() end
		if term.isColor() then
			b(colors.green)
			c(colors.black)
			write("folders are lime")
			b(colors.black)
			write("  ")
			b(colors.gray)
			write("lua files are lightGray")
			b(colors.black)
			c(colors.white)
			print()
		end
	else
		cBad("Timeout, http failed",1)
	end
end

-- initialization
if serverUrlAndDir==nil then
	cBad("Server Url is not set yet. Where do you host your apps?",1)
	changeServerUrl()
end

-- process commands
if #arg==0 then
	cHighlight("Version: "..version,1)
	printUsage()
else
	local cm=arg[1]
	if cm=="list" or cm=="ls" then
		showListOfApps()
	elseif (cm=="download" or cm=="d") then
		local progs = arg
		table.remove(progs,1)
		if #progs==0 then progs=lastDownloads end
		if #progs==0 then printUsage() end
		for _,d in pairs(progs) do
			downloadFile(d)
		end
		setPersistentValue("lastDownloads",progs)
	elseif (cm=="upload" or cm=="u") then
		local progs = arg
		table.remove(progs,1)
		if #progs==0 then progs=lastUploads end
		if #progs==0 then printUsage() end
		for _,d in pairs(progs) do
			uploadFile(d)
		end
		setPersistentValue("lastUploads",progs)
	elseif (cm=="remove" or cm=="r" or cm=="rm") then
		if #arg==2 then deleteFile(arg[2])
		else
			term.setTextColor(colors.red)
			print("remove doesn't accept more than one argument.")
			term.setTextColor(colors.white)
		end
	elseif cm=="update" then
		update()
	elseif cm=="server" then
		changeServerUrl()
	elseif cm=="cd" then
		if #arg==2 then
			if arg[2]==".." then 
				remoteFolder = string.sub(remoteFolder,1,findLast(remoteFolder,"/",2)) --remove last folder
			else
				local l=string.len(arg[2])
				if string.sub(arg[2],1,1)=="/" then
					remoteFolder=arg[2]
				else
					remoteFolder=remoteFolder.. arg[2]
				end
			end
			local l=string.len(remoteFolder)
			if string.sub(remoteFolder,l,l)~="/" then remoteFolder=remoteFolder.."/" end
			cGood("changed to:     "..remoteFolder,1)
		elseif #arg==1 then
			cGood("current folder: "..remoteFolder,1)
		else
			cBad("cd doesn't support more than oen argument.",1)
		end
		setPersistentValue("remoteFolder",remoteFolder)
	elseif cm=="v" or cm=="version" then
		print("local version: "..version)
	elseif cm=="changelog" then
		printChangelog()
	else
		printUsage()
	end
end