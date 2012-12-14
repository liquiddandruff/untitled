projectiles = class:new()

local area

function projectiles:info(image,speed,type,damage,a)
	self.image 		=	image
	self.damage 	=	damage
	self.initspeed 	= 	speed
	self.speed 		=	speed
	self.type		=	type
	area 			=	a
end

function projectiles:init(startpos,startdir,angle,id)
	self.box		=	{w = 20,h = 20}	
	-- can increase boundnig box to get detected earlier
	--self.box.w 		= 20	--16
	--self.box.h 		= 20

	self.pos 		=	startpos
	
	if startdir == 0 then
		self.dir 	=	vec(math.cos(angle),math.sin(angle)):normalized()
	else
		self.dir	=	startdir--:normalized()--+math.pi/2
	end
	--self.dirX 	= 	math.cos(self.dir)
	--self.dirY 	= 	math.sin(self.dir)
	self.angle		=	angle
	
	self.owner 		= id
	
	
	self.active 	=	true
end

function projectiles:update(dt)
	--self.box.x = self.x - 8; self.box.y = self.y - 8; 
	self.box.x = self.pos.x - 10; self.box.y = self.pos.y - 10;	-- increasing bounding box by a few pixels helps fix ghosting
	
	--self.active = (self.x > -500 and self.x < 1500 and self.y > -500 and self.y < 1300) and true or false
	if (self.pos.x > area.x-30 and self.pos.x < area.x+area.width+30 and self.pos.y > area.y-30 and self.pos.y < area.y+area.height+30 and self.active) then
		self.active = true
		shash:hash(self)
	else
		self.active = false
		return 
	end
	--self.active = (self.x > 0 and self.x < 1500 and self.y > -500 and self.y < 300) and true or false
	
    --self.x = self.x + self.dirX*self.speed*dt
    --self.y = self.y + self.dirY*self.speed*dt
	self.speed = dbgl.bulletslow and 0.4 or initspeed
	self.pos = self.pos + self.dir*self.speed*dt*60
end

function projectiles:draw()
	lg.circle("line",self.pos.x,self.pos.y,self.box.w/2,10)
	lg.draw(self.image,self.pos.x,self.pos.y,self.angle,1,1,8,8)--,self.dir+math.pi/2
	--lg.print("x: "..self.pos.x,self.pos.x,self.pos.y-28)
	--lg.print("y: "..self.pos.y,self.pos.x,self.pos.y-14)
	--lg.print("i am in buckets: "..shash:inbuckets(self),self.pos.x,self.pos.y)
	--lg.rectangle("line",self.x-8,self.y-8,16,16)
end

--[[
function projectiles:gethitbox()
	return { x = self.x-8, y = self.y-8, w = 16, h = 16, r = math.tan(self.dir.y/self.dir.x), ox = 8, oy = 8 } --angle self.dir+math.pi/2 unnesscary
end]]