-- GMod Optimizer
-- Server-side admin functionality

GMOpt.Admin = GMOpt.Admin or {}

-- Store admin data
GMOpt.Admin.Data = {
    activeAdmins = {},
    lastPerformanceUpdate = 0,
    performanceUpdateInterval = 5 -- Send updates every 5 seconds
}

-- Add console commands for admin control
function GMOpt.Admin:SetupConsoleCommands()
    -- Reset all optimization settings to defaults
    concommand.Add("gmopt_reset_all", function(ply)
        if IsValid(ply) and not ply:IsAdmin() then
            ply:ChatPrint("You need to be an admin to use this command")
            return
        end
        
        -- Reset server settings
        RunConsoleCommand("gmopt_prop_cleanup_enabled", "1")
        RunConsoleCommand("gmopt_prop_cleanup_interval", "300")
        RunConsoleCommand("gmopt_prop_abandon_time", "600")
        RunConsoleCommand("gmopt_entity_throttling", "1")
        
        RunConsoleCommand("gmopt_bandwidth_optimization", "1")
        RunConsoleCommand("gmopt_message_batching", "1")
        RunConsoleCommand("gmopt_nonessential_update_rate", "0.5")
        
        RunConsoleCommand("gmopt_enforce_client_settings", "0")
        RunConsoleCommand("gmopt_monitor_addons", "1")
        RunConsoleCommand("gmopt_auto_adjust_settings", "1")
        
        RunConsoleCommand("gmopt_high_load_threshold", "0.8")
        RunConsoleCommand("gmopt_low_performance_threshold", "15")
        
        print("[GMod Optimizer] Reset all server settings to defaults")
    end)
    
    -- Force cleanup all props
    concommand.Add("gmopt_cleanup_all", function(ply)
        if IsValid(ply) and not ply:IsAdmin() then
            ply:ChatPrint("You need to be an admin to use this command")
            return
        end
        
        -- Run cleanup
        game.CleanUpMap(false, {"env_fire", "entityflame", "_firesmoke"})
        
        -- Notify all players
        for _, p in ipairs(player.GetAll()) do
            p:ChatPrint("Server admin performed a cleanup")
        end
        
        print("[GMod Optimizer] Admin cleanup performed")
    end)
    
    -- Set client optimization level for all players
    concommand.Add("gmopt_set_all_clients", function(ply, cmd, args)
        if IsValid(ply) and not ply:IsAdmin() then
            ply:ChatPrint("You need to be an admin to use this command")
            return
        end
        
        if #args < 1 then
            print("Usage: gmopt_set_all_clients <ultra|low|medium|high|max>")
            return
        end
        
        local preset = string.lower(args[1])
        local validPresets = {
            ["ultra"] = true,
            ["low"] = true,
            ["medium"] = true,
            ["high"] = true,
            ["max"] = true
        }
        
        if not validPresets[preset] then
            print("Invalid preset. Available presets: ultra, low, medium, high, max")
            return
        end
        
        -- Enforce preset on all clients
        for _, p in ipairs(player.GetAll()) do
            p:ConCommand("gmopt_preset " .. preset)
            p:ChatPrint("Server admin set your optimization level to: " .. preset)
        end
        
        print("[GMod Optimizer] Set all clients to " .. preset .. " optimization level")
    end)
    
    -- Emergency performance mode
    concommand.Add("gmopt_emergency_mode", function(ply)
        if IsValid(ply) and not ply:IsAdmin() then
            ply:ChatPrint("You need to be an admin to use this command")
            return
        end
        
        -- Apply extreme performance settings
        RunConsoleCommand("gmopt_prop_cleanup_enabled", "1")
        RunConsoleCommand("gmopt_prop_cleanup_interval", "30") -- Very frequent cleanups
        RunConsoleCommand("gmopt_prop_abandon_time", "120") -- Very short abandonment time
        RunConsoleCommand("gmopt_entity_throttling", "1")
        
        RunConsoleCommand("gmopt_enforce_client_settings", "1")
        RunConsoleCommand("gmopt_auto_adjust_settings", "0") -- Disable auto-adjustment
        
        -- Enforce ultra preset on all clients
        for _, p in ipairs(player.GetAll()) do
            p:ConCommand("gmopt_preset ultra")
            p:ChatPrint("EMERGENCY: Server performance mode activated")
        end
        
        -- Cleanup the map
        game.CleanUpMap(false)
        
        print("[GMod Optimizer] Emergency performance mode activated")
    end)
end

-- Register network messages
function GMOpt.Admin:RegisterNetworkMessages()
    util.AddNetworkString("GMOpt_AdminMenu")
    util.AddNetworkString("GMOpt_AdminCommand")
    util.AddNetworkString("GMOpt_AdminPerformance")
end

