-- GMod Optimizer
-- Client-side settings menu - FIXED VERSION

GMOpt = GMOpt or {}
GMOpt.Menu = GMOpt.Menu or {}

-- Create menu frame
function GMOpt.Menu:Open()
    -- Close existing menu if open
    if IsValid(self.Frame) then
        self.Frame:Remove()
    end
    
    -- Create frame
    self.Frame = vgui.Create("DFrame")
    self.Frame:SetTitle("GMod Optimizer")
    self.Frame:SetSize(600, 500)
    self.Frame:Center()
    self.Frame:MakePopup()
    
    -- Create tabs
    local tabs = vgui.Create("DPropertySheet", self.Frame)
    tabs:Dock(FILL)
    
    -- Add preset tab
    local presetPanel = self:CreatePresetsPanel()
    tabs:AddSheet("Presets", presetPanel, "icon16/application_lightning.png")
    
    -- Add render settings tab
    local renderPanel = self:CreateRenderPanel()
    tabs:AddSheet("Render", renderPanel, "icon16/monitor.png")
    
    -- Add material settings tab
    local materialPanel = self:CreateMaterialPanel()
    tabs:AddSheet("Materials", materialPanel, "icon16/palette.png")
    
    -- Add UI settings tab
    local uiPanel = self:CreateUIPanel()
    tabs:AddSheet("UI", uiPanel, "icon16/application.png")
    
    -- Add about tab
    local aboutPanel = self:CreateAboutPanel()
    tabs:AddSheet("About", aboutPanel, "icon16/information.png")
end

-- Create presets panel
function GMOpt.Menu:CreatePresetsPanel()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(10, 10, 10, 10)
    
    -- Create preset buttons
    local heading = vgui.Create("DLabel", panel)
    heading:SetText("Performance Presets")
    heading:SetFont("DermaLarge")
    heading:SetTextColor(Color(255, 255, 255))
    heading:Dock(TOP)
    heading:DockMargin(0, 0, 0, 10)
    
    -- Description label
    local description = vgui.Create("DLabel", panel)
    description:SetText("Select a performance preset to optimize your game. The lower the quality, the better the performance.")
    description:SetTextColor(Color(200, 200, 200))
    description:Dock(TOP)
    description:DockMargin(0, 0, 0, 20)
    description:SetWrap(true)
    description:SetTall(40)
    
    -- Create a panel for preset buttons
    local presetButtons = vgui.Create("DPanel", panel)
    presetButtons:Dock(TOP)
    presetButtons:SetTall(45 * 5 + 10) -- 5 buttons with margin
    presetButtons:DockPadding(5, 5, 5, 5)
    presetButtons.Paint = function() end -- Transparent
    
    -- Create a button for each preset
    local presets = {
        {name = "Ultra", desc = "Maximum performance, lowest quality", color = Color(255, 0, 0)},
        {name = "Low", desc = "Good performance, low quality", color = Color(255, 128, 0)},
        {name = "Medium", desc = "Balanced performance and quality", color = Color(255, 255, 0)},
        {name = "High", desc = "High quality, good performance", color = Color(0, 255, 0)},
        {name = "Max", desc = "Maximum quality, no optimizations", color = Color(0, 128, 255)}
    }
    
    for i, preset in ipairs(presets) do
        local button = vgui.Create("DButton", presetButtons)
        button:SetText(preset.name .. " - " .. preset.desc)
        button:Dock(TOP)
        button:DockMargin(0, 0, 0, 5)
        button:SetTall(40)
        
        -- Highlight current preset
        if GMOpt.Config.Client.CurrentPreset == preset.name then
            button:SetColor(preset.color)
        end
        
        -- Apply preset when button is clicked - FIXED
        button.DoClick = function()
            -- Use console command instead of direct method
            RunConsoleCommand("gmopt_preset", string.lower(preset.name))
            
            -- Update buttons
            for _, child in pairs(presetButtons:GetChildren()) do
                child:SetColor(Color(255, 255, 255))
            end
            
            button:SetColor(preset.color)
        end
    end
    
    -- Auto-detect button
    local autoDetect = vgui.Create("DButton", panel)
    autoDetect:SetText("Auto-Detect Best Preset")
    autoDetect:Dock(TOP)
    autoDetect:DockMargin(0, 20, 0, 0)
    autoDetect:SetTall(30)
    
    autoDetect.DoClick = function()
        -- Use console command instead of direct method
        RunConsoleCommand("gmopt_auto_preset")
        
        -- Update UI to reflect changes
        timer.Simple(0.5, function()
            self:Open() -- Reopen menu to refresh
        end)
    end
    
    -- Performance display
    local perfPanel = vgui.Create("DPanel", panel)
    perfPanel:Dock(TOP)
    perfPanel:DockMargin(0, 20, 0, 0)
    perfPanel:SetTall(60)
    
    local fpsLabel = vgui.Create("DLabel", perfPanel)
    fpsLabel:SetText("Current FPS: " .. GMOpt.Utils:GetFPS())
    fpsLabel:SetFont("DermaLarge")
    fpsLabel:SetTextColor(Color(255, 255, 255))
    fpsLabel:SizeToContents()
    fpsLabel:SetPos(10, 10)
    
    local frameTimeLabel = vgui.Create("DLabel", perfPanel)
    frameTimeLabel:SetText("Frame Time: " .. GMOpt.Utils:GetFrameTimeMS() .. " ms")
    frameTimeLabel:SetTextColor(Color(200, 200, 200))
    frameTimeLabel:SizeToContents()
    frameTimeLabel:SetPos(10, 35)
    
    -- Update performance display regularly
    perfPanel.Think = function()
        fpsLabel:SetText("Current FPS: " .. GMOpt.Utils:GetFPS())
        frameTimeLabel:SetText("Frame Time: " .. GMOpt.Utils:GetFrameTimeMS() .. " ms")
    end
    
    return panel
