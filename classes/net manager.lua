netManager = class:new()

local createQ

local function getkey(k)
	local lk = love.keyboard
	if k == 'up' then
		return lk.isDown("w") or lk.isDown("up")
	elseif k == 'down' then
		return lk.isDown("s") or lk.isDown("down")
	elseif k == 'left' then
		return lk.isDown("a") or lk.isDown("left")
	elseif k == 'right' then
		return lk.isDown("d") or lk.isDown("right")
	end
end

function netManager:init(client)
	createQ				= {}
	self.client			= client
	self.peers			= {}
	self.player 		= nil
	self.area			= nil
	self.bullets		= nil	
	self.fired			= 0
	
	self.rcvCount		= -1
	self.rcvSize		= -1
	self.rcvTimer		= 0
	
	self.rcvSizeRate	= 0
	self.rcvRate		= 0
	
	self.buffer			= cBuffer:new(client, 0.1, 2)
	
	self._ready 		= false

	self.tSincePacket = {
		pMov 		= 0,
		posUpdate 	= 0,

		action = nil
	}
	
	if self.client.connected then
		print("Net manager initialized")
	else
		print("Net manager failed to initialize")
	end
end

function netManager:ready(player,area,bullets)
	self._ready 	= true
	self.player 	= player
	self.area		= area
	self.bullets	= bullets
	
	_G.peerPlayer:info(bullets)

	for peerid,name in pairs(createQ) do 
		self:createPeer(peerid)
		self.peers[peerid].peer.name = name == "" and nil or name
	end
	
	createQ = {}
	-- send server information about client	
	local packet = string.format("%s %s", "ID_2", player.name)
	self.client:send(packet)
	--self.client:send("ID_2"	..self.player.name) 	
end

function netManager:push(packet)
	self.buffer:push(packet)
end

function netManager:setName(name, peerid)
	if createQ[peerid] then
		createQ[peerid] = name
	end
end

-- create peer with its area, once more maps added 
function netManager:createPeer(peerid)
	--table.insert(self.createQ,{peerid})
	--[[]]
	if self._ready then
		self.peers[peerid] = {
			peer = _G.peerPlayer:new(400, 300, self.area, zombies, peerid)	
		}
	else
		--table.insert(createQ,peerid)
		createQ[peerid] = ""
	end
end

function netManager:dropPeer(peerid)
	self.peers[peerid] = nil
end

