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

		packetList[i] 	= sub(packetMerged,1,splitter-1)
		packetList[i]	= {x,y,xpos,ypos,rotDeg,fired,health,peerid = packetList[i]:match("^(%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*)")}
		packetMerged 	= sub(packetMerged,splitter+1)
	end
	
	self.buffer[self.bufferLen] = {count, packetList}
end

function cBuffer:updateAndPop(dt)
	if self.bufferLen >= self.catchCount then
		self.bufferLen 		= self.bufferLen - 1
		local prepared	= table.remove(self.buffer,1)

		return prepared.count, prepared.packetList
	end
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