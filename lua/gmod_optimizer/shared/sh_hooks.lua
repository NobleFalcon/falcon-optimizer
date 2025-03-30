-- GMod Optimizer
-- Hook optimization system

GMOpt.Hooks = GMOpt.Hooks or {}

-- Store original hook functions
GMOpt.Hooks.OriginalAdd = GMOpt.Hooks.OriginalAdd or hook.Add
GMOpt.Hooks.OriginalRemove = GMOpt.Hooks.OriginalRemove or hook.Remove

-- Hook priorities
GMOpt.Hooks.PRIORITY_HIGH = 1    -- Run first
GMOpt.Hooks.PRIORITY_NORMAL = 2  -- Run in normal order
GMOpt.Hooks.PRIORITY_LOW = 3     -- Run last

-- Store hooks with priorities
GMOpt.Hooks.RegisteredHooks = GMOpt.Hooks.RegisteredHooks or {}

-- Initialize hook tables for a given event if they don't exist
local function InitHookTables(eventName)
    GMOpt.Hooks.RegisteredHooks[eventName] = GMOpt.Hooks.RegisteredHooks[eventName] or {}
    GMOpt.Hooks.RegisteredHooks[eventName].high = GMOpt.Hooks.RegisteredHooks[eventName].high or {}
    GMOpt.Hooks.RegisteredHooks[eventName].normal = GMOpt.Hooks.RegisteredHooks[eventName].normal or {}
    GMOpt.Hooks.RegisteredHooks[eventName].low = GMOpt.Hooks.RegisteredHooks[eventName].low or {}
end

-- Custom hook.Add replacement with priorities
function GMOpt.Hooks:Add(eventName, identifier, func, priority)
    -- Default to normal priority
    priority = priority or self.PRIORITY_NORMAL
    
    -- Initialize tables if needed
    InitHookTables(eventName)
    
    -- Store hook in appropriate priority table
    local priorityName
    if priority == self.PRIORITY_HIGH then
        priorityName = "high"
    elseif priority == self.PRIORITY_LOW then
        priorityName = "low"
    else
        priorityName = "normal"
    end
    
    self.RegisteredHooks[eventName][priorityName][identifier] = func
    
    -- Create the master hook if it doesn't exist
    if not hook.GetTable()[eventName] or not hook.GetTable()[eventName]["GMOpt_MasterHook"] then
        self.OriginalAdd(eventName, "GMOpt_MasterHook", function(...)
            return self:RunHooks(eventName, ...)
        end)
    end
end

-- Custom hook.Remove replacement
function GMOpt.Hooks:Remove(eventName, identifier)
    if not self.RegisteredHooks[eventName] then return end
    
    -- Try to remove hook from all priority tables
    if self.RegisteredHooks[eventName].high[identifier] then
        self.RegisteredHooks[eventName].high[identifier] = nil
    end
    
    if self.RegisteredHooks[eventName].normal[identifier] then
        self.RegisteredHooks[eventName].normal[identifier] = nil
    end
    
    if self.RegisteredHooks[eventName].low[identifier] then
        self.RegisteredHooks[eventName].low[identifier] = nil
    end
    
    -- Check if all hooks are gone
    if table.IsEmpty(self.RegisteredHooks[eventName].high) and
       table.IsEmpty(self.RegisteredHooks[eventName].normal) and
       table.IsEmpty(self.RegisteredHooks[eventName].low) then
        -- Remove master hook if no hooks remain
        self.OriginalRemove(eventName, "GMOpt_MasterHook")
    end
end

-- Run hooks in priority order
function GMOpt.Hooks:RunHooks(eventName, ...)
    if not self.RegisteredHooks[eventName] then return end
    
    local args = {...}
    local result
    
    -- Run high priority hooks first
    for _, func in pairs(self.RegisteredHooks[eventName].high) do
        result = func(unpack(args))
        if result ~= nil then return result end
    end
    
    -- Then run normal priority hooks
    for _, func in pairs(self.RegisteredHooks[eventName].normal) do
        result = func(unpack(args))
        if result ~= nil then return result end
    end
    
    -- Finally run low priority hooks
    for _, func in pairs(self.RegisteredHooks[eventName].low) do
        result = func(unpack(args))
        if result ~= nil then return result end
    end
end

-- Only replace hooks if optimization is enabled
if GMOpt.Config.Server.EntityThrottling or GMOpt.Config.Client.EntityCulling then
    -- Replace standard hook functions with our optimized versions
    hook.Add = function(eventName, identifier, func)
        GMOpt.Hooks:Add(eventName, identifier, func)
    end
    
    hook.Remove = function(eventName, identifier)
        GMOpt.Hooks:Remove(eventName, identifier)
    end
end

-- Add console command to toggle hook optimization
concommand.Add("gmopt_toggle_hook_optimization", function(ply, cmd, args)
    if SERVER and IsValid(ply) and not ply:IsAdmin() then return end
    
    if hook.Add == GMOpt.Hooks.Add then
        -- Restore original hook functions
        hook.Add = GMOpt.Hooks.OriginalAdd
        hook.Remove = GMOpt.Hooks.OriginalRemove
        
        print("[GMod Optimizer] Hook optimization disabled")
    else
        -- Enable optimized hook functions
        hook.Add = function(eventName, identifier, func)
            GMOpt.Hooks:Add(eventName, identifier, func)
        end
        
        hook.Remove = function(eventName, identifier)
            GMOpt.Hooks:Remove(eventName, identifier)
        end
        
        print("[GMod Optimizer] Hook optimization enabled")
    end
end)