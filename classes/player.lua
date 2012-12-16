require "libs/AnAL"

local zombies
local camera

--require("classes/projectiles/bullet")
local lassospeed = 10
local lassothrowspeed = 10
local ropelength = 300
local ropelengthSq = ropelength^2

local idleAnim
local walkAnim
local spinAnim
local currAnim
--bullets = nil
player = actor:new()



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

function player:init(x, y, a, z, name, cam)		--radius and box moved to actor
	self.type 			= "player"
	self.name			= name
	
	self.invuln			= 0
	self.lvl			= 1
	self.exp			= 0
	self.health			= 200
	
	self.pos 			= vec(x,y)	
	self.rotRad			= vec(0,0)
	self.rotDeg			= 0	
	self.maxspeed 		= 360			--300  	350	/dt(100) 	= 35 pixels per 
	self.maxforce		= 24			--60	/dt(100) 	= 0.6 pixels max acceleration


	self.fired			= false	
	zombies 			= z
	camera				= cam

	
	
	self.area 			= a
	
	if not self.damagedEffect then
		print("Func player.damagedEffect loaded")
		self.damagedEffect = function(damage,dir,pos)
			self.health = math.max(self.health-damage,0)
		  --createblood(pos, amount, speedMin, speedMax, dir)
			if self.health == 0 then
				createblood(self.pos, 600, 100, 500, 0)
			else
				createblood(pos, 100*damage, 50, 300+2*damage, dir,self)
			end
		end
	end

	--self.headyoffset	= -25*2
	--self.headxoffset	= -3.182
	self.lassor 		= 0
	self.gripping 		= false
	self.spinning 		= false
	self.gripped 		= 0
	self.moving 		= false
	self.throwing		= false
	self.lasso 			= {}
	self.lasso.x 		= 0
	self.lasso.y 		= 0
	self.lasso.dirx 	= 0
	self.lasso.diry 	= 0
	

	
	self.leftbound 		= self.area:left()		+25
	self.rightbound 	= self.area:right()		-25
	self.topbound 		= self.area:top()		+25
	self.botbound 		= self.area:bottom()	-25
	
	--bullet:init(images.player.icon,1000)
	
	
	if not idleAnim then
		idleAnim = newAnimation(images.player.walk2, 49, 49, 0.1,1)
		idleAnim:play()
	end
	if not walkAnim then
		walkAnim = newAnimation(images.player.walk2, 49, 49, 0.1,1)
		walkAnim:play()
	end
	if not spinAnim then
		spinAnim = newAnimation(images.playerspinning, 55, 64, 0.1, 16)
		spinAnim:play()
	end
end


function player:mousepressed(x, y, button)
	--bullet:shot(self.x,self.y,self.armfront_angle)

	if button == "l" then
		self.fired=true

		--[[
		if self.gripping then
			self.gripping = false
			zombies[self.gripped].caught = false
			self.cb(false)
		else
		self.spinning = true]]
    end
end

function player:mousereleased(x, y, button)
  if button == "l" then
    if self.spinning then
      self.spinning = false
      self.throwing = true
      self.lasso.x = self.pos.x
      self.lasso.y = self.pos.y
      self.lasso.dirx = math.cos(self.r-0.5*math.pi)
      self.lasso.diry = math.sin(self.r-0.5*math.pi)
    end
  end
end

function player:hashedUpdate()
	for _,obj in ipairs(shash:getnearby(self))  do		--todo: move to function
		if obj.type == "zombie" then
			local p = {r = self.radius	* 0.51, x = self.pos.x	, y = self.pos.y}
			local z = {r = obj.radius	* 0.51, x = obj.pos.x	, y = obj.pos.y}
			
			if CircleCircleCollision(p, z) then
				local entryangle	= (self.pos - obj.pos):normalized()  --vec(0.001,0.001)  to avoid div by 0
				self.entryoffset	= entryangle * p.r
				local entrypos 	= self.pos - self.entryoffset
				

				local dot 		= (entryangle.x*obj.heading.x + entryangle.y*obj.heading.y)
				
				local theta 	= math.acos(dot)
				local anglec 	= 180 - math.pi*theta
				local length 	= 2*(p.r * math.sin(anglec*0.5))
				local exitpos 	= entrypos + obj.heading * length

				if not self.invuln then
					self.invuln = 1
					self:damaged(math.random(1,100),-entryangle,exitpos)
					self.force = self.force + (2*entryangle)
				end

				self.force = self.force + (0.1*entryangle)
				obj.force = obj.force - (0.1*entryangle)
			end			
			
			--self:damaged(math.random(1,100),self.pos-obj.pos,self.pos)
			
			--self.pos = self.pos + self:nooverlap(obj)
		elseif obj.type == "bullet" and obj.id == "enemy" then
			if obj.active then 
				-- todo: maybe ditch quads colliding and do collision check based on bullets distance from center of zombie (radius)
				local p = {r = self.radius	* 0.5, x = self.pos.x	, y = self.pos.y}
				local b = {r = obj.box.w	* 0.5, x = obj.pos.x	, y = obj.pos.y}

				if CircleCircleCollision(p, b) then
					local entryangle	= (self.pos - obj.pos):normalized()
					self.entryoffset	= entryangle * p.r
					local entrypos 	= self.pos - self.entryoffset
					

					local dot 		= (entryangle.x*obj.dir.x + entryangle.y*obj.dir.y)
					
					local theta 	= math.acos(dot)
					local anglec 	= 180 - math.pi*theta
					local length 	= 2*(p.r * math.sin(anglec*0.5))
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
end

