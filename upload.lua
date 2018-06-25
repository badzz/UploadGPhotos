#!/usr/bin/lua
--require("mobdebug").start()

local oauth2 = require ("oauth2")
local gphoto = require ("gphoto")
local lfs = require"lfs"


local listImages = {}

function findJPGFiles (path)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
--            print ("\t "..f)
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
            if attr.mode == "directory" then
                findJPGFiles (f)
            else
 		       local upper = f:upper()
			   if (upper:sub(upper:len()-2) == "JPG") then
				 listImages[f]=attr["size"]
			   end
--                for name, value in pairs(attr) do
--                    print (name, value)
--                end
            end
        end
    end
	return listImages
end
oauth2.load_credentials()
local token = oauth2.load_or_create_token (gphoto.SCOPE)

--gphoto.listAlbums(token)
gphoto.upload_image (token,"DSC04501.JPG")
--picasa.upload_image(token, Filename, Album Name , Album URL)

-- picasa.upload_image(token, "/root/4.jpg", "Drop Box")
-- picasa.upload_image(token, "/root/4.jpg")


--local listImages = findJPGFiles(".")
--for name, value in pairs(listImages) do
--		picasa.upload_image(token, name, albumid)
--end
