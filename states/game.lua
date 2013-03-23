require("classes/projectiles/bullet")
game = {}
dbgl = {}

Gamestate.game 	= Gamestate.new()
local state 	= Gamestate.game

local cam 	
local area

local player
local zombies

local bullets  	
local blood

local gui
local statepaused

local minimap
local timer
local spawnlist
local gorelist

local score
local combo
local combotimer

local zorder

--time critical
local insert, remove = table.insert,table.remove

--todo: move all parameters as member variables in actor
function createblood(pos, amount, speedMin, speedMax, radian, actor)
	local p = lg.newParticleSystem(images.bloodparticle,amount)
	p:setSizes(0.8, 1, 1.3)
	p:setParticleLife(0.3)
	p:setLifetime(0.1)
	p:setPosition(pos.x, pos.y)
	p:setSpeed(speedMin, speedMax)
	p:setEmissionRate(amount)
	p:setColors(207, 31, 31, 255, 255, 0, 0, 0)
	p:setRadialAcceleration(1,100)
	
	-- 0 means fatal
	if radian == nil then 										
		p:setEmissionRate(amount*amount)
		p:setSpeed(10, speedMax)
		p:setSpread(2*math.pi)
	else
		p:setEmissionRate(amount+randomClamped()*100)
		p:setSpread(math.pi/math.random(2,5))
		print("RADIAN: ",radian)
		p:setDirection(radian)
	end
	p:start()
	
	local dataset = {p}

	if actor then 
		dataset[2] = actor
	end
	
	insert(blood, dataset)
end

function state:enter(last, playerName)
	dbgl.zombiefreeze 	= false
	dbgl.bulletslow		= false
	
	if not cam then
		cam = camera()
	end
	
	bullets 			= {}
	zombies 			= {}
	spawnlist 			= {}
	gorelist 			= {}
	blood 				= {}
	
	timer 				= 9
	score 				= 0
	combo 				= 0
	combotimer 			= 0

	lg.setBackgroundColor(unpack(color["menubackground"]))
	
	area 		= _G.area		:new(0,0,1408,1408)
	player 		= _G.player		:new(400, 300, area, zombies , playerName, cam)	
	minimap 	= _G.minimap	:new(player, area, zombies, spawnlist)	

	bullet						:info(images.player.icon,15,"bullet",25,area)
	nMngr						:ready(player,area,bullets)
	
	player.invuln = false

	--soundmanager:playMusic(music.ritd)
	--if not guifont then guifont = lg.newFont("resources/fonts/accid.ttf", 20) end

	
	local x, y = area:center()--[[
	table.insert(zombies, zombie:new(x-200	, y		, area, player, zombies))
	table.insert(zombies, zombie:new(x-200	, y		, area, player, zombies))
	table.insert(zombies, zombie:new(x-200	, y		, area, player, zombies))]]

	
	if not gui then
		gui = _G.gui:new(player,zombie,zombies,area)
	else
		gui:info(player,zombie,zombies,area)
		gui:show()
	end
	
	if not statepaused then 
		statepaused = {}
		statepaused.buttons = {	new 	= Button.create("New Game"		, 300, 400),
								resume 	= Button.create("Respawn"		, screenW*0.33, 400),
								menu 	= Button.create("Menu"			, screenW*0.66, 400) }
		statepaused.update = function(dt)
			statepaused.buttons["resume"]:update(dt)
			statepaused.buttons["menu"]:update(dt)
		end
		statepaused.draw 	= function()
			local lg = lg
			lg.setColor(unpack(color["overlay"]))
			lg.rectangle("fill",0,0,screenW,screenH)
			lg.setColor(unpack(color["hover"]))
			lg.setFont(font["huge"])
			lg.printf("You are dead.", 0, screenH*0.25, screenW, "center")
			lg.setColor(unpack(color["text"]))
			lg.setFont(font["default"])		
			
			-- Buttons
			statepaused.buttons["resume"]:draw()
			statepaused.buttons["menu"]:draw()	
		end
	end
	
	loveframes.config["DEBUG"] = showDebug
end

function state:leave()
	gui:hide()
end