function player:Update(dt)
	--bullet:update(dt)
	idleAnim:update(dt)
	walkAnim:update(dt)
	spinAnim:update(dt)

	if self.alive then 
		--self.r	= math.getanglevec(camera:screen(self.pos),vec(love.mouse.getX(),love.mouse.getY()))
		--print("mousepos",camera:mousepos())
		--print("self.pos",self.pos)
		self.r 		= (camera:mousepos() - self.pos):angle2()
		--print("self.r",self.r)
		self.rotRad	= (camera:mousepos() - self.pos):normalized()
		--print("self.rotRad",self.rotRad)
		self.rotDeg	= self.rotRad:angle2()
		--print("self.rotDeg",self.rotDeg)
	end
	
	--self.armfront_angle		= math.getangle(cam:screen(self.pos).x,love.mouse.getX(),cam:screen(self.pos).y,love.mouse.getY())
	--self.armback_angle		= math.getangle(cam:screen(self.pos).x,love.mouse.getX(),cam:screen(self.pos).y,love.mouse.getY())
	--self.head_angle			= math.getangle(cam:screen(self.pos.x+self.headxoffset,self.pos.y+self.headyoffset).x,love.mouse.getX(),cam:screen(self.pos.x+self.headxoffset,self.pos.y+self.headyoffset).y,love.mouse.getY())	
	--self.armfront_angle 		= math.clamp(self.armfront_angle+math.pi/2,-math.pi/2,math.pi/2)
	--self.armback_angle		= math.clamp(self.armback_angle,1.56,-1.56)


	
	self.lassor = self.lassor + lassospeed*dt
	--self.fired = love.mouse.isDown("l")
	
	local move	= self.alive and self.maxforce or 0-- pixels a second * dt correction (100)
	local x 	= (getkey("right") and move or 0) - (getkey("left") and move or 0)
	local y 	= (getkey("down") and move or 0) - (getkey("up") and move or 0)
	if x ~= 0 and y ~= 0 then
		x,y = x*0.65,y*0.65
	end
	--local moving = (x == -self.maxforce or x == self.maxforce  and true or false) or (y == -self.maxforce  or y == self.maxforce  and true or false)
	--self.x = math.clamp(self.x + x*self.maxspeed*dt,self.area:left()+25,self.area:right()-25)
	--self.y = math.clamp(self.y + y*self.maxspeed*dt,self.area:top()+25,self.area:bottom()-25)
	
	if love.keyboard.isDown("o") and zombies[1] then
		--print("X: "..zombies[1].pos.x)
		--print("Y: "..zombies[1].pos.y)
		
		if zombies[1].wanderTargetPos then
			self.pos = zombies[1].wanderTargetPos
		end
	end
	
	self.acc 		= self.acc + vec(x,y)
	--self.acc:trunc(self.maxforce)
	
	--stop gliding
	local velMag	= self.vel:len()

	if velMag > 0.001 then
		local acc_after_friction = self.acc - self.heading*11--greater = more friction
		if velMag - acc_after_friction:len()*dt*60 < 0.001 then
			self.vel 		= vec(0,0)
		else
			self.acc 		= acc_after_friction 
		end
	end

	self.vel 		= self.vel + self.acc * dt * 60 + self.force
	self.vel:trunc(self.maxspeed)
	self.acc 		= vec(0,0)
	self.force 		= vec(0,0)
	
	local newpos 	= self.pos + self.vel * dt
	

	--constrain to area
	--self.x = math.max(self.x, self.area:left()+25)
	--self.x = math.min(self.x, self.area:right()-25)
	--self.y = math.max(self.y, self.area:top()+25)
	--self.y = math.min(self.y, self.area:bottom()-25)
	
	--[[
	newpos.x = clamp(newpos.x,	self.leftbound,	self.rightbound)	--1.7 micro seconds
	newpos.y = clamp(newpos.y, self.topbound,	self.botbound)
	]]
	if newpos.x < self.leftbound then								--0.7 micro seconds
		self.vel.x = 0
		newpos.x = self.leftbound
	elseif newpos.x > self.rightbound then
		self.vel.x = 0
		newpos.x = self.rightbound
	end
	if newpos.y < self.topbound then			--if newpos.y is higher than top | top to bottom = 0 to 1000
		self.vel.y = 0
		newpos.y = self.topbound
	elseif newpos.y > self.botbound then	--if newpos.y is lower than top | bottom to top = 1000 to 0
		self.vel.y = 0 
		newpos.y = self.botbound
	end
	
	self.pos 	= newpos


	
	self.moving = self.vel:len2() > 0 and true or false
	

	if self.moving or love.mouse.isDown("l") then
		currAnim 	= walkAnim
	else
		currAnim	= idleAnim
	end


	
	shash:hash(self)