-- Handle admin command
function GMOpt.Admin:HandleCommand(ply, command, args)
    -- Verify player is an admin
    if not IsValid(ply) or not ply:IsAdmin() then
        return
    end
    
    -- Process command
    if command == "set_convar" then
        -- Set a ConVar value
        if #args >= 2 then
            local convar = args[1]
            local value = args[2]
            
            -- Only allow changing GMOpt ConVars
            if string.find(convar, "gmopt_") == 1 then
                RunConsoleCommand(convar, value)
                ply:ChatPrint("Set " .. convar .. " to " .. value)
            else
                ply:ChatPrint("Can only change GMod Optimizer ConVars")
            end
        end
    elseif command == "get_performance" then
        -- Send performance data to admin
        self:SendPerformanceData(ply)
    elseif command == "cleanup" then
        -- Perform cleanup
        game.CleanUpMap(false, {"env_fire", "entityflame", "_firesmoke"})
        
        -- Notify all players
        for _, p in ipairs(player.GetAll()) do
            p:ChatPrint("Server admin performed a cleanup")
        end
    elseif command == "enforce_preset" then
        -- Enforce a preset on all clients
        if #args >= 1 then
            local preset = args[1]
            
            for _, p in ipairs(player.GetAll()) do
                p:ConCommand("gmopt_preset " .. preset)
                p:ChatPrint("Server admin set your optimization level to: " .. preset)
            end
        end
    end
end

-- Send performance data to admin
function GMOpt.Admin:SendPerformanceData(ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    -- Get performance data
    local data = {
        server = {
            fps = GMOpt.Resources.Data.serverPerformance.fps,
            frameTime = GMOpt.Resources.Data.serverPerformance.frameTime,
            entityCount = #ents.GetAll(),
            playerCount = #player.GetAll(),
            uptime = CurTime(),
            cpuUsage = "N/A" -- Not directly available in GMod
        },
        settings = {
            propCleanup = GMOpt.ConVars.Server.PropCleanupEnabled:GetBool(),
            propCleanupInterval = GMOpt.ConVars.Server.PropCleanupInterval:GetInt(),
            entityThrottling = GMOpt.ConVars.Server.EntityThrottling:GetBool(),
            bandwidthOptimization = GMOpt.ConVars.Server.BandwidthOptimization:GetBool(),
            enforceClientSettings = GMOpt.ConVars.Server.EnforceClientSettings:GetBool(),
            autoAdjustSettings = GMOpt.ConVars.Server.AutoAdjustSettings:GetBool()
        },
        clients = {}
    }
    
    -- Add client data
    for _, p in ipairs(player.GetAll()) do
        table.insert(data.clients, {
            name = p:Nick(),
            steamID = p:SteamID(),
            ping = p:Ping()
        })
    end
    
    -- Send data to admin
    net.Start("GMOpt_AdminPerformance")
    net.WriteTable(data)
    net.Send(ply)
end

-- Update active admins
function GMOpt.Admin:UpdateActiveAdmins()
    -- Find all admins
    self.Data.activeAdmins = {}
    
    for _, ply in ipairs(player.GetAll()) do
        if ply:IsAdmin() then
            table.insert(self.Data.activeAdmins, ply)
        end
    end
end

-- Send periodic updates to admins
function GMOpt.Admin:SendPeriodicUpdates()
    -- Check if it's time for an update
    local currentTime = CurTime()
    if currentTime - self.Data.lastPerformanceUpdate < self.Data.performanceUpdateInterval then
        return
    end
    
    -- Update last update time
    self.Data.lastPerformanceUpdate = currentTime
    
    -- Update active admins list
    self:UpdateActiveAdmins()
    
    -- Send updates to all active admins
    for _, admin in ipairs(self.Data.activeAdmins) do
        self:SendPerformanceData(admin)
    end
end

-- Initialize admin functionality
hook.Add("Initialize", "GMOpt_AdminInit", function()
    GMOpt.Admin:RegisterNetworkMessages()
    GMOpt.Admin:SetupConsoleCommands()
end)

-- Handle commands from client admin panel
net.Receive("GMOpt_AdminCommand", function(len, ply)
    local command = net.ReadString()
    local argsStr = net.ReadString()
    local args = string.Explode(" ", argsStr)
    
    GMOpt.Admin:HandleCommand(ply, command, args)
end)

-- Main admin panel update
hook.Add("Think", "GMOpt_AdminUpdate", function()
    GMOpt.Admin:SendPeriodicUpdates()
end)

-- Handle player initial spawn
hook.Add("PlayerInitialSpawn", "GMOpt_AdminPlayerInit", function(ply)
    -- Check if player is an admin after a short delay
    timer.Simple(5, function()
        if IsValid(ply) and ply:IsAdmin() then
            -- Add player to active admins
            GMOpt.Admin:UpdateActiveAdmins()
            
            -- Send initial performance data
            GMOpt.Admin:SendPerformanceData(ply)
        end
    end)
end)