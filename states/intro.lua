Gamestate.intro = Gamestate.new()

local state = Gamestate.intro

function state:enter()
	lg.setBackgroundColor(unpack(color["introbackground"]))
	
	state.timer				= 0
	state.menuCue			= 3.6
	state.played 			= {}
	
	state.introFont 		= lg.newFont("resources/fonts/accid.ttf", 20)
	state.introFontHeight	= state.introFont:getHeight()
	state.introText			= {text = "hi", y = -200}

	tween(3, state.introText, { y = screenHc-state.introFontHeight }, "outBounce")
	
	lg.setFont(state.introFont)
end

function state:update(dt)
	tween.update(dt)
	client:update(dt)
	soundmanager:update(dt)
	state.timer = state.timer + dt
	
	if state.timer > state.menuCue then
		Gamestate.switch(Gamestate.menu)
	end
end

function state:draw()
	--screenWc-introfont:getWidth(state.introtext)/2,screenHc-introfont:getHeight()/2
	lg.print(state.introText.text,screenWc-state.introFontHeight*0.5,state.introText.y)
	--[[
	if state.played.impact then
		lg.draw(images.gaycity, 7, 147)
		lg.setColor(233, 233, 233, math.max(0, 255+((math.min(0, (state.timer-state.explodeCue)*-0.8)*510)/2)))
		lg.rectangle("fill", 0, 0, 800, 600)
		lg.setColor(255, 255, 255, 255)
	elseif state.played.bombfall then
		lg.draw(images.bg, 198, 224)
		lg.draw(images.city, 243, 253)
		lg.draw(images.bomb, 388, (state.timer-state.bombCue)*170-100)
	else
		lg.draw(images.bg, 198, 224)
		lg.draw(images.city, 243, 253)
	end
	--]]
end

function state:keypressed(key, unicode)
	Gamestate.switch(Gamestate.menu)
end

function state:mousepressed(button)
	Gamestate.switch(Gamestate.menu)
end

function state:leave()
	love.audio.stop()
end