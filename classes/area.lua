local gates = {0, 0, 0, 0}
local gatedirs = {0, 0, 0, 0}
local gatespeed = 40
--local floorquad



area = class:new()

function area:init(x, y, w, h)
	self.x 		= x
	self.y 		= y
	self.width 	= w	--self.width+512
	self.height = h
	
	--shash = spacialhashclass:new(self.x,self.y,self.width,self.height,200)
	shash:Init(self.x,self.y,self.width,self.height,200)
	
	--floorquad = lg.newQuad(0, 0, 2048, 2048, images.start:getWidth(), images.start:getHeight())
	images.sandtile:setWrap("repeat", "repeat")  --gay
end

function area:opengate(g)
  local n
  if g == "top" then
    n = 1
  elseif g == "left" then
    n = 2
  elseif g == "right" then
    n = 3
  elseif g == "bottom" then
    n = 4
  end
  n = n or tonumber(g)
  if not n then return end
  gatedirs[n] = 1
end

function area:closegate(g)
  local n
  if g == "top" then
    n = 1
  elseif g == "left" then
    n = 2
  elseif g == "right" then
    n = 3
  elseif g == "bottom" then
    n = 4
  end
  n = n or tonumber(g)
  if not n then return end
  gatedirs[n] = -1
end

function area:gateopen(g)
  local n
  if g == "top" then
    n = 1
  elseif g == "left" then
    n = 2
  elseif g == "right" then
    n = 3
  elseif g == "bottom" then
    n = 4
  end
  n = n or tonumber(g)
  if not n then return end
  return gates[n] == 128
end

function area:update(dt)
	--shash:update()
  for i, v in ipairs(gates) do
    gates[i] = math.max(math.min(v+gatedirs[i]*dt*gatespeed, 128), 0)
    if gates[i] == 0 or gates[i] == 128 then
      gatedirs[i] = 0
    end
  end
 
end

function area:left()
  return (self.x + 128)
end

function area:right()
  return (self.width - 128)
end

function area:top()
  return (self.y + 128)
end

function area:bottom()
  return (self.height - 128)
end

function area:center()
  local x = (self.x + self.width) * 0.5
  local y = (self.y + self.height) * 0.5
  return x, y
end

function area:draw()
	--Draw floor
	--lg.drawq(images.start2, floorquad, -256,-256) --sandtile
  
	--draw top walls
	for i = 128, self.width-256, 256 do
		if i == 640 then
			lg.draw(images.walltiles.gate, i+gates[1], self.y+110, math.rad(-90))
		elseif i < 640 then
			lg.draw(images.walltiles.top, i, self.y+30)
		else
			lg.draw(images.walltiles.top, i-128, self.y+30)
		end
	end
  
	--draw left walls
	for i = 128, self.height-256, 256 do
		if i == 640 then
			lg.draw(images.walltiles.gate, self.x+60, i+gates[2])
		elseif i < 640 then
			lg.draw(images.walltiles.left, self.x+30, i)
		else
			lg.draw(images.walltiles.left, self.x+30, i-128)
		end
	end
  
	--draw right walls
	for i = 128, self.height-256, 256 do
		if i == 640 then
			lg.draw(images.walltiles.gate, self.x+self.width-114, i+gates[3])
		elseif i < 640 then
			lg.draw(images.walltiles.right, self.x+self.width-154, i)
		else
			lg.draw(images.walltiles.right, self.x+self.width-154, i-128)
		end
	end
  
	--draw bottom walls
	for i = 128, self.width-256, 256 do
		if i == 640 then
			lg.draw(images.walltiles.gate, i+128+gates[4], self.y+self.height-110, math.rad(90))
		elseif i < 640 then
			lg.draw(images.walltiles.bottom, i, self.y+self.height-154)
		else
			lg.draw(images.walltiles.bottom, i-128, self.y+self.height-154)
		end
	end
  
	--draw corners
	lg.draw(images.walltiles.topleft, self.x+30, self.y+30)
	lg.draw(images.walltiles.topright, self.width-128, self.y+30)
	lg.draw(images.walltiles.bottomleft, self.x+30, self.height-128)
	lg.draw(images.walltiles.bottomright, self.width-128, self.height-128)

	--if release then return end 
	--shash:draw()
end
