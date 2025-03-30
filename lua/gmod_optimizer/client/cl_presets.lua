-- GMod Optimizer
-- Performance presets

GMOpt.Presets = GMOpt.Presets or {}

-- Define performance presets
GMOpt.Presets.Definitions = {
    -- Ultra performance (lowest quality)
    ["Ultra"] = {
        -- Render settings
        RenderDistance = 2000,
        EntityCulling = true,
        ParticleLimit = true,
        LODSystem = true,
        
        -- Material settings
        LowQualityTextures = true,
        MaterialSimplification = true,
        TextureMemoryLimit = 256,
        
        -- UI settings
        FPSLimit = 60, -- Cap at 60 FPS for stability
        DisableHUDAnimations = true,
        MinimalistHUD = true
    },
    
    -- Low quality (good performance)
    ["Low"] = {
        -- Render settings
        RenderDistance = 3000,
        EntityCulling = true,
        ParticleLimit = true,
        LODSystem = true,
        
        -- Material settings
        LowQualityTextures = true,
        MaterialSimplification = true,
        TextureMemoryLimit = 384,
        
        -- UI settings
        FPSLimit = 90,
        DisableHUDAnimations = true,
        MinimalistHUD = false
    },
    
    -- Medium quality (balanced)
    ["Medium"] = {
        -- Render settings
        RenderDistance = 4000,
        EntityCulling = true,
        ParticleLimit = true,
        LODSystem = true,
        
        -- Material settings
        LowQualityTextures = false,
        MaterialSimplification = true,
        TextureMemoryLimit = 512,
        
        -- UI settings
        FPSLimit = 120,
        DisableHUDAnimations = false,
        MinimalistHUD = false
    },
    
    -- High quality (prioritize visuals)
    ["High"] = {
        -- Render settings
        RenderDistance = 6000,
        EntityCulling = true,
        ParticleLimit = false,
        LODSystem = true,
        
        -- Material settings
        LowQualityTextures = false,
        MaterialSimplification = false,
        TextureMemoryLimit = 768,
        
        -- UI settings
        FPSLimit = 0, -- Unlimited FPS
        DisableHUDAnimations = false,
        MinimalistHUD = false
    },
    
    -- Maximum quality (no optimizations)
    ["Max"] = {
        -- Render settings
        RenderDistance = 10000,
        EntityCulling = false,
        ParticleLimit = false,
        LODSystem = false,
        
        -- Material settings
        LowQualityTextures = false,
        MaterialSimplification = false,
        TextureMemoryLimit = 1024,
        
        -- UI settings
        FPSLimit = 0, -- Unlimited FPS
        DisableHUDAnimations = false,
        MinimalistHUD = false
    }
}

-- Apply a preset
function GMOpt.Presets:Apply(presetName)
    -- Check if preset exists
    if not self.Definitions[presetName] then
        GMOpt.Utils:DebugPrint("Preset not found: " .. presetName)
        return false
    end
    
    local preset = self.Definitions[presetName]
    
    -- Apply render settings safely using RunConsoleCommand instead of direct SetInt/SetBool
    RunConsoleCommand("gmopt_render_distance", tostring(preset.RenderDistance))
    RunConsoleCommand("gmopt_entity_culling", preset.EntityCulling and "1" or "0")
    RunConsoleCommand("gmopt_particle_limit", preset.ParticleLimit and "1" or "0")
    RunConsoleCommand("gmopt_lod_system", preset.LODSystem and "1" or "0")
    
    -- Apply material settings
    RunConsoleCommand("gmopt_low_quality_textures", preset.LowQualityTextures and "1" or "0")
    RunConsoleCommand("gmopt_material_simplification", preset.MaterialSimplification and "1" or "0")
    RunConsoleCommand("gmopt_texture_memory_limit", tostring(preset.TextureMemoryLimit))
    
    -- Apply UI settings
    RunConsoleCommand("gmopt_fps_limit", tostring(preset.FPSLimit))
    RunConsoleCommand("gmopt_disable_hud_animations", preset.DisableHUDAnimations and "1" or "0")
    RunConsoleCommand("gmopt_minimalist_hud", preset.MinimalistHUD and "1" or "0")
    
    -- Update configuration
    GMOpt.Config.Client.CurrentPreset = presetName
    GMOpt.ConVars:UpdateConfig()
    
    -- Force material optimization update
    GMOpt.Materials:Optimize()
    
    GMOpt.Utils:DebugPrint("Applied preset: " .. presetName)
    
    -- Notify user
    notification.AddLegacy("Applied " .. presetName .. " Performance Preset", NOTIFY_GENERIC, 4)
    
    return true
end

-- Detect system performance and suggest a preset
function GMOpt.Presets:DetectSystem()
    -- Get system information
    local systemInfo = {
        cpuCount = math.max(1, jit.arch == "x64" and 4 or 2), -- Estimate based on architecture
        ramMB = collectgarbage("count") / 1024 * 100, -- Rough estimate based on Lua memory usage
        fps = GMOpt.Utils:GetFPS()
    }
    
    -- Suggest preset based on performance
    local suggestedPreset = "Medium" -- Default suggestion
    
    if systemInfo.fps < 30 then
        -- Low performance system
        suggestedPreset = "Ultra"
    elseif systemInfo.fps < 60 then
        -- Medium-low performance system
        suggestedPreset = "Low"
    elseif systemInfo.fps < 100 then
        -- Medium performance system
        suggestedPreset = "Medium"
    elseif systemInfo.fps < 144 then
        -- High performance system
        suggestedPreset = "High"
    else
        -- Very high performance system
        suggestedPreset = "Max"
    end
    
    return suggestedPreset
end

-- Console command to apply a preset
concommand.Add("gmopt_preset", function(_, _, args)
    if #args < 1 then
        print("Usage: gmopt_preset <ultra|low|medium|high|max>")
        return
    end
    
    local presetName = args[1]:lower()
    local mappedPreset = {
        ["ultra"] = "Ultra",
        ["low"] = "Low",
        ["medium"] = "Medium",
        ["high"] = "High",
        ["max"] = "Max"
    }
    
    if mappedPreset[presetName] then
        GMOpt.Presets:Apply(mappedPreset[presetName])
    else
        print("Invalid preset. Available presets: Ultra, Low, Medium, High, Max")
    end
end)

-- Console command to detect and apply recommended preset
concommand.Add("gmopt_auto_preset", function()
    local suggestedPreset = GMOpt.Presets:DetectSystem()
    GMOpt.Presets:Apply(suggestedPreset)
    print("Auto-detected and applied " .. suggestedPreset .. " preset")
end)

-- Apply default preset on initialization
hook.Add("InitPostEntity", "GMOpt_DefaultPreset", function()
    -- Check if a preset is specified in the config
    if GMOpt.Config.Client.CurrentPreset and GMOpt.Presets.Definitions[GMOpt.Config.Client.CurrentPreset] then
        GMOpt.Presets:Apply(GMOpt.Config.Client.CurrentPreset)
    else
        -- Apply High preset by default
        GMOpt.Presets:Apply("High")
    end
end)