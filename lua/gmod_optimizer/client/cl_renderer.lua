-- GMod Optimizer
-- Client-side renderer optimization

GMOpt.Renderer = GMOpt.Renderer or {}

-- Store culled entities
GMOpt.Renderer.CulledEntities = {}

-- Store entity visibility states
GMOpt.Renderer.EntityVisibility = {}

-- Check and update entity visibility
function GMOpt.Renderer:UpdateEntityVisibility()
    -- Skip if entity culling is disabled
    if not GMOpt.ConVars.Client.EntityCulling:GetBool() then
        -- Make all previously culled entities visible
        for ent, _ in pairs(self.CulledEntities) do
            if IsValid(ent) and ent:GetNoDraw() then
                ent:SetNoDraw(false)
            end
        end
        
        -- Clear culled entities list
        self.CulledEntities = {}
        return
    end
    
    -- Get all entities
    local allEntities = ents.GetAll()
    local renderDistance = GMOpt.ConVars.Client.RenderDistance:GetInt()
    local playerPos = LocalPlayer():GetPos()
    
    -- Update visibility for each entity
    for _, ent in ipairs(allEntities) do
        if IsValid(ent) and not ent:IsPlayer() then
            local entPos = ent:GetPos()
            local distance = playerPos:Distance(entPos)
            
            -- Should this entity be visible?
            local shouldBeVisible = distance <= renderDistance
            
            -- Apply LOD if enabled
            if shouldBeVisible and GMOpt.ConVars.Client.LODSystem:GetBool() then
                GMOpt.Utils:ApplyLOD(ent)
            end
            
            -- Update entity visibility if changed
            if ent:GetNoDraw() ~= (not shouldBeVisible) then
                ent:SetNoDraw(not shouldBeVisible)
                
                -- Track culled entities
                if not shouldBeVisible then
                    self.CulledEntities[ent] = true
                else
                    self.CulledEntities[ent] = nil
                end
            end
        end
    end
end

-- Particle effect limiter
local nextParticleCheck = 0
local particleCount = 0
local maxParticles = 100

function GMOpt.Renderer:LimitParticleEffects()
    -- Skip if particle limiting is disabled
    if not GMOpt.ConVars.Client.ParticleLimit:GetBool() then
        return true
    end
    
    -- Count active particles and limit them
    local currentTime = CurTime()
    
    if currentTime > nextParticleCheck then
        particleCount = 0
        nextParticleCheck = currentTime + 1 -- Check once per second
    end
    
    particleCount = particleCount + 1
    
    -- Return false to block particle creation if over limit
    return particleCount <= maxParticles
end

-- Hook into ParticleEffectStart to limit particles
hook.Add("PostDrawTranslucentRenderables", "GMOpt_ParticleLimit", function()
    if GMOpt.ConVars.Client.ParticleLimit:GetBool() then
        -- Reset particle count periodically
        local currentTime = CurTime()
        if currentTime > nextParticleCheck then
            particleCount = 0
            nextParticleCheck = currentTime + 1
        end
    end
end)

-- Override particle creation function if particle limiting is enabled
local originalParticleEffect = ParticleEffect
function ParticleEffect(name, pos, ang, parent)
    if GMOpt.ConVars.Client.ParticleLimit:GetBool() then
        -- Check if we should allow this particle
        if not GMOpt.Renderer:LimitParticleEffects() then
            return -- Block particle creation
        end
    end
    
    -- Call original function if allowed
    return originalParticleEffect(name, pos, ang, parent)
end

-- Main update function for renderer optimizations
function GMOpt.Renderer:Update()
    -- Update entity visibility
    self:UpdateEntityVisibility()
end

-- Register main think hook for renderer updates
hook.Add("Think", "GMOpt_RendererUpdate", function()
    GMOpt.Renderer:Update()
end)

-- Restore entity visibility when module is unloaded
concommand.Add("gmopt_reset_visibility", function()
    for ent, _ in pairs(GMOpt.Renderer.CulledEntities) do
        if IsValid(ent) then
            ent:SetNoDraw(false)
        end
    end
    
    GMOpt.Renderer.CulledEntities = {}
    print("[GMod Optimizer] Entity visibility reset")
end)