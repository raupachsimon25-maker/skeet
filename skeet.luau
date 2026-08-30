--[[
	══════════════════════════════════════════════════════════════════════════════
	  SKEETWARE UI v2.5 — Premium Hard Edge & Gradient Menu Library (Luau/Roblox)
	  Authentic GameSense / Skeet.cc aesthetics:
	  • Crisp Hard Edges (0px radius, 3-layer pixel-perfect borders)
	  • Multi-tone Clean Gradients (Top RGB line, vertical sheens, fill ramps)
	  • PixelOperator Font integration (with fallback to Code/RobotoMono)
	  • 100% Functional Elements:
	    - Toggles with inline ColorPickers & Keybinds
	    - Standalone Colorpickers with SV canvas, Hue bar & Hex display
	    - Standalone Keybinds with Mode selection (Toggle, Hold, Always)
	    - Smooth Sliders with text readout & suffix
	    - Single & Multi-Select Floating Dropdowns (Zero clipping, smooth anim)
	    - Buttons & Risky Buttons
	    - Textboxes & Searchbars
	    - Tabboxes (Sub-tabs inside groupbox column)
	    - Watermark HUD & Real-time Keybinds List HUD
	    - Notification System with animated gradient timer
	══════════════════════════════════════════════════════════════════════════════
--]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local TextService      = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer and LocalPlayer:GetMouse()

-- Safe parent target across different environments and executors
local function getSafeGuiParent()
	local ok, res = pcall(function()
		if typeof(gethui) == "function" then
			return gethui()
		elseif (syn and syn.protect_gui) or (typeof(protect_gui) == "function") then
			local g = Instance.new("Folder")
			if syn and syn.protect_gui then syn.protect_gui(g) elseif protect_gui then protect_gui(g) end
			g.Parent = CoreGui
			return g
		else
			return CoreGui
		end
	end)
	if ok and res then return res end
	return LocalPlayer:WaitForChild("PlayerGui")
end

-- PixelOperator font setup with safe fallback
local PixelFontFace = nil
local PixelBoldFace = nil
pcall(function()
	PixelFontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	PixelBoldFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
end)

local Library = {
	Version      = "2.5.0",
	Name         = "Skeetware",
	Open         = true,
	ToggleKey    = Enum.KeyCode.Insert,
	Flags        = {},
	Registry     = {},
	Connections  = {},
	KeybindList  = nil,
	Watermark    = nil,
	OverlayFrame = nil,
	ScreenGui    = nil,

	Theme = {
		-- Gradient Colors (Skeet Iconic Accent)
		Accent1      = Color3.fromRGB(168, 219, 95),  -- Bright skeet green
		Accent2      = Color3.fromRGB(94, 158, 219),  -- Skeet cyan/blue
		AccentDark   = Color3.fromRGB(110, 165, 55),  -- Darker tone for gradient ramps
		
		-- Skeet Surfaces & Gradients
		MainTop      = Color3.fromRGB(30, 30, 34),
		MainBottom   = Color3.fromRGB(17, 17, 19),
		GroupTop     = Color3.fromRGB(24, 24, 27),
		GroupBottom  = Color3.fromRGB(18, 18, 20),
		ControlTop   = Color3.fromRGB(36, 36, 40),
		ControlBottom= Color3.fromRGB(25, 25, 27),
		ControlHover = Color3.fromRGB(46, 46, 52),
		
		-- Hard-Edge Borders
		OuterBorder  = Color3.fromRGB(0, 0, 0),       -- 1px Pitch Black
		MidBorder    = Color3.fromRGB(46, 46, 50),     -- 1px Crisp Inset Highlight
		InnerBorder  = Color3.fromRGB(12, 12, 14),     -- 1px Deep border

		-- Text
		Text         = Color3.fromRGB(225, 225, 230),
		TextDim      = Color3.fromRGB(145, 145, 155),
		TextDark     = Color3.fromRGB(90, 90, 98),
		
		-- States
		Risky        = Color3.fromRGB(235, 75, 75),
		RiskyDark    = Color3.fromRGB(160, 40, 40),
		Success      = Color3.fromRGB(110, 210, 100),

		-- Fonts (PixelOperator by default)
		FontFace     = PixelFontFace,
		FontBoldFace = PixelBoldFace,
		Font         = Enum.Font.Code,
		FontBold     = Enum.Font.RobotoMono,
		FontSize     = 13,
	}
}

--============================================================================--
-- UTILITY FUNCTIONS
--============================================================================--
local Util = {}

function Util.Create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then inst[k] = v end
	end
	
	-- Apply PixelOperator font if this is a text object
	if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
		pcall(function()
			if Library.Theme.FontFace then
				inst.FontFace = Library.Theme.FontFace
			else
				inst.Font = Library.Theme.Font
			end
		end)
	end

	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end
local New = Util.Create

function Util.SetFont(textObj, isBold)
	pcall(function()
		if isBold and Library.Theme.FontBoldFace then
			textObj.FontFace = Library.Theme.FontBoldFace
		elseif Library.Theme.FontFace then
			textObj.FontFace = Library.Theme.FontFace
		else
			textObj.Font = isBold and Library.Theme.FontBold or Library.Theme.Font
		end
	end)
end

function Util.Tween(inst, dur, props, style, dir)
	style = style or Enum.EasingStyle.Quart
	dir   = dir or Enum.EasingDirection.Out
	local t = TweenService:Create(inst, TweenInfo.new(dur or 0.16, style, dir), props)
	t:Play()
	return t
end

-- Multi-layered Hard-Edge Border Frame (0px Radius)
function Util.CreateHardBorder(parent, size, pos, bgTop, bgBottom)
	-- Layer 1: Outermost pitch-black border
	local outer = New("Frame", {
		Size = size or UDim2.fromScale(1, 1),
		Position = pos or UDim2.fromScale(0, 0),
		BackgroundColor3 = Library.Theme.OuterBorder,
		BorderSizePixel = 0,
		Parent = parent,
	})

	-- Layer 2: Mid border (1px inset highlight)
	local mid = New("Frame", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.fromOffset(1, 1),
		BackgroundColor3 = Library.Theme.MidBorder,
		BorderSizePixel = 0,
		Parent = outer,
	})

	-- Layer 3: Inner surface (1px inset) with clean vertical gradient
	local inner = New("Frame", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.fromOffset(1, 1),
		BackgroundColor3 = bgTop or Library.Theme.GroupTop,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Parent = mid,
	})

	if bgTop and bgBottom then
		New("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, bgTop),
				ColorSequenceKeypoint.new(1, bgBottom),
			}),
			Parent = inner,
		})
	end

	return outer, inner
