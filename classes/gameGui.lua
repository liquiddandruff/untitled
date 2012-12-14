local guiList = {}

function guiList:hide()
	for i,v in pairs(guiList) do
		if type(v) ~= "function" then
			v:SetVisible(false)
		end
	end
end

function guiList:show()
	for i,v in pairs(guiList) do
		if type(v) ~= "function" then
			v:SetVisible(true)
		end
	end
end

local examplesframe = loveframes.Create("frame")
examplesframe:SetName("Examples List")
examplesframe:SetWidth(180)					--SetSize(180, 120)--love.graphics.getHeight() - 330
examplesframe:SetPos(0, lg.getHeight())		-- -120
examplesframe.internals[1].OnClick = function()
	examplesframe:SetVisible(false)
end
guiList["examplesframe"] = examplesframe

------------------------------------
-- examples list
------------------------------------
local exampleslist = loveframes.Create("list", examplesframe)
exampleslist:SetSize(exampleslist:GetParent():GetSize(), exampleslist:GetParent():GetHeight()-25)
exampleslist:SetPos(0, 25)
exampleslist:SetPadding(5)
exampleslist:SetSpacing(5)
exampleslist:SetDisplayType("vertical")

------------------------------------
-- button example
------------------------------------
local buttonexample = loveframes.Create("button")
buttonexample:SetText("Button")
buttonexample.OnClick = function(object1, x, y)
	--[[bad]]
	if guiList["buttonexample"] then														-- toggle visibility
		guiList["buttonexample"]:Remove()
		guiList["buttonexample"]=nil
		return
	end
	
	local frame1 = loveframes.Create("frame")
	frame1:SetName("Button")
	frame1:Center()
	frame1.OnClose = function()
		guiList["buttonexample"]  = nil
	end
	
	local button1 = loveframes.Create("button", frame1)
	button1:SetWidth(200)
	button1:SetText("Button")
	button1:Center()
	button1.OnClick = function(object2, x, y)
		object2:SetText("You clicked the button!")
	end
	button1.OnMouseEnter = function(object2)
		object2:SetText("The mouse entered the button.")
	end
	button1.OnMouseExit = function(object2)
		object2:SetText("The mouse exited the button.")
	end
	
	guiList["buttonexample"] = frame1
end
exampleslist:AddItem(buttonexample)

------------------------------------
-- checkbox example
------------------------------------
local checkboxexample = loveframes.Create("button")
checkboxexample:SetText("Checkbox")
checkboxexample.OnClick = function(object1, x, y)
	--[[
	local created = guiList["checkboxexample"] 
	if created then														-- toggle visibility
		created:SetVisible(not created:GetVisible())
		return
	end]]
	if guiList["checkboxexample"] then
		guiList["checkboxexample"]:Remove()
		guiList["checkboxexample"]=nil
		return
	end
	
	local frame1 = loveframes.Create("frame")
	frame1:SetName("Checkbox")
	frame1:Center()
	frame1:SetHeight(85)
	frame1.OnClose = function()
		guiList["checkboxexample"]  = nil
	end
	
	local checkbox1 = loveframes.Create("checkbox", frame1)
	checkbox1:SetText("Checkbox 1")
	checkbox1:SetPos(5, 30)
	--checkbox1:SetFont(love.graphics.newFont(50))
	checkbox1.OnChanged = function(object2)
	end
	
	local checkbox2 = loveframes.Create("checkbox", frame1)
	checkbox2:SetText("Checkbox 2")
	checkbox2:SetPos(5, 60)
	checkbox2.OnChanged = function(object3)
	end
	
	guiList["checkboxexample"] = frame1	
end
exampleslist:AddItem(checkboxexample)

