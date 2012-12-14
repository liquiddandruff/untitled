Gamestate.lost = Gamestate.new()
local state = Gamestate.lost

local score

local lost

function state:enter(last, sc)
	lg.setBackgroundColor(unpack(color["menubackground"]))
	lg.setFont(font["huge"])
	
	lost = "You lost the game."
	
	score = sc
end

function state:update(dt)
	soundmanager:update(dt)
end

function state:draw()
	lg.setColor(0,0,0)
	
	lg.print(lost, screenWc-font["huge"]:getWidth(lost)/2, screenHc*0.5)
	--lg.print("Score: " .. score, 100, 200, 600, "center")
end

function state:keypressed(key, unicode)
	if key == "return" then
		love.audio.stop()
		Gamestate.switch(Gamestate.menu)
	elseif key == "escape" then
		love.event.push("quit")
	end
end
