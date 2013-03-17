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
	self.maxspeed 		= 340			--300  	350	/dt(100) 	= 35 pixels per 
	self.maxforce		= 16.5			--60	/dt(100) 	= 0.6 pixels max acceleration


	self.fired			= false	
	zombies 			= z
	camera				= cam

	
	
	self.area 			= a
	
	if not self.damagedEffect then
		print("Func player.damagedEffect loaded")
		self.damagedEffect = function(damage,rotation,pos)
			self.health = math.max(self.health-damage,0)
		  --createblood(pos, amount, speedMin, speedMax, rotation)
			if self.health == 0 then
				createblood(self.pos, 600, 100, 500, nil)
			else
				createblood(pos, 100*damage, 50, 300+2*damage, rotation,self)
			end
		end
	end

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
	if button == "l" then
		self.fired=true
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
					self:damaged(math.random(1,100),entryangle:angle2(),exitpos)
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

					
					self:damaged(obj.damage,obj.r,entrypos)		--straight through, entry
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
	idleAnim:update(dt)
	walkAnim:update(dt)
	spinAnim:update(dt)

	if self.alive then 
		-- 90 degrees = -pi/2 since top to bottom is -y to +y; y signs flipped
		self.dir	= (camera:mousepos() - self.pos):normalized()
		self.r		= self.dir:angle2()
	end
	
	self.lassor = self.lassor + lassospeed*dt
	--self.fired = love.mouse.isDown("l")
	
	local move	= self.alive and self.maxforce or 0-- pixels a second * dt correction (100)
	local x 	= (getkey("right") and move or 0) - (getkey("left") and move or 0)
	local y 	= (getkey("down") and move or 0) - (getkey("up") and move or 0)

	if love.keyboard.isDown("o") and zombies[1] then
		--print("X: "..zombies[1].pos.x)
		--print("Y: "..zombies[1].pos.y)
		
		if zombies[1].wanderTargetPos then
			self.pos = zombies[1].wanderTargetPos
		end
	end
	
	self.acc 		= self.acc + vec(x,y):truncated(self.maxforce)
	--self.acc:trunc(self.maxforce)
	
	-- Friction
	local velMag	= self.vel:len()
	if velMag ~= 0 then
		-- Ff = m*g * mu
		local friction = 1.0*9.8 * 1.0		
		local acc_after_friction = self.acc - self.heading * friction
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
	
	if newpos.x < self.leftbound then
		self.vel.x = 0
		newpos.x = self.leftbound
	elseif newpos.x > self.rightbound then
		self.vel.x = 0
		newpos.x = self.rightbound
	end
	--if newpos.y is higher than top | top to bottom = 0 to 1000
	if newpos.y < self.topbound then			
		self.vel.y = 0
		newpos.y = self.topbound
	--if newpos.y is lower than top | bottom to top = 1000 to 0
	elseif newpos.y > self.botbound then	
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
end

function player:center()
	local xzoom,yzoom = (mousetoarea.x-self.pos.x)*zoompanfactor,(mousetoarea.y-self.pos.y)*zoompanfactor
end

function player:draw() 	
	local c1,c2,c3 = lg.getColor()
	
		if self.invuln then lg.setColor(255, 255, 255, 255-(150*self.invuln)) end

		currAnim:draw(self.pos.x,self.pos.y,self.r,1,1,25,25)
		
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
end

function player:gainexp(exp)
	self.exp = self.exp + exp
	if self.exp % 50 == 0 then
		self.lvl = self.lvl + 1
	end
end