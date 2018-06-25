local json = require('json')
local https = require("ssl.https")
local lxp = require ("lxp")

local P = {}
gphoto = P   

P.SCOPE = "https://www.googleapis.com/auth/photoslibrary"


function P.upload_image (credentials, imageFileName)
   
   imageFile = io.open(imageFileName)
   size = imageFile:seek("end")
   imageFile:seek ("set", 0)
   print ("upload_image " .. imageFileName .. " size: " .. size)
   local response_body = {}
   local body, code, headers, status = https.request{
      url = "http://photoslibrary.googleapis.com/v1/uploads",
      method = "POST",
      headers = {
	 ["Content-Type"] =  "application/octet-stream",
	 ["Content-Length"] = size,
	 ["X-Goog-Upload-File-Name"] = imageFileName,
	 ["Authorization"] = "Bearer " .. credentials["access_token"]
      },
      source = ltn12.source.file(imageFile),
      sink = ltn12.sink.table(response_body)
   }
   print ("response_body")
   for a,b in pairs (response_body) do
      print (a,b)
   end
   print ("code:" .. code)
   if (code ~= 200) then print ("Failure") end

   local request = json.encode( {newMediaItems = { { simpleMediaItem= { uploadToken = response_body[1] } } } } )
   print (request)
   --local body ,code,headers ,status = https.request("https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate", request)
   local response_body = {}
   local body, code, headers, status = https.request{
      url = "https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate",
      method = "POST",
      headers = {
	 ["Content-Type"] =  "application/json",
	 ["Content-Length"] = string.len(request),
	 ["Authorization"] = "Bearer " .. credentials["access_token"]
      },
      source = ltn12.source.string(request),
      sink = ltn12.sink.table(response_body)
   }
   print ("response_body")
   for a,b in pairs (response_body) do
      print (a,b)
   end
end

--function P.upload_image (credentials, imageFileName)
--  return P.upload_image (credentials, imageFileName, "https://picasaweb.google.com/data/feed/api/user/default/albumid/default")
--end

function P.listAlbums(credentials)
   local body ,code,headers ,status = https.request("https://photoslibrary.googleapis.com/v1/albums?access_token=" .. credentials["access_token"] )
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


return gphoto
