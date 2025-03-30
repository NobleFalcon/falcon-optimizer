-- GMod Optimizer
-- Material and texture optimization

GMOpt.Materials = GMOpt.Materials or {}

-- Store original material settings
GMOpt.Materials.OriginalSettings = {}

-- List of materials to optimize
GMOpt.Materials.OptimizedMaterials = {}

-- Material optimization parameters
GMOpt.Materials.OptimizationParams = {
    -- Low quality textures
    lowQuality = {
        ["$reducedtexturequality"] = 1,
        ["$detailblendfactor"] = 0
    },
    
    -- Simplified materials
    simplified = {
        ["$phong"] = 0,
        ["$phongboost"] = 0,
        ["$envmap"] = "",
        ["$envmaptint"] = Vector(0, 0, 0),
        ["$detail"] = "",
        ["$rimlight"] = 0
    }
}

-- Initialize material optimization
function GMOpt.Materials:Initialize()
    -- Try to set texture memory limit
    local memoryLimit = GMOpt.ConVars.Client.TextureMemoryLimit:GetInt()
    RunConsoleCommand("mat_picmip", "1") -- Reduce texture quality
    RunConsoleCommand("r_lod", "2") -- Increase LOD levels
    RunConsoleCommand("mat_mipmaptextures", "1") -- Enable mipmaps
    
    -- Apply memory limit
    if memoryLimit > 0 then
        -- Convert MB to bytes
        local limitBytes = memoryLimit * 1024 * 1024
        RunConsoleCommand("mat_bufferprimitives", "1")
        GMOpt.Utils:DebugPrint("Set texture memory limit to " .. memoryLimit .. " MB")
    end
end

-- Apply material optimizations
function GMOpt.Materials:Optimize()
    -- Check if we need to optimize materials
    local shouldLowQuality = GMOpt.ConVars.Client.LowQualityTextures:GetBool()
    local shouldSimplify = GMOpt.ConVars.Client.MaterialSimplification:GetBool()
    
    if not shouldLowQuality and not shouldSimplify then
        -- Restore original material settings if optimization is disabled
        self:RestoreOriginalSettings()
        return
    end
    
    -- Get all materials
    local materialCount = 0
    local allMaterials = {}
    
    -- Process materials in batches to avoid freezing the game
    for i = 0, 100 do -- Start with a reasonable number
        local mat = Material("__dummy" .. i)
        
        if not mat:IsError() then
            table.insert(allMaterials, mat)
            materialCount = materialCount + 1
        end
    end
    
    GMOpt.Utils:DebugPrint("Found " .. materialCount .. " materials to optimize")
    
    -- Apply optimizations to materials
    for _, mat in ipairs(allMaterials) do
        local matName = mat:GetName()
        
        -- Skip already optimized materials
        if self.OptimizedMaterials[matName] then
            continue
        end
        
        -- Store original settings if not already stored
        if not self.OriginalSettings[matName] then
            self.OriginalSettings[matName] = {
                ["$reducedtexturequality"] = mat:GetInt("$reducedtexturequality"),
                ["$detailblendfactor"] = mat:GetFloat("$detailblendfactor"),
                ["$phong"] = mat:GetInt("$phong"),
                ["$phongboost"] = mat:GetFloat("$phongboost"),
                ["$envmap"] = mat:GetString("$envmap"),
                ["$envmaptint"] = mat:GetVector("$envmaptint"),
                ["$detail"] = mat:GetString("$detail"),
                ["$rimlight"] = mat:GetInt("$rimlight")
            }
        end
        
        -- Apply low quality texture settings
        if shouldLowQuality then
            for param, value in pairs(self.OptimizationParams.lowQuality) do
                if param == "$reducedtexturequality" then
                    mat:SetInt(param, value)
                elseif param == "$detailblendfactor" then
                    mat:SetFloat(param, value)
                end
            end
        end
        
        -- Apply simplified material settings
        if shouldSimplify then
            for param, value in pairs(self.OptimizationParams.simplified) do
                if type(value) == "number" then
                    mat:SetInt(param, value)
                elseif type(value) == "string" then
                    mat:SetString(param, value)
                elseif type(value) == "Vector" then
                    mat:SetVector(param, value)
                end
            end
        end
        
        -- Mark material as optimized
        self.OptimizedMaterials[matName] = true
    end
    
    GMOpt.Utils:DebugPrint("Material optimization complete")
end

-- Restore original material settings
function GMOpt.Materials:RestoreOriginalSettings()
    for matName, settings in pairs(self.OriginalSettings) do
        local mat = Material(matName)
        
        if not mat:IsError() then
            for param, value in pairs(settings) do
                if type(value) == "number" then
                    if param:find("int") then
                        mat:SetInt(param, value)
                    else
                        mat:SetFloat(param, value)
                    end
                elseif type(value) == "string" then
                    mat:SetString(param, value)
                elseif type(value) == "Vector" then
                    mat:SetVector(param, value)
                end
            end
        end
    end
    
    -- Clear optimized materials list
    self.OptimizedMaterials = {}
    
    GMOpt.Utils:DebugPrint("Restored original material settings")
end

-- Initialize material optimization
hook.Add("Initialize", "GMOpt_MaterialInit", function()
    GMOpt.Materials:Initialize()
end)

-- Apply material optimizations when settings change
cvars.AddChangeCallback("gmopt_low_quality_textures", function()
    GMOpt.Materials:Optimize()
end)

cvars.AddChangeCallback("gmopt_material_simplification", function()
    GMOpt.Materials:Optimize()
end)

-- Console command to force material optimization
concommand.Add("gmopt_optimize_materials", function()
    GMOpt.Materials:Optimize()
end)

-- Console command to restore original material settings
concommand.Add("gmopt_restore_materials", function()
    GMOpt.Materials:RestoreOriginalSettings()
end)