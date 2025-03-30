-- GMod Optimizer
-- Utility functions

GMOpt.Utils = GMOpt.Utils or {}

-- Performance measurement
GMOpt.Utils.PerfData = {
    frameTimes = {},
    frameTimeIndex = 1,
    frameTimeCount = 60, -- Store last 60 frames for average
    lastFrameTime = 0,
    averageFrameTime = 0,
    fps = 0
}

-- Update performance metrics
function GMOpt.Utils:UpdatePerformance()
    local currentTime = SysTime()
    local frameTime = currentTime - self.PerfData.lastFrameTime
    self.PerfData.lastFrameTime = currentTime
    
    -- Store frame time in circular buffer
    self.PerfData.frameTimes[self.PerfData.frameTimeIndex] = frameTime
    self.PerfData.frameTimeIndex = (self.PerfData.frameTimeIndex % self.PerfData.frameTimeCount) + 1
    
    -- Calculate average frame time and FPS
    local sum = 0
    local count = 0
    
    for _, time in pairs(self.PerfData.frameTimes) do
        if time then
            sum = sum + time
            count = count + 1
        end
    end
    
    if count > 0 then
        self.PerfData.averageFrameTime = sum / count
        self.PerfData.fps = 1 / self.PerfData.averageFrameTime
    end
end

-- Get current FPS
function GMOpt.Utils:GetFPS()
    return math.floor(self.PerfData.fps + 0.5)
end

-- Get average frame time in milliseconds
function GMOpt.Utils:GetFrameTimeMS()
    return math.floor(self.PerfData.averageFrameTime * 1000 + 0.5)
end

-- Entity distance functions
function GMOpt.Utils:ShouldRenderEntity(ent)
    if not IsValid(ent) then return false end
    
    -- Always render players
    if ent:IsPlayer() then return true end
    
    -- Check if entity is within render distance
    local distance = LocalPlayer():GetPos():Distance(ent:GetPos())
    local renderDistance = GMOpt.ConVars.Client.RenderDistance:GetInt()
    
    return distance <= renderDistance
end

-- Apply level of detail based on distance
function GMOpt.Utils:ApplyLOD(ent)
    if not IsValid(ent) then return end
    
    local distance = LocalPlayer():GetPos():Distance(ent:GetPos())
    local renderDistance = GMOpt.ConVars.Client.RenderDistance:GetInt()
    
    -- Apply LOD based on distance
    if distance > renderDistance * 0.8 then
        -- Far distance: low detail
        ent:SetModelScale(0.99, 0) -- Slight scale to improve performance
    elseif distance > renderDistance * 0.5 then
        -- Medium distance: medium detail
        ent:SetModelScale(1.0, 0)
    else
        -- Close distance: full detail
        ent:SetModelScale(1.0, 0)
    end
end

-- Is entity important? (used for update priority)
function GMOpt.Utils:IsImportantEntity(ent)
    if not IsValid(ent) then return false end
    
    -- Players and NPCs are always important
    if ent:IsPlayer() or ent:IsNPC() then return true end
    
    -- Vehicles with drivers are important
    if ent:IsVehicle() and IsValid(ent:GetDriver()) then return true end
    
    -- Physics props being held or recently touched are important
    if ent:GetClass() == "prop_physics" and ent:IsPlayerHolding() then return true end
    
    -- Weapons are generally important
    if ent:IsWeapon() then return true end
    
    return false
end

-- Debug functions
function GMOpt.Utils:DebugPrint(msg)
    if GetConVar("gmopt_debug"):GetBool() then
        print("[GMOpt Debug] " .. msg)
    end
end

-- Initialize performance tracking
hook.Add("Think", "GMOpt_PerformanceTracking", function()
    GMOpt.Utils:UpdatePerformance()
end)

-- Create debug convar
CreateConVar("gmopt_debug", "0", FCVAR_ARCHIVE, "Enable GMod Optimizer debug messages", 0, 1)