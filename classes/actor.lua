require "libs/AnAL"

actor = class:new()

local wanderRadius		= 25	-- 	Radius for our "wander circle"
local wanderDistance 	= 50	-- 	Distance for our "wander circle"
local wanderJitter		= 900	--	Jitter

local weightSeparation = 300
local weight = {wallavoidance = 0.1, flee = 0.2, seek = 0.2, wander = 0.2, pursue = 0.2, separation = 300}


function actor:calcSteer()
	self.steerForce 	= vec(0,0)
	--self.force		 	= vec(0,0)
	
	self:calcPrioritized()
	
	--return self.steerForce
end

function actor:accumulateForce(forceToAdd)
	local currentMag = self.steerForce:len()
	local magRemaining = 200*60 - currentMag

	if magRemaining <= 0 then return false end

	local magToAdd = forceToAdd:len()
	
	if magToAdd < magRemaining then
		self.steerForce = self.steerForce + forceToAdd
		return true
	else
		self.steerForce = self.steerForce + forceToAdd:normalized()*magRemaining
		return false
	end	
	
end

function actor:calcPrioritized()
	local behaviour = self.behaviour
	local force = vec(0,0)

	--wall
	--force = self:wallAvoidance() * weight["wallavoidance"]
	--if not self:accumulateForce(force) then return self.steerForce end

	--separation
	if behaviour.separate then
		force = self:separation() * weightSeparation
		if not self:accumulateForce(force) then return end
	end
	if behaviour.fleeing1 then
		force = self:flee() * weight.flee
		if not self:accumulateForce(force) then return end
	end
	if behaviour.seeking1 then
		force = self:seek() * weight.seek
		if not self:accumulateForce(force) then return end
	end
	if behaviour.wandering1 then
		force = self:wander() * weight.wander
		if not self:accumulateForce(force) then return end
	end
	if behaviour.pursuing1 then
		force = self:pursue() * weight.pursue
		if not self:accumulateForce(force) then return end
	end	
end

function actor:separation()
	local x,y 		= self.area:center() 
	local force 	= vec(0,0)
	
	for _,obj in ipairs(shash:getnearby(self))  do		--todo: move to function
		if obj.type == "zombie" then
			local toZombie = self.pos - obj.pos
			local toZombieLen2 = toZombie:len2()
			
			if toZombieLen2 > 0 then
				--force = force + toZombie:normalized()toZombieLen
				force = force + toZombie/(toZombieLen2)
				obj.force = obj.force - force
			else
				self.force = self.force + (vec(x,y) - self.pos):normalized() * 3.5
			end
		end
	end
	
	return force * 60
end

function actor:init()
	self.name 			= "actor"
	self.alive			= true	
	
	--rotation
	self.r 				= 0	
	self.radius			= 49					-- diameter actually	
	self.box			= {w = 60, h = 60}
	
	self.vel 			= vec(0,0)	
	self.acc 			= vec(0,0)	
	
	self.behaviour		= {idle = false, separate = true, wandering = true, pursuing = true, fleeing = true}
	self.wanderTarget 	= vec(0,0)
	self.force 			= vec(0,0)
	self.steerForce		= vec(0,0)
	self.heading 		= vec(0,0)
	
	self.circleoffsetr 	= 0
end

function actor:update(dt)
	self.box.x = self.pos.x - 30; self.box.y = self.pos.y - 30; 
	
	local vel = self.vel
	
	if vel:len2() > 0 then
		self.heading = vel:normalized()
	else
		self.heading = vec(0,0)
	end
	
	self.alive	= self.health > 0 and true or false
	
	if self.type == "zombie" then 
		self:calcSteer()	
	end
	
	self:Update(dt)
end

function actor:draw() 

end


function actor:getbodybox()
		 --{ x = self.pos.x-20, y = self.pos.y, w = 66, h = 96, r = self.r, ox = 20, oy = 0 }
	return { x = self.pos.x-25, y = self.pos.y-25, w = 50, h = 50, r = self.r, ox = 25, oy = 25 }
end

function actor:nooverlap(obj)
	local toObj 	= self.pos - obj.pos
	local toObjLen = toObj:len()	
	local mindist 	= self.radius		--radius is diameter .: radius + radius = dist

	
	if toObjLen < mindist and toObjLen > 0 then
		local overlap = mindist - toObjLen
		return (toObj/toObjLen)*overlap
	else
		return vec(0,0)
	end

end
--[[
function actor:nooverlap(obj)
	local toobj = self.pos - obj.pos
	local toObjLen = toobj:len()
	
	if toObjLen > 0.2 then
		local overlap = self.radius - toObjLen
		return overlap > 0 and (toobj/toObjLen)*overlap or vec(0,0)
	else
		return vec(1,0) * self.radius*0.5
	end

end
--]]
--optimize
function actor:disttotarget(target)
	local selfpos 	= self.pos
	local x, y 	= target.x,target.y
	
	x 				= selfpos.x - x
	y 				= selfpos.y - y
	
	return (x*x+y*y)^0.5		--dist
