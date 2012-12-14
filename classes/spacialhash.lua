--create hashclass
spacialhashclass = class:new()
--localize time-critical function calls
local insert,floor = table.insert,math.floor
--setup parameters
function spacialhashclass:init()
end

function spacialhashclass:Init(areax,areay,areawidth,areaheight,bucketsize)
	self.xpos,self.ypos		=	areax,areay
	self.columns,self.rows	=	floor(areawidth/bucketsize),floor(areaheight/bucketsize)
	self.bucketsize 		= 	bucketsize
	self.hashed				=	0

	self.buckets 			= 	{}
	self.objinbucket		=	{}

    for i = 0,self.columns*self.rows do
        --table.insert(self.buckets,{})
		self.buckets[i]={}
	end
	
end

--clear the hash table each frame
function spacialhashclass:update()
	--[[
	--local timer = love.timer
	--local t1 = love.timer.getMicroTime()
	--local count =0]]
	for bucket,_ in pairs(self.objinbucket) do		-- worse if a lot of hashed, good if big map
		--count = count + 1
		--print("objinbucket: "..bucket)
		self.objinbucket[bucket] = nil
		self.buckets[bucket] = {}
	end
	
	--[[
	print(count)
	local t2 = timer.getMicroTime()
	print("A: "..t2-t1)
	local t1 = timer.getMicroTime()
    for i = 0,self.columns*self.rows do				-- worse if big map, good if a lot of hashed
        --table.insert(self.buckets,{})
		self.objinbucket[i] = nil
		self.buckets[i]={}
	end	]]
	--[[
	local t2 = timer.getMicroTime()
	print("B: "..t2-t1)]]
end

--debug, draws each bucket
function spacialhashclass:draw()
	local lg 		= lg
	local drawRect = lg.rectangle
	local bSize 	= self.bucketsize
	
	local c1,c2,c3 = lg.getColor()
	local lw 		= lg.getLineWidth()
	
		lg.setColor(25,25,112)
		lg.setLineWidth(2)
		
		for x = 1,10 do
			for y = 1,10 do
				drawRect("line",self.xpos,self.ypos,bSize,bSize)
				self.ypos = self.ypos+bSize
			end
			self.ypos=-bSize
			drawRect("line",self.xpos,self.ypos,bSize,bSize)
			self.xpos = self.xpos+bSize
		end
		self.xpos=-bSize
	
	lg.setColor(c1,c2,c3)
	lg.setLineWidth(lw)
end

--get the objects that are in this object's bucket
function spacialhashclass:getnearby(object)	--bulletsnearby
	object._hashedID = true
	local objects,buckets = {}, self:getidforobj(object.box)

	--local txtbuckets = ""
	for _,bucket in ipairs(buckets) do
		--txtbuckets=txtbuckets..bucket.." "
		if self.buckets[bucket] then 
			for _,obj in ipairs(self.buckets[bucket]) do
				--objects[#objects+1] = obj
				--prevent returning self
				if not obj._hashedID then 
					insert(objects,obj)
				end	
			end	
		end
	end
	
	object._hashedID = false
	--[[print(object.type.." "..txtbuckets)

	for _,obj in ipairs(objects) do
		if obj.type ~= "player" then
			print("Objects near me: "..obj.type)
		end
	end]]
	
	return objects
end

--hash object to bucket(s)
function spacialhashclass:hash(object)
	local buckets = self:getidforobj(object.box)
	self.hashed = self.hashed + 1

	for _,bucket in ipairs(buckets) do
		--table.insert(self.buckets,bucket,object)
		
		if self.buckets[bucket] then 					--check if the bucket is valid
			self.objinbucket[bucket] = 1
			--table.insert(self.objinbucket,bucket)
			insert(self.buckets[bucket],object) 
			
		end

	end 
end

--[[
taverage = {}
taverage[1] = 0
taverage[2] = 0]]
--interal function, returns the bucket(s) that the object occupies
function spacialhashclass:getidforobj(object)
	local bucketsobjisin		= {}
	--local t1 = love.timer.getMicroTime()
	--bounding box of the object
	
	local objectX = object.x
	local objectY = object.y
	local objectW = object.w
	local objectH = object.h
	
	local tl	= {x = objectX				, y = objectY			}
	local tr	= {x = objectX + objectW	, y = objectY 			}
	local bl	= {x = objectX				, y = objectY + objectH	}
	local br	= {x = objectX + objectW	, y = objectY + objectH	}

	--Top Left
	self:addbucket(tl	, bucketsobjisin);
	--Top Right
	self:addbucket(tr	, bucketsobjisin);
	--Bottom Left
	self:addbucket(bl	, bucketsobjisin);		
	--Bottom Right
	self:addbucket(br	, bucketsobjisin);

	
	--[[
	local t2 = love.timer.getMicroTime()
	taverage[1] = taverage[1] + (t2-t1)
	taverage[2] = taverage[2] + 1
	print(taverage[1]/taverage[2])
	]]
	
	return bucketsobjisin
end

function spacialhashclass:addbucket(vec2,buckettoaddto)
	local bucketsize 	= self.bucketsize
	local cellpos 		= floor(vec2.x/bucketsize) + floor(vec2.y/bucketsize) * self.columns--areawidth/bucketsize

	--[[]]
	if cellpos >= 0 then
		if not buckettoaddto[cellpos] then					--don't add cell more than once				
			buckettoaddto[cellpos] = true
			insert(buckettoaddto,cellpos)
		end
	end
	--[[
	if not table.contains(buckettoaddto,cellpos) then				-- 1.25 microseconds
		insert(buckettoaddto,cellpos)
	end]]
end

return spacialhashclass:new()