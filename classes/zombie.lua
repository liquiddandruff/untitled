require "libs/AnAL"

local capturedspeed = 600
local walkAnim
local caughtAnim
local zombies
local player
zombie = actor:new()

function zombie:init(x, y, a, p, z)
	self.type		= "zombie"
	
	
	self.health 	= 100	
	
	self.pos 		= vec(x,y)	
	self.maxspeed 	= 1.5
	self.maxforce 	= 9		



	zombies 		= z
	player 			= p
	
	self.range 		= 60
	self.a			= {} 					--a = action, action list


	self.dir 		= math.random() * math.pi
	self.dirX 		= math.cos(self.dir)
	self.dirY 		= math.sin(self.dir)
	self.dur 		= math.random(1,3)

	self.caught 	= false
	self.hitwall 	= false

	self.tSinceIdle	= 0
	self.dOfIdle	= 0
	self.idling		= false

	self.area 		= a
	self.leftbound 	= a:left()		+25
	self.rightbound = a:right()		-25
	self.topbound 	= a:top()		+25
	self.botbound 	= a:bottom()	-25
	
	if not self.damagedEffect then
		print("Func zombie.damagedEffect loaded")
		self.damagedEffect = function(damage,dir,pos)
			self.health = math.max(self.health-damage,0)
		  --createblood(pos, amount, speedMin, speedMax, dir)
			if self.health > 0 then 
				createblood(pos, 50*damage, 100, 300+10*damage, dir,self)
			end
		end
	end
	
	
	if not walkAnim then
		walkAnim = newAnimation(images.zombie.walk, self.radius, self.radius, 0.1, 1)
		walkAnim:play()
	end
	if not caughtAnim then
		caughtAnim = newAnimation(images.zombie.walk, 53, 151, 0.1, 4)
		caughtAnim:play()
	end
	
	--[[
	self.dustParticles = love.graphics.newParticleSystem(images.dust, 25)
	self.dustParticles:setSpeed(5, 10)
	self.dustParticles:setSpread(math.rad(180))
	self.dustParticles:setSizes(0.9, 1.1, 1)
	self.dustParticles:setPosition(self.pos.x, self.pos.y)
	self.dustParticles:setDirection(self.r+math.pi)
	self.dustParticles:setLifetime(-1)
	self.dustParticles:setEmissionRate(6)
	self.dustParticles:setParticleLife(1.50)
	self.dustParticles:setSpin(0.1, 1.0, 1)
	self.dustParticles:setColors(255, 255, 255, 225, 255, 255, 255, 0)
	self.dustParticles:start()
	]]
end

