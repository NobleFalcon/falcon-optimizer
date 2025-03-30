-- GMod Optimizer
-- Server-side resource control

GMOpt.Resources = GMOpt.Resources or {}

-- Store resource data
GMOpt.Resources.Data = {
    serverPerformance = {
        frameTime = 0,
        fps = 0,
        lastCheck = 0,
        checkInterval = 1 -- Check every second
    },
    addonUsage = {},
    totalAddonCount = 0,
    riskAddons = {}
}

-- Get server performance metrics
function GMOpt.Resources:UpdatePerformanceMetrics()
    local currentTime = SysTime()
    
    -- Only check periodically
    if currentTime - self.Data.serverPerformance.lastCheck < self.Data.serverPerformance.checkInterval then
        return
    end
    
    -- Update last check time
    self.Data.serverPerformance.lastCheck = currentTime
    
    -- Calculate FPS based on server tick interval
    local tickInterval = engine.TickInterval()
    if tickInterval > 0 then
        self.Data.serverPerformance.fps = math.floor(1 / tickInterval)
        self.Data.serverPerformance.frameTime = tickInterval * 1000 -- Convert to ms
    else
        -- Fallback values
        self.Data.serverPerformance.fps = 66
        self.Data.serverPerformance.frameTime = 15
    end
end

