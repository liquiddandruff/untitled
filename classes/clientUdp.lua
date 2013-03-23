local socket = require "socket"

clientUdp = class:new()

function clientUdp:init(host, port)
	self.host 			= host
	self.port 			= port
	self.handshake 		= "ID_HS"

	self.connected 		= false
	self.ping			= nil
	self.pingMsg		= "!"
	
	self.id 			= nil
	self.recvCallback 	= nil
	self.socket 		= nil

	self:connect()
end

function clientUdp:connect()
	-- Dns resolution currently not needed. Set up connection.
	self.connected 	= true
	self.socket = socket.udp()
	self.socket:settimeout(0)

	-- Send handshake.
	local packet = string.format("%s %s", self.handshake, "+\n")
	self:send(packet)
end

function clientUdp:disconnect()
	if self.connected then
		local packet = string.format("%s %s", self.handshake, "-\n")
		self:send(packet)
		self.host = nil
		self.port = nil
	end
end

function clientUdp:send(data)
	-- Check if we're connected and pass it on.
	if not self.connected then
		return false, "Not connected"
	end
	 print("clientUdp:send:", data)
	return self.socket:sendto(data, self.host, self.port)
end

function clientUdp:receive()
	local data, ip, port = self.socket:receivefrom()
	if ip == self.host and port == self.port then
		print("clientUdp:receive", data)
		return data
	end
	return false, "Unknown remote sent data."
end	

function clientUdp:update(dt)
	if not self.connected then return end

	local data, err = self:receive()

	-- Is the client actually connected? Is there any data to process?
	if not game.didHandshake then
		local hs, id

		if data then
			hs, id = data:match("^(%S*) (%S*)$") 
		end
		
		if hs == self.handshake then
			game.didHandshake = true
			self.id = id
			print("Connection successful - Assigned ID is: "..self.id)
		end
		
		if love.timer.getTime() - game.connectTime > 2 then
			self.connected = false
			print("Connection failed - The server is unavailable at this time.")
		end
	end
	
	while data do
		--print(string.sub(data, 1, 1), data, string.sub(data, 2))
		if string.sub(data, 1, 1) == self.pingMsg then
			self.ping = string.sub(data, 2)
			self:send(self.pingMsg)
		else
			self.recvCallback(data)
		end
		data, err = self:receive()
	end
end