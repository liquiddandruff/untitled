local socket = require "socket"

clientUdp = class:new()

function clientUdp:init(host, port)
	self.host 			= host
	self.port 			= port
	self.handshake 		= "ID_HS"
	self.ping 			= {msg = "!", time = 4, timer = 4}

	self.connected 		= false
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
	return self.socket:sendto(data, self.host, self.port)
end

function clientUdp:receive()
	local data, ip, port = self.socket:receivefrom()
	if ip == self.host and port == self.port then
		return data
	end
	return false, "Unknown remote sent data."
end	

function clientUdp:update(dt)
	if not self.connected then return end

	-- Handle ping messages.
	self.ping.timer = self.ping.timer + dt
	if self.ping.timer > self.ping.time then
		self.socket:sendto(self.ping.msg, self.host, self.port)
		self.ping.timer = 0
	end
	
	local data, err = self:receive()

	-- Is the client actually connected? Is there any data to process?
	if not game.didHandshake and data then
		local hs, id = data:match("^(%S*) (%S*)$") 
		
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
		self.recvCallback(data)
		data, err = self:receive()
	end
end