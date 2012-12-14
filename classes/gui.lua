gui = class:new()

local player,zombie,zombies,area
local images = {"accept.png", "add.png", "application.png", "building.png", "bin.png", "database.png", "box.png", "brick.png"}

local data = {}

local function createTabs()
	local frameobj = loveframes.Create("frame")
	frameobj:SetScreenLocked(false)
	frameobj:SetDraggable(false)
	frameobj:SetName("Console")
	frameobj:SetSize(300, 250)
	frameobj:SetPos(0,screenH)
	frameobj.internals[1].OnClick = function()
		frameobj.hide()
	end
	
	local tabsobj = loveframes.Create("tabs", frameobj)
	tabsobj:SetPos(5, 30)
	tabsobj:SetSize(200, 215)		--290

	--start first tab, miscellaneous
		local panel1 = loveframes.Create("panel")
		panel1.Draw = function()					-- empty draw; don't draw border
		end		
		
		local button = {x = 201.5, w = 82, h = 20}
		
		local text1 = loveframes.Create("text", panel1)
		text1:SetMaxWidth(200)
		text1.Update = function (object)
			object:SetText("Player health: " ..player.health)
		end
		text1:SetPos(0,0)
		
		--note buttons: ypos = height + 5 pixel spacing
		local spawnzombies = loveframes.Create("button", panel1)
		spawnzombies:SetText("Spawn Zombies")
		spawnzombies:SetSize(button.w,button.h)
		spawnzombies:SetPos(button.x,-5)
		spawnzombies.OnClick = function(object1, x, y)	
			for i=1,4 do
				table.insert(zombies, zombie:new(500+i*4, 600, area, player, zombies))
			end
		end
		
		local killzombies = loveframes.Create("button", panel1)
		killzombies:SetText("Kill Zombies")
		killzombies:SetSize(button.w,button.h)
		killzombies:SetPos(button.x,20)
		killzombies.OnClick = function(object1, x, y)	
			local removelist = {}
			for i,v in ipairs(zombies) do
				table.insert(removelist,i)
			end
			for i,v in ipairs(removelist) do
				table.remove(zombies,v-i+1)
			end
		end
		
		local opbullets = loveframes.Create("button", panel1)
		opbullets:SetText("Super Bullets")
		opbullets:SetSize(button.w,button.h)
		opbullets:SetPos(button.x,45)
		opbullets.OnClick = function(object1, x, y)	
			bullet:info(_G.images.player.icon,25,"bullet",1000,area)--2000			
		end
		
		tabsobj:AddTab("Miscellaneous ", panel1, "Miscellaneous", "resources/images/" ..images[6])--images[math.random(1, #images)])
	--end first tab
	
	--start second tab,
		local panel1 = loveframes.Create("panel")
		panel1.Draw = function()
		end	
		
		tabsobj:AddTab("Miscellaneous ", panel1, "Miscellaneous", "resources/images/" ..images[math.random(1, #images)])
	--end second tab
	
	--start third tab,
		--local panel1 = loveframes.Create("panel")
		--panel1.Draw = function()
		--end	
		
		--tabsobj:AddTab("Miscellaneous ", panel1, "Miscellaneous", "resources/images/" ..images[math.random(1, #images)])
	--end third tab
	
	--[[
	for i=2, 4 do
		local panel1 = loveframes.Create("panel")
		panel1.Draw = function()					-- empty draw; don't draw border
		end		
		
		local text1 = loveframes.Create("text", panel1)
		tabsobj:AddTab("Tab " ..i, panel1, "Tab " ..i, "resources/images/" ..images[math.random(1, #images)])
		text1:SetText("Tab " ..player.health)
		text1:Center()	
	end
	]]
	
	
	function frameobj.show()
		local callback =
		function()
			frameobj.changed = true
		end

		frameobj.visible = true
		
		tween(0.5, frameobj, { y = screenH - frameobj:GetHeight() }, 'outExpo', callback)
	end

	function frameobj.hide() 
		local callback = 
		function()
			frameobj.visible = false
			frameobj.changed = true
		end
		
		tween(0.35, frameobj, { y = screenH }, 'inExpo', callback) 
	end
	
	frameobj.changed	= true
	frameobj.visible 	= false
	
	data["console"] 		= frameobj
end

function gui:info(...)
	player,zombie,zombies,area = unpack(arg)
end

function gui:init(...)
	player,zombie,zombies,area = unpack(arg)
	--self:info(unpack(arg))
	
	
	createTabs()
end

function gui:show(framename)
	--if called with no parameters
	if not framename then
		for i,v in pairs(data) do
			--set visibility to whatever it was before gui:hide()
			--do check if v has visiblebefore value. if it does, use it.
			v.visible = v.visiblebefore and v.visiblebefore or false
		end
	elseif data[framename] then
		data[framename].visible = true
	end
end

function gui:hide(framename)
	--if called with no parameters
	if not framename then
		for i,v in pairs(data) do
			--store visibility status in variable
			v.visiblebefore = v.visible
			v.visible = false
		end
	elseif	data[framename] then
		data[framename].visible = false
	end
end

function gui:toggle(framename)

	local frame = data[framename]

	if frame and frame.changed then
	
		frame.changed = false
		
		if frame.visible then
			frame.hide()
		else
			frame.show()
		end
		
	end
	
end

function gui:frame(framename)
	return data[framename]
end