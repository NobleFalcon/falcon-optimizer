-- GMod Optimizer
-- Shared configuration system

GMOpt.Config = GMOpt.Config or {}

-- Default client configuration
GMOpt.Config.Client = {
    -- Render settings
    RenderDistance = 5000,
    EntityCulling = true,
    ParticleLimit = true,
    LODSystem = true,
    
    -- Material settings
    LowQualityTextures = false,
    MaterialSimplification = false,
    TextureMemoryLimit = 512, -- MB
    
    -- UI settings
    FPSLimit = 0, -- 0 = unlimited
    DisableHUDAnimations = false,
    MinimalistHUD = false,
    
    -- Applied preset (for reference)
    CurrentPreset = "High"
}

-- Default server configuration
GMOpt.Config.Server = {
    -- Entity management
    PropCleanupEnabled = true,
    PropCleanupInterval = 300, -- seconds
    PropAbandonTime = 600, -- seconds after owner disconnect
    EntityThrottling = true,
    
    -- Network settings
    BandwidthOptimization = true,
    MessageBatching = true,
    NonEssentialUpdateRate = 0.5, -- seconds
    
    -- Resource settings
    EnforceClientSettings = false,
    MonitorAddons = true,
    AutoAdjustSettings = true,
    
    -- Performance thresholds
    HighLoadThreshold = 0.8, -- 80% server load
    LowPerformanceThreshold = 15 -- FPS
}

-- Save configuration to file
function GMOpt.Config:Save()
    if not file.Exists("gmod_optimizer", "DATA") then
        file.CreateDir("gmod_optimizer")
    end
    
    local configTable = {
        client = self.Client,
        server = self.Server
    }
    
    local jsonString = util.TableToJSON(configTable, true)
    file.Write("gmod_optimizer/config.json", jsonString)
    
    return true
end

-- Load configuration from file
function GMOpt.Config:Load()
    if not file.Exists("gmod_optimizer/config.json", "DATA") then
        return false
    end
    
    local jsonString = file.Read("gmod_optimizer/config.json", "DATA")
    local configTable = util.JSONToTable(jsonString)
    
    if not configTable then
        return false
    end
    
    -- Update only keys that exist in the default config
    if configTable.client then
        for k, v in pairs(configTable.client) do
            if self.Client[k] ~= nil then
                self.Client[k] = v
            end
        end
    end
    
    if configTable.server then
        for k, v in pairs(configTable.server) do
            if self.Server[k] ~= nil then
                self.Server[k] = v
            end
        end
    end
    
    return true
end

-- Apply configuration to ConVars
function GMOpt.Config:ApplyToConVars()
    -- Will be implemented after ConVars are defined in sh_convars.lua
end

-- Initialize configuration
hook.Add("Initialize", "GMOpt_ConfigInit", function()
    -- Try to load existing config
    if not GMOpt.Config:Load() then
        -- Save default config if no existing config
        GMOpt.Config:Save()
    end
    
    -- Apply to convars if available
    if GMOpt.Config.ApplyToConVars then
        GMOpt.Config:ApplyToConVars()
    end
end)