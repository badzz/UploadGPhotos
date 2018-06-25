local https = require("ssl.https")
local lxp = require ("lxp")

local P = {}
picasa = P   

--P.SCOPE = "https://picasaweb.google.com/data/"
P.SCOPE = "https://www.googleapis.com/auth/photoslibrary.appendonly"


function P.upload_image (credentials, imageFileName, albumName, albumid)
   if (not albumid) then
      albumid = P.albumidfromtitle(credentials,albumName) 
      print ("found albumid : ".. albumid)
   end
   print ("albumid " .. albumid)
   
   imageFile = io.open(imageFileName)
   size = imageFile:seek("end")
   imageFile:seek ("set", 0)
   print ("upload_image " .. imageFileName .. " size: " .. size)
   local response_body = {}
   local body, code, headers, status = https.request{
      url = albumid,
      method = "POST",
      headers = {
	 ["Content-Type"] =  "image/jpeg",
	 ["Content-Length"] = size,
	 ["Authorization"] = "Bearer " .. credentials["access_token"]
      },
      source = ltn12.source.file(imageFile),
      sink = ltn12.sink.table(response_body)
   }
   --  table.foreach (response_body,print)
   if (code == 201) then print ("Success") end
end

--function P.upload_image (credentials, imageFileName)
--  return P.upload_image (credentials, imageFileName, "https://picasaweb.google.com/data/feed/api/user/default/albumid/default")
--end

function P.listAlbums(credentials)
   local body ,code,headers ,status = https.request("https://picasaweb.google.com/data/feed/api/user/default?access_token=" .. credentials["access_token"] )
   return (body)
end

function P.albumidfromtitle(credentials, titletofind)
   body = P.listAlbums(credentials)
   local id
   local title
   local root = true
   local parsedAlbums = {}
   callbacks = {
      StartElement = function (parser, name, attributes)
	 if (name == "entry") then
	    if (root) then
	       if (not titletofind) then titletofind=title end
	       parsedAlbums[title] = id 
	       root = false
	    end
	 else 
	    if (name == "link") then
	       if (attributes["rel"] == "http://schemas.google.com/g/2005#feed") then
		  id = attributes["href"]
	       end
	       callbacks.CharacterData = false
	    else 
	       if (name == "title") then
		  callbacks.CharacterData = function (parser, string) title = string end
	       else
		  callbacks.CharacterData = false
	       end
	    end
	 end
      end,
      EndElement = function (parser, name, attributes)
	 if (name == "entry") then
	    parsedAlbums[title] = id 
	 end
      end,
      CharacterData = false
   }
   p = lxp.new(callbacks)
   p:parse(body )
   p:close()
   --  table.foreach (parsedAlbums,print)
   print (titletofind .. " " .. parsedAlbums[titletofind])
   return (parsedAlbums[titletofind])
end


return picasa