function zombie:Update(dt)	
	walkAnim:update(dt)
	caughtAnim:update(dt)
	--self.dustParticles:update(dt)

	if self.alive then		
		for _,obj in ipairs(shash:getnearby(self))  do		--todo: move to function
			if obj.type == "zombie" then
				self.pos = self.pos + self:nooverlap(obj)
			elseif obj.type == "bullet" then
				if obj.active then 
					-- todo: maybe ditch quads colliding and do collision check based on bullets distance from center of zombie (radius)
					local z = {r = self.radius	* 0.5, x = self.pos.x	, y = self.pos.y}
					local b = {r = obj.box.w	* 0.5, x = obj.pos.x	, y = obj.pos.y}

					if CircleCircleCollision(z, b) then
						local entryangle	= (self.pos - obj.pos):normalized()
						self.entryoffset	= entryangle * z.r
						local entrypos 	= self.pos - self.entryoffset
						

						local dot 		= (entryangle.x*obj.dir.x + entryangle.y*obj.dir.y)
						
						local theta 	= math.acos(dot)
						local anglec 	= 180 - math.pi*theta
						local length 	= 2*(z.r * math.sin(anglec*0.5))
						local exitpos 	= entrypos + obj.dir * length

						
						self:damaged(obj.damage,-obj.dir,entrypos)		--straight through, entry
						--self:damaged(obj.damage,obj.dir,exitpos)		--straight through, exit
						--self:damaged(obj.damage,entryangle,entrypos)	--angle to the bullet from zombie.pos

						self.force = self.force + (250*obj.dir)			
						obj.active = false
					end
					--[[
					if quadsColliding(rotatebox(self:getbodybox()), rotatebox(obj:gethitbox())) then
						--self:damaged(obj.damage,obj.dir,obj.pos+obj.dir:normalized()*50)--math.random(2,15))
						self:damaged(obj.damage,obj.dir,obj.pos+obj.dir:normalized()*10)
						self.acc = self.acc + 10*obj.dir			--to do: lag=super knockback, 300fps = normal knockback variable knockback based on weapons
						obj.active = false
					end		]]			
				end
			end
		end
		
		if self.entryoffset then
			self.entrypos = self.pos - self.entryoffset
		end
		--[[
		self.a.wandering 	= false
		self.a.seeking		= false
		self.a.arriving		= false
		self.a.fleeing		= false]]
		self.a = {current = "Idle"}		
		
		if not dbgl.zombiefreeze then
			--[[]]
			--local distToPlayer = self:disttotarget(player.pos)
			local distToPlayer = (self.pos - player.pos):len()
			--[[]]
			if self.health > 40 then
				if distToPlayer < 300 then 
					--	aware of player, pursue 
					self.a.pursuing		= true	
					self.a.current 		= "Pursuing"	
					self.maxspeed 		= 240
					self.maxforce 		= 12

					self:pursue(player)
					
					if distToPlayer<50 then
						self.vel = vec(0,0)
						self.pos = self.pos + self:nooverlap(player)
					end
				else
					-- wander
					self.a.wandering 	= true		
					self.a.current 		= self.idling and "Idling" or "Wandering"
					self.maxspeed 		= 180
					self.maxforce 		= 9
					
					self:wander(dt) 			--todo: fix wander changing directions too aruptly
					
				end
			else
				if distToPlayer < 250 then 
					-- aware of player, flee
					self.a.fleeing 		= true		
					self.a.current		= "Fleeing"
					self.maxspeed 		= 270
					self.maxforce 		= 15

					self:flee(player)
				else
					-- injured wander
					self.a.wandering 	= true	
					self.a.current		= "Wandering"
					self.maxspeed 		= 210
					self.maxforce 		= 6
					
					self:wander(dt)
				end
			end--[[
			local velMag	= self.vel:len()

			if velMag > 0.001 then
				local acc_after_friction = self.acc - self.heading*11--greater = more friction
				if velMag - acc_after_friction:len()*dt*60 < 0.001 then
					self.vel 		= vec(0,0)
				else
					self.acc 		= acc_after_friction 
				end
			end
			]]

			self.vel 	= self.vel + (self.acc + self.steerForce) * dt + self.force
			self.pos 	= self.pos + self.vel * dt
			
			self.force 	= vec(0,0)
			self.acc 	= vec(0,0)
		end
		
		
		self.facing = self.vel.x < 0 and -1 or 1		
		
		
		shash:hash(self)
	else
		createblood(self.pos, 600, 100, 500, 0)
		player:gainexp(10)
	end
	--self.facing = (self.dirX < 0) and -1 or 1  -- dirX = -1 to 1 	assignement :: -1 = left   1 = right
	

	--constrain to area
	--[[
	self.pos.x = math.max(self.pos.x, self.area:left()+38)
	self.pos.x = math.min(self.pos.x, self.area:right()-38)
	self.pos.y = math.max(self.pos.y, self.area:top()+70)
	self.pos.y = math.min(self.pos.y, self.area:bottom()-70)	]]
	--self.pos.x = clamp(self.pos.x,	self.area:left()+38,	self.area:right()-38)	
	--self.pos.y = clamp(self.pos.y, self.area:top()+70,	self.area:bottom()-70)	
	--self.pos.x = clamp(self.pos.x,	self.leftbound,	self.rightbound)						-- 1.7 microseconds
	--self.pos.y = clamp(self.pos.y, self.topbound,	self.botbound)
	
	local newpos = self.pos										--localing self.pos trims off .1 microsecond
	if newpos.x < self.leftbound then								--0.7 micro seconds
		newpos.x = self.leftbound
	elseif newpos.x > self.rightbound then
		newpos.x = self.rightbound
	end
	if newpos.y < self.topbound then			--if newpos.y is higher than top | top to bottom = 0 to 1000
		newpos.y = self.topbound
	elseif newpos.y > self.botbound then	--if newpos.y is lower than top | bottom to top = 1000 to 0
		newpos.y = self.botbound
	end
	self.pos = newpos
	

	
	--self.dustParticles:setPosition(self.pos.x, self.pos.y)
	--self.dustParticles:setDirection(self.r+math.pi)
	--[[
	if self.pos.x ~= x or self.pos.y ~= y then
		--we ran into a wall
		self.hitwall = true
		--player loses control now
		if self.caught then
			self.caught.gripping = false
			self.caught.cb(false)
			self.caught = false 
		end
	end]]
	
end

