local json = require('json')
local https = require("ssl.https")
local socket = require("socket")

local P = {}
oauth2 = P   

P.CREDENTIALSFILE = os.getenv("HOME") .. "/credentials.json"
P.TOKENFILE = os.getenv("HOME") .. "/.goauth2.json"



function P.request_code (scope)
   local request = "response_type=code&client_id=" .. P.CLIENTID .. "&scope=" .. scope .."&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
   local body ,code,headers ,status = https.request("https://accounts.google.com/o/oauth2/v2/auth?" .. request)
   -- "verification_url" , "expires_in" , "interval" , "device_code" , "user_code" 
   --   for a,b in pairs (body) do
   --    print (a,b)
   --end
   --print ("body:" .. body)
   print ("https://accounts.google.com/o/oauth2/v2/auth?"..request)
   print ("code:" ..code)
   if code == 200 then
      local decoded = json.decode(body)
      print (body)
      return decoded
   end
end

function P.request_token (device_code)
   print ("request_token")
   local request =  "client_id=" .. P.CLIENTID .. "&client_secret=" .. P.CLIENTSECRET ..  "&code=" .. device_code .. "&grant_type=authorization_code&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
   print (request)
   local body ,code,headers ,status = https.request("https://www.googleapis.com/oauth2/v4/token", request)
   --"access_token" , "token_type" , "expires_in", "refresh_token"
   if code == 200 then
      local decoded = json.decode(body)
      print (body)
      return decoded
   end
end

function P.renew_token (refresh_token)
   local request = "client_id=" .. P.CLIENTID .. "&client_secret=" .. P.CLIENTSECRET .. "&refresh_token=" .. refresh_token .. "&grant_type=refresh_token"
   local body ,code,headers ,status = https.request("https://www.googleapis.com/oauth2/v4/token", request)
   --"access_token", "expires_in", "token_type"
   if code == 200 then
      local decoded = json.decode(body)
      return decoded
   else 
      print (request)
      print (code)
      print (headers)
      print (body)
   end 
end

local function create_token (scope)
   local url_to_show = "https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=" .. P.CLIENTID .. "&scope=" .. scope .."&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
   local code = P.request_code(scope)
   -- TODO check result is not null
   print (url_to_show)
   print ("code:")
   code = io.read()
   --  local tokeninfo = {}
   tokeninfo =  P.request_token ( code)
   -- TODO check result is not null
   return tokeninfo
end

local function file_exists(file)
   local f = io.open(file, "rb")
   if f then f:close()  end
   return f ~= nil
end

local function read_jsonfile (file)
   print (file)
   if not file_exists(file) then return {} end
   local temp = io.input()
   io.input (file)
   content = io.read("*all")
   if (not content) then return {} end
   local decoded = json.decode(content)
   io.close()
   io.input(temp)
   return decoded
end

local function write_token_json (file, tokeninfo)
   tokeninfo["timestamp"] = os.time()
   io.output (file)
   io.write(json.encode(tokeninfo))
   io.close()
end

function P.load_credentials ()
   local credentials = read_jsonfile(P.CREDENTIALSFILE)
   P.CLIENTID = (credentials["installed"])["client_id"]
   P.CLIENTSECRET = (credentials["installed"])["client_secret"]
end

function P.load_or_create_token (scope)
   --send empty table if it did not work
   local tokeninfo = read_jsonfile(P.TOKENFILE)
--   print (tokeninfo)
   if ((not tokeninfo) or not tokeninfo["access_token"] )  then
      --find token
      tokeninfo = create_token (scope)
      if (not tokeninfo["access_token"] )  then return tokeninfo end
      print (tokeninfo["access_token"])
      write_token_json (P.TOKENFILE, tokeninfo)
   else 
      print (os.time() .. " " .. tokeninfo["timestamp"] )
      if  (os.time() - tokeninfo["timestamp"] > tokeninfo["expires_in"]) then
	 print ("token expired")
	 local result = P.renew_token (tokeninfo["refresh_token"])
	 if (not result["access_token"] )  then return tokeninfo end
	 tokeninfo["access_token"] = result["access_token"]
	 tokeninfo["expires_in"] = result["expires_in"]
	 write_token_json (P.TOKENFILE, tokeninfo)
      else
	 print ("token ok")
      end
   end
   return tokeninfo
end

return oauth2
