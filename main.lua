--global defines
lg			= 	love.graphics
release		=	true
showDebug	= 	false

--global variables
screenW		= 	lg.getWidth()
screenH		= 	lg.getHeight()
screenWc	=	screenW*0.5
screenHc	=	screenH*0.5

--save!
viewpanfactor = 0.1

--libs
require("libs/loveframes/init")
require("libs/button")
require("libs/SECS")
tween 	= require("libs/tween/tween")
camera	= require("libs/hump/camera")
vec		= require("libs/hump/vector")
--timer 	= require("libs/hump/timer")
require("libs/LUBE")

--require("libs/debug_unstable") --screws up key detection fixed sorta, and laggs game	--make custom debug
require("libs/gamestate")
require("libs/soundmanager")
require("libs/utils")


--states
require("states/intro")
require("states/menu")
require("states/game")
require("states/lost")


--classes
require("classes/gui")
require("classes/clientBuffer")
require("classes/net manager")
shash = require("classes/spacialhash")
require("classes/actor")
require("classes/peerPlayer")
require("classes/player")
require("classes/zombie")
require("classes/area")
require("classes/minimap")

function love.run()
    math.randomseed(os.time())
    math.random() math.random()
	--file = io.open("log.txt","w")
	--file:write(math.random())
    if love.load then love.load(arg) end

    local dt = 0

    -- Main loop time.
    while true do
        -- Process events.
        if love.event then
            love.event.pump()
            for e,a,b,c,d in love.event.poll() do
                if e == "quit" then
                    if not love.quit or not love.quit() then
                        if love.audio then
                            love.audio.stop()
                        end
						client:disconnect()
                        return
                    end
                end
                love.handlers[e](a,b,c,d)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then
            love.timer.step()
            dt = love.timer.getDelta()
        end

        -- Call update and draw
        if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
        if love.graphics then
            love.graphics.clear()
            if love.draw then love.draw() end
        end

        if love.timer then love.timer.sleep(0.001) end
        if love.graphics then love.graphics.present() end

    end

end

function love.load() 
	math.random()
	--game.r_data = 0
	
	
	lg.setBackgroundColor(0,0,0)
	love.mouse.setGrab(false)
	love.mouse.setVisible(true)

	--Resources
	color =	{	menubackground 	= {240,243,247},
				introbackground = {0,0,0},
				hover 			= {0,0,0},
				text 			= {76,77,78},
				overlay 		= {250,250,250,190}	}
	font =	{	default 		= lg.newFont(18),
				tiny			= lg.newFont(10),
				small 			= lg.newFont(15),
				large 			= lg.newFont(32),
				huge 			= lg.newFont(72)	}

	ui 				= {}
	loadfromdir(ui				, "resources/ui"			, "png", lg.newImage)
	
	images 			= {}
	images.player	= {}
	images.zombie 	= {}
	loadfromdir(images			,"resources/images"			, "png", lg.newImage)
	loadfromdir(images.player	,"resources/images/player"	, "png", lg.newImage)
	loadfromdir(images.zombie	,"resources/images/zombie"	, "png", lg.newImage)

	sounds 			= {}
	loadfromdir(sounds			, "resources/sounds"		, "ogg", love.sound.newSoundData)

	music 			= {}
	loadfromdir(music			, "resources/music"			, "wav", love.audio.newSource)

	
	function server_data(data)
		nMngr.rcvCount	= nMngr.rcvCount + 1
		nMngr.rcvSize	= nMngr.rcvSize + #data
		
		local header, body = data:match("^(%S*) (.*)")
		
		--print(data)

		if header == "ID_0" then				-- on join/disconnect
			local peerid = body:match("^(%S*)")
			print(peerid)
			if nMngr.peers[peerid] then				-- drop client if client exists
				nMngr:dropPeer(peerid)
				print(peerid.." has disconnected")
			else
				nMngr:createPeer(peerid)				-- create client if client doesn't exist
				print(peerid.." has joined")
			end
			
			print(nMngr:numPeers())
			
		elseif header == "ID_1" then			-- movement packet
			
			nMngr:push(body)
			
			--local x,y,xvel,yvel,rotDeg,fired,health,peerid = body:match("^(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.+)$")		-- everything before : everything before : everything 
			--%f %f %f %f %f %s %f
			--this aint working right
			
			--[[ THIS BLOCK
			local x,y,xvel,yvel,rotDeg,fired,health,peerid = body:match("^(%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*) (%S*)|")
			if peerid ~= client.id then
				local peer 		= nMngr.peers[peerid].peer
				local tonumber	= tonumber
				peer.health 		= tonumber(health)
				peer.fired			= tonumber(fired) --== "1" and true or false	
				peer.r 				= rotDeg
				
				x,y = tonumber(x),tonumber(y)
	
				if x ~= 0 and y ~= 0 then
					x,y = x*0.65,y*0.65
				end	

				peer.xInput,peer.yInput = x,y]]
				
				--peer.acc 			= peer.acc + vec(x*peer.maxforce*20,y*peer.maxforce*20)
				
				--[[
				--nMngr.peers[peerid].peer.acc = vec(tonumber(xacc),tonumber(yacc))	
				local newvel		= vec(tonumber(xvel)	,tonumber(yvel))
				local newpos 		= vec(tonumber(x)		,tonumber(y))
				local currpos 		= peer.pos

				local offset 		= newpos - (currpos+newvel)
				local offsetl 		= offset:len()
				
				if offsetl > 10 then 
					peer.pos = newpos 
					--print(peerid.." position changed aruptly")
				elseif offsetl > 2 then
					offset = offset:normalized() * offsetl*0.2
					--print(offsetl)
					newvel = newvel + offset
				end
				
				peer.vel = newvel
				--]]
				
			--end
			
		elseif header == "ID_2" then			-- information packet
			--local name,peerid = body:match("^(.-):(.+)$")
			local name, peerid = body:match("^(.-) (%S*)$")
			
			print(string.format("Body:%sName:%sPeerID:%s", body, name, peerid))

			if peerid ~= client.id then
			
				if nMngr.peers[peerid] then			-- if this client exists
					local peer = nMngr.peers[peerid].peer
					
					peer.name 	= name		-- then modify his name
				else
					nMngr:setName(name, peerid)
					--nMngr:createPeer(peerid)			-- then create client
					--print(peerid.." has joined LATE")
				end
			end

		end
		
	end
	-- 145 000 K mem
    client 					= lube.udpClient:new()
    client.handshake 		= "ID_HS"	
	--client.callbacks.hs		= hs
	client.callbacks.recv 	= server_data

	game.didhandshake		= false
	game.connectTime		= love.timer.getTime()
	client:setPing(true,4,"!")
    client:connect("174.6.70.212", 7777)

	nMngr					= netManager:new(client)
	
	Gamestate.registerEvents()
	Gamestate.switch(Gamestate.intro)
end