function zombie:draw() 
	local currAnim = walkAnim
	--if self.caught then currAnim = caughtAnim end
	--return { x = self.pos.x-25, y = self.pos.y-25, w = 50, h = 50, r = self.r, ox = 25, oy = 25 }
	-- x,y,rotation,xflip,yflip,xoffset,yoffset | self.r 						self.facing direction 1 = right -1 left --,currAnim.fw/2,currAnim.fw/2	-- second param should be currAnim.fh/2
	--currAnim:draw(math.round(self.pos.x),math.round(self.pos.y),self.r,1,1,25,25) 
	currAnim:draw(self.pos.x,self.pos.y,self.r,1,1,25,25) 
	
	--lg.point(self.pos.x,self.pos.y)
	--local action = self.a.wandering and "Wandering" or (self.a.seeking and "Chasing" or "Fleeing")
	
	local c1,c2,c3 = lg.getColor()
	
		lg.setColor(0,0,0)
		
		local healthdisp 	= "Health: "..self.health
		local actiondisp	= "Action: "..self.a.current
		--local veldisp		= "Velocity: "..self.vel:len()
		local sFont	= font["small"]
		
		local printxloc	= self.pos.x-sFont:getWidth(healthdisp)*0.5
		local printyloc	= self.pos.y+self.radius*0.5
		--[[]]
		--lg.setFont(font["default"])
		lg.print(healthdisp		,printxloc		,printyloc)	
		lg.print(actiondisp		,printxloc		,printyloc+sFont:getHeight())
		--lg.print(veldisp		,printxloc		,printyloc+sFont:getHeight()*2)
		
		
		--lg.circle("line",self.pos.x,self.pos.y,26,40)
		
	lg.setColor(c1,c2,c3)
	
	
	
	--self:wanderdraw()
	
	if release then return end
	
	
	lg.draw(self.dustParticles, 0, 0)
	
	--lg.print("Dist to Player: "..self.disttodest,self.pos.x-10,self.pos.y-60)
	
	lg.rectangle("line",self.pos.x-25,self.pos.y-25,50,50)
	
	
	-- Wander Debug
	
	--lg.print("i am in buckets: "..shash:inbuckets(self),self.pos.x,self.pos.y)
	
	
	--lg.rectangle("line",self.pos.x-17,self.pos.y-50,35,25)--head
	--slg.rectangle("line",self.pos.x-25,self.pos.y-25,50,50)--body	self.pos.x-20,self.pos.y-25,35,50)		--20 right 14 left
	--lg.rectangle("line",self.pos.x-17,self.pos.y+25,35,75)--legs
	--lg.rectangle("line",self.box.x,self.box.y,self.box.w,self.box.h)
end


--[[
function zombie:move(mode,target,deltatime)
	local dt = deltatime
	local x,y,r
	local obslist={}	--obstruction list

	if mode == 1 then									--  1 	=	eat
		self.mode = 1
		x,y = 	target.x,target.y	
		r 	=	math.atan2(y-self.pos.y,x-self.pos.x)
		

		for _,obj in ipairs(shash:getnearby(self))  do
			if obj ~= self and obj.type == "zombie" then
				if self:disttotarget(obj) -self.range <= 0 then
				--if self.range+obj.range - self:disttotarget(obj) > 0 then
					table.insert(obslist,obj)
				end
			end
		end
		
		--for _,v in ipairs(zombies) do
		--	if v ~= self then
		--		if self:disttotarget(v) -self.range <= 0 then
		--			table.insert(obslist,v)
		--		end
		--	end
		--end
		
		self.dir 	= r+0.08*math.random()--r
		self.dirX 	= math.cos(self.dir)
		self.dirY 	= math.sin(self.dir)
		
		if obslist then
			for _,obj in ipairs(obslist) do
				local x,y 		= 	obj.x,obj.y
				local r			=	math.atan2(y-self.pos.y,x-self.pos.x)
				
				self.dirX 	= 	self.dirX - math.cos(r)
				self.dirY 	= 	self.dirY - math.sin(r)				--move away from obstruction 	
			end
		end
	elseif mode == -1 then								
		x,y = 	target.x,target.y
		r 	=	math.atan2(y-self.pos.y,x-self.pos.x)
		
		self.dir = r+0.08*math.random()---r
		
		self.dirX = self.dirX-math.cos(self.dir)
		self.dirY = self.dirY-math.sin(self.dir)
	end
	
	
	if (self:disttotarget(player) - self.range > 1) and self.hasroom then
		self.pos.x = self.pos.x + self.dirX*self.maxspeed*dt
		self.pos.y = self.pos.y + self.dirY*self.maxspeed*dt
	elseif (self:disttotarget(player) - self.range < -1) and self.hasroom then
		self.pos.x = self.pos.x - self.dirX*self.maxspeed*dt
		self.pos.y = self.pos.y - self.dirY*self.maxspeed*dt
	end
end
]]