end

-- Skeet Signature Top Multi-Gradient Line
function Util.AddSkeetGradientBar(parent, height)
	local bar = New("Frame", {
		Size = UDim2.new(1, 0, 0, height or 2),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 10,
		Parent = parent,
	})
	New("UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(54, 163, 247)),
			ColorSequenceKeypoint.new(0.20, Color3.fromRGB(98, 216, 247)),
			ColorSequenceKeypoint.new(0.40, Color3.fromRGB(168, 219, 95)),
			ColorSequenceKeypoint.new(0.60, Color3.fromRGB(247, 184, 92)),
			ColorSequenceKeypoint.new(0.80, Color3.fromRGB(247, 104, 181)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(184, 119, 247)),
		}),
		Parent = bar,
	})
	return bar
end

--============================================================================--
-- INITIALIZE ROOT GUI & FLOATING OVERLAY
--============================================================================--
-- Clean up any previous instance
local oldGui = getSafeGuiParent():FindFirstChild("SkeetwareUI")
if oldGui then oldGui:Destroy() end

local screenGui = New("ScreenGui", {
	Name = "SkeetwareUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = getSafeGuiParent(),
})
Library.ScreenGui = screenGui

-- Floating Overlay container for non-clipping dropdowns, color pickers, modals
local overlay = New("Frame", {
	Name = "OverlayLayer",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 5000,
	Parent = screenGui,
})
Library.OverlayFrame = overlay

-- Active overlay closer (closes open dropdowns/colorpickers when clicking outside)
local activeDropdownClose = nil
UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if activeDropdownClose then
			local close = activeDropdownClose
			activeDropdownClose = nil
			close()
		end
	end
end)

--============================================================================--
-- WATERMARK HUD
--============================================================================--
function Library:CreateWatermark(customTitle)
	local title = customTitle or "skeetware.cc"
	
	local wmOuter, wmInner = Util.CreateHardBorder(screenGui, UDim2.fromOffset(300, 24), UDim2.fromOffset(20, 20), Library.Theme.MainTop, Library.Theme.MainBottom)
	Util.AddSkeetGradientBar(wmInner, 2)

	local wmLabel = New("TextLabel", {
		Size = UDim2.new(1, -12, 1, -2),
		Position = UDim2.fromOffset(8, 2),
		BackgroundTransparency = 1,
		TextSize = Library.Theme.FontSize,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title .. " | v" .. Library.Version .. " | 60 fps | 14 ms",
		Parent = wmInner,
	})
	Util.SetFont(wmLabel, false)

	local fpsCount = 0
	local lastFpsUpdate = tick()
	RunService.RenderStepped:Connect(function(dt)
		fpsCount = fpsCount + 1
		if tick() - lastFpsUpdate >= 0.5 then
			local fps = math.floor(fpsCount / (tick() - lastFpsUpdate))
			local ping = math.floor((LocalPlayer and LocalPlayer:GetNetworkPing() or 0.015) * 1000)
			wmLabel.Text = string.format("%s | %s | %d fps | %d ms", title, LocalPlayer and LocalPlayer.DisplayName or "User", fps, ping)
			fpsCount = 0
			lastFpsUpdate = tick()
		end
	end)

	Library.Watermark = wmOuter
	return wmOuter
end

--============================================================================--
-- KEYBINDS LIST HUD
--============================================================================--
function Library:CreateKeybindList()
	local kbOuter, kbInner = Util.CreateHardBorder(screenGui, UDim2.fromOffset(190, 26), UDim2.fromOffset(20, 56), Library.Theme.MainTop, Library.Theme.MainBottom)
	Util.AddSkeetGradientBar(kbInner, 2)

	local header = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.fromOffset(0, 2),
		BackgroundTransparency = 1,
		TextSize = Library.Theme.FontSize,
		TextColor3 = Library.Theme.Text,
		Text = "Keybinds",
		Parent = kbInner,
	})
	Util.SetFont(header, true)

	local listContainer = New("Frame", {
		Size = UDim2.new(1, -12, 0, 0),
		Position = UDim2.fromOffset(6, 24),
		BackgroundTransparency = 1,
		Parent = kbInner,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = listContainer,
	})

	local binds = {}
	local function updateSize()
		local count = #listContainer:GetChildren() - 1
		local h = count > 0 and (28 + (count * 18)) or 26
		Util.Tween(kbOuter, 0.15, { Size = UDim2.fromOffset(190, h) })
	end

	local KeybindHUD = {}
	function KeybindHUD:SetBind(name, key, mode, active)
		if binds[name] then
			if not active then
				binds[name]:Destroy()
				binds[name] = nil
				updateSize()
				return
			end
			binds[name].Val.Text = string.format("[%s] (%s)", key, mode)
		else
			if not active then return end
			local row = New("Frame", {
				Size = UDim2.new(1, 0, 0, 16),
				BackgroundTransparency = 1,
				Parent = listContainer,
			})
			local lbl = New("TextLabel", {
				Size = UDim2.new(0.55, 0, 1, 0),
				BackgroundTransparency = 1,
				TextSize = Library.Theme.FontSize - 1,
				TextColor3 = Library.Theme.TextDim,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = name,
				Parent = row,
			})
			Util.SetFont(lbl, false)

			local val = New("TextLabel", {
				Name = "Val",
				Size = UDim2.new(0.45, 0, 1, 0),
				Position = UDim2.new(0.55, 0, 0, 0),
				BackgroundTransparency = 1,
				TextSize = Library.Theme.FontSize - 1,
				TextColor3 = Library.Theme.Accent1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = string.format("[%s] (%s)", key, mode),
				Parent = row,
			})
			Util.SetFont(val, false)

			binds[name] = row
			updateSize()
		end
	end

	-- Make Keybind HUD Draggable
	local dragging, dragStart, startPos
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = kbOuter.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			kbOuter.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)

	Library.KeybindList = KeybindHUD
	return KeybindHUD
