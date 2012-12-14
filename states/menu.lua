Gamestate.menu = Gamestate.new()
local state = Gamestate.menu
local playername = "Nameless"
local name 

local dmenu
local i
function state:enter()
	i = 0
	lg.setBackgroundColor(unpack(color["menubackground"]))
	self.buttons = {new 			= Button.create("New Game", screenWc		, screenH * 0.4),
					instructions 	= Button.create("Instructions", screenWc	, screenH * 0.5),
					options 		= Button.create("Options", screenWc			, screenH * 0.6),
					quit 			= Button.create("Quit", screenWc			, screenH * 0.8) }
					

	loveframes.config["DEBUG"] = showDebug--not loveframes.config["DEBUG"]

--[[
	local frame1 = loveframes.Create("frame")
	frame1:SetName("Text Input")
	frame1:SetSize(350, 60)
	frame1:Center()
	frame1:SetPos(screenWc-frame1.width/2, screenH * 0.2)
	]]
	if not name then
		local ghosttext = "Name"
		name = loveframes.Create("textinput")
		name.font = font["small"]
		name.text = ghosttext
		name.OnTextEntered = function(name1,ckey)
			playername = name.text
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

	-- load the examples menu
	dmenu = showDebug and loveframes.debug.ExamplesMenu() or nil
	
	-- load the skin selector menu
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
	
	i = i + dt
	if i > 2.5 then
		client:send(" ")
		i = 0
	end
		
	
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
				Gamestate.switch(Gamestate.game,playername)	
			elseif n == "instructions" then
				--Gamestate.switch(Gamestate.game,playername)
			elseif n == "options" then
				--Gamestate.switch(Gamestate.game,playername)
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
		Gamestate.switch(Gamestate.game,playername)
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
--[[
Gamestate.menu = Gamestate.new()
local state = Gamestate.menu

local font
local titlefont
local subtitlefont
local menufont
local submenufont

function state:enter()
  if not font then font = lg.getFont() end
  if not titlefont then titlefont = lg.newFont("resources/fonts/note_this.otf", 110) end --burnstown_dam
  if not subtitlefont then subtitlefont = lg.newFont("resources/fonts/accid.ttf", 32) end
  if not menufont then menufont = lg.newFont("resources/fonts/accid.ttf", 24) end
  if not submenufont then submenufont = lg.newFont("resources/fonts/accid.ttf", 16) end
  lg.setBackgroundColor(236,227,200)

  --soundmanager:playMusic(music.ritd)
end

function state:leave()
	love.audio.stop()
end

function state:update(dt)
	soundmanager:update(dt)
	client:update(dt)
end

function state:draw()
	lg.setColor(255,255,255)
	lg.draw(ui.mainmenu, 0, 0)


	lg.setColor(30, 30, 30)
	lg.setFont(titlefont)
	lg.print("blahblah", 90+screenWc-titlefont:getWidth("blahblah")/2, 175) --  lg.print("the game", screenWc-titlefont:getWidth("the game")/2, 175)
	lg.setFont(subtitlefont)
	lg.print("if something bad happens, press escape and left click",50, 20) --180
	lg.setFont(menufont)
	lg.print("Controls", screenWc-menufont:getWidth("Controls")/2, 325)
	lg.setFont(submenufont)
	lg.print("Movement:", 250, 350)
	--lg.print("Swing lasso:", 250, 370)
	lg.print("Shoot:", 250, 390)
	--lg.print("Release zombie:", 250, 410)
	lg.print("WASD / Arrow keys", 390, 350)
	--lg.print("Hold left mouse button", 390, 370)
	lg.print("Left Click", 390, 390)
	--lg.print("Single click", 390, 410)

	lg.setFont(subtitlefont)
	lg.print("Click to start", screenWc-subtitlefont:getWidth("Click to start")/2, 500)
end

function state:keypressed(key, unicode)
	if key == "return" then
		Gamestate.switch(Gamestate.game)
	elseif key == "escape" then
		love.event.quit()
	end
end

function state:mousepressed(x,y,button)
  if button == "l" then
    Gamestate.switch(Gamestate.game)
  end
end
--]]