end

-- Create render settings panel
function GMOpt.Menu:CreateRenderPanel()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(10, 10, 10, 10)
    
    -- Create settings controls
    local scrollPanel = vgui.Create("DScrollPanel", panel)
    scrollPanel:Dock(FILL)
    
    -- Render Distance slider
    local renderDistance = vgui.Create("DNumSlider", scrollPanel)
    renderDistance:SetText("Render Distance")
    renderDistance:SetMin(1000)
    renderDistance:SetMax(10000)
    renderDistance:SetDecimals(0)
    renderDistance:SetValue(GetConVar("gmopt_render_distance"):GetInt())
    renderDistance:Dock(TOP)
    renderDistance:DockMargin(0, 10, 0, 10)
    
    renderDistance.OnValueChanged = function(_, value)
        -- FIXED: Use RunConsoleCommand instead of direct SetInt
        RunConsoleCommand("gmopt_render_distance", tostring(math.Round(value)))
    end
    
    -- Entity Culling checkbox
    local entityCulling = vgui.Create("DCheckBoxLabel", scrollPanel)
    entityCulling:SetText("Entity Culling (hide distant objects)")
    entityCulling:SetValue(GetConVar("gmopt_entity_culling"):GetBool())
    entityCulling:Dock(TOP)
    entityCulling:DockMargin(0, 10, 0, 5)
    
    entityCulling.OnChange = function(_, value)
        -- FIXED: Use RunConsoleCommand instead of direct SetBool
        RunConsoleCommand("gmopt_entity_culling", value and "1" or "0")
    end
    
    -- Particle Limit checkbox
    local particleLimit = vgui.Create("DCheckBoxLabel", scrollPanel)
    particleLimit:SetText("Particle Effect Limit")
    particleLimit:SetValue(GetConVar("gmopt_particle_limit"):GetBool())
    particleLimit:Dock(TOP)
    particleLimit:DockMargin(0, 5, 0, 5)
    
    particleLimit.OnChange = function(_, value)
        -- FIXED: Use RunConsoleCommand instead of direct SetBool
        RunConsoleCommand("gmopt_particle_limit", value and "1" or "0")
    end
    
    -- LOD System checkbox
    local lodSystem = vgui.Create("DCheckBoxLabel", scrollPanel)
    lodSystem:SetText("Level of Detail System")
    lodSystem:SetValue(GetConVar("gmopt_lod_system"):GetBool())
    lodSystem:Dock(TOP)
    lodSystem:DockMargin(0, 5, 0, 5)
    
    lodSystem.OnChange = function(_, value)
        -- FIXED: Use RunConsoleCommand instead of direct SetBool
        RunConsoleCommand("gmopt_lod_system", value and "1" or "0")
    end
    
    return panel
end

