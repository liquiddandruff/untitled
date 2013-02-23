require "libs/AnAL"

local idleAnim
local walkAnim
local currAnim

local bullets

peerPlayer = actor:new()

function peerPlayer:info(b)
	bullets = b
end

function peerPlayer:init(x, y, a, z, id)
	self.temp			= "NIL"
	self.type 			= "peerplayer"
	self.id				= id
	
	self.invuln			= 0
	self.lvl			= 1
	self.exp			= 0
	self.health			= 200
	
	self.pos 			= vec(x,y)	
	self.dir			= vec(0,0)
	self.r				= 0		
	self.maxspeed 		= 360			--300  	350	/dt(100) 	= 35 pixels per 
	self.maxforce		= 24			--60	/dt(100) 	= 0.6 pixels max acceleration

	self.xInput,self.yInput = 0,0
	self.fired			= 0	
	self.dtfire			= 0
	
	self.facing 		= 1
	self.moving 		= false
	
	self.area 			= a
	
	if not self.damagedEffect then
		print("Func peer.damagedEffect loaded")
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
	
	self.leftbound 		= self.area:left()		+25
	self.rightbound 	= self.area:right()		-25
	self.topbound 		= self.area:top()		+25
	self.botbound 		= self.area:bottom()	-25	
	
	if not idleAnim then
		idleAnim = newAnimation(images.player.walk2, 49, 49, 0.1,1)
		idleAnim:play()
	end
	if not walkAnim then
		walkAnim = newAnimation(images.player.walk2, 49, 49, 0.1,1)
		walkAnim:play()
	end
end

function peerPlayer:Update(dt)	
	idleAnim:update(dt)
	walkAnim:update(dt)

	self.dtfire = self.dtfire + dt
	
	local maxforce = self.maxforce

	self.acc 		= self.acc + vec(self.xInput*maxforce,self.yInput*maxforce)
	--print(self.acc.x.." "..self.acc.y)
	--self.acc:trunc(self.maxforce)
	
	--stop gliding
	local velMag	= self.vel:len()
	
	if velMag > 0.001 then
		local acc_after_friction = self.acc - self.heading*11--greater = more friction /8
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
	if newpos.y < self.topbound then
		self.vel.y = 0
		newpos.y = self.topbound
	elseif newpos.y > self.botbound then
		self.vel.y = 0 
		newpos.y = self.botbound
	end
		
	self.pos 		= newpos
	
	--todo: make bullet shoot at radius
	-- recieved a shoot notification sent from a peer
	if self.fired > 0 and self.dtfire > 0.05 then
		local dir = vec(math.cos(self.r),math.sin(self.r))
		local bullet = bullet:new(self.pos+dir*self.radius*0.5,dir,self.r,self.id)--move to player player.armfront_angle)
		table.insert(bullets, bullet)
		self.fired	=	self.fired - 1
		self.dtfire = 0
	end


	self.moving = (x ~= 0 or y ~= 0)
	
	if self.moving then
		currAnim 	= walkAnim
	else
		currAnim	= idleAnim
	end
	
	shash:hash(self)
end

function peerPlayer:draw() 	
	local c1,c2,c3 = lg.getColor()

		if self.invuln then lg.setColor(255, 255, 255, 255-(150*self.invuln)) end

		currAnim:draw(self.pos.x,self.pos.y,self.r,1,1,25,25)
		
		lg.setColor(0,0,0)
		local round 		= math.round
		
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