end

function actor:disttosurround(target)
	return self:disttotarget(target) - self.range --surround target with radius of self.range
end

function actor:pursue(evader)
	local toEvader = evader.pos - self.pos
	--[[
	local selfvelnormal = self.vel:normalized()
	local evadervelnormal = evader.vel:normalized()
	
	local RelativeHeading = selfvelnormal.x * evadervelnormal.y + selfvelnormal.y * evadervelnormal.y

	
	
	if ( (ToEvader:dot(selfvelnormal) > 0) and (RelativeHeading < -0.95)) then --acos(0.95)=18 degs
		self:seek(evader);
		return
	end]]

	local LookAheadTime = toEvader:len2() / (self.maxspeed + evader.vel:len2())
  



	self:seek({pos = evader.pos + evader.vel * math.sqrt(LookAheadTime)})
end

function actor:seek(target)
    self.acc = self.acc + self:steer(target,false)
	
	--local desired = target.pos-self.pos
	self.r = math.atan2(self.heading.y,self.heading.x)
end

function actor:flee(target)
    self.acc = self.acc + self:steer(target,false)
	
	self.r = math.atan2(self.heading.y,self.heading.x) 
end

function actor:arrive(target)
    self.acc = self.acc + self:steer(target,true)
	
	self.r = math.atan2(self.heading.y,self.heading.x)
end

function actor:wander(dt)
	self.wandering 		= true
	
	if not self.idling then
		self.tSinceIdle		= self.tSinceIdle + dt
		
		local random = math.random
		random()
		
		if self.tSinceIdle > (random(5,11) + self.dOfIdle) and random(-123,123) == 0 then
			self.tSinceIdle = 0
			self.dOfIdle	= random(2,4)
			self.idling 	= true
		end
		
		local jitter 		= dt * wanderJitter
		self.wanderTarget 	= self.wanderTarget + vec(randomClamped() * jitter, randomClamped() * jitter)


		self.wanderTarget 	= self.wanderTarget:normalized() * wanderRadius -- + 
		local target	 	= {pos = self.wanderTarget + self.pos } --+ vec(dbgl.wanderd,0) --supposed to add then do stuff with matrix
		--if self.vel:len2() > 0 then
			target.pos = target.pos + self.heading * wanderDistance
		--end
		self.wanderTargetPos = target.pos

		self.acc = self.acc + self:steer(target,false)  -- Steer towards it

		--local desired = target.pos-self.pos
	else
		self.dOfIdle		= self.dOfIdle - dt
		self.maxforce		= self.maxforce * 0.15
		self.acc 			= self.acc + self:steer({pos = self.pos},true)
		if self.dOfIdle <= 0 then
			--self.maxforce = 0
			--tween(4, self, { maxforce = 9 }, "inQuad")
			self.idling = false
		end
	end
		
	self.r = math.atan2(self.heading.y,self.heading.x)   
end

function actor:steer(target,slowdown)
	local slowdown_distance 	= 150 --preferred slowdown_distance + distance
	local steer 				= vec(0,0)
	local desired 				= target.pos-self.pos

	local distance = desired:len()
	--fix div by 0
	desired:normalize()
	
	if slowdown and (distance < slowdown_distance) then
		desired = desired * (self.maxspeed*(distance/slowdown_distance))-- sticky actor: (5*self.maxspeed*(distance/slowdown_distance))
	else
		desired = desired * (self.maxspeed)
	end
	
	steer = self.a.fleeing and -desired-self.vel or desired-self.vel
	--print("Mag before trunc	: "..steer:len())	
	steer:trunc(self.maxforce)
	--print("Mag after trunc		: "..steer:len())

	return steer * 60
end

function actor:wanderdraw()
	if self.a.wandering then
		local c1,c2,c3 	= lg.getColor()
		local psize		= lg.getPointSize()
		local lwidth		= lg.getLineWidth()
		
			lg.setColor(0,0,0)
			lg.setPointSize(4)
			--lg.setLineWidth(2)
			local circleCenter = self.pos + self.heading*dbgl.wanderd
			lg.circle("line",circleCenter.x,circleCenter.y,dbgl.wanderr,15)
			lg.setColor(255,0,0)
			lg.point(self.wanderTargetPos.x,self.wanderTargetPos.y)
			
		lg.setLineWidth(lwidth)
		lg.setPointSize(psize)
		lg.setColor(c1,c2,c3)
	end
end

function actor:damaged(damage,dir,pos)
	if self.damagedEffect then
		self.damagedEffect(damage,dir,pos)
		return
	end
	if not dbgl.zombiefreeze then 
		self.health = math.max(self.health-damage,0)
	end
	if pos then 
		createblood(pos, 200, 50, 300,dir)
	else
		createblood(self.pos, 200, 50, 300,dir)
	end
end