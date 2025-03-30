-- GMod Optimizer Initialization
-- This is the main entry point for the addon

-- Create the main table if it doesn't exist
GMOpt = GMOpt or {}
GMOpt.Version = "1.0"

-- Important: Set the proper directory name
local rootDir = "gmod_optimizer"

print("[GMod Optimizer] Initializing...")

-- Define files to include in loading order
local sharedFiles = {
    -- CRITICAL: Load these first - they define ConVars and Config
    "shared/sh_config.lua",
    "shared/sh_convars.lua",
    -- Then load these
    "shared/sh_utils.lua",
    "shared/sh_hooks.lua"
}

local clientFiles = {
    "client/cl_renderer.lua",
    "client/cl_materials.lua",
    "client/cl_ui.lua",
    "client/cl_presets.lua",
    "client/cl_menu.lua"
}

local serverFiles = {
    "server/sv_helper.lua",
    "server/sv_entity.lua",
    "server/sv_network.lua",
    "server/sv_resources.lua",
    "server/sv_admin.lua"
}

-- SERVER: Add files for client download
if SERVER then
    -- Add shared files
    for _, file in ipairs(sharedFiles) do
        AddCSLuaFile(rootDir .. "/" .. file)
        print("[GMod Optimizer] AddCSLuaFile: " .. rootDir .. "/" .. file)
    end
    
    -- Add client files
    for _, file in ipairs(clientFiles) do
        AddCSLuaFile(rootDir .. "/" .. file)
        print("[GMod Optimizer] AddCSLuaFile: " .. rootDir .. "/" .. file)
    end
end

-- BOTH CLIENT & SERVER: Load shared files FIRST
print("[GMod Optimizer] Loading shared files...")
for _, file in ipairs(sharedFiles) do
    include(rootDir .. "/" .. file)
    print("[GMod Optimizer] Included: " .. rootDir .. "/" .. file)
end

-- Then load realm-specific files
if SERVER then
    print("[GMod Optimizer] Loading server files...")
    for _, file in ipairs(serverFiles) do
        include(rootDir .. "/" .. file)
        print("[GMod Optimizer] Included: " .. rootDir .. "/" .. file)
    end
    print("[GMod Optimizer] Server initialization complete")
else -- CLIENT
    print("[GMod Optimizer] Loading client files...")
    for _, file in ipairs(clientFiles) do
        include(rootDir .. "/" .. file)
        print("[GMod Optimizer] Included: " .. rootDir .. "/" .. file)
    end
    print("[GMod Optimizer] Client initialization complete")
end