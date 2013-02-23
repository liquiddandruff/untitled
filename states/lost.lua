Gamestate.lost = Gamestate.new()
local state = Gamestate.lost

function state:enter(last, sc)
	lg.setBackgroundColor(unpack(color["menubackground"]))
	lg.setFont(font["huge"])
	
	state.lostMsg 	= "You lost the game."
	state.score 	= sc
end

function state:update(dt)
	soundmanager:update(dt)
end

function state:draw()
	lg.setColor(0,0,0)
	
	lg.print(state.lostMsg, screenWc-font["huge"]:getWidth(state.lostMsg)/2, screenHc*0.5)
end

function state:keypressed(key, unicode)
	if key == "return" then
		love.audio.stop()
		Gamestate.switch(Gamestate.menu)
	elseif key == "escape" then
		love.event.push("quit")
	end
end
