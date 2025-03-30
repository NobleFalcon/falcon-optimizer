-- GMod Optimizer
-- Console variable management

GMOpt.ConVars = GMOpt.ConVars or {}

-- Client ConVars
GMOpt.ConVars.Client = {
    -- Render settings
    RenderDistance = CreateConVar("gmopt_render_distance", "5000", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Maximum distance to render entities", 1000, 10000),
    EntityCulling = CreateConVar("gmopt_entity_culling", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable entity culling based on distance", 0, 1),
    ParticleLimit = CreateConVar("gmopt_particle_limit", "1", FCVAR_ARCHIVE, "Limit particle effects for better performance", 0, 1),
    LODSystem = CreateConVar("gmopt_lod_system", "1", FCVAR_ARCHIVE, "Enable level of detail system for models", 0, 1),
    
    -- Material settings
    LowQualityTextures = CreateConVar("gmopt_low_quality_textures", "0", FCVAR_ARCHIVE, "Use lower quality textures", 0, 1),
    MaterialSimplification = CreateConVar("gmopt_material_simplification", "0", FCVAR_ARCHIVE, "Simplify materials for performance", 0, 1),
    TextureMemoryLimit = CreateConVar("gmopt_texture_memory_limit", "512", FCVAR_ARCHIVE, "Texture memory limit in MB", 128, 2048),
    
    -- UI settings
    FPSLimit = CreateConVar("gmopt_fps_limit", "0", FCVAR_ARCHIVE, "Limit FPS (0 = unlimited)", 0, 300),
    DisableHUDAnimations = CreateConVar("gmopt_disable_hud_animations", "0", FCVAR_ARCHIVE, "Disable HUD animations", 0, 1),
    MinimalistHUD = CreateConVar("gmopt_minimalist_hud", "0", FCVAR_ARCHIVE, "Use minimalist HUD", 0, 1)
}

-- Server ConVars
if SERVER then
    GMOpt.ConVars.Server = {
        -- Entity management
        PropCleanupEnabled = CreateConVar("gmopt_prop_cleanup_enabled", "1", FCVAR_ARCHIVE, "Enable automatic prop cleanup", 0, 1),
        PropCleanupInterval = CreateConVar("gmopt_prop_cleanup_interval", "300", FCVAR_ARCHIVE, "Seconds between cleanup checks", 60, 3600),
        PropAbandonTime = CreateConVar("gmopt_prop_abandon_time", "600", FCVAR_ARCHIVE, "Seconds until props are considered abandoned", 60, 7200),
        EntityThrottling = CreateConVar("gmopt_entity_throttling", "1", FCVAR_ARCHIVE, "Enable entity throttling under high load", 0, 1),
        
        -- Network settings
        BandwidthOptimization = CreateConVar("gmopt_bandwidth_optimization", "1", FCVAR_ARCHIVE, "Enable bandwidth optimization", 0, 1),
        MessageBatching = CreateConVar("gmopt_message_batching", "1", FCVAR_ARCHIVE, "Enable network message batching", 0, 1),
        NonEssentialUpdateRate = CreateConVar("gmopt_nonessential_update_rate", "0.5", FCVAR_ARCHIVE, "Non-essential entity update interval", 0.1, 5.0),
        
        -- Resource settings
        EnforceClientSettings = CreateConVar("gmopt_enforce_client_settings", "0", FCVAR_ARCHIVE, "Enforce client optimization settings", 0, 1),
        MonitorAddons = CreateConVar("gmopt_monitor_addons", "1", FCVAR_ARCHIVE, "Monitor resource-intensive addons", 0, 1),
        AutoAdjustSettings = CreateConVar("gmopt_auto_adjust_settings", "1", FCVAR_ARCHIVE, "Auto-adjust settings based on performance", 0, 1),
        
        -- Performance thresholds
        HighLoadThreshold = CreateConVar("gmopt_high_load_threshold", "0.8", FCVAR_ARCHIVE, "High server load threshold (0-1)", 0.5, 0.95),
        LowPerformanceThreshold = CreateConVar("gmopt_low_performance_threshold", "15", FCVAR_ARCHIVE, "Low performance threshold in FPS", 10, 30)
    }
end

-- Update configuration from ConVars
function GMOpt.ConVars:UpdateConfig()
    -- Update client config
    GMOpt.Config.Client.RenderDistance = self.Client.RenderDistance:GetInt()
    GMOpt.Config.Client.EntityCulling = self.Client.EntityCulling:GetBool()
    GMOpt.Config.Client.ParticleLimit = self.Client.ParticleLimit:GetBool()
    GMOpt.Config.Client.LODSystem = self.Client.LODSystem:GetBool()
    
    GMOpt.Config.Client.LowQualityTextures = self.Client.LowQualityTextures:GetBool()
    GMOpt.Config.Client.MaterialSimplification = self.Client.MaterialSimplification:GetBool()
    GMOpt.Config.Client.TextureMemoryLimit = self.Client.TextureMemoryLimit:GetInt()
    
    GMOpt.Config.Client.FPSLimit = self.Client.FPSLimit:GetInt()
    GMOpt.Config.Client.DisableHUDAnimations = self.Client.DisableHUDAnimations:GetBool()
    GMOpt.Config.Client.MinimalistHUD = self.Client.MinimalistHUD:GetBool()
    
    -- Update server config if on server
    if SERVER and self.Server then
        GMOpt.Config.Server.PropCleanupEnabled = self.Server.PropCleanupEnabled:GetBool()
        GMOpt.Config.Server.PropCleanupInterval = self.Server.PropCleanupInterval:GetInt()
        GMOpt.Config.Server.PropAbandonTime = self.Server.PropAbandonTime:GetInt()
        GMOpt.Config.Server.EntityThrottling = self.Server.EntityThrottling:GetBool()
        
        GMOpt.Config.Server.BandwidthOptimization = self.Server.BandwidthOptimization:GetBool()
        GMOpt.Config.Server.MessageBatching = self.Server.MessageBatching:GetBool()
        GMOpt.Config.Server.NonEssentialUpdateRate = self.Server.NonEssentialUpdateRate:GetFloat()
        
        GMOpt.Config.Server.EnforceClientSettings = self.Server.EnforceClientSettings:GetBool()
        GMOpt.Config.Server.MonitorAddons = self.Server.MonitorAddons:GetBool()
        GMOpt.Config.Server.AutoAdjustSettings = self.Server.AutoAdjustSettings:GetBool()
        
        GMOpt.Config.Server.HighLoadThreshold = self.Server.HighLoadThreshold:GetFloat()
        GMOpt.Config.Server.LowPerformanceThreshold = self.Server.LowPerformanceThreshold:GetInt()
    end
    
    -- Save updated config
    GMOpt.Config:Save()
end

-- Apply configuration to ConVars
function GMOpt.Config:ApplyToConVars()
    -- Apply client config using RunConsoleCommand instead of direct SetInt/SetBool
    RunConsoleCommand("gmopt_render_distance", tostring(self.Client.RenderDistance))
    RunConsoleCommand("gmopt_entity_culling", self.Client.EntityCulling and "1" or "0")
    RunConsoleCommand("gmopt_particle_limit", self.Client.ParticleLimit and "1" or "0")
    RunConsoleCommand("gmopt_lod_system", self.Client.LODSystem and "1" or "0")
    
    RunConsoleCommand("gmopt_low_quality_textures", self.Client.LowQualityTextures and "1" or "0")
    RunConsoleCommand("gmopt_material_simplification", self.Client.MaterialSimplification and "1" or "0")
    RunConsoleCommand("gmopt_texture_memory_limit", tostring(self.Client.TextureMemoryLimit))
    
    RunConsoleCommand("gmopt_fps_limit", tostring(self.Client.FPSLimit))
    RunConsoleCommand("gmopt_disable_hud_animations", self.Client.DisableHUDAnimations and "1" or "0")
    RunConsoleCommand("gmopt_minimalist_hud", self.Client.MinimalistHUD and "1" or "0")
    
    -- Apply server config if on server
    if SERVER and GMOpt.ConVars.Server then
        RunConsoleCommand("gmopt_prop_cleanup_enabled", self.Server.PropCleanupEnabled and "1" or "0")
        RunConsoleCommand("gmopt_prop_cleanup_interval", tostring(self.Server.PropCleanupInterval))
        RunConsoleCommand("gmopt_prop_abandon_time", tostring(self.Server.PropAbandonTime))
        RunConsoleCommand("gmopt_entity_throttling", self.Server.EntityThrottling and "1" or "0")
        
        RunConsoleCommand("gmopt_bandwidth_optimization", self.Server.BandwidthOptimization and "1" or "0")
        RunConsoleCommand("gmopt_message_batching", self.Server.MessageBatching and "1" or "0")
        RunConsoleCommand("gmopt_nonessential_update_rate", tostring(self.Server.NonEssentialUpdateRate))
        
        RunConsoleCommand("gmopt_enforce_client_settings", self.Server.EnforceClientSettings and "1" or "0")
        RunConsoleCommand("gmopt_monitor_addons", self.Server.MonitorAddons and "1" or "0")
        RunConsoleCommand("gmopt_auto_adjust_settings", self.Server.AutoAdjustSettings and "1" or "0")
        
        RunConsoleCommand("gmopt_high_load_threshold", tostring(self.Server.HighLoadThreshold))
        RunConsoleCommand("gmopt_low_performance_threshold", tostring(self.Server.LowPerformanceThreshold))
    end
end

-- Set up ConVar change callbacks
local function SetupConVarCallbacks()
    for _, convar in pairs(GMOpt.ConVars.Client) do
        cvars.AddChangeCallback(convar:GetName(), function(_, _, _)
            GMOpt.ConVars:UpdateConfig()
        end)
    end
    
    if SERVER and GMOpt.ConVars.Server then
        for _, convar in pairs(GMOpt.ConVars.Server) do
            cvars.AddChangeCallback(convar:GetName(), function(_, _, _)
                GMOpt.ConVars:UpdateConfig()
            end)
        end
    end
end

-- Initialize ConVars
hook.Add("Initialize", "GMOpt_ConVarInit", function()
    SetupConVarCallbacks()
end)