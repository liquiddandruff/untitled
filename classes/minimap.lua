minimap = class:new()

function minimap:init(p,a,b,s)
	self.width = 180
	self.height = 180
	self.x = screenW-self.width
	self.y = screenH-self.height

	self.player = p
	self.area = a
	self.zombies = b
	self.spawnlist = s

	self.xratio = a.width/self.width
	self.yratio = a.height/self.height
end

function minimap:update(dt)

end

function minimap:draw()
	--draw minimap bg
	lg.draw(images.minimap, self.x, self.y)
	
	--draw zombies
	for _, zombie in ipairs(self.zombies) do
		local xPos = self.x + (zombie.pos.x - self.area.x) / self.xratio;
		local yPos = self.y + (zombie.pos.y - self.area.y) / self.yratio;
		lg.draw(images.zombie.icon, xPos, yPos, zombie.r, 1, 1, 7, 8)	--zombie.dir+math.rad(90) dick
	end
	
	for i, v in ipairs(self.spawnlist) do
		local zombie = v.zombie
		local xPos = self.x + (zombie.pos.x - self.area.x) / self.xratio;
		local yPos = self.y + (zombie.pos.y - self.area.y) / self.yratio;
		lg.draw(images.zombie.icon, xPos, yPos, 0, 1, 1, 7, 8) --zombie.dir+math.rad(90) dick
	end

	--draw player
	local xPos = self.x + (self.player.pos.x - self.area.x) / self.xratio;
	local yPos = self.y + (self.player.pos.y - self.area.y) / self.yratio;
	lg.draw(images.player.icon, xPos, yPos, self.player.rotDeg, 1, 1, 8, 8)
end