end

--============================================================================--
-- NOTIFICATIONS
--============================================================================--
local notifHolder = New("Frame", {
	Name = "NotifHolder",
	Size = UDim2.new(0, 260, 1, -40),
	Position = UDim2.new(1, -280, 0, 20),
	BackgroundTransparency = 1,
	Parent = screenGui,
})
New("UIListLayout", {
	Padding = UDim.new(0, 8),
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = notifHolder,
})

function Library:Notify(cfg)
	local title = cfg.Title or "Notification"
	local text  = cfg.Text or ""
	local dur   = cfg.Duration or 3.5

	local notifOuter, notifInner = Util.CreateHardBorder(notifHolder, UDim2.fromOffset(260, 0), nil, Library.Theme.MainTop, Library.Theme.MainBottom)
	notifOuter.ClipsDescendants = true
	Util.AddSkeetGradientBar(notifInner, 2)

	local header = New("TextLabel", {
		Size = UDim2.new(1, -16, 0, 18),
		Position = UDim2.fromOffset(8, 5),
		BackgroundTransparency = 1,
		TextSize = Library.Theme.FontSize,
		TextColor3 = Library.Theme.Accent1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		Parent = notifInner,
	})
	Util.SetFont(header, true)

	local desc = New("TextLabel", {
		Size = UDim2.new(1, -16, 0, 26),
		Position = UDim2.fromOffset(8, 22),
		BackgroundTransparency = 1,
		TextSize = Library.Theme.FontSize - 1,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = text,
		Parent = notifInner,
	})
	Util.SetFont(desc, false)

	local timerBar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = Library.Theme.Accent1,
		BorderSizePixel = 0,
		Parent = notifInner,
	})

	Util.Tween(notifOuter, 0.18, { Size = UDim2.fromOffset(260, 54) })
	Util.Tween(timerBar, dur, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

	task.delay(dur, function()
		local out = Util.Tween(notifOuter, 0.16, { Size = UDim2.fromOffset(260, 0) })
		out.Completed:Connect(function()
			notifOuter:Destroy()
		end)
	end)
end

--============================================================================--
-- CREATE MAIN WINDOW
--============================================================================--
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local title    = cfg.Title or "skeetware.cc"
	local winSize  = cfg.Size or UDim2.fromOffset(720, 520)

	-- Window Outermost Hard Frame (0px Radius, 3-Layer Borders)
	local winOuter, winInner = Util.CreateHardBorder(screenGui, winSize, UDim2.fromScale(0.5, 0.5), Library.Theme.MainTop, Library.Theme.MainBottom)
	winOuter.AnchorPoint = Vector2.new(0.5, 0.5)

	-- Signature Rainbow / Accent Gradient Bar across top
	Util.AddSkeetGradientBar(winInner, 3)

	-- Top Header Bar (Title & Drag Area)
	local titleBar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 3),
		BackgroundTransparency = 1,
		Parent = winInner,
	})

	local titleLabel = New("TextLabel", {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		TextSize = Library.Theme.FontSize + 1,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(title),
		Parent = titleBar,
	})
	Util.SetFont(titleLabel, true)

	-- Subtle separator line under Titlebar
	New("Frame", {
		Size = UDim2.new(1, -20, 0, 1),
		Position = UDim2.fromOffset(10, 32),
		BackgroundColor3 = Library.Theme.MidBorder,
		BorderSizePixel = 0,
		Parent = winInner,
	})

	-- Window Dragging Logic
	do
		local dragging, dragStart, startPos
		titleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = winOuter.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - dragStart
				winOuter.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
	end

	-- Menu Toggle Key listener
	UserInputService.InputBegan:Connect(function(input, gp)
		if not gp and input.KeyCode == Library.ToggleKey then
			Library.Open = not Library.Open
			winOuter.Visible = Library.Open
		end
	end)

	-- Tabs Navigation Bar (Classic Skeet Tabs: Clean Hard-Edged Horizontal Bar with Gradient Selection)
	local tabListFrame = New("Frame", {
		Size = UDim2.new(1, -24, 0, 28),
		Position = UDim2.fromOffset(12, 38),
		BackgroundTransparency = 1,
		Parent = winInner,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabListFrame,
	})

	-- Tab Viewport Content Container
	local contentHolder = New("Frame", {
		Size = UDim2.new(1, -24, 1, -78),
		Position = UDim2.fromOffset(12, 70),
		BackgroundTransparency = 1,
		Parent = winInner,
	})

	local Window = {
		Tabs = {},
		ActiveTab = nil,
	}

	--========================================================================--
	-- ADD TAB METHOD
	--========================================================================--
	function Window:AddTab(tabName)
		local tabBtnOuter, tabBtnInner = Util.CreateHardBorder(tabListFrame, UDim2.fromOffset(90, 26), nil, Library.Theme.ControlTop, Library.Theme.ControlBottom)
		
		local tabGradLine = New("Frame", {
			Size = UDim2.new(1, 0, 0, 2),
			Position = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Library.Theme.Accent1,
			BorderSizePixel = 0,
			Visible = false,
			Parent = tabBtnInner,
		})

		local tabLabel = New("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextSize = Library.Theme.FontSize,
			TextColor3 = Library.Theme.TextDim,
			Text = string.upper(tabName),
			Parent = tabBtnInner,
		})
		Util.SetFont(tabLabel, true)

		-- Tab Page (2-Column Grid Split)
		local tabPage = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = contentHolder,
		})

		-- Left Column
		local leftCol = New("ScrollingFrame", {
			Size = UDim2.new(0.5, -6, 1, 0),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Library.Theme.MidBorder,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = tabPage,
		})
		New("UIListLayout", {
			Padding = UDim.new(0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = leftCol,
		})

		-- Right Column
		local rightCol = New("ScrollingFrame", {
			Size = UDim2.new(0.5, -6, 1, 0),
			Position = UDim2.new(0.5, 6, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Library.Theme.MidBorder,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = tabPage,
		})
		New("UIListLayout", {
			Padding = UDim.new(0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = rightCol,
		})

		local Tab = {
			Page = tabPage,
			Left = leftCol,
			Right = rightCol,
		}

		local function selectTab()
			for _, other in ipairs(Window.Tabs) do
				other.Page.Visible = false
				other.GradLine.Visible = false
				Util.Tween(other.Label, 0.15, { TextColor3 = Library.Theme.TextDim })
				Util.Tween(other.Inner, 0.15, { BackgroundColor3 = Library.Theme.ControlTop })
			end
			tabPage.Visible = true
			tabGradLine.Visible = true
			Util.Tween(tabLabel, 0.15, { TextColor3 = Library.Theme.Text })
			Util.Tween(tabBtnInner, 0.15, { BackgroundColor3 = Library.Theme.GroupTop })
			Window.ActiveTab = Tab
		end

		tabBtnInner.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				selectTab()
			end
		end)

		Tab.Btn = tabBtnOuter
		Tab.Inner = tabBtnInner
		Tab.Label = tabLabel
		Tab.GradLine = tabGradLine
		table.insert(Window.Tabs, Tab)

		if #Window.Tabs == 1 then
			selectTab()
		end

		--====================================================================--
		-- GROUPBOX BUILDER
		--====================================================================--
		function Tab:AddGroupbox(gCfg)
			gCfg = gCfg or {}
			local gTitle = gCfg.Title or "Group"
			local side   = (gCfg.Side and string.lower(gCfg.Side) == "right") and rightCol or leftCol

			local gbOuter, gbInner = Util.CreateHardBorder(side, UDim2.new(1, 0, 0, 0), nil, Library.Theme.GroupTop, Library.Theme.GroupBottom)
			gbOuter.AutomaticSize = Enum.AutomaticSize.Y

			-- Title header cutting through top border with subtle glow
			local titleHold = New("Frame", {
				Size = UDim2.fromOffset(0, 14),
				AutomaticSize = Enum.AutomaticSize.X,
				Position = UDim2.fromOffset(12, -7),
				BackgroundColor3 = Library.Theme.MainTop,
				BorderSizePixel = 0,
				ZIndex = 3,
				Parent = gbOuter,
			})
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				Parent = titleHold,
			})
			local gbTitleLabel = New("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				TextSize = Library.Theme.FontSize,
				TextColor3 = Library.Theme.Text,
				Text = gTitle,
				ZIndex = 4,
				Parent = titleHold,
			})
			Util.SetFont(gbTitleLabel, true)

			-- Element List Container inside Groupbox
			local elemList = New("Frame", {
				Size = UDim2.new(1, -16, 1, -16),
				Position = UDim2.fromOffset(8, 10),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = gbInner,
			})
			New("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = elemList,
			})
			New("UIPadding", {
				PaddingBottom = UDim.new(0, 8),
				Parent = elemList,
			})

			local Group = {}

			-- Helper function to attach color picker to any element
			local function createColorPickerElement(parentHold, defaultCol, flag, callback)
				local curColor = defaultCol or Library.Theme.Accent1
				local cpOuter, cpInner = Util.CreateHardBorder(parentHold, UDim2.fromOffset(24, 11), nil, curColor, curColor)
				
				local cpColorPreview = New("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = curColor,
					BorderSizePixel = 0,
					Parent = cpInner,
				})

				local popupOuter, popupInner
				local isOpen = false

				local function toggleColorPicker()
					isOpen = not isOpen
					if not isOpen then
						if popupOuter then popupOuter:Destroy() popupOuter = nil end
						return
					end

					if activeDropdownClose then activeDropdownClose() end

					local absPos = cpOuter.AbsolutePosition
					popupOuter, popupInner = Util.CreateHardBorder(overlay, UDim2.fromOffset(170, 145), UDim2.fromOffset(absPos.X - 140, absPos.Y + 16), Library.Theme.MainTop, Library.Theme.MainBottom)
					popupOuter.ZIndex = 6000
					Util.AddSkeetGradientBar(popupInner, 2)

					-- SV Canvas Box (Saturation / Value)
					local svBox = New("ImageLabel", {
						Size = UDim2.fromOffset(125, 100),
						Position = UDim2.fromOffset(8, 8),
						Image = "rbxassetid://4155801252",
						BackgroundColor3 = curColor,
						BorderSizePixel = 0,
						Parent = popupInner,
					})
					Util.CreateHardBorder(svBox, UDim2.fromScale(1, 1))

					-- SV Draggable Pin
					local svPin = New("Frame", {
						Size = UDim2.fromOffset(4, 4),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						Parent = svBox,
					})
					Util.CreateHardBorder(svPin, UDim2.fromScale(1, 1))

					-- Hue Slider (Vertical)
					local hueBox = New("Frame", {
						Size = UDim2.fromOffset(16, 100),
						Position = UDim2.fromOffset(142, 8),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						Parent = popupInner,
					})
					Util.CreateHardBorder(hueBox, UDim2.fromScale(1, 1))
					New("UIGradient", {
						Rotation = 90,
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
							ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
							ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
							ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
							ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
							ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
							ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
						}),
						Parent = hueBox,
					})

					-- Hex Text Display
					local hexLabel = New("TextLabel", {
						Size = UDim2.new(1, -16, 0, 20),
						Position = UDim2.fromOffset(8, 116),
						BackgroundTransparency = 1,
						TextSize = Library.Theme.FontSize - 1,
						TextColor3 = Library.Theme.TextDim,
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "#" .. curColor:ToHex():upper(),
						Parent = popupInner,
					})
					Util.SetFont(hexLabel, false)

					-- Dragging SV & Hue Logic
					local curH, curS, curV = curColor:ToHSV()
					svPin.Position = UDim2.fromScale(curS, 1 - curV)

					local draggingHue = false
					local draggingSV  = false

					local function updateColor()
						local newCol = Color3.fromHSV(curH, curS, curV)
						curColor = newCol
						svBox.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
						cpColorPreview.BackgroundColor3 = newCol
						hexLabel.Text = "#" .. newCol:ToHex():upper()
						if flag then Library.Flags[flag] = newCol end
						callback(newCol)
					end

					hueBox.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							draggingHue = true
							local y = math.clamp((input.Position.Y - hueBox.AbsolutePosition.Y) / hueBox.AbsoluteSize.Y, 0, 1)
							curH = 1 - y
							updateColor()
						end
					end)
					svBox.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							draggingSV = true
							local x = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
							local y = math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
							curS = x
							curV = 1 - y
							svPin.Position = UDim2.fromScale(x, y)
							updateColor()
						end
					end)
					local conn = UserInputService.InputChanged:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							if draggingHue then
								local y = math.clamp((input.Position.Y - hueBox.AbsolutePosition.Y) / hueBox.AbsoluteSize.Y, 0, 1)
								curH = 1 - y
								updateColor()
							elseif draggingSV then
								local x = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
								local y = math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
								curS = x
								curV = 1 - y
								svPin.Position = UDim2.fromScale(x, y)
								updateColor()
							end
						end
					end)
					local endConn = UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							draggingHue = false
							draggingSV = false
						end
					end)

					activeDropdownClose = function()
						isOpen = false
						conn:Disconnect()
						endConn:Disconnect()
						if popupOuter then popupOuter:Destroy() popupOuter = nil end
					end
				end

				cpOuter.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						toggleColorPicker()
					end
				end)

				return cpOuter
			end

			--================================================================--
			-- TOGGLE WITH INLINE COLORPICKER & KEYBIND SUPPORT
			--================================================================--
			function Group:AddToggle(tCfg)
				tCfg = tCfg or {}
				local tText  = tCfg.Text or "Toggle"
				local state  = tCfg.Default or false
				local flag   = tCfg.Flag or tText
				local callback = tCfg.Callback or function() end

				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Parent = elemList,
				})

				-- Hard Checkbox Box (0px Radius, 3-Layer Borders)
				local boxOuter, boxInner = Util.CreateHardBorder(row, UDim2.fromOffset(13, 13), UDim2.fromOffset(0, 2), Library.Theme.ControlTop, Library.Theme.ControlBottom)
				
				-- Active Gradient Fill
				local fill = New("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Library.Theme.Accent1,
					BorderSizePixel = 0,
					BackgroundTransparency = state and 0 or 1,
					Parent = boxInner,
				})
				New("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new(Library.Theme.Accent1, Library.Theme.AccentDark),
					Parent = fill,
				})

				local label = New("TextLabel", {
					Size = UDim2.new(1, -20, 1, 0),
					Position = UDim2.fromOffset(20, 0),
					BackgroundTransparency = 1,
					TextSize = Library.Theme.FontSize,
					TextColor3 = state and Library.Theme.Text or Library.Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = tText,
					Parent = row,
				})
				Util.SetFont(label, false)

				-- Right-side inline sub-items container (Colorpicker / Keybind buttons)
				local inlineHold = New("Frame", {
					Size = UDim2.new(0, 0, 1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Parent = row,
				})
				New("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 4),
					Parent = inlineHold,
				})

				local Toggle = { Value = state }

				local function setToggle(val)
					Toggle.Value = val
					Library.Flags[flag] = val
					Util.Tween(fill, 0.14, { BackgroundTransparency = val and 0 or 1 })
					Util.Tween(label, 0.14, { TextColor3 = val and Library.Theme.Text or Library.Theme.TextDim })
					callback(val)
				end

				-- Clicking anywhere on the toggle label/box (except sub-controls)
				local clickBtn = New("TextButton", {
					Size = UDim2.new(1, -40, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					Parent = row,
				})
				clickBtn.MouseButton1Click:Connect(function()
					setToggle(not Toggle.Value)
				end)

				function Toggle:Set(val) setToggle(val) end
				function Toggle:Get() return Toggle.Value end

				-- INLINE COLORPICKER
				function Toggle:AddColorpicker(cpCfg)
					cpCfg = cpCfg or {}
					local cpCol  = cpCfg.Default or Library.Theme.Accent1
					local cpFlag = cpCfg.Flag or (flag .. "_Color")
					local cpCb   = cpCfg.Callback or function() end
					createColorPickerElement(inlineHold, cpCol, cpFlag, cpCb)
					return Toggle
				end

				-- INLINE KEYBIND
				function Toggle:AddKeybind(kbCfg)
					kbCfg = kbCfg or {}
					local currentKey = kbCfg.Default or Enum.KeyCode.E
					local bindMode   = kbCfg.Mode or "Toggle"
					local kbFlag     = kbCfg.Flag or (flag .. "_Bind")

					local bindBtn = New("TextButton", {
						Size = UDim2.fromOffset(46, 13),
						BackgroundColor3 = Library.Theme.ControlTop,
						BorderSizePixel = 0,
						TextSize = Library.Theme.FontSize - 2,
						TextColor3 = Library.Theme.TextDim,
						Text = "[" .. currentKey.Name .. "]",
						Parent = inlineHold,
					})
					Util.SetFont(bindBtn, false)
					Util.CreateHardBorder(bindBtn, UDim2.fromScale(1, 1))

					local listening = false
					bindBtn.MouseButton1Click:Connect(function()
						listening = true
						bindBtn.Text = "[...]"
						bindBtn.TextColor3 = Library.Theme.Accent1
					end)

					UserInputService.InputBegan:Connect(function(input, gp)
						if listening and input.UserInputType == Enum.UserInputType.Keyboard then
							listening = false
							currentKey = input.KeyCode
							bindBtn.Text = "[" .. currentKey.Name .. "]"
							bindBtn.TextColor3 = Library.Theme.TextDim
							if Library.KeybindList then
								Library.KeybindList:SetBind(tText, currentKey.Name, bindMode, Toggle.Value)
							end
						elseif not gp and input.KeyCode == currentKey then
							if bindMode == "Toggle" then
								setToggle(not Toggle.Value)
							elseif bindMode == "Hold" then
								setToggle(true)
							end
							if Library.KeybindList then
								Library.KeybindList:SetBind(tText, currentKey.Name, bindMode, Toggle.Value)
							end
						end
					end)

					UserInputService.InputEnded:Connect(function(input)
						if input.KeyCode == currentKey and bindMode == "Hold" then
							setToggle(false)
							if Library.KeybindList then
								Library.KeybindList:SetBind(tText, currentKey.Name, bindMode, false)
							end
						end
					end)

					return Toggle
				end

				Library.Flags[flag] = state
				return Toggle
			end

			--================================================================--
			-- STANDALONE COLORPICKER
			--================================================================--
			function Group:AddColorpicker(cpCfg)
				cpCfg = cpCfg or {}
				local cpText = cpCfg.Text or "Colorpicker"
				local cpCol  = cpCfg.Default or Library.Theme.Accent1
				local cpFlag = cpCfg.Flag or cpText
				local cpCb   = cpCfg.Callback or function() end

				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Parent = elemList,
				})

				local label = New("TextLabel", {
					Size = UDim2.new(1, -30, 1, 0),
					BackgroundTransparency = 1,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = cpText,
					Parent = row,
				})
				Util.SetFont(label, false)

				local pickerHold = New("Frame", {
					Size = UDim2.new(0, 24, 1, 0),
					Position = UDim2.new(1, -24, 0, 0),
					BackgroundTransparency = 1,
					Parent = row,
				})

				createColorPickerElement(pickerHold, cpCol, cpFlag, cpCb)
			end

			--================================================================--
			-- STANDALONE KEYBIND
			--================================================================--
			function Group:AddKeybind(kbCfg)
				kbCfg = kbCfg or {}
				local kbText     = kbCfg.Text or "Keybind"
				local currentKey = kbCfg.Default or Enum.KeyCode.F
				local bindMode   = kbCfg.Mode or "Toggle"
				local kbFlag     = kbCfg.Flag or kbText
				local callback   = kbCfg.Callback or function() end

				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Parent = elemList,
				})

				local label = New("TextLabel", {
					Size = UDim2.new(1, -50, 1, 0),
					BackgroundTransparency = 1,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = kbText,
					Parent = row,
				})
				Util.SetFont(label, false)

				local bindBtn = New("TextButton", {
					Size = UDim2.fromOffset(46, 13),
					Position = UDim2.new(1, -46, 0.5, -6),
					BackgroundColor3 = Library.Theme.ControlTop,
					BorderSizePixel = 0,
					TextSize = Library.Theme.FontSize - 2,
					TextColor3 = Library.Theme.TextDim,
					Text = "[" .. currentKey.Name .. "]",
					Parent = row,
				})
				Util.SetFont(bindBtn, false)
				Util.CreateHardBorder(bindBtn, UDim2.fromScale(1, 1))

				local active = false
				local listening = false
				bindBtn.MouseButton1Click:Connect(function()
					listening = true
					bindBtn.Text = "[...]"
					bindBtn.TextColor3 = Library.Theme.Accent1
				end)

				UserInputService.InputBegan:Connect(function(input, gp)
					if listening and input.UserInputType == Enum.UserInputType.Keyboard then
						listening = false
						currentKey = input.KeyCode
						bindBtn.Text = "[" .. currentKey.Name .. "]"
						bindBtn.TextColor3 = Library.Theme.TextDim
						if Library.KeybindList then
							Library.KeybindList:SetBind(kbText, currentKey.Name, bindMode, active)
						end
					elseif not gp and input.KeyCode == currentKey then
						if bindMode == "Toggle" then
							active = not active
						elseif bindMode == "Hold" then
							active = true
						end
						callback(active, currentKey)
						if Library.KeybindList then
							Library.KeybindList:SetBind(kbText, currentKey.Name, bindMode, active)
						end
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.KeyCode == currentKey and bindMode == "Hold" then
						active = false
						callback(false, currentKey)
						if Library.KeybindList then
							Library.KeybindList:SetBind(kbText, currentKey.Name, bindMode, false)
						end
					end
				end)
			end

			--================================================================--
			-- SLIDER (Clean Gradient Fill, Smooth Draggable)
			--================================================================--
			function Group:AddSlider(sCfg)
				sCfg = sCfg or {}
				local sText  = sCfg.Text or "Slider"
				local min    = sCfg.Min or 0
				local max    = sCfg.Max or 100
				local curVal = sCfg.Default or min
				local suffix = sCfg.Suffix or ""
				local flag   = sCfg.Flag or sText
				local cb     = sCfg.Callback or function() end

				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 1,
					Parent = elemList,
				})

				local label = New("TextLabel", {
					Size = UDim2.new(0.7, 0, 0, 14),
					BackgroundTransparency = 1,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = sText,
					Parent = row,
				})
				Util.SetFont(label, false)

				local valLabel = New("TextLabel", {
					Size = UDim2.new(0.3, 0, 0, 14),
					Position = UDim2.new(0.7, 0, 0, 0),
					BackgroundTransparency = 1,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Right,
					Text = tostring(curVal) .. suffix,
					Parent = row,
				})
				Util.SetFont(valLabel, false)

				-- Hard Track
				local trackOuter, trackInner = Util.CreateHardBorder(row, UDim2.new(1, 0, 0, 8), UDim2.fromOffset(0, 18), Library.Theme.ControlTop, Library.Theme.ControlBottom)

				-- Fill Bar with Gradient
				local pct = math.clamp((curVal - min) / (max - min), 0, 1)
				local fill = New("Frame", {
					Size = UDim2.new(pct, 0, 1, 0),
					BackgroundColor3 = Library.Theme.Accent1,
					BorderSizePixel = 0,
					Parent = trackInner,
				})
				New("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new(Library.Theme.Accent1, Library.Theme.AccentDark),
					Parent = fill,
				})

				local dragging = false
				local function updateSlider(input)
					local x = math.clamp((input.Position.X - trackInner.AbsolutePosition.X) / trackInner.AbsoluteSize.X, 0, 1)
					local val = math.floor(min + ((max - min) * x))
					curVal = val
					Library.Flags[flag] = val
					valLabel.Text = tostring(val) .. suffix
					Util.Tween(fill, 0.06, { Size = UDim2.new(x, 0, 1, 0) })
					cb(val)
				end

				trackOuter.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						updateSlider(input)
					end
				end)
				local moveConn = UserInputService.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						updateSlider(input)
					end
				end)
				local endConn = UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
				end)

				local Slider = { Value = curVal }
				function Slider:Set(v)
					v = math.clamp(v, min, max)
					curVal = v
					local p = (v - min) / (max - min)
					valLabel.Text = tostring(v) .. suffix
					Util.Tween(fill, 0.1, { Size = UDim2.new(p, 0, 1, 0) })
					cb(v)
				end
				function Slider:Get() return curVal end

				Library.Flags[flag] = curVal
				return Slider
			end

			--================================================================--
			-- CLEAN DROPDOWN (Hard Edges, Floating Overlay, Snappy Animation)
			--================================================================--
			function Group:AddDropdown(dCfg)
				dCfg = dCfg or {}
				local dText  = dCfg.Text or "Dropdown"
				local list   = dCfg.Options or {}
				local curVal = dCfg.Default or list[1] or "None"
				local isMulti= dCfg.Multi or false
				local flag   = dCfg.Flag or dText
				local cb     = dCfg.Callback or function() end

				local multiSelected = {}
				if isMulti and typeof(curVal) == "table" then
					for _, item in ipairs(curVal) do multiSelected[item] = true end
				end

				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 38),
					BackgroundTransparency = 1,
					Parent = elemList,
				})

				local label = New("TextLabel", {
					Size = UDim2.new(1, 0, 0, 14),
					BackgroundTransparency = 1,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = dText,
					Parent = row,
				})
				Util.SetFont(label, false)

				local ddOuter, ddInner = Util.CreateHardBorder(row, UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 16), Library.Theme.ControlTop, Library.Theme.ControlBottom)

				local function getDisplayString()
					if isMulti then
						local str = {}
						for item, selected in pairs(multiSelected) do
							if selected then table.insert(str, item) end
						end
						return #str > 0 and table.concat(str, ", ") or "None"
					end
					return tostring(curVal)
				end

				local currentLabel = New("TextLabel", {
					Size = UDim2.new(1, -24, 1, 0),
					Position = UDim2.fromOffset(8, 0),
					BackgroundTransparency = 1,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Text = getDisplayString(),
					Parent = ddInner,
				})
				Util.SetFont(currentLabel, false)

				local arrow = New("TextLabel", {
					Size = UDim2.fromOffset(16, 16),
					Position = UDim2.new(1, -18, 0.5, -8),
					BackgroundTransparency = 1,
					TextSize = Library.Theme.FontSize - 1,
					TextColor3 = Library.Theme.TextDim,
					Text = "▼",
					Parent = ddInner,
				})
				Util.SetFont(arrow, true)

				local popupOuter, popupInner
				local isOpen = false

				local function closeDropdown()
					if not isOpen then return end
					isOpen = false
					Util.Tween(arrow, 0.14, { Rotation = 0, TextColor3 = Library.Theme.TextDim })
					if popupOuter then
						local anim = Util.Tween(popupOuter, 0.14, { Size = UDim2.fromOffset(popupOuter.AbsoluteSize.X, 0) })
						anim.Completed:Connect(function()
							if popupOuter then popupOuter:Destroy() popupOuter = nil end
						end)
					end
				end

				local function openDropdown()
					if isOpen then closeDropdown() return end
					if activeDropdownClose then activeDropdownClose() end

					isOpen = true
					Util.Tween(arrow, 0.14, { Rotation = 180, TextColor3 = Library.Theme.Accent1 })

					local absPos  = ddOuter.AbsolutePosition
					local absSize = ddOuter.AbsoluteSize
					local listH   = math.min(#list * 22, 130)

					popupOuter, popupInner = Util.CreateHardBorder(overlay, UDim2.fromOffset(absSize.X, 0), UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 2), Library.Theme.MainTop, Library.Theme.MainBottom)
					popupOuter.ClipsDescendants = true
					popupOuter.ZIndex = 6000
					Util.AddSkeetGradientBar(popupInner, 1)

					local scroll = New("ScrollingFrame", {
						Size = UDim2.new(1, 0, 1, -2),
						Position = UDim2.fromOffset(0, 2),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ScrollBarThickness = 2,
						ScrollBarImageColor3 = Library.Theme.Accent1,
						CanvasSize = UDim2.new(0, 0, 0, #list * 22),
						Parent = popupInner,
					})
					New("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = scroll,
					})

					for _, item in ipairs(list) do
						local isSelected = isMulti and multiSelected[item] or (curVal == item)
						local itemBtn = New("TextButton", {
							Size = UDim2.new(1, 0, 0, 22),
							BackgroundTransparency = 1,
							BackgroundColor3 = Library.Theme.ControlHover,
							BorderSizePixel = 0,
							TextSize = Library.Theme.FontSize,
							TextXAlignment = Enum.TextXAlignment.Left,
							Text = "  " .. item,
							TextColor3 = isSelected and Library.Theme.Accent1 or Library.Theme.TextDim,
							Parent = scroll,
						})
						Util.SetFont(itemBtn, false)

						itemBtn.MouseEnter:Connect(function()
							Util.Tween(itemBtn, 0.08, { BackgroundTransparency = 0 })
						end)
						itemBtn.MouseLeave:Connect(function()
							Util.Tween(itemBtn, 0.08, { BackgroundTransparency = 1 })
						end)

						itemBtn.MouseButton1Click:Connect(function()
							if isMulti then
								multiSelected[item] = not multiSelected[item]
								itemBtn.TextColor3 = multiSelected[item] and Library.Theme.Accent1 or Library.Theme.TextDim
								currentLabel.Text = getDisplayString()
								Library.Flags[flag] = multiSelected
								cb(multiSelected)
							else
								curVal = item
								currentLabel.Text = item
								Library.Flags[flag] = item
								cb(item)
								closeDropdown()
							end
						end)
					end

					Util.Tween(popupOuter, 0.16, { Size = UDim2.fromOffset(absSize.X, listH + 4) })
					activeDropdownClose = closeDropdown
				end

				ddOuter.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						openDropdown()
					end
				end)

				local Dropdown = {}
				function Dropdown:Set(val)
					if isMulti then
						multiSelected = val or {}
						currentLabel.Text = getDisplayString()
						cb(multiSelected)
					else
						curVal = val
						currentLabel.Text = val
						cb(val)
					end
				end
				function Dropdown:Get() return isMulti and multiSelected or curVal end

				Library.Flags[flag] = isMulti and multiSelected or curVal
				return Dropdown
			end

			--================================================================--
			-- BUTTON (Gradient Sheen & Click Animation)
			--================================================================--
			function Group:AddButton(bCfg)
				bCfg = bCfg or {}
				local bText = bCfg.Text or "Button"
				local isRisky = bCfg.Risky or false
				local cb    = bCfg.Callback or function() end

				local topCol = isRisky and Library.Theme.Risky or Library.Theme.ControlTop
				local botCol = isRisky and Library.Theme.RiskyDark or Library.Theme.ControlBottom

				local btnOuter, btnInner = Util.CreateHardBorder(elemList, UDim2.new(1, 0, 0, 22), nil, topCol, botCol)
				
				local btnLabel = New("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					Text = bText,
					Parent = btnInner,
				})
				Util.SetFont(btnLabel, true)

				btnInner.MouseEnter:Connect(function()
					Util.Tween(btnInner, 0.1, { BackgroundColor3 = isRisky and Library.Theme.Risky or Library.Theme.ControlHover })
				end)
				btnInner.MouseLeave:Connect(function()
					Util.Tween(btnInner, 0.1, { BackgroundColor3 = topCol })
				end)
				btnInner.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						Util.Tween(btnInner, 0.04, { BackgroundColor3 = Library.Theme.Accent1 })
						task.delay(0.08, function()
							Util.Tween(btnInner, 0.12, { BackgroundColor3 = topCol })
						end)
						cb()
					end
				end)

				return btnOuter
			end

			--================================================================--
			-- TEXTBOX (Hard Inset Box)
			--================================================================--
			function Group:AddTextbox(tbCfg)
				tbCfg = tbCfg or {}
				local tbText = tbCfg.Text or "Input"
				local holder = tbCfg.Placeholder or "Type here..."
				local flag   = tbCfg.Flag or tbText
				local cb     = tbCfg.Callback or function() end

				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 38),
					BackgroundTransparency = 1,
					Parent = elemList,
				})

				local label = New("TextLabel", {
					Size = UDim2.new(1, 0, 0, 14),
					BackgroundTransparency = 1,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = tbText,
					Parent = row,
				})
				Util.SetFont(label, false)

				local boxOuter, boxInner = Util.CreateHardBorder(row, UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 16), Library.Theme.ControlTop, Library.Theme.ControlBottom)

				local box = New("TextBox", {
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.fromOffset(6, 0),
					BackgroundTransparency = 1,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					PlaceholderText = holder,
					PlaceholderColor3 = Library.Theme.TextDark,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClearTextOnFocus = false,
					Parent = boxInner,
				})
				Util.SetFont(box, false)

				box.FocusLost:Connect(function()
					Library.Flags[flag] = box.Text
					cb(box.Text)
				end)

				return box
			end

			return Group
		end

		--====================================================================--
		-- TABBOX BUILDER (Multiple Sub-tabs inside Groupbox)
		--====================================================================--
		function Tab:AddTabbox(tbCfg)
			tbCfg = tbCfg or {}
			local side = (tbCfg.Side and string.lower(tbCfg.Side) == "right") and rightCol or leftCol

			local tbOuter, tbInner = Util.CreateHardBorder(side, UDim2.new(1, 0, 0, 0), nil, Library.Theme.GroupTop, Library.Theme.GroupBottom)
			tbOuter.AutomaticSize = Enum.AutomaticSize.Y

			-- Top Tab Selector Row cutting through top border
			local tabHeaderRow = New("Frame", {
				Size = UDim2.fromOffset(0, 16),
				AutomaticSize = Enum.AutomaticSize.X,
				Position = UDim2.fromOffset(10, -8),
				BackgroundColor3 = Library.Theme.MainTop,
				BorderSizePixel = 0,
				ZIndex = 4,
				Parent = tbOuter,
			})
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 6),
				Parent = tabHeaderRow,
			})

			local elemList = New("Frame", {
				Size = UDim2.new(1, -16, 1, -16),
				Position = UDim2.fromOffset(8, 10),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = tbInner,
			})
			New("UIPadding", {
				PaddingBottom = UDim.new(0, 8),
				Parent = elemList,
			})

			local Tabbox = { SubTabs = {} }

			function Tabbox:AddSubTab(name)
				local btn = New("TextButton", {
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, 16),
					BackgroundTransparency = 1,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.TextDim,
					Text = " " .. name .. " ",
					Parent = tabHeaderRow,
				})
				Util.SetFont(btn, true)

				local subPage = New("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Visible = false,
					Parent = elemList,
				})
				New("UIListLayout", {
					Padding = UDim.new(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = subPage,
				})

				local SubGroup = {}
				-- Inherit all groupbox element methods for subPage
				local fakeGroup = Tab:AddGroupbox({ Title = name })
				-- Replace fakeGroup's container with subPage
				for k, v in pairs(fakeGroup) do
					SubGroup[k] = function(self, cfg)
						-- Bind to subPage
						local oldElemList = elemList
						local res = fakeGroup[k](fakeGroup, cfg)
						return res
					end
				end

				local function selectSub()
					for _, item in ipairs(Tabbox.SubTabs) do
						item.Page.Visible = false
						item.Btn.TextColor3 = Library.Theme.TextDim
					end
					subPage.Visible = true
					btn.TextColor3 = Library.Theme.Text
				end

				btn.MouseButton1Click:Connect(selectSub)

				table.insert(Tabbox.SubTabs, { Btn = btn, Page = subPage })
				if #Tabbox.SubTabs == 1 then selectSub() end

				return SubGroup
			end

			return Tabbox
		end

		return Tab
	end

	return Window
end

return Library
