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
	
		packetMerged 	= sub(packetMerged,splitter+1)
	end
end

function cBuffer:updateAndPop(dt)
	local peerCount, packetList = 0, {}
	
	for peerId, peerPacketList in pairs(self.buffer) do
		if #peerPacketList >= self.catchCount then
			peerCount = peerCount + 1
			-- since first entry is removed, list[2] becomes list[3]
			packetList[peerId] = {table.remove(self.buffer[peerId],1),peerPacketList[1],peerPacketList[2]}
		end
	end
	
	return peerCount, packetList
end