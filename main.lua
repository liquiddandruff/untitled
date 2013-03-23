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
require("libs/gamestate")
require("libs/soundmanager")
require("libs/utils")

--states
require("states/intro")
require("states/menu")
require("states/game")
require("states/lost")

--classes
require("classes/clientUdp")
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

	-- Resources
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

	
	local function server_data(data)
		nMngr.rcvCount	= nMngr.rcvCount + 1
		nMngr.rcvSize	= nMngr.rcvSize + #data
		
		local header, body = data:match("^(%S*) (.*)")
		
		--print(data)
		
		-- movement packet
		if header == "ID_1" then	
			nMngr:push(body)

		-- on join/disconnect
		elseif header == "ID_0" then

			local peerid = body:match("^(%S*)")
			print(peerid)
			-- drop client if client exists, create client if client doesn't exist
			if nMngr.peers[peerid] then				
				nMngr:dropPeer(peerid)
				print(peerid.." has disconnected")
			else
				if peerid ~= client.id then
					print(peerid.." has joined")
					nMngr:createPeer(peerid)
				else
					print("Received ID_0 from self: This means that we have been dropped from the server")
				end
			end
			
			print(nMngr:numPeers())

		-- information packet
		elseif header == "ID_2" then			
			--local name,peerid = body:match("^(.-):(.+)$")
			local name, peerid = body:match("^(.-) (%S*)$")
			
			print(string.format("Body:%sName:%sPeerID:%s", body, name, peerid))

			if peerid ~= client.id then
				-- update client's name if client exists, else create the client
				if nMngr.peers[peerid] then			
					local peer = nMngr.peers[peerid].peer
					peer.name 	= name		
				else
					nMngr:setName(name, peerid)
					--nMngr:createPeer(peerid)
					--print(peerid.." has joined LATE")
				end
			end

		end
		
	end
	-- 145 000 K mem
	
	game.didHandshake		= false
	game.connectTime		= love.timer.getTime()

	client 					= clientUdp:new("174.6.80.110", 4141)
	client.recvCallback		= server_data

	nMngr					= netManager:new(client)
	
	Gamestate.registerEvents()
	Gamestate.switch(Gamestate.intro)
end

