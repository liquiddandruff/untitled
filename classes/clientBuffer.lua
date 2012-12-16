cBuffer = class:new()

local client = nil
local getTime = love.timer.getTime

function cBuffer:init(xclient, catchTime, catchCount)
	client 			= xclient
	self.buffer 	= {}
	self.catchTime 	= catchTime
	self.catchCount	= catchCount
	self.bufferLen	= 0
end

function cBuffer:push(packetBody)
	self.bufferLen = self.bufferLen + 1
	
	local packetMerged	= packetBody
	local packetList 	= {}
	
	local _, count 	= string.gsub(packetMerged, "|", "|")	
	local sub 			= string.sub
	local splitter
	
	for i = 1, count do 
		splitter 		= string.find(packetMerged,"|")

		local packet 	= sub(packetMerged,1,splitter-1)
		
		local peerPacket, peerId = packet:match("(.-) (%S+)$")
		
		-- Does this peer exist in our history? If so, insert new packet from peer to table. If not, make new table with packet.
		if self.buffer[peerId] then
			table.insert(self.buffer[peerId],peerPacket)
		else
			self.buffer[peerId] = {peerPacket}
		end
		
		--local x,y,xpos,ypos,rotDeg,fired,health,peerid = packetList[i]:match("(%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*)$")
		--packetList[i]	= {packetList[i]:match("(%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*)$")}	
		--print(packetList[i].x,packetList[i].y,packetList[i].xpos,packetList[i].ypos,packetList[i].rotDeg,packetList[i].fired,packetList[i].health,packetList[i].peerid)
	
		packetMerged 	= sub(packetMerged,splitter+1)
	end
	
	--self.buffer[self.bufferLen] = {count, packetList}
end

function cBuffer:updateAndPop(dt)
	local peerCount, packetList = 0, {}
	
	for peerId, peerPacketList in pairs(self.buffer) do
		if #peerPacketList >= self.catchCount then
			peerCount = peerCount + 1
			packetList[peerId] = table.remove(self.buffer[peerId],1)		-- table.remove(peerPacketList,1)
		end
	end
	
	return peerCount, packetList
--[[
	if self.bufferLen >= self.catchCount then
		self.bufferLen 	= self.bufferLen - 1
		print("BufferLEN: ",self.bufferLen)
		local tick1	= table.remove(self.buffer,1)
		local tick2	= self.buffer[1]
		local tick3	= self.buffer[2]

		return tick1[1], tick1[2], tick2[1], tick2[2], tick3[1], tick3[2]
	end]]
end

--[[
function cBuffer:push(packetBody)
	self.bufferLen = self.bufferLen + 1
	
	self.buffer[self.bufferLen] = {packet = packetBody,cTime = getTime()}
end

function cBuffer:updateAndPop(dt)
	if self.bufferLen >= self.catchCount then
		self.bufferLen 		= self.bufferLen - 1
		local packetMerged	= table.remove(self.buffer,1).packet
		local packetList 	= {}
		
		local _, count 	= string.gsub(packetMerged, "|", "|")	
		local sub 			= string.sub
		local splitter
		
		for i = 1, count do 
			splitter 		= string.find(packetMerged,"|")

			packetList[i] 	= sub(packetMerged,1,splitter-1)
			packetMerged 	= sub(packetMerged,splitter+1)
		end
		
		return count, packetList
	end
end

]]