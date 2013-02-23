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
	lg.print(state.introText.text,screenWc-state.introFontHeight*0.5,state.introText.y)
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