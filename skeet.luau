--[[
	══════════════════════════════════════════════════════════════════════════════
	  SKEETWARE UI — Hard Edge & Clean Gradient Menu Library for Luau / Roblox
	  Authentic GameSense / Skeet.cc aesthetics:
	  • Crisp Hard Edges (0px radius, 3-layer pixel-perfect borders)
	  • Multi-tone Clean Gradients (Top accent bar, container sheens, fill ramps)
	  • Clean, Snappy Animations (Quad/Quart tweens on dropdowns, toggles, popups)
	  • Floating Top-Layer Dropdowns (Zero clipping, single & multi-select)
	  • Inline sub-controls (Toggle + Inline ColorPicker & Keybind)
	  • Watermark & Keybinds List HUD
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

-- Safe parent target (handles CoreGui permission checks across executors)
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

local Library = {
	Version      = "2.0.0",
	Name         = "Skeetware",
	Open         = true,
	ToggleKey    = Enum.KeyCode.Insert,
	Flags        = {},
	Registry     = {},
	Connections  = {},
	KeybindList  = nil,
	Watermark    = nil,
	OverlayFrame = nil, -- Top-level z-index layer for popups/dropdowns/colorpickers
	ScreenGui    = nil,

	Theme = {
		-- Gradient Colors (Skeet Iconic Accent)
		Accent1      = Color3.fromRGB(168, 219, 95),  -- Bright skeet green
		Accent2      = Color3.fromRGB(94, 158, 219),  -- Skeet cyan/blue
		AccentDark   = Color3.fromRGB(120, 175, 60),  -- Darker tone for gradient ramps
		
		-- Skeet Surfaces & Gradients
		MainTop      = Color3.fromRGB(32, 32, 36),
		MainBottom   = Color3.fromRGB(18, 18, 20),
		GroupTop     = Color3.fromRGB(25, 25, 28),
		GroupBottom  = Color3.fromRGB(19, 19, 21),
		ControlTop   = Color3.fromRGB(38, 38, 42),
		ControlBottom= Color3.fromRGB(26, 26, 28),
		ControlHover = Color3.fromRGB(48, 48, 54),
		
		-- Hard-Edge Borders
		OuterBorder  = Color3.fromRGB(0, 0, 0),       -- 1px Pitch Black
		MidBorder    = Color3.fromRGB(48, 48, 52),     -- 1px Crisp Highlight / Inset
		InnerBorder  = Color3.fromRGB(12, 12, 14),     -- 1px Deep border

		-- Text
		Text         = Color3.fromRGB(220, 220, 225),
		TextDim      = Color3.fromRGB(140, 140, 148),
		TextDark     = Color3.fromRGB(90, 90, 96),
		
		-- States
		Risky        = Color3.fromRGB(235, 75, 75),
		RiskyDark    = Color3.fromRGB(160, 40, 40),
		Success      = Color3.fromRGB(110, 210, 100),

		-- Fonts
		Font         = Enum.Font.RobotoMono,
		FontBold     = Enum.Font.RobotoCondensed,
		FontSize     = 12,
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
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end
local New = Util.Create

function Util.Tween(inst, dur, props, style, dir)
	style = style or Enum.EasingStyle.Quart
	dir   = dir or Enum.EasingDirection.Out
	local t = TweenService:Create(inst, TweenInfo.new(dur or 0.18, style, dir), props)
	t:Play()
	return t
end

-- Multi-layered Hard-Edge Border Frame
function Util.CreateHardBorder(parent, size, pos, bgTop, bgBottom)
	-- Layer 1: Outermost black border
	local outer = New("Frame", {
		Size = size or UDim2.fromScale(1, 1),
		Position = pos or UDim2.fromScale(0, 0),
		BackgroundColor3 = Library.Theme.OuterBorder,
		BorderSizePixel = 0,
		Parent = parent,
	})

	-- Layer 2: Mid border (1px inset)
	local mid = New("Frame", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.fromOffset(1, 1),
		BackgroundColor3 = Library.Theme.MidBorder,
		BorderSizePixel = 0,
		Parent = outer,
	})

	-- Layer 3: Inner surface (1px inset) with vertical gradient
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
		ZIndex = 5,
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
-- INITIALIZE ROOT GUI
--============================================================================--
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
	ZIndex = 1000,
	Parent = screenGui,
})
Library.OverlayFrame = overlay

-- Global overlay closer
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
	
	local wmOuter, wmInner = Util.CreateHardBorder(screenGui, UDim2.fromOffset(280, 24), UDim2.fromOffset(20, 20), Library.Theme.MainTop, Library.Theme.MainBottom)
	Util.AddSkeetGradientBar(wmInner, 2)

	local wmLabel = New("TextLabel", {
		Size = UDim2.new(1, -12, 1, -2),
		Position = UDim2.fromOffset(8, 2),
		BackgroundTransparency = 1,
		Font = Library.Theme.Font,
		TextSize = 11,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title .. " | v" .. Library.Version .. " | 60 fps | 14 ms",
		Parent = wmInner,
	})

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
	local kbOuter, kbInner = Util.CreateHardBorder(screenGui, UDim2.fromOffset(180, 28), UDim2.fromOffset(20, 60), Library.Theme.MainTop, Library.Theme.MainBottom)
	Util.AddSkeetGradientBar(kbInner, 2)

	local header = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.fromOffset(0, 2),
		BackgroundTransparency = 1,
		Font = Library.Theme.FontBold,
		TextSize = 12,
		TextColor3 = Library.Theme.Text,
		Text = "Keybinds",
		Parent = kbInner,
	})

	local listContainer = New("Frame", {
		Size = UDim2.new(1, -12, 0, 0),
		Position = UDim2.fromOffset(6, 26),
		BackgroundTransparency = 1,
		Parent = kbInner,
	})
	local listLayout = New("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = listContainer,
	})

	local binds = {}
	local function updateSize()
		local count = #listContainer:GetChildren() - 1
		local h = count > 0 and (28 + (count * 20)) or 28
		Util.Tween(kbOuter, 0.15, { Size = UDim2.fromOffset(180, h) })
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
			New("TextLabel", {
				Size = UDim2.new(0.55, 0, 1, 0),
				BackgroundTransparency = 1,
				Font = Library.Theme.Font,
				TextSize = 11,
				TextColor3 = Library.Theme.TextDim,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = name,
				Parent = row,
			})
			local val = New("TextLabel", {
				Name = "Val",
				Size = UDim2.new(0.45, 0, 1, 0),
				Position = UDim2.new(0.55, 0, 0, 0),
				BackgroundTransparency = 1,
				Font = Library.Theme.Font,
				TextSize = 11,
				TextColor3 = Library.Theme.Accent1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = string.format("[%s] (%s)", key, mode),
				Parent = row,
			})
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
		Position = UDim2.fromOffset(8, 6),
		BackgroundTransparency = 1,
		Font = Library.Theme.FontBold,
		TextSize = 12,
		TextColor3 = Library.Theme.Accent1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		Parent = notifInner,
	})

	local desc = New("TextLabel", {
		Size = UDim2.new(1, -16, 0, 28),
		Position = UDim2.fromOffset(8, 22),
		BackgroundTransparency = 1,
		Font = Library.Theme.Font,
		TextSize = 11,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = text,
		Parent = notifInner,
	})

	local timerBar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = Library.Theme.Accent1,
		BorderSizePixel = 0,
		Parent = notifInner,
	})

	-- Animate In
	Util.Tween(notifOuter, 0.22, { Size = UDim2.fromOffset(260, 56) })
	Util.Tween(timerBar, dur, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

	task.delay(dur, function()
		local out = Util.Tween(notifOuter, 0.2, { Size = UDim2.fromOffset(260, 0) })
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
	local winSize  = cfg.Size or UDim2.fromOffset(700, 520)

	-- Window Outermost Hard Frame
	local winOuter, winInner = Util.CreateHardBorder(screenGui, winSize, UDim2.fromScale(0.5, 0.5), Library.Theme.MainTop, Library.Theme.MainBottom)
	winOuter.AnchorPoint = Vector2.new(0.5, 0.5)

	-- Signature Gradient Bar across top
	Util.AddSkeetGradientBar(winInner, 3)

	-- Top Header Bar (Title & Drag Area)
	local titleBar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.fromOffset(0, 3),
		BackgroundTransparency = 1,
		Parent = winInner,
	})

	local titleLabel = New("TextLabel", {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Font = Library.Theme.FontBold,
		TextSize = 13,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(title),
		Parent = titleBar,
	})

	-- Subtle separator line under Titlebar
	local headerSep = New("Frame", {
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
		Size = UDim2.new(1, -24, 0, 30),
		Position = UDim2.fromOffset(12, 38),
		BackgroundTransparency = 1,
		Parent = winInner,
	})
	local tabLayout = New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabListFrame,
	})

	-- Tab Viewport Content Container
	local contentHolder = New("Frame", {
		Size = UDim2.new(1, -24, 1, -80),
		Position = UDim2.fromOffset(12, 72),
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
			Font = Library.Theme.FontBold,
			TextSize = 11,
			TextColor3 = Library.Theme.TextDim,
			Text = string.upper(tabName),
			Parent = tabBtnInner,
		})

		-- Tab Page (2-Column Grid Split)
		local tabPage = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = contentHolder,
		})

		-- Left Column
		local leftCol = New("ScrollingFrame", {
			Size = UDim2.new(0.5, -5, 1, 0),
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
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = leftCol,
		})

		-- Right Column
		local rightCol = New("ScrollingFrame", {
			Size = UDim2.new(0.5, -5, 1, 0),
			Position = UDim2.new(0.5, 5, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Library.Theme.MidBorder,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = tabPage,
		})
		New("UIListLayout", {
			Padding = UDim.new(0, 10),
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
		-- GROUPBOX BUILDER (Hard Edge Inset with Titled Header)
		--====================================================================--
		function Tab:AddGroupbox(gCfg)
			gCfg = gCfg or {}
			local gTitle = gCfg.Title or "Group"
			local side   = (gCfg.Side and string.lower(gCfg.Side) == "right") and rightCol or leftCol

			local gbOuter, gbInner = Util.CreateHardBorder(side, UDim2.new(1, 0, 0, 0), nil, Library.Theme.GroupTop, Library.Theme.GroupBottom)
			gbOuter.AutomaticSize = Enum.AutomaticSize.Y

			-- Title header cutting through top border
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
			New("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Font = Library.Theme.FontBold,
				TextSize = 11,
				TextColor3 = Library.Theme.Text,
				Text = gTitle,
				ZIndex = 4,
				Parent = titleHold,
			})

			-- Element List Container inside Groupbox
			local elemList = New("Frame", {
				Size = UDim2.new(1, -20, 1, -20),
				Position = UDim2.fromOffset(10, 12),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = gbInner,
			})
			New("UIListLayout", {
				Padding = UDim.new(0, 7),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = elemList,
			})
			New("UIPadding", {
				PaddingBottom = UDim.new(0, 8),
				Parent = elemList,
			})

			local Group = {}

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
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Parent = elemList,
				})

				-- Hard Checkbox Box
				local boxOuter, boxInner = Util.CreateHardBorder(row, UDim2.fromOffset(13, 13), UDim2.fromOffset(0, 1), Library.Theme.ControlTop, Library.Theme.ControlBottom)
				
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
					Font = Library.Theme.Font,
					TextSize = 11,
					TextColor3 = state and Library.Theme.Text or Library.Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = tText,
					Parent = row,
				})

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
					Util.Tween(fill, 0.15, { BackgroundTransparency = val and 0 or 1 })
					Util.Tween(label, 0.15, { TextColor3 = val and Library.Theme.Text or Library.Theme.TextDim })
					callback(val)
				end

				row.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						-- Check if click is not on inline sub items
						setToggle(not Toggle.Value)
					end
				end)

				function Toggle:Set(val) setToggle(val) end
				function Toggle:Get() return Toggle.Value end

				-- INLINE COLORPICKER ATTACHMENT
				function Toggle:AddColorpicker(cpCfg)
					cpCfg = cpCfg or {}
					local cpColor = cpCfg.Default or Library.Theme.Accent1
					local cpFlag  = cpCfg.Flag or (flag .. "_Color")
					local cpCb    = cpCfg.Callback or function() end

					local cpOuter, cpInner = Util.CreateHardBorder(inlineHold, UDim2.fromOffset(24, 11), nil, cpColor, cpColor)
					
					local cpColorPreview = New("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = cpColor,
						BorderSizePixel = 0,
						Parent = cpInner,
					})

					-- Colorpicker Popup Floating Window (Attached to OverlayLayer)
					local popupOuter, popupInner
					local isOpen = false

					local function toggleColorPicker()
						isOpen = not isOpen
						if not isOpen then
							if popupOuter then popupOuter:Destroy() popupOuter = nil end
							return
						end

						local absPos = cpOuter.AbsolutePosition
						popupOuter, popupInner = Util.CreateHardBorder(overlay, UDim2.fromOffset(160, 140), UDim2.fromOffset(absPos.X - 130, absPos.Y + 16), Library.Theme.MainTop, Library.Theme.MainBottom)
						Util.AddSkeetGradientBar(popupInner, 2)

						-- SV Canvas Box
						local svBox = New("ImageLabel", {
							Size = UDim2.fromOffset(120, 100),
							Position = UDim2.fromOffset(8, 8),
							Image = "rbxassetid://4155801252",
							BackgroundColor3 = cpColor,
							BorderSizePixel = 0,
							Parent = popupInner,
						})
						Util.CreateHardBorder(svBox, UDim2.fromScale(1, 1))

						-- Hue Slider (Vertical)
						local hueBox = New("Frame", {
							Size = UDim2.fromOffset(14, 100),
							Position = UDim2.fromOffset(136, 8),
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

						-- Dragging SV Logic
						local curH, curS, curV = cpColor:ToHSV()
						local draggingHue = false
						local draggingSV  = false

						local function updateColor()
							local newCol = Color3.fromHSV(curH, curS, curV)
							svBox.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
							cpColorPreview.BackgroundColor3 = newCol
							Library.Flags[cpFlag] = newCol
							cpCb(newCol)
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
								updateColor()
							end
						end)
						UserInputService.InputChanged:Connect(function(input)
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
									updateColor()
								end
							end
						end)
						UserInputService.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								draggingHue = false
								draggingSV = false
							end
						end)

						activeDropdownClose = function()
							isOpen = false
							if popupOuter then popupOuter:Destroy() popupOuter = nil end
						end
					end

					cpOuter.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							toggleColorPicker()
						end
					end)

					return Toggle
				end

				-- INLINE KEYBIND ATTACHMENT
				function Toggle:AddKeybind(kbCfg)
					kbCfg = kbCfg or {}
					local currentKey = kbCfg.Default or Enum.KeyCode.E
					local bindMode   = kbCfg.Mode or "Toggle" -- Toggle, Hold, Always
					local kbFlag     = kbCfg.Flag or (flag .. "_Bind")

					local bindBtn = New("TextButton", {
						Size = UDim2.fromOffset(45, 13),
						BackgroundColor3 = Library.Theme.ControlTop,
						BorderSizePixel = 0,
						Font = Library.Theme.Font,
						TextSize = 10,
						TextColor3 = Library.Theme.TextDim,
						Text = "[" .. currentKey.Name .. "]",
						Parent = inlineHold,
					})
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
			-- SLIDER (Clean Gradient Fill, Smooth Draggable, Precision Tooltip)
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
					Font = Library.Theme.Font,
					TextSize = 11,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = sText,
					Parent = row,
				})

				local valLabel = New("TextLabel", {
					Size = UDim2.new(0.3, 0, 0, 14),
					Position = UDim2.new(0.7, 0, 0, 0),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = 11,
					TextColor3 = Library.Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Right,
					Text = tostring(curVal) .. suffix,
					Parent = row,
				})

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
					Util.Tween(fill, 0.08, { Size = UDim2.new(x, 0, 1, 0) })
					cb(val)
				end

				trackOuter.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						updateSlider(input)
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						updateSlider(input)
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
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

				New("TextLabel", {
					Size = UDim2.new(1, 0, 0, 14),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = 11,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = dText,
					Parent = row,
				})

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
					Font = Library.Theme.Font,
					TextSize = 11,
					TextColor3 = Library.Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Text = getDisplayString(),
					Parent = ddInner,
				})

				local arrow = New("TextLabel", {
					Size = UDim2.fromOffset(16, 16),
					Position = UDim2.new(1, -18, 0.5, -8),
					BackgroundTransparency = 1,
					Font = Library.Theme.FontBold,
					TextSize = 10,
					TextColor3 = Library.Theme.TextDim,
					Text = "▼",
					Parent = ddInner,
				})

				local popupOuter, popupInner
				local isOpen = false

				local function closeDropdown()
					if not isOpen then return end
					isOpen = false
					Util.Tween(arrow, 0.15, { Rotation = 0, TextColor3 = Library.Theme.TextDim })
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
					Util.Tween(arrow, 0.15, { Rotation = 180, TextColor3 = Library.Theme.Accent1 })

					local absPos  = ddOuter.AbsolutePosition
					local absSize = ddOuter.AbsoluteSize
					local listH   = math.min(#list * 22, 130)

					popupOuter, popupInner = Util.CreateHardBorder(overlay, UDim2.fromOffset(absSize.X, 0), UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 2), Library.Theme.MainTop, Library.Theme.MainBottom)
					popupOuter.ClipsDescendants = true
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
						local itemBtn = New("TextButton", {
							Size = UDim2.new(1, 0, 0, 22),
							BackgroundTransparency = 1,
							BackgroundColor3 = Library.Theme.ControlHover,
							BorderSizePixel = 0,
							Font = Library.Theme.Font,
							TextSize = 11,
							TextXAlignment = Enum.TextXAlignment.Left,
							Text = "  " .. item,
							TextColor3 = (isMulti and multiSelected[item]) or (curVal == item) and Library.Theme.Accent1 or Library.Theme.TextDim,
							Parent = scroll,
						})

						itemBtn.MouseEnter:Connect(function()
							Util.Tween(itemBtn, 0.1, { BackgroundTransparency = 0 })
						end)
						itemBtn.MouseLeave:Connect(function()
							Util.Tween(itemBtn, 0.1, { BackgroundTransparency = 1 })
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
					Font = Library.Theme.FontBold,
					TextSize = 11,
					TextColor3 = Library.Theme.Text,
					Text = bText,
					Parent = btnInner,
				})

				btnInner.MouseEnter:Connect(function()
					Util.Tween(btnInner, 0.12, { BackgroundColor3 = isRisky and Library.Theme.Risky or Library.Theme.ControlHover })
				end)
				btnInner.MouseLeave:Connect(function()
					Util.Tween(btnInner, 0.12, { BackgroundColor3 = topCol })
				end)
				btnInner.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						Util.Tween(btnInner, 0.05, { BackgroundColor3 = Library.Theme.Accent1 })
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

				New("TextLabel", {
					Size = UDim2.new(1, 0, 0, 14),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = 11,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = tbText,
					Parent = row,
				})

				local boxOuter, boxInner = Util.CreateHardBorder(row, UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 16), Library.Theme.ControlTop, Library.Theme.ControlBottom)

				local box = New("TextBox", {
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.fromOffset(6, 0),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = 11,
					TextColor3 = Library.Theme.Text,
					PlaceholderText = holder,
					PlaceholderColor3 = Library.Theme.TextDark,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClearTextOnFocus = false,
					Parent = boxInner,
				})

				box.FocusLost:Connect(function()
					Library.Flags[flag] = box.Text
					cb(box.Text)
				end)

				return box
			end

			return Group
		end

		return Tab
	end

	return Window
end

return Library
