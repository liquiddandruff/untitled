--[[
Copyright (c) 2010 Matthias Richter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--

local assert = assert
local sqrt, cos, sin = math.sqrt, math.cos, math.sin

local vector = {}
vector.__index = vector

local function new(x,y)
	local v = {x = x or 0, y = y or 0}
	setmetatable(v, vector)
	return v
end

local function isvector(v)
	return getmetatable(v) == vector
end

function vector:string()
   --return "(" .. self.x .. ", " .. self.y .. ")"
   return string.format("Length: %.2f X: %.2f, Y: %.2f Deg: %.2f",self:len(),self.x,self.y,math.deg(self:ang()))
end

function vector:angle()
   return math.atan(self.y / self.x)
end

function vector:angle2()
	return math.atan2(self.y,self.x)
end

function vector:trunc(maxmag)
	local currmag 	= sqrt(self.x * self.x + self.y * self.y)


	if currmag > maxmag then
		local newvec = self:normalized() * maxmag
		self.x, self.y = newvec.x, newvec.y
	end
end

function vector:truncated(maxmag)
	local currmag 	= sqrt(self.x * self.x + self.y * self.y)


	if currmag > maxmag then
		local newvec = self:normalized() * maxmag
		self.x, self.y = newvec.x, newvec.y
	end
	return self
end

function vector:clone()
	return new(self.x, self.y)
end

function vector:unpack()
	return self.x, self.y
end

function vector:__tostring()
	return "("..tonumber(self.x)..","..tonumber(self.y)..")"
end

function vector.__unm(a)
	return new(-a.x, -a.y)
end

function vector.__add(a,b)
	assert(isvector(a) and isvector(b), "Add: wrong argument types (<vector> expected)")
	return new(a.x+b.x, a.y+b.y)
end

function vector.__sub(a,b)
	assert(isvector(a) and isvector(b), "Sub: wrong argument types (<vector> expected)")
	return new(a.x-b.x, a.y-b.y)
end

function vector.__mul(a,b)
	if type(a) == "number" then
		return new(a*b.x, a*b.y)
	elseif type(b) == "number" then
		return new(b*a.x, b*a.y)
	else
		assert(isvector(a) and isvector(b), "Mul: wrong argument types (<vector> or <number> expected)")
		--return a.x*b.x + a.y*b.y
		return new(a.x*b.x, a.y*b.y)
	end
end

function vector.__div(a,b)
	assert(isvector(a) and type(b) == "number", "wrong argument types (expected <vector> / <number>)")
	return new(a.x / b, a.y / b)
end

function vector.__eq(a,b)
	return a.x == b.x and a.y == b.y
end

function vector.__lt(a,b)
	return a.x < b.x or (a.x == b.x and a.y < b.y)
end

function vector.__le(a,b)
	return a.x <= b.x and a.y <= b.y
end

function vector.permul(a,b)
	assert(isvector(a) and isvector(b), "permul: wrong argument types (<vector> expected)")
	return new(a.x*b.x, a.y*b.y)
end

function vector:len2()
	return self.x * self.x + self.y * self.y
end

function vector:len()
	return sqrt(self.x * self.x + self.y * self.y)
end

function vector.dist(a, b)
	assert(isvector(a) and isvector(b), "dist: wrong argument types (<vector> expected)")
	return (b-a):len()
end

function vector:normalize()
	local l = self:len()
	if l == 0 then 
		--print("normalize: length = 0")
		return 
	end
	self.x, self.y = self.x / l, self.y / l
	return self
end

function vector:normalized()
	local l = self:len()
	if l == 0 then
		return vec(0,0)
	end
	return self / l
end

function vector:rotate_inplace(phi)
	local c, s = cos(phi), sin(phi)
	self.x, self.y = c * self.x - s * self.y, s * self.x + c * self.y
	return self
end

function vector:rotated(phi)
	return self:clone():rotate_inplace(phi)
end

function vector:perpendicular()
	return new(-self.y, self.x)
end

function vector:projectOn(v)
	assert(isvector(v), "invalid argument: cannot project onto anything other than a vector")
	return (self * v) * v / v:len2()
end

function vector:mirrorOn(other)
	assert(isvector(other), "invalid argument: cannot mirror on anything other than a vector")
	return 2 * self:projectOn(other) - self
end

function vector:cross(other)
	assert(isvector(other), "cross: wrong argument types (<vector> expected)")
	return self.x * other.y - self.y * other.x
end
function vector:dot(other)
	return self.x * other.y + self.y * other.x
end

-- the module
return setmetatable({new = new, isvector = isvector},
	{__call = function(_, ...) return new(...) end})