-- Create material settings panel
function GMOpt.Menu:CreateMaterialPanel()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(10, 10, 10, 10)
    
    -- Create settings controls
    local scrollPanel = vgui.Create("DScrollPanel", panel)
    scrollPanel:Dock(FILL)
    
    -- Low Quality Textures checkbox
    local lowQualityTextures = vgui.Create("DCheckBoxLabel", scrollPanel)
    lowQualityTextures:SetText("Low Quality Textures")
    lowQualityTextures:SetValue(GetConVar("gmopt_low_quality_textures"):GetBool())
    lowQualityTextures:Dock(TOP)
    lowQualityTextures:DockMargin(0, 10, 0, 5)
    
    lowQualityTextures.OnChange = function(_, value)
        -- FIXED: Use RunConsoleCommand instead of direct SetBool
        RunConsoleCommand("gmopt_low_quality_textures", value and "1" or "0")
    end
    
    -- Material Simplification checkbox
    local materialSimplification = vgui.Create("DCheckBoxLabel", scrollPanel)
    materialSimplification:SetText("Material Simplification (disable reflections, etc.)")
    materialSimplification:SetValue(GetConVar("gmopt_material_simplification"):GetBool())
    materialSimplification:Dock(TOP)
    materialSimplification:DockMargin(0, 5, 0, 5)
    
    materialSimplification.OnChange = function(_, value)
        -- FIXED: Use RunConsoleCommand instead of direct SetBool
        RunConsoleCommand("gmopt_material_simplification", value and "1" or "0")
    end
    
    -- Texture Memory Limit slider
    local textureMemoryLimit = vgui.Create("DNumSlider", scrollPanel)
    textureMemoryLimit:SetText("Texture Memory Limit (MB)")
    textureMemoryLimit:SetMin(128)
    textureMemoryLimit:SetMax(2048)
    textureMemoryLimit:SetDecimals(0)
    textureMemoryLimit:SetValue(GetConVar("gmopt_texture_memory_limit"):GetInt())
    textureMemoryLimit:Dock(TOP)
    textureMemoryLimit:DockMargin(0, 10, 0, 10)
    
    textureMemoryLimit.OnValueChanged = function(_, value)
        -- FIXED: Use RunConsoleCommand instead of direct SetInt
        RunConsoleCommand("gmopt_texture_memory_limit", tostring(math.Round(value)))
    end
    
    -- Force apply button
    local forceApply = vgui.Create("DButton", scrollPanel)
    forceApply:SetText("Force Apply Material Settings")
    forceApply:Dock(TOP)
    forceApply:DockMargin(0, 20, 0, 5)
    
    forceApply.DoClick = function()
        RunConsoleCommand("gmopt_optimize_materials")
        notification.AddLegacy("Material settings applied", NOTIFY_GENERIC, 3)
    end
    
    -- Reset button
    local resetButton = vgui.Create("DButton", scrollPanel)
    resetButton:SetText("Reset Material Settings")
    resetButton:Dock(TOP)
    resetButton:DockMargin(0, 5, 0, 5)
    
    resetButton.DoClick = function()
        RunConsoleCommand("gmopt_restore_materials")
        notification.AddLegacy("Material settings reset", NOTIFY_GENERIC, 3)
    end
    
    return panel
end

