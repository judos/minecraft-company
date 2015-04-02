--version 1

data = "name=apps"
http.request("http://www.however.ch/tekkit-cc/download.php",data)
local event,url,ans=os.pullEvent()
if event=="http_success" then
 local source=ans.readAll()
 if source=="404" then
  print("error")
 else
  local file=fs.open("/download","w")
  file.write(source)
  file.close()
  print("Client success")
 end
else
 print("Error")
end
print()