--[[
  if self.throwing then
    self.lasso.x = self.lasso.x + self.lasso.dirx*lassothrowspeed
    self.lasso.y = self.lasso.y + self.lasso.diry*lassothrowspeed

    local lassobox = { { x=self.lasso.x-37, y=self.lasso.y-37 },  { x=self.lasso.x+37, y=self.lasso.y-37 }, { x=self.lasso.x+37, y=self.lasso.y+37 }, { x=self.lasso.x-37, y=self.lasso.y+37 } }
    for i, zombie in ipairs(zombies) do
      if quadsColliding(lassobox, rotatebox(zombie:getbodybox())) or quadsColliding(lassobox, rotatebox(zombie:getheadbox())) then
        self.throwing = false
        soundmanager:play(sounds.yeehaw)
        self.gripping = true
        self.gripped = i
        zombies[i].caught = self
        self.cb(true)
      end
    end

    if (self.x - self.lasso.x)^2 + (self.y - self.lasso.y)^2 > ropelengthSq then
      self.throwing = false;
    end
  end

  if self.gripping then
    local zombie = zombies[self.gripped]
    if not zombie then self.gripping = false return end
    local angle = math.atan2(self.y-zombie.y, self.x-zombie.x)-0.5*math.pi
    self.r = angle
    local dist = (self.x - zombie.x)^2 + (self.y - zombie.y)^2
    if dist > ropelengthSq then
      local ropeangle = math.atan2(zombie.y-self.y, zombie.x-self.x)
      zombie.x = self.x + ropelength*math.cos(ropeangle);
      zombie.y = self.y + ropelength*math.sin(ropeangle);
    end
  end
  ]]
end

function player:center()
	local xzoom,yzoom = (mousetoarea.x-self.pos.x)*zoompanfactor,(mousetoarea.y-self.pos.y)*zoompanfactor
end