function state:update(dt)
	if dt > 0.05 then dt = 0.05 else dt = dt end
	game.dt  = dt
	
	loveframes.update(dt)
	soundmanager:update(dt)
	client:update(dt)
	
	timer 		= timer + dt + combo*dt
	zorder		= {}
	
	
	local i = 1
	while spawnlist[i] do
		local v = spawnlist[i]
		if area:gateopen(v.gate) then
			insert(zombies, v.zombie)
			area:closegate(v.gate)
			remove(spawnlist, i)
		else
			i = i + 1
		end
	end
	insert(zorder,player)
	
	area:update(dt)
	player:update(dt)
	
	cam.pos 					= player.pos:clone()
	cam.viewpan 				= (cam:mousepos()-player.pos)*viewpanfactor
	
	--bullets
	if player.fired then
		--local dir = vec(math.cos(player.r),math.sin(player.r))

		local bullet = bullet:new(player.pos+player.dir*player.radius*0.5,player.dir,player.r,client.id)--todo: change to gun:shoot
		insert(bullets, bullet)
		--player.fired=false
	end	
	local bulletremovelist = {}
	for i, bullet in ipairs(bullets) do
		bullet:update(dt)

		if not bullet.active then insert(bulletremovelist,i) end
	end

	nMngr:update(dt)
	
	
	if player.fired then
		--local bullet = bullet:new(player.pos,cam:mousepos()-player.pos,player.r,client.id)--move to player player.armfront_angle)
		--insert(bullets, bullet)
		player.fired = false
	end

	for i, v in ipairs(bulletremovelist) do
		remove(bullets,v-i+1)
	end
	--bullets	
	
	
	--bullets from peers that hit player
	for _,obj in ipairs(shash:getnearby(player))  do
		if obj.type == "bullet" then
			if obj.active and obj.owner ~= client.id then 
				local a = {r = player.radius*0.5	, x = player.pos.x	, y = player.pos.y}
				--a.r = player.radius/2	--radius is diameter
				--a.x,a.y = player.pos.x,player.pos.y
				local b = {r = obj.box.w*0.5		, x = obj.pos.x		, y = obj.pos.y}
				--b.r = obj.box.w/2
				--b.x,b.y = obj.pos.x,obj.pos.y
				if CircleCircleCollision(a, b) then
					local ab			= player.pos - obj.pos
					local entryangle 	= (ab):normalize()
					player.entryoffset	= entryangle * player.radius*0.5
					local entrypos 	= player.pos - entryangle * player.radius*0.5
					

					local dot 			= entryangle.x*obj.dir.x + entryangle.y*obj.dir.y
					

					local theta 	= math.acos(dot)
					local anglec 	= 180 - math.pi*theta
					local length 	= 2*(a.r * math.sin(anglec*0.5))
					local exitpos 	= entrypos + obj.dir * length

					
					player:damaged(obj.damage,obj.r,entrypos)		--straight through, entry
					--player:damaged(obj.damage,obj.dir,exitpos)		--straight through, exit
					--player:damaged(obj.damage,entryangle,entrypos)	--angle to the bullet from zombie.pos

					player.force = player.force + (120*obj.dir)
					obj.active = false
				end
				--[[
				if quadsColliding(rotatebox(player:getbodybox()), rotatebox(obj:gethitbox())) then
					player:damaged(obj.damage,obj.dir,obj.pos+obj.dir:normalized()*10)--math.random(2,15))
					player.acc = player.acc + 10*obj.dir			--to do: lag=super knockback, 300fps = normal knockback variable knockback based on weapons
					obj.active = false
				end
				]]
			end
		end
	end
	--bullets from peers that hit player
	
	
	--zombies	
	local zombieremovelist = {}
	for i, zombie in ipairs(zombies) do
		zombie:update(dt)
		if not zombie.alive then insert(zombieremovelist,i) end
		insert(zorder, zombie)
	end
	for i, v in ipairs(zombieremovelist) do
		remove(zombies, v-i+1)
		if player.gripping and (v-i+1) < player.gripped then
			player.gripped = player.gripped - 1
		end
	end	
	--zombies	
	
	--gorelist
	local removelist = {}
	for i, v in ipairs(gorelist) do
		v.timer = v.timer + dt
		v.alpha = 255*(5-v.timer)/5
		v.zombie.dustParticles:update(dt)
		if v.timer > 5 then
			insert(removelist, i)
		end
	end
	for i, v in ipairs(removelist) do
		remove(gorelist, v-i+1)
	end
	--gorelist
	
	if player.invuln then
		player.invuln = player.invuln - dt
		if player.invuln < 0 then player.invuln = false end
	end
	if player.gripping then
		combotimer = combotimer + dt
		if combotimer > 8 then
			combo = 0
			zombies[player.gripped].caught = false
			player.gripping = false
			combo = 0
		end
	end
  
	--blood
	local bloodremovelist = {}
	for i, v in ipairs(blood) do
		--v[1] , v[2] = particle , actor
		if v[2] then
			if v[2].entrypos then
				v[1]:setPosition(v[2].entrypos.x, v[2].entrypos.y)
			else
				v[1]:setPosition(v[2].pos.x, v[2].pos.y)
			end
		end
		
		v[1]:update(dt)
		
		if not v[1]:isActive() and v[1]:count() == 0 then
			insert(bloodremovelist, i)
		end
	end
	
	for i, v in ipairs(bloodremovelist) do
		remove(blood, v-i+1)
	end
	--blood
	
	--collisions
	local caughtzombie = player.gripping
	if caughtzombie then
		caughtzombie = zombies[player.gripped]
	end
	
	player:hashedUpdate()

	if not player.alive then
		statepaused:update(dt)
		--Gamestate.switch(Gamestate.lost, score)
	end

	shash:update()
	tween.update(dt)
	
	--love.timer.sleep(0.035)