------------------------------------
-- collapsible category example
------------------------------------
local collapsiblecategoryexample = loveframes.Create("button")
collapsiblecategoryexample:SetText("Collapsible Category")
collapsiblecategoryexample.OnClick = function(object1, x, y)
	--[[
	local created = guiList["catexample"] 
	if created then														-- toggle visibility
		created:SetVisible(not created:GetVisible())
		return
	end]]
	if guiList["catexample"] then
		guiList["catexample"]:Remove()
		guiList["catexample"]=nil
		return
	end
	
	local frame1 = loveframes.Create("frame")
	frame1:SetName("Collapsible Category")
	frame1:SetSize(500, 300)
	frame1:Center()
	frame1.OnClose = function()
		guiList["catexample"]  = nil
	end
	
	local panel1 = loveframes.Create("panel")
	panel1:SetVisible(false)
	panel1:SetHeight(230)
		
	local collapsiblecategory1 = loveframes.Create("collapsiblecategory", frame1)
	collapsiblecategory1:SetPos(5, 30)
	collapsiblecategory1:SetSize(490, 265)
	collapsiblecategory1:SetText("Category 1")
	collapsiblecategory1:SetObject(panel1)
	
	guiList["catexample"] = frame1	
end
exampleslist:AddItem(collapsiblecategoryexample)


------------------------------------
-- cmd window
------------------------------------
local cmd = {visible = false, pos = {x=0,y=screenH}}
function cmd:show()
	local tabsframe = loveframes.Create("frame")
	tabsframe:SetName("Tabs")
	tabsframe:SetSize(500, 300)
	tabsframe:SetScreenLocked(true)
	tabsframe:SetPos(cmd.pos.x,cmd.pos.y)
	tabsframe.OnClose = function()
		cmd.pos.x,cmd.pos.y = cmd.obj:GetPos()
		cmd.visible  = false
	end
	
	local tabs1 = loveframes.Create("tabs", tabsframe)
	tabs1:SetPos(5, 30)
	tabs1:SetSize(490, 265)

	local images = {"accept.png", "add.png", "application.png", "building.png", "bin.png", "database.png", "box.png", "brick.png"}

	for i=1, 4 do
		local panel1 = loveframes.Create("panel")
		panel1.Draw = function()					-- empty draw; don't draw border
		end		
		
		local text1 = loveframes.Create("text", panel1)
		tabs1:AddTab("Tab " ..i, panel1, "Tab " ..i, "resources/images/" ..images[math.random(1, #images)])
		text1:SetText("Tab " ..i)
		text1:Center()	
	end
	
	cmd.obj = tabsframe
	cmd.visible = true
end
function cmd:hide()
	if cmd.obj then
		cmd.pos.x,cmd.pos.y = cmd.obj:GetPos()
		cmd.obj:Remove()
		cmd.visible = false
	end
end
function cmd:SetVisible(x)
	if x then cmd:show() else cmd:hide() end
end
guiList["cmd"] = cmd

--[[
------------------------------------
-- tabs example
------------------------------------
local tabsexample = loveframes.Create("button")
tabsexample:SetText("Tabs")
tabsexample.OnClick = function(object1, x, y)

	if guiList["tabsframe"] then
		guiList["tabsframe"]:Remove()
		guiList["tabsframe"]=nil
		return
	end
	
	local tabsframe = loveframes.Create("frame")
	tabsframe:SetName("Tabs")
	tabsframe:SetSize(500, 300)
	tabsframe:SetScreenLocked(true)
	tabsframe:Center()
	tabsframe.OnClose = function()
		guiList["tabsframe"]  = nil
	end
	
	local tabs1 = loveframes.Create("tabs", tabsframe)
	tabs1:SetPos(5, 30)
	tabs1:SetSize(490, 265)
	
	local images = {"accept.png", "add.png", "application.png", "building.png", "bin.png", "database.png", "box.png", "brick.png"}
	
	for i=1, 4 do
	
		local panel1 = loveframes.Create("panel")
		panel1.Draw = function()					-- empty draw; don't draw border
		end		

		
		local text1 = loveframes.Create("text", panel1)
		tabs1:AddTab("Tab " ..i, panel1, "Tab " ..i, "resources/images/" ..images[math.random(1, #images)])
		text1:SetText("Tab " ..i)
		text1:Center()

		--text1:SetAlwaysUpdate(true)
		--text1.Update = function(object, dt)
		--	object:Center()
		--end
		
	end
	
	guiList["tabsframe"] = tabsframe	
	guiList["tabsframe"].create = tabsexample.OnClick
end
exampleslist:AddItem(tabsexample)
]]
return guiList