function player:draw() 	
	local c1,c2,c3 = lg.getColor()
	
		if self.invuln then lg.setColor(255, 255, 255, 255-(150*self.invuln)) end
		--print(self.r)
		--currAnim:draw(math.round(self.pos.x),math.round(self.pos.y),self.r,1,1,25,25)	--self.facing
		currAnim:draw(self.pos.x,self.pos.y,self.rotDeg,1,1,25,25)	--self.facing
		
		--[[
		if self.facing == 1 then		-- facing right			1.5707 or pi/2 = horizontal
			lg.draw(images.player.armback_s		,math.round(self.x)					,math.round(self.y-20)					,self.armback_angle+math.pi/2		,self.facing,1,5,5	)	--,1, 4,4	)
			currAnim:draw(						 math.round(self.x)					,math.round(self.y)						,self.r								,self.facing,1,50,50)	--,currAnim.fw/2,currAnim.fw/2	-- second param should be currAnim.fh/2
			lg.draw(images.player.head			,math.round(self.x-self.headxoffset),math.round(self.y+self.headyoffset/2-1),self.head_angle+math.pi/2			,self.facing,1,11,24)	--images.player.head.width/2,images.player.head.height -- origin at neck
			lg.draw(images.player.armfront_s	,math.round(self.x)					,math.round(self.y-20)					,self.armfront_angle+math.pi/2+0.03	,self.facing,1,5,5	)	--,4.503,27.483

			lg.setColor(207,16,32)
			if dbg then lg.line(self.x+5,self.y-25,cam:mousepos().x,cam:mousepos().y) end		


		elseif self.facing == -1 then
			lg.draw(images.player.armback_s		,math.round(self.x)					,math.round(self.y-20)					,self.armback_angle-math.pi/2		,self.facing,1,5,5	)	--,1, 4,4	)
			currAnim:draw(						 math.round(self.x)					,math.round(self.y)						,self.r								,self.facing,1,50,50)	--,currAnim.fw/2,currAnim.fw/2	-- second param should be currAnim.fh/2
			lg.draw(images.player.head			,math.round(self.x+self.headxoffset),math.round(self.y+self.headyoffset/2-1),self.head_angle-math.pi/2			,self.facing,1,11,24)	--images.player.head.width/2,images.player.head.height -- origin at neck
			lg.draw(images.player.armfront_s	,math.round(self.x)					,math.round(self.y-20)					,self.armfront_angle-math.pi/2-0.03	,self.facing,1,5,5	)	--,4.503,27.483

			lg.setColor(207,16,32)
			if dbg then lg.line(self.x-5,self.y-25,cam:mousepos().x,cam:mousepos().y) end

		end]]
		lg.setColor(0,0,0)
		local round = math.round
		
		local namedisp		= self.name
		local healthdisp 	= self.alive and "Health: "..round(self.health,2) or "Dead"
		local veldisp		= "Velocity: "..round(self.vel:len(),3)
		local sFont		= font["small"]
		
		local printxloc	= self.pos.x-sFont:getWidth(healthdisp)*0.5
		local printyloc	= self.pos.y+self.radius*0.5
		
		lg.setFont(font["default"])
		lg.print(namedisp		,self.pos.x-font["default"]:getWidth(namedisp)*0.5	,printyloc)
		lg.setFont(sFont)
		lg.print(healthdisp		,printxloc											,printyloc+sFont:getHeight())	
		lg.print(veldisp		,printxloc											,printyloc+sFont:getHeight()*2)
		
		for test=1,6 do
			lg.point(self.pos.x+test,self.pos.y)
			lg.point(self.pos.x-test,self.pos.y)
			lg.point(self.pos.x,self.pos.y+test)
			lg.point(self.pos.x,self.pos.y-test)
		end
	
	lg.setColor(c1,c2,c3)	
	

	if release then return end
	lg.print(self.pos.y,self.pos.x,self.pos.y)
	
	--lg.print("armfront_angle: "..self.armfront_angle,self.x,self.y+30)
	--lg.print("armback_angle: "..self.armback_angle,self.x,self.y+60)
	
	--lg.print("temp: "..temp,self.x,self.y+15)
  --[[
  if self.spinning then
	local x, y = math.cos(self.r-0.6)*30, math.sin(self.r-0.6)*30
	lg.draw(images.lasso, self.x+x, self.y+y, self.lassor, 1, 1, 12, 12)
  elseif self.gripping then
	local zombie = zombies[self.gripped]
	if not zombie then self.gripping = false return end
	local x, y = math.cos(self.r-0.5*math.pi)*23, math.sin(self.r-0.5*math.pi)*23
	lg.setColor(104, 89, 67)
	lg.line(self.x+x, self.y+y, zombie.x, zombie.y)
	lg.setColor(255, 255, 255)
  end
  if self.throwing then
	local dist = math.sqrt((self.x-self.lasso.x)^2 + (self.y-self.lasso.y)^2)
	local angle = math.atan2(self.lasso.y-self.y, self.lasso.x-self.x)
	dist = dist - 37
	local x, y = math.cos(self.r-0.6)*30, math.sin(self.r-0.6)*30
	local tx = math.cos(angle)*dist
	local ty = math.sin(angle)*dist
	lg.setColor(104, 89, 67)
	lg.line(self.x+x,self.y+y, self.x+tx, self.y+ty)
	lg.setColor(255, 255, 255)
	lg.draw(images.lasso, self.lasso.x, self.lasso.y, 0, 1, 1, 37, 37)
  end
  ]]
end

--[[
function player:gethitbox()
	if self.moving then
		return { x = self.pos.x-20, y = self.pos.y-20, w = self.radius, h = self.radius, r = self.r, ox = 20, oy = 20 }
	else
		return { x = self.pos.x-25, y = self.pos.y-25, w = self.radius, h = self.radius, r = self.r, ox = 25, oy = 25 }
	end
end
]]

function player:gainexp(exp)
	self.exp = self.exp + exp
	if self.exp % 50 == 0 then
		self.lvl = self.lvl + 1
	end
end