function netManager:update(dt)
	if not game.didhandshake then return false end
	
	--self.rcvTimer = self.rcvTimer + dt
	--self.rcvRate = self.rcvCount/self.rcvTimer
	self.rcvTimer = self.rcvTimer + dt
	if self.rcvTimer >= 1 then
		self.rcvTimer = 0
		
		self.rcvRate = self.rcvCount
		self.rcvCount = 0
		
		self.rcvSizeRate = self.rcvSize
		self.rcvSize = 0
	end
	local count,packetList = self.buffer:updateAndPop(dt)
	if packetList then
		for i = 1, count do
			local x,y,xpos,ypos,rotDeg,fired,health,peerid = packetList[i]:unpack()
			
			if self.peers[peerid] then
				local peer = self.peers[peerid].peer
				
				if peerid ~= self.client.id and peer then
					local tonumber	= tonumber
					peer.health 		= tonumber(health)
					peer.fired			= tonumber(fired) --== "1" and true or false	
					peer.r 				= rotDeg
					
					x,y 				= tonumber(x),tonumber(y)

					if x ~= 0 and y ~= 0 then
						x,y = x*0.65,y*0.65
					end	

					peer.xInput,peer.yInput = x,y	
				end
			else
				--[[
				self:createPeer(peerid)
				print(peerid.." has joined")
				]]
			end
			
		end
	end
	--[[
	local count,packetList = self.buffer:updateAndPop(dt)
	if packetList then
		for i = 1, count do
			local x,y,xpos,ypos,rotDeg,fired,health,peerid = packetList[i]:match("^(%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*)")
			
			if self.peers[peerid] then
				local peer = self.peers[peerid].peer
				
				if peerid ~= self.client.id and peer then
					local tonumber	= tonumber
					peer.health 		= tonumber(health)
					peer.fired			= tonumber(fired) --== "1" and true or false	
					peer.r 				= rotDeg
					
					x,y 				= tonumber(x),tonumber(y)

					if x ~= 0 and y ~= 0 then
						x,y = x*0.65,y*0.65
					end	

					peer.xInput,peer.yInput = x,y	
				end
			else
				--self:createPeer(peerid)
				--print(peerid.." has joined")
			end
			
		end
	end
	]]
	for peerid,data in pairs(self.peers) do
		data.peer:update(dt)
		
		for _,obj in ipairs(shash:getnearby(data.peer))  do
			--print("something near")
			if obj.type == "bullet" then
				--print("bullet near")
				if obj.active and obj.owner ~= data.peer.id then 
					local peer = data.peer
					local p = {r = peer.radius * 0.5, x = peer.pos.x	, y = peer.pos.y}
					local b = {r = obj.box.w	* 0.5, x = obj.pos.x	, y = obj.pos.y}

					if CircleCircleCollision(p, b) then
						local entryangle 	= (peer.pos - obj.pos):normalize()
						peer.entryoffset	= entryangle * p.r
						local entrypos 	= peer.pos - peer.entryoffset
						

						local dot 		= (entryangle.x*obj.dir.x + entryangle.y*obj.dir.y)
						
						local theta 	= math.acos(dot)
						local anglec 	= 180 - math.pi*theta
						local length 	= 2*(p.r * math.sin(anglec*0.5))
						local exitpos 	= entrypos + obj.dir * length

						
						peer:damaged(obj.damage,-obj.dir,entrypos)		--straight through, entry
						--self:damaged(obj.damage,obj.dir,exitpos)		--straight through, exit
						--self:damaged(obj.damage,entryangle,entrypos)	--angle to the bullet from zombie.pos

						peer.force = peer.force + (120*obj.dir)			--to do: lag=super knockback, 300fps = normal knockback variable knockback based on weapons
						obj.active = false
					end
					--[[					
					if quadsColliding(rotatebox(data.peer:getbodybox()), rotatebox(obj:gethitbox())) then
						data.peer:damaged(obj.damage,obj.dir,obj.pos+obj.dir:normalized()*10)
						data.peer.acc = data.peer.acc + 10*obj.dir			--to do: lag=super knockback, 300fps = normal knockback variable knockback based on weapons
						obj.active = false
					end]]
				end
			end
		end		
		--print(data.peer.pos.x)
	end

	if self.player then 
		self.tSincePacket.pMov = self.tSincePacket.pMov + dt
		
		if self.player.fired == true then
			self.fired = self.fired + 1
		end
		if self.tSincePacket.pMov > 0.05 then
			self.tSincePacket.posUpdate = self.tSincePacket.posUpdate + 1
			--local fired = self.player.fired == true and "1" or "0"
			local round	= math.round
			local player 	= self.player
			--[[
			local packet	= "ID_1"..round(player.pos.x,3)	..":"..		round(player.pos.y,3)..":"	-- change vel to acc
									..round(player.vel.x,3)		..":"..		round(player.vel.y,3)..":"	-- rounded to send less data
									..round(player.rotDeg,4)	..":"..		tostring(self.fired)..":"
									..round(player.health,3)
			local packet	= 
				string.format("%s %s %s %s %s %s %s %s", "ID_1", 
				round(player.pos.x,1)	,	round(player.pos.y,1),
				round(player.vel.x,2)	,	round(player.vel.y,2),
				round(player.rotDeg,3)	,	tostring(self.fired),
				round(player.health,3))]]
			--[[]]
			local x 	= (getkey("right") and 1 or 0) - (getkey("left") and 1 or 0)
			local y 	= (getkey("down") and 1 or 0) - (getkey("up") and 1 or 0)
			
			local packet
			
			if self.tSincePacket.posUpdate > 30 then
				print("yea")
				packet	= 
					string.format("%s %s %s %s %s %s %s %s", "ID_1", 
					x	,	y,
					round(player.pos.x,2)	,	round(player.pos.y,2),
					round(player.rotDeg,4)	,	tostring(self.fired),
					round(player.health,3))
				self.tSincePacket.posUpdate = 0
			else
				packet	= 
					string.format("%s %s %s %s %s %s %s %s", "ID_1", 
					x	,	y,
					0	,	0,
					round(player.rotDeg,4)	,	tostring(self.fired),
					round(player.health,3))
			end
				
			self.client:send(packet) 		
			self.fired = 0
			self.tSincePacket.pMov = 0
		end		
		
	end
	

	
end

function netManager:draw()
	for peerid,data in pairs(self.peers) do
		data.peer:draw()
	end
end

function netManager:numPeers()			
	local numberOfPeers = 0
	for peerid,_ in pairs(self.peers) do
		numberOfPeers = numberOfPeers + 1
	end
	return numberOfPeers+1					-- include self in count
end