-- Create UI settings panel
function GMOpt.Menu:CreateUIPanel()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(10, 10, 10, 10)
    
    -- Create settings controls
    local scrollPanel = vgui.Create("DScrollPanel", panel)
    scrollPanel:Dock(FILL)
    
    -- FPS Limit controls
    local fpsLimitLabel = vgui.Create("DLabel", scrollPanel)
    fpsLimitLabel:SetText("FPS Limit (0 = unlimited)")
    fpsLimitLabel:Dock(TOP)
    fpsLimitLabel:DockMargin(0, 10, 0, 5)
    
    local fpsLimitPresets = vgui.Create("DPanel", scrollPanel)
    fpsLimitPresets:Dock(TOP)
    fpsLimitPresets:SetTall(30)
    fpsLimitPresets:DockMargin(0, 0, 0, 10)
    fpsLimitPresets.Paint = function() end -- Transparent
    
    -- FPS preset buttons
    local presets = {0, 30, 60, 120, 144, 240}
    
    for i, preset in ipairs(presets) do
        local width = 70
        local button = vgui.Create("DButton", fpsLimitPresets)
        button:SetText(preset == 0 and "Unlimited" or tostring(preset))
        button:SetSize(width, 25)
        button:SetPos((i - 1) * (width + 5), 0)
        
        button.DoClick = function()
            -- FIXED: Use RunConsoleCommand instead of direct SetInt
            RunConsoleCommand("gmopt_fps_limit", tostring(preset))
        end
    end
    
    -- FPS Limit slider
    local fpsLimit = vgui.Create("DNumSlider", scrollPanel)
    fpsLimit:SetText("Custom Limit")
    fpsLimit:SetMin(0)
    fpsLimit:SetMax(300)
    fpsLimit:SetDecimals(0)
    fpsLimit:SetValue(GetConVar("gmopt_fps_limit"):GetInt())
    fpsLimit:Dock(TOP)
    fpsLimit:DockMargin(0, 0, 0, 10)
    
    fpsLimit.OnValueChanged = function(_, value)
        -- FIXED: Use RunConsoleCommand instead of direct SetInt
        RunConsoleCommand("gmopt_fps_limit", tostring(math.Round(value)))
    end
    
    -- Disable HUD Animations checkbox
    local disableHUDAnimations = vgui.Create("DCheckBoxLabel", scrollPanel)
    disableHUDAnimations:SetText("Disable HUD Animations")
    disableHUDAnimations:SetValue(GetConVar("gmopt_disable_hud_animations"):GetBool())
    disableHUDAnimations:Dock(TOP)
    disableHUDAnimations:DockMargin(0, 10, 0, 5)
    
    disableHUDAnimations.OnChange = function(_, value)
        -- FIXED: Use RunConsoleCommand instead of direct SetBool
        RunConsoleCommand("gmopt_disable_hud_animations", value and "1" or "0")
    end
    
    -- Minimalist HUD checkbox
    local minimalistHUD = vgui.Create("DCheckBoxLabel", scrollPanel)
    minimalistHUD:SetText("Minimalist HUD (hide non-essential elements)")
    minimalistHUD:SetValue(GetConVar("gmopt_minimalist_hud"):GetBool())
    minimalistHUD:Dock(TOP)
    minimalistHUD:DockMargin(0, 5, 0, 5)
    
    minimalistHUD.OnChange = function(_, value)
        -- FIXED: Use RunConsoleCommand instead of direct SetBool
        RunConsoleCommand("gmopt_minimalist_hud", value and "1" or "0")
    end
    
    -- Performance Counter checkbox
    local showPerformance = vgui.Create("DCheckBoxLabel", scrollPanel)
    showPerformance:SetText("Show Performance Counter")
    showPerformance:SetValue(GetConVar("gmopt_show_performance"):GetBool())
    showPerformance:Dock(TOP)
    showPerformance:DockMargin(0, 5, 0, 5)
    
    showPerformance.OnChange = function(_, value)
        RunConsoleCommand("gmopt_show_performance", value and "1" or "0")
    end
    
    return panel
end

-- Create about panel
function GMOpt.Menu:CreateAboutPanel()
    local panel = vgui.Create("DPanel")
    panel:DockPadding(10, 10, 10, 10)
    
    -- Title
    local title = vgui.Create("DLabel", panel)
    title:SetText("GMod Optimizer v" .. GMOpt.Version)
    title:SetFont("DermaLarge")
    title:Dock(TOP)
    title:DockMargin(0, 0, 0, 10)
    
    -- Description
    local description = vgui.Create("DLabel", panel)
    description:SetText("A lightweight addon designed to improve Garry's Mod performance through targeted optimizations.")
    description:SetWrap(true)
    description:SetTall(40)
    description:Dock(TOP)
    description:DockMargin(0, 0, 0, 10)
    
    -- Features
    local features = vgui.Create("DLabel", panel)
    features:SetText("Features:")
    features:SetFont("DermaDefaultBold")
    features:Dock(TOP)
    features:DockMargin(0, 10, 0, 5)
    
    local featureList = vgui.Create("DLabel", panel)
    featureList:SetText("• Entity culling to hide distant objects\n• Particle effect limiting\n• Level of detail system\n• Material and texture optimization\n• FPS limiting\n• HUD performance options")
    featureList:SetWrap(true)
    featureList:SetTall(100)
    featureList:Dock(TOP)
    featureList:DockMargin(10, 0, 0, 0)
    
    -- Commands
    local commands = vgui.Create("DLabel", panel)
    commands:SetText("Console Commands:")
    commands:SetFont("DermaDefaultBold")
    commands:Dock(TOP)
    commands:DockMargin(0, 10, 0, 5)
    
    local commandList = vgui.Create("DLabel", panel)
    commandList:SetText("• gmopt_menu - Open this menu\n• gmopt_preset <ultra|low|medium|high|max> - Apply a preset\n• gmopt_auto_preset - Auto-detect and apply best preset\n• gmopt_optimize_materials - Force material optimization\n• gmopt_restore_materials - Restore original materials\n• gmopt_reset_visibility - Reset entity visibility")
    commandList:SetWrap(true)
    commandList:SetTall(120)
    commandList:Dock(TOP)
    commandList:DockMargin(10, 0, 0, 0)
    
    return panel
end

-- Register console command to open menu
concommand.Add("gmopt_menu", function()
    GMOpt.Menu:Open()
end)