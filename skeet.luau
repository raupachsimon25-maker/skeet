--[[
	══════════════════════════════════════════════════════════════════════════════
	  SKEETWARE UI v5.0 — Complete Hard Edge & Clean Gradient Menu Engine
	  • 100% Native 2D Saturation/Value Palette & 7-Stop Hue Rainbow Bar
	  • Bulletproof Icons Suite & Safe AddTab Handler
	  • High-Contrast Keybind Buttons with Right-Click Context Menu (Hold/Toggle/Always)
	  • Non-Clipping Floating Dropdowns (Single & Multi-Select)
	  • Smooth Sliders & Micro-Animations
	  • Watermark & Real-Time Keybinds List HUD
	  • Notification System with animated gradient timer
	══════════════════════════════════════════════════════════════════════════════
--]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

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

local oldGui = getSafeGuiParent():FindFirstChild("SkeetwareUI")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkeetwareUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = getSafeGuiParent()

local Library = {
	Version   = "5.0.0",
	Open      = true,
	ToggleKey = Enum.KeyCode.Insert,
	Flags     = {},
	Registry  = {},
	KeybindList = nil,
	Watermark   = nil,
	ScreenGui   = screenGui,

	Theme = {
		Accent1      = Color3.fromRGB(168, 219, 95),  -- Skeet Green
		Accent2      = Color3.fromRGB(94, 158, 219),  -- Skeet Cyan
		AccentDark   = Color3.fromRGB(105, 160, 50),
		MainTop      = Color3.fromRGB(28, 28, 32),
		MainBottom   = Color3.fromRGB(16, 16, 18),
		GroupTop     = Color3.fromRGB(24, 24, 27),
		GroupBottom  = Color3.fromRGB(17, 17, 19),
		ControlTop   = Color3.fromRGB(36, 36, 40),
		ControlBottom= Color3.fromRGB(24, 24, 26),
		ControlHover = Color3.fromRGB(48, 48, 54),
		OuterBorder  = Color3.fromRGB(0, 0, 0),
		MidBorder    = Color3.fromRGB(48, 48, 54),
		Text         = Color3.fromRGB(230, 230, 235),
		TextDim      = Color3.fromRGB(155, 155, 165),
		TextDark     = Color3.fromRGB(95, 95, 105),
		Risky        = Color3.fromRGB(235, 75, 75),
		RiskyDark    = Color3.fromRGB(160, 40, 40),
		Font         = Enum.Font.GothamMedium,
		FontBold     = Enum.Font.GothamBold,
		FontSize     = 12,
	},

	ThemeSignals = {},

	Icons = {
		Target    = "rbxassetid://10734977012",
		Crosshair = "rbxassetid://10709818534",
		Eye       = "rbxassetid://10723346959",
		Users     = "rbxassetid://10747373426",
		User      = "rbxassetid://10747373176",
		Shield    = "rbxassetid://10734951847",
		Sliders   = "rbxassetid://10734963400",
		Settings  = "rbxassetid://10734950309",
		Palette   = "rbxassetid://10734910430",
		Save      = "rbxassetid://10734941499",
		Trash     = "rbxassetid://10747362241",
		Zap       = "rbxassetid://10723376114",
		Skull     = "rbxassetid://10734962068",
		Swords    = "rbxassetid://10734975692",
		Check     = "rbxassetid://10709790644",
		Chevron   = "rbxassetid://10709790948",
	}
}

--============================================================================--
-- UTILITIES & THEME REGISTRY
--============================================================================--
local Util = {}

function Util.Create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then inst[k] = v end
	end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	if props and props.Parent then inst.Parent = props.Parent end
	return inst
end
local New = Util.Create

function Util.RegisterTheme(inst, propName, themeKey)
	if not Library.Registry[themeKey] then
		Library.Registry[themeKey] = {}
	end
	table.insert(Library.Registry[themeKey], { Instance = inst, Property = propName })
	return inst
end

function Util.Tween(inst, dur, props, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(dur or 0.15, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

function Util.CreateHardBorder(parent, size, pos, bgTop, bgBottom, isMainWin)
	local outer = New("Frame", {
		Size = size or UDim2.fromScale(1, 1),
		Position = pos or UDim2.fromScale(0, 0),
		BackgroundColor3 = Library.Theme.OuterBorder,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Util.RegisterTheme(outer, "BackgroundColor3", "OutlineColor")

	local mid = New("Frame", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.fromOffset(1, 1),
		BackgroundColor3 = Library.Theme.MidBorder,
		BorderSizePixel = 0,
		Parent = outer,
	})

	local inner = New("Frame", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.fromOffset(1, 1),
		BackgroundColor3 = bgTop or Library.Theme.GroupTop,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Parent = mid,
	})

	if isMainWin then
		Util.RegisterTheme(inner, "BackgroundColor3", "BackgroundColor")
	else
		Util.RegisterTheme(inner, "BackgroundColor3", "MainColor")
	end

	if bgTop and bgBottom then
		local grad = New("UIGradient", {
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

function Util.AddSkeetGradientBar(parent, height)
	local bar = New("Frame", {
		Size = UDim2.new(1, 0, 0, height or 2),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Library.Theme.Accent1,
		BorderSizePixel = 0,
		ZIndex = 10,
		Parent = parent,
	})
	Util.RegisterTheme(bar, "BackgroundColor3", "AccentColor")

	local grad = New("UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(54, 163, 247)),
			ColorSequenceKeypoint.new(0.20, Color3.fromRGB(98, 216, 247)),
			ColorSequenceKeypoint.new(0.40, Library.Theme.Accent1),
			ColorSequenceKeypoint.new(0.60, Color3.fromRGB(247, 184, 92)),
			ColorSequenceKeypoint.new(0.80, Color3.fromRGB(247, 104, 181)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(184, 119, 247)),
		}),
		Parent = bar,
	})
	return bar
end

--============================================================================--
-- WATERMARK HUD
--============================================================================--
function Library:CreateWatermark(customTitle)
	local title = customTitle or "skeetware.cc"
	local wmOuter, wmInner = Util.CreateHardBorder(screenGui, UDim2.fromOffset(300, 24), UDim2.fromOffset(20, 20), Library.Theme.MainTop, Library.Theme.MainBottom)
	wmOuter.ZIndex = 50
	Util.AddSkeetGradientBar(wmInner, 2)

	New("ImageLabel", {
		Size = UDim2.fromOffset(13, 13),
		Position = UDim2.fromOffset(6, 5),
		BackgroundTransparency = 1,
		Image = Library.Icons.Shield,
		ImageColor3 = Library.Theme.Accent1,
		Parent = wmInner,
	})

	local wmLabel = New("TextLabel", {
		Size = UDim2.new(1, -26, 1, -2),
		Position = UDim2.fromOffset(24, 2),
		BackgroundTransparency = 1,
		Font = Library.Theme.Font,
		TextSize = Library.Theme.FontSize - 1,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title .. " | 60 fps | 14 ms",
		Parent = wmInner,
	})

	local fpsCount = 0
	local lastFpsUpdate = tick()
	RunService.RenderStepped:Connect(function()
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
	kbOuter.ZIndex = 50
	Util.AddSkeetGradientBar(kbInner, 2)

	local header = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.fromOffset(0, 2),
		BackgroundTransparency = 1,
		Font = Library.Theme.FontBold,
		TextSize = Library.Theme.FontSize,
		TextColor3 = Library.Theme.Text,
		Text = "Keybinds",
		Parent = kbInner,
	})

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
			New("TextLabel", {
				Size = UDim2.new(0.55, 0, 1, 0),
				BackgroundTransparency = 1,
				Font = Library.Theme.Font,
				TextSize = Library.Theme.FontSize - 1,
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
				TextSize = Library.Theme.FontSize - 1,
				TextColor3 = Library.Theme.Accent1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = string.format("[%s] (%s)", key, mode),
				Parent = row,
			})
			binds[name] = row
			updateSize()
		end
	end

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
	ZIndex = 90,
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

	New("TextLabel", {
		Size = UDim2.new(1, -16, 0, 18),
		Position = UDim2.fromOffset(8, 5),
		BackgroundTransparency = 1,
		Font = Library.Theme.FontBold,
		TextSize = Library.Theme.FontSize,
		TextColor3 = Library.Theme.Accent1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		Parent = notifInner,
	})

	New("TextLabel", {
		Size = UDim2.new(1, -16, 0, 26),
		Position = UDim2.fromOffset(8, 22),
		BackgroundTransparency = 1,
		Font = Library.Theme.Font,
		TextSize = Library.Theme.FontSize - 1,
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

	Util.Tween(notifOuter, 0.18, { Size = UDim2.fromOffset(260, 54) })
	Util.Tween(timerBar, dur, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

	task.delay(dur, function()
		local out = Util.Tween(notifOuter, 0.16, { Size = UDim2.fromOffset(260, 0) })
		out.Completed:Connect(function() notifOuter:Destroy() end)
	end)
end

--============================================================================--
-- CREATE MAIN WINDOW
--============================================================================--
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local title   = cfg.Title or "skeetware.cc"
	local winSize = cfg.Size or UDim2.fromOffset(720, 520)

	local winOuter, winInner = Util.CreateHardBorder(screenGui, winSize, UDim2.fromScale(0.5, 0.5), Library.Theme.MainTop, Library.Theme.MainBottom, true)
	winOuter.AnchorPoint = Vector2.new(0.5, 0.5)
	winOuter.ZIndex = 10

	Util.AddSkeetGradientBar(winInner, 3)

	local titleBar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 3),
		BackgroundTransparency = 1,
		Parent = winInner,
	})

	New("TextLabel", {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Font = Library.Theme.FontBold,
		TextSize = Library.Theme.FontSize + 1,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(title),
		Parent = titleBar,
	})

	New("Frame", {
		Size = UDim2.new(1, -20, 0, 1),
		Position = UDim2.fromOffset(10, 32),
		BackgroundColor3 = Library.Theme.MidBorder,
		BorderSizePixel = 0,
		Parent = winInner,
	})

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
				winOuter.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
	end

	UserInputService.InputBegan:Connect(function(input, gp)
		if not gp and input.KeyCode == Library.ToggleKey then
			Library.Open = not Library.Open
			winOuter.Visible = Library.Open
		end
	end)

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

	local contentHolder = New("Frame", {
		Size = UDim2.new(1, -24, 1, -78),
		Position = UDim2.fromOffset(12, 70),
		BackgroundTransparency = 1,
		Parent = winInner,
	})

	local Window = { Tabs = {} }

	function Window:AddTab(tabName, iconAsset)
		local tabBtnOuter, tabBtnInner = Util.CreateHardBorder(tabListFrame, UDim2.fromOffset(95, 26), nil, Library.Theme.ControlTop, Library.Theme.ControlBottom)
		
		local tabGradLine = New("Frame", {
			Size = UDim2.new(1, 0, 0, 2),
			Position = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Library.Theme.Accent1,
			BorderSizePixel = 0,
			Visible = false,
			Parent = tabBtnInner,
		})

		local hasIcon = (iconAsset ~= nil and typeof(iconAsset) == "string")

		if hasIcon then
			New("ImageLabel", {
				Size = UDim2.fromOffset(14, 14),
				Position = UDim2.new(0, 6, 0.5, -7),
				BackgroundTransparency = 1,
				Image = iconAsset,
				ImageColor3 = Library.Theme.TextDim,
				Parent = tabBtnInner,
			})
		end

		local tabLabel = New("TextLabel", {
			Size = UDim2.new(1, hasIcon and -24 or 0, 1, 0),
			Position = UDim2.fromOffset(hasIcon and 22 or 0, 0),
			BackgroundTransparency = 1,
			Font = Library.Theme.FontBold,
			TextSize = Library.Theme.FontSize,
			TextColor3 = Library.Theme.TextDim,
			Text = string.upper(tabName or "TAB"),
			Parent = tabBtnInner,
		})

		local tabPage = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = contentHolder,
		})

		local leftCol = New("ScrollingFrame", {
			Size = UDim2.new(0.5, -6, 1, 0),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Library.Theme.Accent1,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Selectable = false,
			ClipsDescendants = true,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = tabPage,
		})
		Util.RegisterTheme(leftCol, "ScrollBarImageColor3", "AccentColor")
		New("UIListLayout", {
			Padding = UDim.new(0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = leftCol,
		})

		local rightCol = New("ScrollingFrame", {
			Size = UDim2.new(0.5, -6, 1, 0),
			Position = UDim2.new(0.5, 6, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Library.Theme.Accent1,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Selectable = false,
			ClipsDescendants = true,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = tabPage,
		})
		Util.RegisterTheme(rightCol, "ScrollBarImageColor3", "AccentColor")
		New("UIListLayout", {
			Padding = UDim.new(0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = rightCol,
		})

		local Tab = { Page = tabPage, Left = leftCol, Right = rightCol, SubTabs = {} }

		function Tab:AddSubTab(subTabName)
			if not self.SubTabBar then
				-- Reposition the columns to give room for sub-tab bar
				leftCol.Size = UDim2.new(0.5, -6, 1, -28)
				leftCol.Position = UDim2.fromOffset(0, 28)
				rightCol.Size = UDim2.new(0.5, -6, 1, -28)
				rightCol.Position = UDim2.new(0.5, 6, 0, 28)

				local subBar = New("Frame", {
					Size = UDim2.new(1, 0, 0, 22),
					Position = UDim2.fromOffset(0, 0),
					BackgroundTransparency = 1,
					Parent = tabPage,
				})
				New("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = subBar,
				})
				self.SubTabBar = subBar
			end

			-- SubTab specific left and right columns
			local subLeftCol = New("ScrollingFrame", {
				Size = UDim2.new(0.5, -6, 1, -28),
				Position = UDim2.fromOffset(0, 28),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = Library.Theme.Accent1,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Selectable = false,
				ClipsDescendants = true,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Visible = false,
				Parent = tabPage,
			})
			Util.RegisterTheme(subLeftCol, "ScrollBarImageColor3", "AccentColor")
			New("UIListLayout", {
				Padding = UDim.new(0, 12),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = subLeftCol,
			})

			local subRightCol = New("ScrollingFrame", {
				Size = UDim2.new(0.5, -6, 1, -28),
				Position = UDim2.new(0.5, 6, 0, 28),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = Library.Theme.Accent1,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Selectable = false,
				ClipsDescendants = true,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Visible = false,
				Parent = tabPage,
			})
			Util.RegisterTheme(subRightCol, "ScrollBarImageColor3", "AccentColor")
			New("UIListLayout", {
				Padding = UDim.new(0, 12),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = subRightCol,
			})

			-- Hide default root columns if SubTabs exist
			leftCol.Visible = false
			rightCol.Visible = false

			local subBtnOuter, subBtnInner = Util.CreateHardBorder(self.SubTabBar, UDim2.fromOffset(75, 20), nil, Library.Theme.ControlTop, Library.Theme.ControlBottom)
			local subLabel = New("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Font = Library.Theme.FontBold,
				TextSize = Library.Theme.FontSize - 1,
				TextColor3 = Library.Theme.TextDim,
				Text = string.upper(subTabName or "SUBTAB"),
				Parent = subBtnInner,
			})

			local SubTab = {
				Btn = subBtnOuter,
				Inner = subBtnInner,
				Label = subLabel,
				Left = subLeftCol,
				Right = subRightCol,
			}

			local function selectSubTab()
				for _, other in ipairs(self.SubTabs) do
					other.Left.Visible = false
					other.Right.Visible = false
					Util.Tween(other.Label, 0.12, { TextColor3 = Library.Theme.TextDim })
					Util.Tween(other.Inner, 0.12, { BackgroundColor3 = Library.Theme.ControlTop })
				end
				SubTab.Left.Visible = true
				SubTab.Right.Visible = true
				Util.Tween(subLabel, 0.12, { TextColor3 = Library.Theme.Accent1 })
				Util.Tween(subBtnInner, 0.12, { BackgroundColor3 = Library.Theme.GroupTop })
			end

			subBtnInner.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					selectSubTab()
				end
			end)

			table.insert(self.SubTabs, SubTab)
			if #self.SubTabs == 1 then
				selectSubTab()
			end

			function SubTab:AddGroupbox(gCfg)
				gCfg = gCfg or {}
				local side = (gCfg.Side and string.lower(gCfg.Side) == "right") and subRightCol or subLeftCol
				return Tab.CreateGroupbox(side, gCfg)
			end

			return SubTab
		end

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
		end

		tabBtnInner.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then selectTab() end
		end)

		Tab.Btn = tabBtnOuter
		Tab.Inner = tabBtnInner
		Tab.Label = tabLabel
		Tab.GradLine = tabGradLine
		table.insert(Window.Tabs, Tab)

		if #Window.Tabs == 1 then selectTab() end

		-- Helper function to generate groupbox inside any column
		function Tab.CreateGroupbox(parentCol, gCfg)
			gCfg = gCfg or {}
			local gTitle = gCfg.Title or "Group"

			local gbOuter, gbInner = Util.CreateHardBorder(parentCol, UDim2.new(1, 0, 0, 0), nil, Library.Theme.GroupTop, Library.Theme.GroupBottom)
			gbOuter.AutomaticSize = Enum.AutomaticSize.Y

			local titleHold = New("Frame", {
				Size = UDim2.fromOffset(0, 16),
				AutomaticSize = Enum.AutomaticSize.X,
				Position = UDim2.fromOffset(10, -8),
				BackgroundColor3 = Library.Theme.MainTop,
				BorderSizePixel = 0,
				ZIndex = 5,
				Parent = gbOuter,
			})
			Util.RegisterTheme(titleHold, "BackgroundColor3", "BackgroundColor")

			New("UIPadding", {
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
				Parent = titleHold,
			})
			local titleText = New("TextLabel", {
				Size = UDim2.new(1, 0, 1, -2),
				BackgroundTransparency = 1,
				Font = Library.Theme.FontBold,
				TextSize = Library.Theme.FontSize,
				TextColor3 = Library.Theme.Text,
				Text = string.upper(gTitle),
				ZIndex = 6,
				Parent = titleHold,
			})
			Util.RegisterTheme(titleText, "TextColor3", "FontColor")

			local titleUnderline = New("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, -1),
				BackgroundColor3 = Library.Theme.Accent1,
				BorderSizePixel = 0,
				ZIndex = 6,
				Parent = titleHold,
			})
			Util.RegisterTheme(titleUnderline, "BackgroundColor3", "AccentColor")

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

			-- COLORPICKER (100% NATIVE SV + HUE GRADIENTS)
			local function createColorPicker(parentHold, defaultCol, flag, callback)
				local curColor = defaultCol or Library.Theme.Accent1
				local curH, curS, curV = curColor:ToHSV()

				local cpOuter = New("TextButton", {
					Size = UDim2.fromOffset(28, 14),
					BackgroundColor3 = Library.Theme.OuterBorder,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Text = "",
					Parent = parentHold,
				})
				local cpMid = New("Frame", {
					Size = UDim2.new(1, -2, 1, -2),
					Position = UDim2.fromOffset(1, 1),
					BackgroundColor3 = Library.Theme.MidBorder,
					BorderSizePixel = 0,
					Parent = cpOuter,
				})
				local cpPreview = New("Frame", {
					Size = UDim2.new(1, -2, 1, -2),
					Position = UDim2.fromOffset(1, 1),
					BackgroundColor3 = curColor,
					BorderSizePixel = 0,
					Parent = cpMid,
				})
				New("Frame", {
					Size = UDim2.new(1, 0, 0.5, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.85,
					BorderSizePixel = 0,
					Parent = cpPreview,
				})

				local isOpen = false
				local popOuter = nil
				local blocker = nil

				local function closePicker()
					if not isOpen then return end
					isOpen = false
					if blocker then blocker:Destroy() blocker = nil end
					if popOuter then popOuter:Destroy() popOuter = nil end
				end

				local function openPicker()
					if isOpen then closePicker() return end
					isOpen = true

					blocker = New("TextButton", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = "",
						ZIndex = 9990,
						Parent = screenGui,
					})
					blocker.MouseButton1Click:Connect(closePicker)

					local absPos = cpOuter.AbsolutePosition
					local pOuter, pInner = Util.CreateHardBorder(screenGui, UDim2.fromOffset(175, 148), UDim2.fromOffset(math.clamp(absPos.X - 145, 10, 1500), absPos.Y + 16), Library.Theme.MainTop, Library.Theme.MainBottom)
					pOuter.ZIndex = 9995
					Util.AddSkeetGradientBar(pInner, 2)
					popOuter = pOuter

					-- 1. NATIVE SV PALETTE (Layer 1: Base Hue Color)
					local svBorder = New("Frame", {
						Size = UDim2.fromOffset(130, 100),
						Position = UDim2.fromOffset(8, 8),
						BackgroundColor3 = Library.Theme.OuterBorder,
						BorderSizePixel = 0,
						ZIndex = 9996,
						Parent = pInner,
					})
					local svBase = New("Frame", {
						Size = UDim2.new(1, -2, 1, -2),
						Position = UDim2.fromOffset(1, 1),
						BackgroundColor3 = Color3.fromHSV(curH, 1, 1),
						BorderSizePixel = 0,
						ClipsDescendants = true,
						ZIndex = 9996,
						Parent = svBorder,
					})

					-- Layer 2: White to Transparent Horizontal Gradient (Saturation)
					local satLayer = New("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						ZIndex = 9997,
						Parent = svBase,
					})
					New("UIGradient", {
						Rotation = 0,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(1, 1),
						}),
						Parent = satLayer,
					})

					-- Layer 3: Transparent to Black Vertical Gradient (Value)
					local valLayer = New("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						ZIndex = 9998,
						Parent = svBase,
					})
					New("UIGradient", {
						Rotation = 90,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(1, 0),
						}),
						Parent = valLayer,
					})

					-- SV Cursor Reticle
					local svPin = New("Frame", {
						Size = UDim2.fromOffset(5, 5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(curS, 1 - curV),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						ZIndex = 9999,
						Parent = svBase,
					})

					-- 2. NATIVE HUE RAINBOW BAR
					local hueBorder = New("Frame", {
						Size = UDim2.fromOffset(16, 100),
						Position = UDim2.fromOffset(148, 8),
						BackgroundColor3 = Library.Theme.OuterBorder,
						BorderSizePixel = 0,
						ZIndex = 9996,
						Parent = pInner,
					})
					local hueBase = New("Frame", {
						Size = UDim2.new(1, -2, 1, -2),
						Position = UDim2.fromOffset(1, 1),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						ZIndex = 9997,
						Parent = hueBorder,
					})
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
						Parent = hueBase,
					})

					-- Hue Pin
					local huePin = New("Frame", {
						Size = UDim2.new(1, 0, 0, 3),
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.fromScale(0, 1 - curH),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						ZIndex = 9999,
						Parent = hueBase,
					})

					-- Hex Text
					local hexLabel = New("TextLabel", {
						Size = UDim2.new(1, -16, 0, 22),
						Position = UDim2.fromOffset(8, 116),
						BackgroundTransparency = 1,
						Font = Library.Theme.Font,
						TextSize = Library.Theme.FontSize - 1,
						TextColor3 = Library.Theme.TextDim,
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "#" .. curColor:ToHex():upper(),
						ZIndex = 9996,
						Parent = pInner,
					})

					local function updateColor()
						local newCol = Color3.fromHSV(curH, curS, curV)
						curColor = newCol
						svBase.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
						cpPreview.BackgroundColor3 = newCol
						hexLabel.Text = "#" .. newCol:ToHex():upper()
						if flag then Library.Flags[flag] = newCol end
						callback(newCol)
					end

					local draggingSV, draggingHue = false, false

					valLayer.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							draggingSV = true
							local mPos = input.Position
							curS = math.clamp((mPos.X - svBase.AbsolutePosition.X) / svBase.AbsoluteSize.X, 0, 1)
							curV = 1 - math.clamp((mPos.Y - svBase.AbsolutePosition.Y) / svBase.AbsoluteSize.Y, 0, 1)
							svPin.Position = UDim2.fromScale(curS, 1 - curV)
							updateColor()
						end
					end)

					hueBase.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							draggingHue = true
							local mPos = input.Position
							curH = 1 - math.clamp((mPos.Y - hueBase.AbsolutePosition.Y) / hueBase.AbsoluteSize.Y, 0, 1)
							huePin.Position = UDim2.fromScale(0, 1 - curH)
							updateColor()
						end
					end)

					local moveConn = UserInputService.InputChanged:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							if draggingSV then
								local mPos = input.Position
								curS = math.clamp((mPos.X - svBase.AbsolutePosition.X) / svBase.AbsoluteSize.X, 0, 1)
								curV = 1 - math.clamp((mPos.Y - svBase.AbsolutePosition.Y) / svBase.AbsoluteSize.Y, 0, 1)
								svPin.Position = UDim2.fromScale(curS, 1 - curV)
								updateColor()
							elseif draggingHue then
								local mPos = input.Position
								curH = 1 - math.clamp((mPos.Y - hueBase.AbsolutePosition.Y) / hueBase.AbsoluteSize.Y, 0, 1)
								huePin.Position = UDim2.fromScale(0, 1 - curH)
								updateColor()
							end
						end
					end)

					local endConn = UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							draggingSV = false
							draggingHue = false
						end
					end)

					pOuter.AncestryChanged:Connect(function()
						if not pOuter.Parent then
							moveConn:Disconnect()
							endConn:Disconnect()
						end
					end)
				end

				cpOuter.MouseButton1Click:Connect(openPicker)
				return cpOuter
			end

			-- KEYBIND
			local function createKeybindElement(parentHold, defaultKey, defaultMode, flag, elemName, onToggleVal)
				local currentKey = defaultKey or Enum.KeyCode.E
				local bindMode   = defaultMode or "Toggle"
				local listening  = false

				local bindBtnOuter, bindBtnInner = Util.CreateHardBorder(parentHold, UDim2.fromOffset(48, 15), nil, Library.Theme.ControlTop, Library.Theme.ControlBottom)
				bindBtnOuter.ZIndex = 6

				local bindLabel = New("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Font = Library.Theme.FontBold,
					TextSize = Library.Theme.FontSize - 2,
					TextColor3 = Library.Theme.Text,
					Text = "[" .. (currentKey.Name or "NONE") .. "]",
					ZIndex = 7,
					Parent = bindBtnInner,
				})

				local clickArea = New("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					ZIndex = 8,
					Parent = bindBtnOuter,
				})

				local function refreshBindState(isActive)
					if listening then
						bindLabel.Text = "[...]"
						bindLabel.TextColor3 = Library.Theme.Accent1
					elseif isActive then
						bindLabel.Text = "[" .. (currentKey.Name or "NONE") .. "]"
						bindLabel.TextColor3 = Library.Theme.Accent1
					else
						bindLabel.Text = "[" .. (currentKey.Name or "NONE") .. "]"
						bindLabel.TextColor3 = Library.Theme.Text
					end
				end

				clickArea.MouseButton1Click:Connect(function()
					listening = true
					refreshBindState(false)
				end)

				clickArea.MouseButton2Click:Connect(function()
					local blocker = New("TextButton", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = "",
						ZIndex = 9990,
						Parent = screenGui,
					})
					local absPos = bindBtnOuter.AbsolutePosition
					local menuOuter, menuInner = Util.CreateHardBorder(screenGui, UDim2.fromOffset(80, 68), UDim2.fromOffset(absPos.X - 32, absPos.Y + 18), Library.Theme.MainTop, Library.Theme.MainBottom)
					menuOuter.ZIndex = 9995
					Util.AddSkeetGradientBar(menuInner, 1)

					local modes = {"Toggle", "Hold", "Always"}
					for i, modeName in ipairs(modes) do
						local mBtn = New("TextButton", {
							Size = UDim2.new(1, 0, 0, 20),
							Position = UDim2.fromOffset(0, (i-1)*22 + 2),
							BackgroundTransparency = 1,
							BackgroundColor3 = Library.Theme.ControlHover,
							BorderSizePixel = 0,
							Font = Library.Theme.Font,
							TextSize = Library.Theme.FontSize - 1,
							TextColor3 = (bindMode == modeName) and Library.Theme.Accent1 or Library.Theme.TextDim,
							Text = modeName,
							ZIndex = 9996,
							Parent = menuInner,
						})
						mBtn.MouseEnter:Connect(function() Util.Tween(mBtn, 0.08, { BackgroundTransparency = 0 }) end)
						mBtn.MouseLeave:Connect(function() Util.Tween(mBtn, 0.08, { BackgroundTransparency = 1 }) end)
						mBtn.MouseButton1Click:Connect(function()
							bindMode = modeName
							if Library.KeybindList and currentKey ~= Enum.KeyCode.Unknown then
								Library.KeybindList:SetBind(elemName, currentKey.Name, bindMode, true)
							end
							blocker:Destroy()
							menuOuter:Destroy()
						end)
					end

					blocker.MouseButton1Click:Connect(function()
						blocker:Destroy()
						menuOuter:Destroy()
					end)
				end)

				UserInputService.InputBegan:Connect(function(input, gp)
					if listening then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							listening = false
							if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
								currentKey = Enum.KeyCode.Unknown
							else
								currentKey = input.KeyCode
							end
							refreshBindState(onToggleVal and onToggleVal())
							if Library.KeybindList and currentKey ~= Enum.KeyCode.Unknown then
								Library.KeybindList:SetBind(elemName, currentKey.Name, bindMode, onToggleVal and onToggleVal())
							end
						end
					elseif not gp and currentKey ~= Enum.KeyCode.Unknown and input.KeyCode == currentKey then
						if bindMode == "Toggle" then
							local nxt = not (onToggleVal and onToggleVal())
							if onToggleVal then onToggleVal(nxt) end
							refreshBindState(nxt)
						elseif bindMode == "Hold" then
							if onToggleVal then onToggleVal(true) end
							refreshBindState(true)
						end
						if Library.KeybindList then
							Library.KeybindList:SetBind(elemName, currentKey.Name, bindMode, onToggleVal and onToggleVal())
						end
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if currentKey ~= Enum.KeyCode.Unknown and input.KeyCode == currentKey and bindMode == "Hold" then
						if onToggleVal then onToggleVal(false) end
						refreshBindState(false)
						if Library.KeybindList then
							Library.KeybindList:SetBind(elemName, currentKey.Name, bindMode, false)
						end
					end
				end)

				return bindBtnOuter
			end

			-- TOGGLE
			function Group:AddToggle(tCfg)
				tCfg = tCfg or {}
				local tText    = tCfg.Text or "Toggle"
				local state    = tCfg.Default or false
				local flag     = tCfg.Flag or tText
				local callback = tCfg.Callback or function() end

				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Parent = elemList,
				})

				local boxOuter, boxInner = Util.CreateHardBorder(row, UDim2.fromOffset(13, 13), UDim2.fromOffset(0, 2), Library.Theme.ControlTop, Library.Theme.ControlBottom)
				
				local fill = New("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Library.Theme.Accent1,
					BorderSizePixel = 0,
					BackgroundTransparency = state and 0 or 1,
					Parent = boxInner,
				})
				Util.RegisterTheme(fill, "BackgroundColor3", "AccentColor")

				local label = New("TextLabel", {
					Size = UDim2.new(1, -20, 1, 0),
					Position = UDim2.fromOffset(20, 0),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = Library.Theme.FontSize,
					TextColor3 = state and Library.Theme.Text or Library.Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = tText,
					Parent = row,
				})
				Util.RegisterTheme(label, "TextColor3", "FontColor")

				local inlineHold = New("Frame", {
					Size = UDim2.new(0, 0, 1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					ZIndex = 5,
					Parent = row,
				})
				New("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 5),
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

				local clickBtn = New("TextButton", {
					Size = UDim2.new(1, -65, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					ZIndex = 2,
					Parent = row,
				})
				clickBtn.MouseButton1Click:Connect(function() setToggle(not Toggle.Value) end)

				function Toggle:Set(val) setToggle(val) end
				function Toggle:Get() return Toggle.Value end

				function Toggle:AddColorpicker(cpCfg)
					cpCfg = cpCfg or {}
					createColorPicker(inlineHold, cpCfg.Default, cpCfg.Flag or (flag .. "_Color"), cpCfg.Callback or function() end)
					return Toggle
				end

				function Toggle:AddKeybind(kbCfg)
					kbCfg = kbCfg or {}
					createKeybindElement(inlineHold, kbCfg.Default or Enum.KeyCode.E, kbCfg.Mode or "Toggle", kbCfg.Flag or (flag .. "_Bind"), tText, function(newVal)
						if newVal ~= nil then setToggle(newVal) end
						return Toggle.Value
					end)
					return Toggle
				end

				Library.Flags[flag] = state
				return Toggle
			end

			-- STANDALONE COLORPICKER
			function Group:AddColorpicker(cpCfg)
				cpCfg = cpCfg or {}
				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Parent = elemList,
				})
				New("TextLabel", {
					Size = UDim2.new(1, -34, 1, 0),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = cpCfg.Text or "Colorpicker",
					Parent = row,
				})
				local pickerHold = New("Frame", {
					Size = UDim2.new(0, 28, 1, 0),
					Position = UDim2.new(1, -28, 0, 0),
					BackgroundTransparency = 1,
					Parent = row,
				})
				createColorPicker(pickerHold, cpCfg.Default, cpCfg.Flag or cpCfg.Text, cpCfg.Callback or function() end)
			end

			-- STANDALONE KEYBIND
			function Group:AddKeybind(kbCfg)
				kbCfg = kbCfg or {}
				local kbText     = kbCfg.Text or "Keybind"
				local callback   = kbCfg.Callback or function() end
				local active     = false

				local row = New("Frame", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Parent = elemList,
				})
				New("TextLabel", {
					Size = UDim2.new(1, -54, 1, 0),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = kbText,
					Parent = row,
				})
				local bindHold = New("Frame", {
					Size = UDim2.new(0, 48, 1, 0),
					Position = UDim2.new(1, -48, 0, 0),
					BackgroundTransparency = 1,
					Parent = row,
				})
				createKeybindElement(bindHold, kbCfg.Default or Enum.KeyCode.F, kbCfg.Mode or "Toggle", kbCfg.Flag or kbText, kbText, function(newVal)
					if newVal ~= nil then
						active = newVal
						callback(active)
					end
					return active
				end)
			end

			-- SLIDER
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

				New("TextLabel", {
					Size = UDim2.new(0.7, 0, 0, 14),
					BackgroundTransparency = 1,
					Font = Library.Theme.Font,
					TextSize = Library.Theme.FontSize,
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
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Right,
					Text = tostring(curVal) .. suffix,
					Parent = row,
				})

				local trackOuter, trackInner = Util.CreateHardBorder(row, UDim2.new(1, 0, 0, 8), UDim2.fromOffset(0, 18), Library.Theme.ControlTop, Library.Theme.ControlBottom)

				local pct = math.clamp((curVal - min) / (max - min), 0, 1)
				local fill = New("Frame", {
					Size = UDim2.new(pct, 0, 1, 0),
					BackgroundColor3 = Library.Theme.Accent1,
					BorderSizePixel = 0,
					Parent = trackInner,
				})
				Util.RegisterTheme(fill, "BackgroundColor3", "AccentColor")

				local dragging = false
				local function updateSlider(xPos)
					local x = math.clamp((xPos - trackInner.AbsolutePosition.X) / trackInner.AbsoluteSize.X, 0, 1)
					local val = math.floor(min + ((max - min) * x))
					curVal = val
					Library.Flags[flag] = val
					valLabel.Text = tostring(val) .. suffix
					Util.Tween(fill, 0.05, { Size = UDim2.new(x, 0, 1, 0) })
					cb(val)
				end

				local trackBtn = New("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					Parent = trackOuter,
				})

				trackBtn.MouseButton1Down:Connect(function()
					dragging = true
					local mouse = UserInputService:GetMouseLocation()
					updateSlider(mouse.X)
				end)

				UserInputService.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						updateSlider(input.Position.X)
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
				end)

				local Slider = { Value = curVal }
				function Slider:Set(v)
					v = math.clamp(v, min, max)
					curVal = v
					valLabel.Text = tostring(v) .. suffix
					Util.Tween(fill, 0.1, { Size = UDim2.new((v - min) / (max - min), 0, 1, 0) })
					cb(v)
				end
				function Slider:Get() return curVal end
				return Slider
			end

			-- DROPDOWN
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
					TextSize = Library.Theme.FontSize,
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
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Text = getDisplayString(),
					Parent = ddInner,
				})

				local arrow = New("ImageLabel", {
					Size = UDim2.fromOffset(12, 12),
					Position = UDim2.new(1, -16, 0.5, -6),
					BackgroundTransparency = 1,
					Image = Library.Icons.Chevron,
					ImageColor3 = Library.Theme.TextDim,
					Parent = ddInner,
				})

				local popOuter = nil
				local blocker  = nil
				local isOpen   = false

				local function closeDropdown()
					if not isOpen then return end
					isOpen = false
					Util.Tween(arrow, 0.14, { Rotation = 0, ImageColor3 = Library.Theme.TextDim })
					if blocker then blocker:Destroy() blocker = nil end
					if popOuter then
						local anim = Util.Tween(popOuter, 0.12, { Size = UDim2.fromOffset(popOuter.AbsoluteSize.X, 0) })
						anim.Completed:Connect(function()
							if popOuter then popOuter:Destroy() popOuter = nil end
						end)
					end
				end

				local function openDropdown()
					if isOpen then closeDropdown() return end
					isOpen = true
					Util.Tween(arrow, 0.14, { Rotation = 180, ImageColor3 = Library.Theme.Accent1 })

					blocker = New("TextButton", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = "",
						ZIndex = 9990,
						Parent = screenGui,
					})
					blocker.MouseButton1Click:Connect(closeDropdown)

					local absPos  = ddOuter.AbsolutePosition
					local absSize = ddOuter.AbsoluteSize
					local listH   = math.min(#list * 22, 130)

					local pOuter, pInner = Util.CreateHardBorder(screenGui, UDim2.fromOffset(absSize.X, 0), UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 2), Library.Theme.MainTop, Library.Theme.MainBottom)
					pOuter.ClipsDescendants = true
					pOuter.ZIndex = 9995
					Util.AddSkeetGradientBar(pInner, 1)
					popOuter = pOuter

					local scroll = New("ScrollingFrame", {
						Size = UDim2.new(1, 0, 1, -2),
						Position = UDim2.fromOffset(0, 2),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ScrollBarThickness = 2,
						ScrollBarImageColor3 = Library.Theme.Accent1,
						CanvasSize = UDim2.new(0, 0, 0, #list * 22),
						ZIndex = 9996,
						Parent = pInner,
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
							Font = Library.Theme.Font,
							TextSize = Library.Theme.FontSize,
							TextXAlignment = Enum.TextXAlignment.Left,
							Text = "  " .. item,
							TextColor3 = isSelected and Library.Theme.Accent1 or Library.Theme.TextDim,
							ZIndex = 9997,
							Parent = scroll,
						})

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

					Util.Tween(pOuter, 0.15, { Size = UDim2.fromOffset(absSize.X, listH + 4) })
				end

				local clickBtn = New("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					Parent = ddOuter,
				})
				clickBtn.MouseButton1Click:Connect(openDropdown)

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
				function Dropdown:Refresh(newList, retainSelection)
					list = newList or {}
					if not retainSelection then
						if isMulti then
							multiSelected = {}
						else
							curVal = list[1] or ""
						end
					end
					currentLabel.Text = getDisplayString()
				end
				return Dropdown
			end

			-- BUTTON
			function Group:AddButton(bCfg)
				bCfg = bCfg or {}
				local bText   = bCfg.Text or "Button"
				local isRisky = bCfg.Risky or false
				local cb      = bCfg.Callback or function() end

				local topCol = isRisky and Library.Theme.Risky or Library.Theme.ControlTop
				local botCol = isRisky and Library.Theme.RiskyDark or Library.Theme.ControlBottom

				local btnOuter, btnInner = Util.CreateHardBorder(elemList, UDim2.new(1, 0, 0, 22), nil, topCol, botCol)
				
				New("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Font = Library.Theme.FontBold,
					TextSize = Library.Theme.FontSize,
					TextColor3 = Library.Theme.Text,
					Text = bText,
					Parent = btnInner,
				})

				local clickBtn = New("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					Parent = btnOuter,
				})

				clickBtn.MouseEnter:Connect(function()
					Util.Tween(btnInner, 0.1, { BackgroundColor3 = isRisky and Library.Theme.Risky or Library.Theme.ControlHover })
				end)
				clickBtn.MouseLeave:Connect(function()
					Util.Tween(btnInner, 0.1, { BackgroundColor3 = topCol })
				end)
				clickBtn.MouseButton1Click:Connect(function()
					Util.Tween(btnInner, 0.04, { BackgroundColor3 = Library.Theme.Accent1 })
					task.delay(0.08, function() Util.Tween(btnInner, 0.12, { BackgroundColor3 = topCol }) end)
					cb()
				end)

				return btnOuter
			end

			-- TEXTBOX
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
					TextSize = Library.Theme.FontSize,
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
					TextSize = Library.Theme.FontSize,
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

		function Tab:AddGroupbox(gCfg)
			gCfg = gCfg or {}
			local side = (gCfg.Side and string.lower(gCfg.Side) == "right") and rightCol or leftCol
			return Tab.CreateGroupbox(side, gCfg)
		end

		return Tab
	end

	return Window
