Gamestate.menu = Gamestate.new()
local state = Gamestate.menu

local playerName = "Nameless"
local name 

local dmenu
function state:enter()
	lg.setBackgroundColor(unpack(color["menubackground"]))
	self.buttons = {new 			= Button.create("New Game", screenWc		, screenH * 0.4),
					instructions 	= Button.create("Instructions", screenWc	, screenH * 0.5),
					options 		= Button.create("Options", screenWc			, screenH * 0.6),
					quit 			= Button.create("Quit", screenWc			, screenH * 0.8) }
					

	loveframes.config["DEBUG"] = showDebug

	if not name then
		local ghosttext = "Name"
		name = loveframes.Create("textinput")
		name.font = font["small"]
		name.text = ghosttext
		name.OnTextEntered = function(name1,ckey)
			playerName = name.text
		end
		name.Update = function(name1,dt)
			if name.focus and name.text == ghosttext then
				name.text = ""
			elseif not name.focus and name.text == "" then
				name.text = ghosttext
			end
		end
		name:SetWidth(250)
		name:SetPos(screenWc-name.width*0.5, screenH * 0.2)
	else
		name:SetPos(screenWc-name.width*0.5, screenH * 0.2)
		name.visible = true
	end
	

	--tween(2,name,{x = name.x + 300},'inOutExpo')

	-- examples menu
	dmenu = showDebug and loveframes.debug.ExamplesMenu() or nil
	
	-- skin menu
	--loveframes.debug.SkinSelector()				
end

function state:leave()
	if dmenu then
		dmenu:Remove()
	end
	name.visible = false
	
	love.audio.stop()
end

function state:update(dt)
	tween.update(dt)
	client:update(dt)
	loveframes.update(dt)		
	
	for n,b in pairs(self.buttons) do
		b:update(dt)
	end
	soundmanager:update(dt)
end

function state:draw()
	loveframes.draw()
	for n,b in pairs(self.buttons) do
		b:draw()
	end
end

function state:mousepressed(x,y,button)
	loveframes.mousepressed(x, y, button)
	for n,b in pairs(self.buttons) do
		if b:mousepressed(x,y,button) then
			if n == "new" then
				Gamestate.switch(Gamestate.game,playerName)	
			elseif n == "instructions" then
				--Gamestate.switch(Gamestate.game,playerName)
			elseif n == "options" then
				--Gamestate.switch(Gamestate.game,playerName)
			elseif n == "quit" then
				love.event.push("quit")
			end
		end
	end
	
end

function state:mousereleased(x,y,button)
	loveframes.mousereleased(x, y, button)
end

function state:keypressed(key, unicode)
	loveframes.keypressed(key, unicode)
	if key == "return" then
		Gamestate.switch(Gamestate.game,playerName)
	elseif key == "escape" then
		love.event.quit()
	end
	if key == "``" then
		loveframes.config["DEBUG"] = not loveframes.config["DEBUG"]
	end	
end

function state:keyreleased(key)
	loveframes.keyreleased(key)
end