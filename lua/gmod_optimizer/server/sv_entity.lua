-- GMod Optimizer
-- Server-side entity management

GMOpt.Entity = GMOpt.Entity or {}

-- Store entity data
GMOpt.Entity.Data = {
    lastCleanup = 0,
    entityOwners = {},
    disconnectedPlayers = {},
    throttledEntities = {}
}

-- Track entity owners
function GMOpt.Entity:TrackEntityOwner(ent, ply)
    if not IsValid(ent) or not IsValid(ply) then return end
    
    -- Store entity owner
    self.Data.entityOwners[ent] = {
        steamID = ply:SteamID(),
        name = ply:Nick(),
        lastActive = CurTime()
    }
end

-- Track disconnected players
function GMOpt.Entity:PlayerDisconnected(ply)
    if not IsValid(ply) then return end
    
    -- Store disconnected player data
    self.Data.disconnectedPlayers[ply:SteamID()] = {
        name = ply:Nick(),
        disconnectTime = CurTime()
    }
end

-- Check for abandoned props
function GMOpt.Entity:CleanupAbandonedProps()
    -- Skip if cleanup is disabled
    if not GMOpt.ConVars.Server.PropCleanupEnabled:GetBool() then return end
    
    -- Check if it's time for cleanup
    local currentTime = CurTime()
    local interval = GMOpt.ConVars.Server.PropCleanupInterval:GetInt()
    
    if currentTime - self.Data.lastCleanup < interval then return end
    
    -- Update last cleanup time
    self.Data.lastCleanup = currentTime
    
    -- Get abandonment threshold
    local abandonTime = GMOpt.ConVars.Server.PropAbandonTime:GetInt()
    local removedCount = 0
    
    -- Check each entity
    for ent, ownerData in pairs(self.Data.entityOwners) do
        if not IsValid(ent) then
            -- Clean up invalid entity references
            self.Data.entityOwners[ent] = nil
            continue
        end
        
        -- Check if owner is disconnected
        local playerData = self.Data.disconnectedPlayers[ownerData.steamID]
        
        if playerData then
            -- Check if prop has been abandoned long enough
            if currentTime - playerData.disconnectTime > abandonTime then
                -- Remove abandoned prop
                ent:Remove()
                removedCount = removedCount + 1
            end
        else
            -- Check for inactive props from connected players
            if currentTime - ownerData.lastActive > abandonTime * 2 then
                -- Remove long inactive prop
                ent:Remove()
                removedCount = removedCount + 1
            end
        end
    end
    
    -- Notify about cleanup
    if removedCount > 0 then
        print("[GMod Optimizer] Cleaned up " .. removedCount .. " abandoned props")
    end
end

-- Apply entity throttling under high load
function GMOpt.Entity:ApplyThrottling()
    -- Skip if throttling is disabled
    if not GMOpt.ConVars.Server.EntityThrottling:GetBool() then
        -- Remove throttling from all entities
        for ent, _ in pairs(self.Data.throttledEntities) do
            if IsValid(ent) then
                ent:SetUpdateRate(0) -- Reset to default
            end
        end
        
        -- Clear throttled entities list
        self.Data.throttledEntities = {}
        return
    end
    
    -- Check server load
    local highLoadThreshold = GMOpt.ConVars.Server.HighLoadThreshold:GetFloat()
    local serverLoad = 0 -- We'll need to estimate this
    
    -- Calculate server load based on frame time
    local frameTime = engine.TickInterval()
    if frameTime > 0 then
        serverLoad = math.min(1.0, frameTime / (1 / 20)) -- Normalize to 0-1 range (20 FPS = high load)
    end
    
    -- Apply throttling if server load is high
    if serverLoad > highLoadThreshold then
        -- Get all entities
        local allEntities = ents.GetAll()
        
        for _, ent in ipairs(allEntities) do
            if IsValid(ent) and not ent:IsPlayer() and not ent:IsWeapon() and not ent:IsNPC() then
                -- Check if entity is important
                local isImportant = false
                
                -- Players, NPCs, and vehicles are important
                if ent:IsPlayer() or ent:IsNPC() or ent:IsVehicle() then
                    isImportant = true
                end
                
                -- Physics props being held or moved recently are important
                if ent:GetClass() == "prop_physics" then
                    if ent:IsPlayerHolding() or ent:GetVelocity():Length() > 10 then
                        isImportant = true
                    end
                end
                
                -- Apply throttling to non-important entities
                if not isImportant then
                    local updateRate = 0.1 -- 10 updates per second
                    
                    -- Distant entities get even less frequent updates
                    local nearestPlayer = nil
                    local nearestDist = math.huge
                    
                    for _, ply in ipairs(player.GetAll()) do
                        local dist = ply:GetPos():Distance(ent:GetPos())
                        if dist < nearestDist then
                            nearestDist = dist
                            nearestPlayer = ply
                        end
                    end
                    
                    if nearestDist > 1000 then
                        updateRate = 0.5 -- Only 2 updates per second for distant entities
                    end
                    
                    -- Apply throttling
                    ent:SetUpdateRate(updateRate)
                    
                    -- Track throttled entities
                    self.Data.throttledEntities[ent] = true
                else
                    -- Reset update rate for important entities
                    ent:SetUpdateRate(0) -- Default rate
                    
                    -- Remove from throttled entities list
                    self.Data.throttledEntities[ent] = nil
                end
            end
        end
    else
        -- Server load is acceptable, reduce throttling
        for ent, _ in pairs(self.Data.throttledEntities) do
            if IsValid(ent) then
                ent:SetUpdateRate(0) -- Reset to default
            end
        end
        
        -- Clear throttled entities list
        self.Data.throttledEntities = {}
    end
end

-- Main update function
function GMOpt.Entity:Update()
    -- Cleanup abandoned props
    self:CleanupAbandonedProps()
    
    -- Apply entity throttling
    self:ApplyThrottling()
end

-- Hook into entity creation
hook.Add("OnEntityCreated", "GMOpt_TrackEntity", function(ent)
    if not IsValid(ent) then return end
    
    -- Wait until entity is initialized
    timer.Simple(0.1, function()
        if not IsValid(ent) then return end
        
        -- Track props created by players
        if ent:GetClass() == "prop_physics" or ent:GetClass() == "prop_dynamic" then
            local owner = ent:GetOwner()
            
            if IsValid(owner) and owner:IsPlayer() then
                GMOpt.Entity:TrackEntityOwner(ent, owner)
            end
        end
    end)
end)

-- Track player disconnection
hook.Add("PlayerDisconnected", "GMOpt_PlayerDisconnect", function(ply)
    GMOpt.Entity:PlayerDisconnected(ply)
end)

-- Main entity management think hook
hook.Add("Think", "GMOpt_EntityManagement", function()
    GMOpt.Entity:Update()
end)

-- Console command to force cleanup
concommand.Add("gmopt_cleanup_props", function(ply)
    -- Only allow admins to force cleanup
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("You need to be an admin to use this command")
        return
    end
    
    -- Force cleanup
    GMOpt.Entity.Data.lastCleanup = 0
    GMOpt.Entity:CleanupAbandonedProps()
    
    -- Notify
    print("[GMod Optimizer] Forced prop cleanup")
end)