end

function state:draw()
	local lg 		= lg
	local lgPrint 	= lg.print
	
	lg.setColor(255,255,255)
	
	lg.setFont(font["small"])
	cam:attach()
		area:draw()
		
		for i, v in ipairs(gorelist) do
			lg.setColor(255, 255, 255, v.alpha)
			lg.draw(v.zombie.dustParticles, 0, 0)
			lg.draw(images.gore, v.zombie.x, v.zombie.y, v.zombie.r, 1, 1, 25, 25)
			lg.printf(v.combo .. "X", v.zombie.x-30, v.zombie.y-10-10*(255/v.alpha), 60, "center")
		end
		
		nMngr:draw()
		player:draw()
		

		for _, zombie in ipairs(zombies) do
			zombie:draw()
		end
		--[[if(zorder) then
			table.sort(zorder,function(a,b) return a.pos.y<b.pos.y end)
			for _, object in ipairs(zorder) do
				object:draw()
			end
		end]]
		
		--[[if player.invuln then lg.setColor(255, 255, 255, 255-(150*player.invuln)) end
			object:draw()
		if player.invuln then lg.setColor(255, 255, 255, 255) end		]]
		
		for _, bullet in pairs(bullets) do
			bullet:draw()
		end		
		
		for i, v in ipairs(blood) do
			lg.draw(v[1], 0, 0)
		end
	cam:detach()
	
	lg.setColor(0,0,0)
		lgPrint("number of zombies: "	..#zombies				,10,0)
		lgPrint("number of bullets: "	..#bullets 				,10,20)
		lgPrint("hashed objects: "		..shash.hashed			,10,40)
		lgPrint("level: "				..player.lvl			,10,380)
		lgPrint("experience: "			..player.exp			,10,400)
		
		local rightAlign	= screenW-240
		
		lgPrint("delta time: "			..game.dt				,rightAlign,0) 
		lgPrint("fps: "					..love.timer.getFPS()	,rightAlign,20)
		
		local str 	= nMngr.client.connected and math.round(nMngr.rcvRate,3) or "Not Connected"
		lgPrint("packets/second: "		..str,rightAlign,40)
		
		str 		= nMngr.client.connected and tonumber(nMngr.rcvSizeRate) or "Not Connected"
		lgPrint("bytes/second: "		..str,rightAlign,60)
		
		str 		= nMngr.client.connected and client.ping or "Not Connected"
		lgPrint("ping: "				..str,rightAlign,80)
	lg.setColor(255,255,255)
	
	shash.hashed = 0	
	
	minimap:draw()
	loveframes.draw()

	if not player.alive then
		statepaused:draw()	
	end
end

function state:mousepressed(x, y, button)
	loveframes.mousepressed(x, y, button)
	local player 	= player
	if not player.alive then
		if statepaused.buttons["resume"]:mousepressed(x, y, button) then
			player.health 	= 200
			player.pos 		= vec(400,300)
		elseif statepaused.buttons["menu"]:mousepressed(x, y, button) then
			Gamestate.switch(Gamestate.menu)
		end
	else
		player:mousepressed(x, y, button)
	end
end

function state:mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)
	player:mousereleased(x, y, button)
end

local keymap = {
	["escape"] 	= 	function() Gamestate.switch(Gamestate.menu) end,
	["rctrl"] 	= 	function() debug.debug() end,
	["]"] 		= 	function() gui:toggle("console") end,
  
	["kp1"] 	= 	function() dbgl.zombiefreeze = not dbgl.zombiefreeze end,
	["kp2"] 	= 	function() dbgl.bulletslow = not dbgl.bulletslow end,

  
	["p"] 		= 	function()	
						tween(3,player,{health = 10000},'linear') 
					end
}

function state:keypressed(key, unicode)
	loveframes.keypressed(key, unicode)

	--switch
	if keymap[key] then 
		keymap[key]()
	end
end

function state:keyreleased(key)
	loveframes.keyreleased(key)
end