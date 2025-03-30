-- GMod Optimizer
-- Server-side network optimization

GMOpt.Network = GMOpt.Network or {}

-- Store network data
GMOpt.Network.Data = {
    messageBatches = {},
    lastBatchSend = 0,
    batchInterval = 0.1, -- 10 batches per second
    entityUpdateTimes = {},
    nonEssentialEntities = {}
}

-- Check if entity is essential
function GMOpt.Network:IsEssentialEntity(ent)
    if not IsValid(ent) then return false end
    
    -- Players are always essential
    if ent:IsPlayer() then return true end
    
    -- NPCs are essential
    if ent:IsNPC() then return true end
    
    -- Vehicles with drivers are essential
    if ent:IsVehicle() and IsValid(ent:GetDriver()) then return true end
    
    -- Weapons being held are essential
    if ent:IsWeapon() and IsValid(ent:GetOwner()) and ent:GetOwner():IsPlayer() then return true end
    
    -- Props being held or moved recently are essential
    if ent:GetClass() == "prop_physics" then
        if ent:IsPlayerHolding() or ent:GetVelocity():Length() > 10 then
            return true
        end
    end
    
    -- All other entities are non-essential
    return false
end

-- Add message to batch
function GMOpt.Network:BatchMessage(name, recipient, ...)
    -- Skip if message batching is disabled
    if not GMOpt.ConVars.Server.MessageBatching:GetBool() then
        -- Send message directly
        net.Start(name)
        net.WriteTable({...})
        
        if recipient == nil then
            net.Broadcast()
        else
            net.Send(recipient)
        end
        
        return
    end
    
    -- Create batch key
    local batchKey = name
    if recipient then
        if type(recipient) == "Player" then
            batchKey = batchKey .. "_" .. recipient:SteamID()
        else
            batchKey = batchKey .. "_" .. tostring(recipient)
        end
    else
        batchKey = batchKey .. "_broadcast"
    end
    
    -- Create batch if it doesn't exist
    if not self.Data.messageBatches[batchKey] then
        self.Data.messageBatches[batchKey] = {
            name = name,
            recipient = recipient,
            messages = {}
        }
    end
    
    -- Add message to batch
    table.insert(self.Data.messageBatches[batchKey].messages, {...})
end

-- Send all batched messages
function GMOpt.Network:SendBatches()
    -- Skip if no batches or not time yet
    local currentTime = CurTime()
    if currentTime - self.Data.lastBatchSend < self.Data.batchInterval then return end
    
    -- Update last batch send time
    self.Data.lastBatchSend = currentTime
    
    -- Send each batch
    for batchKey, batch in pairs(self.Data.messageBatches) do
        if #batch.messages > 0 then
            -- Send batch
            net.Start("GMOpt_MessageBatch")
            net.WriteString(batch.name)
            net.WriteTable(batch.messages)
            
            if batch.recipient == nil then
                net.Broadcast()
            else
                net.Send(batch.recipient)
            end
            
            -- Clear batch
            self.Data.messageBatches[batchKey].messages = {}
        end
    end
end