-- Scan for resource-intensive addons
function GMOpt.Resources:ScanAddons()
    -- Skip if addon monitoring is disabled
    if not GMOpt.ConVars.Server.MonitorAddons:GetBool() then return end
    
    -- Only scan addons periodically (every 30 seconds)
    local currentTime = CurTime()
    if self.Data.lastAddonScan and currentTime - self.Data.lastAddonScan < 30 then
        return
    end
    
    self.Data.lastAddonScan = currentTime
    
    -- Get list of installed addons
    local addons = engine.GetAddons()
    self.Data.totalAddonCount = #addons
    
    -- Known problematic addons (these are just examples)
    local knownProblematicAddons = {
        ["extreme_particles_mod"] = "High particle count",
        ["ultra_realistic_graphics"] = "Intensive post-processing",
        ["mega_prop_pack"] = "High entity count",
        ["realistic_explosions"] = "Intensive particle effects",
        ["extreme_physics"] = "CPU-intensive physics calculations"
    }
    
    -- Scan installed addons
    self.Data.riskAddons = {}
    
    for _, addon in ipairs(addons) do
        -- Check if addon is known to be problematic
        local addonTitle = addon.title:lower()
        
        for problematicName, reason in pairs(knownProblematicAddons) do
            if addonTitle:find(problematicName) then
                table.insert(self.Data.riskAddons, {
                    title = addon.title,
                    reason = reason,
                    wsid = addon.wsid
                })
                break
            end
        end
        
        -- Also look for keywords that might indicate performance issues
        local keywords = {"extreme", "ultra", "realistic", "high quality", "maximum"}
        
        for _, keyword in ipairs(keywords) do
            if addonTitle:find(keyword) and not table.HasValue(self.Data.riskAddons, addon) then
                table.insert(self.Data.riskAddons, {
                    title = addon.title,
                    reason = "Possible performance impact based on name",
                    wsid = addon.wsid
                })
                break
            end
        end
    end
    
    -- Log found risky addons
    if #self.Data.riskAddons > 0 then
        print("[GMod Optimizer] Found " .. #self.Data.riskAddons .. " potentially resource-intensive addons:")
        for _, addon in ipairs(self.Data.riskAddons) do
            print("  - " .. addon.title .. " (Reason: " .. addon.reason .. ")")
        end
    end
end

-- Enforce client settings if enabled
function GMOpt.Resources:EnforceClientSettings()
    -- Skip if enforcement is disabled
    if not GMOpt.ConVars.Server.EnforceClientSettings:GetBool() then return end
    
    -- Only enforce settings periodically (every 60 seconds)
    local currentTime = CurTime()
    if self.Data.lastEnforcement and currentTime - self.Data.lastEnforcement < 60 then
        return
    end
    
    self.Data.lastEnforcement = currentTime
    
    -- Get recommended preset based on server performance
    local recommendedPreset = "Medium"
    local fps = self.Data.serverPerformance.fps
    
    if fps < 20 then
        recommendedPreset = "Ultra"
    elseif fps < 40 then
        recommendedPreset = "Low"
    elseif fps < 60 then
        recommendedPreset = "Medium"
    else
        recommendedPreset = "High"
    end
    
    -- Apply enforcement to all players
    for _, ply in ipairs(player.GetAll()) do
        -- Send notification to player
        net.Start("GMOpt_EnforceSettings")
        net.WriteString(recommendedPreset)
        net.Send(ply)
        
        -- Directly set some critical ConVars
        ply:ConCommand("gmopt_render_distance " .. GMOpt.Presets.Definitions[recommendedPreset].RenderDistance)
        ply:ConCommand("gmopt_entity_culling " .. (GMOpt.Presets.Definitions[recommendedPreset].EntityCulling and "1" or "0"))
        
        -- Don't enforce all settings to avoid being too intrusive
    end
    
    print("[GMod Optimizer] Enforced " .. recommendedPreset .. " performance settings on clients")
end

-- Auto-adjust server settings based on performance
function GMOpt.Resources:AutoAdjustSettings()
    -- Skip if auto-adjustment is disabled
    if not GMOpt.ConVars.Server.AutoAdjustSettings:GetBool() then return end
    
    -- Only adjust settings periodically (every 60 seconds)
    local currentTime = CurTime()
    if self.Data.lastAdjustment and currentTime - self.Data.lastAdjustment < 60 then
        return
    end
    
    self.Data.lastAdjustment = currentTime
    
    -- Get current server performance
    local fps = self.Data.serverPerformance.fps
    local lowPerformanceThreshold = GMOpt.ConVars.Server.LowPerformanceThreshold:GetInt()
    
    -- Adjust settings based on performance
    if fps < lowPerformanceThreshold then
        -- Server is struggling, apply aggressive optimizations
        GMOpt.ConVars.Server.PropCleanupInterval:SetInt(60) -- More frequent cleanups
        GMOpt.ConVars.Server.PropAbandonTime:SetInt(300) -- Shorter abandonment time
        GMOpt.ConVars.Server.EntityThrottling:SetBool(true) -- Enable entity throttling
        GMOpt.ConVars.Server.NonEssentialUpdateRate:SetFloat(0.5) -- Reduce update rate
        
        print("[GMod Optimizer] Auto-adjusted settings for low server performance (" .. fps .. " FPS)")
    else
        -- Server is performing well, use normal settings
        GMOpt.ConVars.Server.PropCleanupInterval:SetInt(300) -- Normal cleanup interval
        GMOpt.ConVars.Server.PropAbandonTime:SetInt(600) -- Normal abandonment time
        GMOpt.ConVars.Server.EntityThrottling:SetBool(false) -- Disable entity throttling
        GMOpt.ConVars.Server.NonEssentialUpdateRate:SetFloat(0.2) -- Normal update rate
        
        print("[GMod Optimizer] Auto-adjusted settings for normal server performance (" .. fps .. " FPS)")
    end
    
    self.Data.lastAdjustment = currentTime
end

-- Register network messages
function GMOpt.Resources:RegisterNetworkMessages()
    util.AddNetworkString("GMOpt_EnforceSettings")
    util.AddNetworkString("GMOpt_PerformanceData")
end

-- Send performance data to admins
function GMOpt.Resources:SendPerformanceData()
    -- Only send periodically (every 5 seconds)
    local currentTime = CurTime()
    if self.Data.lastDataSend and currentTime - self.Data.lastDataSend < 5 then
        return
    end
    
    self.Data.lastDataSend = currentTime
    
    -- Create performance data packet
    local data = {
        fps = self.Data.serverPerformance.fps,
        frameTime = self.Data.serverPerformance.frameTime,
        playerCount = #player.GetAll(),
        entityCount = #ents.GetAll(),
        riskAddonCount = #self.Data.riskAddons,
        enforceSettings = GMOpt.ConVars.Server.EnforceClientSettings:GetBool(),
        autoAdjust = GMOpt.ConVars.Server.AutoAdjustSettings:GetBool()
    }
    
    -- Send to all admins
    local admins = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:IsAdmin() then
            table.insert(admins, ply)
        end
    end
    
    if #admins > 0 then
        net.Start("GMOpt_PerformanceData")
        net.WriteTable(data)
        net.Send(admins)
    end
end

-- Main update function
function GMOpt.Resources:Update()
    -- Update performance metrics
    self:UpdatePerformanceMetrics()
    
    -- Scan for resource-intensive addons
    self:ScanAddons()
    
    -- Enforce client settings if enabled
    self:EnforceClientSettings()
    
    -- Auto-adjust server settings based on performance
    self:AutoAdjustSettings()
    
    -- Send performance data to admins
    self:SendPerformanceData()
end

-- Initialize resource control
hook.Add("Initialize", "GMOpt_ResourcesInit", function()
    GMOpt.Resources:RegisterNetworkMessages()
end)

-- Resource control think hook
hook.Add("Think", "GMOpt_ResourcesUpdate", function()
    GMOpt.Resources:Update()
end)

-- Console command to toggle client settings enforcement
concommand.Add("gmopt_toggle_enforce_settings", function(ply)
    -- Only allow admins to use this command
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("You need to be an admin to use this command")
        return
    end
    
    -- Toggle setting
    local currentValue = GMOpt.ConVars.Server.EnforceClientSettings:GetBool()
    GMOpt.ConVars.Server.EnforceClientSettings:SetBool(not currentValue)
    
    -- Notify
    print("[GMod Optimizer] Client settings enforcement " .. (not currentValue and "enabled" or "disabled"))
end)

-- Console command to toggle auto-adjustment
concommand.Add("gmopt_toggle_auto_adjust", function(ply)
    -- Only allow admins to use this command
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("You need to be an admin to use this command")
        return
    end
    
    -- Toggle setting
    local currentValue = GMOpt.ConVars.Server.AutoAdjustSettings:GetBool()
    GMOpt.ConVars.Server.AutoAdjustSettings:SetBool(not currentValue)
    
    -- Notify
    print("[GMod Optimizer] Auto-adjustment " .. (not currentValue and "enabled" or "disabled"))
end)