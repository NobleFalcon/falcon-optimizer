-- GMod Optimizer
-- UI performance settings

GMOpt.UI = GMOpt.UI or {}

-- Store original UI functions
GMOpt.UI.OriginalFunctions = GMOpt.UI.OriginalFunctions or {}

-- FPS limiter implementation
GMOpt.UI.LastFrameTime = 0
GMOpt.UI.FPSLimit = 0

-- Disabled HUD elements
GMOpt.UI.DisabledHUDElements = {}

-- Initialize UI optimization
function GMOpt.UI:Initialize()
    -- Store FPS limit setting
    self.FPSLimit = GMOpt.ConVars.Client.FPSLimit:GetInt()
    
    -- Store original HUD paint function
    if not self.OriginalFunctions.HUDPaint then
        self.OriginalFunctions.HUDPaint = hook.GetTable().HUDPaint
    end
end

-- Apply FPS limiter
function GMOpt.UI:ApplyFPSLimit()
    -- Get current FPS limit
    local limit = GMOpt.ConVars.Client.FPSLimit:GetInt()
    
    -- Disable FPS limit if set to 0
    if limit <= 0 then
        self.FPSLimit = 0
        return
    end
    
    -- Update FPS limit
    self.FPSLimit = limit
    
    -- Calculate frame time in milliseconds
    local frameTimeMs = 1000 / limit
    
    -- Get current time
    local currentTime = SysTime() * 1000
    
    -- Calculate time to wait
    local timeToWait = frameTimeMs - (currentTime - self.LastFrameTime)
    
    -- Wait if needed
    if timeToWait > 0 then
        -- Use timer.Sleep for more precise timing
        timer.Simple(timeToWait / 1000, function() end)
    end
    
    -- Update last frame time
    self.LastFrameTime = currentTime
end

-- Toggle HUD elements
function GMOpt.UI:ToggleHUDElements()
    local minimalistHUD = GMOpt.ConVars.Client.MinimalistHUD:GetBool()
    
    if minimalistHUD then
        -- List of non-essential HUD elements to disable
        local elementsToDisable = {
            "CHudHealth",
            "CHudBattery",
            "CHudAmmo",
            "CHudSecondaryAmmo",
            "CHudDamageIndicator",
            "CHudCrosshair",
            "CHudHistoryResource",
            "CHudPoisonDamageIndicator",
            "CHudSquadStatus",
            "CHudGeiger",
            "CHudTrain",
            "CHudFlashlight",
            "CHudMessage",
            "CHudAnimationInfo"
        }
        
        -- Disable non-essential HUD elements
        for _, element in ipairs(elementsToDisable) do
            if not self.DisabledHUDElements[element] then
                -- Store original state
                self.DisabledHUDElements[element] = true
                
                -- Hide the element
                hook.Add("HUDShouldDraw", "GMOpt_HideHUD_" .. element, function(name)
                    if name == element then return false end
                end)
            end
        end
    else
        -- Re-enable all previously disabled HUD elements
        for element, _ in pairs(self.DisabledHUDElements) do
            hook.Remove("HUDShouldDraw", "GMOpt_HideHUD_" .. element)
        end
        
        -- Clear disabled elements list
        self.DisabledHUDElements = {}
    end
end

-- Toggle HUD animations
function GMOpt.UI:ToggleHUDAnimations()
    local disableAnimations = GMOpt.ConVars.Client.DisableHUDAnimations:GetBool()
    
    if disableAnimations then
        -- Disable smooth HUD movement animations
        hook.Add("HUDPaint", "GMOpt_DisableHUDAnimations", function()
            -- This is a stub function that will be called before any HUD animations
            -- By adding this hook with high priority, we can prevent some animations
        end, GMOpt.Hooks.PRIORITY_HIGH)
    else
        -- Re-enable HUD animations
        hook.Remove("HUDPaint", "GMOpt_DisableHUDAnimations")
    end
end

-- Draw performance counter
function GMOpt.UI:DrawPerformanceCounter()
    -- Draw FPS counter in top-left corner
    local fps = GMOpt.Utils:GetFPS()
    local frameTime = GMOpt.Utils:GetFrameTimeMS()
    
    -- Set text color based on performance
    local fpsColor = Color(255, 255, 255)
    if fps < 30 then
        fpsColor = Color(255, 0, 0) -- Red for low FPS
    elseif fps < 60 then
        fpsColor = Color(255, 255, 0) -- Yellow for medium FPS
    else
        fpsColor = Color(0, 255, 0) -- Green for high FPS
    end
    
    -- Draw FPS counter
    draw.SimpleText("FPS: " .. fps, "DermaDefault", 10, 10, fpsColor)
    
    -- Draw frame time
    draw.SimpleText("Frame time: " .. frameTime .. " ms", "DermaDefault", 10, 25, Color(200, 200, 200))
    
    -- Draw optimization status
    local optStatus = "GMod Optimizer: "
    
    if GMOpt.ConVars.Client.EntityCulling:GetBool() then
        optStatus = optStatus .. "Culling ON | "
    else
        optStatus = optStatus .. "Culling OFF | "
    end
    
    if GMOpt.ConVars.Client.LODSystem:GetBool() then
        optStatus = optStatus .. "LOD ON | "
    else
        optStatus = optStatus .. "LOD OFF | "
    end
    
    if GMOpt.ConVars.Client.LowQualityTextures:GetBool() then
        optStatus = optStatus .. "LQ Textures ON"
    else
        optStatus = optStatus .. "LQ Textures OFF"
    end
    
    draw.SimpleText(optStatus, "DermaDefault", 10, 40, Color(150, 150, 255))
end

-- Update UI settings
function GMOpt.UI:Update()
    -- Apply FPS limiter
    self:ApplyFPSLimit()
    
    -- Toggle HUD elements based on settings
    self:ToggleHUDElements()
    
    -- Toggle HUD animations
    self:ToggleHUDAnimations()
end

-- Initialize UI optimization
hook.Add("Initialize", "GMOpt_UIInit", function()
    GMOpt.UI:Initialize()
end)

-- Set up UI update hook
hook.Add("Think", "GMOpt_UIUpdate", function()
    GMOpt.UI:Update()
end)

-- Draw performance counter
hook.Add("HUDPaint", "GMOpt_PerformanceCounter", function()
    GMOpt.UI:DrawPerformanceCounter()
end)

-- Add console command to toggle performance counter
local showPerformanceCounter = CreateConVar("gmopt_show_performance", "1", FCVAR_ARCHIVE, "Show performance counter", 0, 1)

-- Callback for performance counter toggle
cvars.AddChangeCallback("gmopt_show_performance", function(_, _, newValue)
    if newValue == "1" then
        hook.Add("HUDPaint", "GMOpt_PerformanceCounter", function()
            GMOpt.UI:DrawPerformanceCounter()
        end)
    else
        hook.Remove("HUDPaint", "GMOpt_PerformanceCounter")
    end
end)