-- Control entity update rate
-- Control entity update rate
function GMOpt.Network:ControlEntityUpdates()
    -- Skip if bandwidth optimization is disabled
    if not GMOpt.ConVars.Server.BandwidthOptimization:GetBool() then
        -- Reset update rates for all tracked entities
        for ent, _ in pairs(self.Data.nonEssentialEntities) do
            if IsValid(ent) then
                -- Safely attempt to reset update rate
                if ent.SetUpdateRate then
                    ent:SetUpdateRate(0) -- Reset to default
                else
                    -- Alternative approach if SetUpdateRate doesn't exist
                    -- Just mark the entity as no longer throttled
                    self.Data.nonEssentialEntities[ent] = nil
                end
            end
        end
        
        -- Clear non-essential entities list
        self.Data.nonEssentialEntities = {}
        return
    end
    
    -- Get non-essential update rate
    local nonEssentialRate = GMOpt.ConVars.Server.NonEssentialUpdateRate:GetFloat()
    
    -- Get all entities
    local allEntities = ents.GetAll()
    
    -- Update each entity
    for _, ent in ipairs(allEntities) do
        if IsValid(ent) then
            -- Check if entity is essential
            if self:IsEssentialEntity(ent) then
                -- Reset update rate for essential entities
                if self.Data.nonEssentialEntities[ent] then
                    -- Safely attempt to reset update rate
                    if ent.SetUpdateRate then
                        ent:SetUpdateRate(0) -- Default rate
                    end
                    self.Data.nonEssentialEntities[ent] = nil
                end
            else
                -- Reduce update rate for non-essential entities
                if ent.SetUpdateRate then
                    -- Only apply if the method exists
                    ent:SetUpdateRate(nonEssentialRate)
                    self.Data.nonEssentialEntities[ent] = true
                end
            end
        end
    end
end

-- Apply bandwidth limits
function GMOpt.Network:ApplyBandwidthLimits()
    -- Skip if bandwidth optimization is disabled
    if not GMOpt.ConVars.Server.BandwidthOptimization:GetBool() then return end
    
    -- Set reasonable bandwidth limits
    local maxPlayerCount = game.MaxPlayers()
    local bytesPerSecondPerPlayer = 10000 -- 10 KB/s per player
    
    -- Calculate total rate
    local totalRateBytes = maxPlayerCount * bytesPerSecondPerPlayer
    local totalRateKB = totalRateBytes / 1024
    
    -- Set max bandwidth rate
    RunConsoleCommand("sv_maxrate", math.floor(totalRateBytes))
    
    -- Set individual client rate limits
    for _, ply in ipairs(player.GetAll()) do
        ply:ConCommand("rate " .. bytesPerSecondPerPlayer)
    end
end

-- Register network message for batching
function GMOpt.Network:RegisterNetworkMessage()
    if not util.NetworkStringToID("GMOpt_MessageBatch") then
        util.AddNetworkString("GMOpt_MessageBatch")
    end
end

-- Initialize client-side message batch handler
function GMOpt.Network:SetupClientHandler()
    -- Send client setup data
    for _, ply in ipairs(player.GetAll()) do
        net.Start("GMOpt_MessageBatch_Setup")
        net.Send(ply)
    end
end

-- Main update function
function GMOpt.Network:Update()
    -- Send batched messages
    self:SendBatches()
    
    -- Control entity update rates
    self:ControlEntityUpdates()
end

-- Initialize network optimization
hook.Add("Initialize", "GMOpt_NetworkInit", function()
    GMOpt.Network:RegisterNetworkMessage()
    GMOpt.Network:ApplyBandwidthLimits()
end)

-- Handle player joins
hook.Add("PlayerInitialSpawn", "GMOpt_NetworkPlayerInit", function(ply)
    -- Apply bandwidth limits to new player
    timer.Simple(5, function()
        if IsValid(ply) then
            ply:ConCommand("rate " .. 10000) -- 10 KB/s
        end
    end)
end)

-- Network think hook
hook.Add("Think", "GMOpt_NetworkUpdate", function()
    GMOpt.Network:Update()
end)

-- Console command to toggle bandwidth optimization
concommand.Add("gmopt_toggle_bandwidth_optimization", function(ply)
    -- Only allow admins to use this command
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("You need to be an admin to use this command")
        return
    end
    
    -- Toggle bandwidth optimization
    local currentValue = GMOpt.ConVars.Server.BandwidthOptimization:GetBool()
    GMOpt.ConVars.Server.BandwidthOptimization:SetBool(not currentValue)
    
    -- Notify
    print("[GMod Optimizer] Bandwidth optimization " .. (not currentValue and "enabled" or "disabled"))
end)