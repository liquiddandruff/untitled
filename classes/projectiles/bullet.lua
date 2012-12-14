require "libs/SECS"
require "classes/projectiles/projectiles"
bullet=projectiles

function bullet:gethitbox()
	return { x = self.x-8, y = self.y-8, w = 18, h = 18, r = math.tan(self.dir.y/self.dir.x), ox = 8, oy = 8 } --angle unnesscary
end