end

function Library:SetThemeColor(colorType, newColor)
	if not colorType or not newColor then return end

	local internalKey = colorType
	if colorType == "FontColor" or colorType == "Text" then
		internalKey = "FontColor"
		Library.Theme.Text = newColor
	elseif colorType == "MainColor" or colorType == "GroupTop" then
		internalKey = "MainColor"
		Library.Theme.GroupTop = newColor
	elseif colorType == "AccentColor" or colorType == "Accent1" then
		internalKey = "AccentColor"
		Library.Theme.Accent1 = newColor
	elseif colorType == "BackgroundColor" or colorType == "MainTop" then
		internalKey = "BackgroundColor"
		Library.Theme.MainTop = newColor
	elseif colorType == "OutlineColor" or colorType == "OuterBorder" then
		internalKey = "OutlineColor"
		Library.Theme.OuterBorder = newColor
	end

	-- Live-update all registered UI elements across the whole menu
	if Library.Registry[internalKey] then
		for _, item in ipairs(Library.Registry[internalKey]) do
			if item.Instance and item.Instance.Parent then
				pcall(function()
					item.Instance[item.Property] = newColor
				end)
			end
		end
	end

	if Library.ThemeSignals[internalKey] then
		for _, cb in ipairs(Library.ThemeSignals[internalKey]) do
			pcall(cb, newColor)
		end
	end
end

function Library:SetTheme(themeTable)
	for name, col in pairs(themeTable or {}) do
		Library:SetThemeColor(name, col)
	end
end

return Library
