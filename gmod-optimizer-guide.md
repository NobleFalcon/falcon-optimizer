# GMod Optimizer User Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)
3. [For Players](#for-players)
   - [Quick Start](#quick-start)
   - [Performance Presets](#performance-presets)
   - [Customizing Settings](#customizing-settings)
4. [For Server Administrators](#for-server-administrators)
   - [Server Optimization](#server-optimization)
   - [Client Enforcement](#client-enforcement)
   - [Emergency Performance Mode](#emergency-performance-mode)
5. [Console Commands](#console-commands)
6. [Troubleshooting](#troubleshooting)
7. [Advanced Configuration](#advanced-configuration)

## Introduction

GMod Optimizer is a lightweight performance enhancement addon designed to improve your Garry's Mod experience through targeted optimizations. Unlike other performance addons that may cause compatibility issues, GMod Optimizer focuses on the most impactful optimizations while maintaining compatibility with most other addons.

**Key Features:**
- Entity culling to reduce rendering load
- Texture and material optimizations
- FPS limiting options
- Intelligent prop cleanup
- Network traffic optimization
- Customizable performance presets
- Server-side optimizations
- Admin performance monitoring tools

## Installation

1. Download the GMod Optimizer addon.
2. Extract the folder to your `steamapps\common\GarrysMod\garrysmod\addons` directory.
3. Ensure the folder structure looks like this:
   ```
   addons/
   └── gmod_optimizer/
       ├── lua/
       │   ├── autorun/
       │   │   └── gmod_optimizer_init.lua
       │   └── gmod_optimizer/
       │       ├── shared/
       │       ├── client/
       │       └── server/
       └── addon.txt
   ```
4. Start or restart Garry's Mod.
5. You should see "[GMod Optimizer] Initialization complete" message in the console when the game launches.

## For Players

### Quick Start

1. Open the console by pressing the tilde key (`~`).
2. Type `gmopt_menu` to open the optimizer menu.
3. Click on the "Presets" tab.
4. Select the preset that best matches your system:
   - **Ultra**: Maximum performance, lowest quality (for very low-end PCs)
   - **Low**: Good performance, low quality (for low-end PCs)
   - **Medium**: Balanced performance and quality (for average PCs)
   - **High**: High quality, good performance (for gaming PCs)
   - **Max**: Maximum quality, no optimizations (for high-end PCs)
5. Alternatively, click "Auto-Detect Best Preset" to let the addon choose for you.

### Performance Presets

Each preset configures multiple settings at once:

**Ultra Preset:**
- Short render distance (2000 units)
- Low quality textures
- Material simplification
- Particle effects limiting
- HUD animations disabled
- 60 FPS cap for stability

**Low Preset:**
- Medium render distance (3000 units)
- Low quality textures
- Material simplification
- 90 FPS cap

**Medium Preset:**
- Better render distance (4000 units)
- Normal quality textures
- Material simplification
- 120 FPS cap

**High Preset:**
- Long render distance (6000 units)
- Normal quality textures
- No material simplification
- Unlimited FPS

**Max Preset:**
- Maximum render distance (10000 units)
- All optimizations disabled
- Unlimited FPS

### Customizing Settings

For fine-tuning your experience, use the other tabs in the GMod Optimizer menu:

**Render Tab:**
- Adjust render distance (how far you can see objects)
- Toggle entity culling (hide distant objects)
- Enable/disable particle effect limiting
- Toggle Level of Detail system

**Materials Tab:**
- Toggle low quality textures
- Enable/disable material simplification (removes reflections, etc.)
- Adjust texture memory limit
- Force apply material settings or reset them

**UI Tab:**
- Set FPS limit (0 = unlimited, or choose 30, 60, 120, 144, 240)
- Toggle HUD animations
- Enable minimalist HUD (hides non-essential elements)
- Toggle performance counter display

## For Server Administrators

### Server Optimization

Server admins have additional commands and features to optimize server performance:

1. Open the console by pressing the tilde key (`~`).
2. Use server-specific commands:
   - `gmopt_cleanup_all` - Force cleanup all props on the server
   - `gmopt_emergency_mode` - Activate emergency performance mode
   - `gmopt_set_all_clients <preset>` - Force client settings for all players

### Client Enforcement

You can enforce optimization settings on all clients:

1. In console, type `gmopt_toggle_enforce_settings` to enable enforcement.
2. The server will automatically apply the recommended preset to all clients based on server performance.
3. Players will see a notification when settings are enforced.

### Emergency Performance Mode

When the server is experiencing severe lag:

1. Type `gmopt_emergency_mode` in console.
2. This will:
   - Apply extreme performance settings to the server
   - Force "Ultra" preset on all clients
   - Perform a map cleanup
   - Set very aggressive prop cleanup settings
   - Disable non-essential features

## Console Commands

**Client Commands:**
- `gmopt_menu` - Open the optimizer menu
- `gmopt_preset <ultra|low|medium|high|max>` - Apply a preset
- `gmopt_auto_preset` - Auto-detect and apply best preset
- `gmopt_optimize_materials` - Force material optimization
- `gmopt_restore_materials` - Restore original materials
- `gmopt_reset_visibility` - Reset entity visibility
- `gmopt_show_performance <0|1>` - Toggle performance counter

**Server Admin Commands:**
- `gmopt_cleanup_all` - Force cleanup all props
- `gmopt_emergency_mode` - Activate emergency performance mode
- `gmopt_set_all_clients <preset>` - Force client settings for all players
- `gmopt_toggle_enforce_settings` - Toggle client settings enforcement
- `gmopt_toggle_auto_adjust` - Toggle automatic settings adjustment
- `gmopt_toggle_bandwidth_optimization` - Toggle bandwidth optimization
- `gmopt_reset_all` - Reset all settings to defaults

## Troubleshooting

**Addon doesn't appear to be working:**
- Check console for error messages
- Ensure the addon is properly installed with the correct folder structure
- Try typing `gmopt_menu` in console to see if the interface appears

**Game crashes when applying settings:**
- Try using a more conservative preset (Medium instead of Low)
- Disable material optimization by typing `gmopt_material_simplification 0` in console
- Reset visibility with `gmopt_reset_visibility` 

**Low FPS despite optimization:**
- Use the "Ultra" preset for maximum performance
- Disable other resource-intensive addons
- Try disabling particle effects with `gmopt_particle_limit 1`
- Lower render distance with `gmopt_render_distance 2000`

**Visual glitches after applying settings:**
- Reset material settings with `gmopt_restore_materials`
- Try a different preset or disable material simplification
- Reset entity visibility with `gmopt_reset_visibility`

## Advanced Configuration

**Custom ConVar Settings:**

You can directly set any optimization setting using console variables:

```
gmopt_render_distance <1000-10000> - Set render distance
gmopt_entity_culling <0|1> - Toggle entity culling
gmopt_particle_limit <0|1> - Toggle particle limiting
gmopt_lod_system <0|1> - Toggle level of detail system
gmopt_low_quality_textures <0|1> - Toggle texture quality reduction
gmopt_material_simplification <0|1> - Toggle material simplification
gmopt_texture_memory_limit <128-2048> - Set texture memory limit in MB
gmopt_fps_limit <0-300> - Set FPS limit (0 = unlimited)
gmopt_disable_hud_animations <0|1> - Toggle HUD animations
gmopt_minimalist_hud <0|1> - Toggle minimalist HUD
```

**Server Configuration:**

Server administrators can fine-tune server-side optimizations:

```
gmopt_prop_cleanup_enabled <0|1> - Toggle automatic prop cleanup
gmopt_prop_cleanup_interval <60-3600> - Set seconds between cleanup checks
gmopt_prop_abandon_time <60-7200> - Set seconds until props are considered abandoned
gmopt_entity_throttling <0|1> - Toggle entity throttling under high load
gmopt_bandwidth_optimization <0|1> - Toggle bandwidth optimization
gmopt_message_batching <0|1> - Toggle network message batching
gmopt_nonessential_update_rate <0.1-5.0> - Set update interval for non-essential entities
gmopt_enforce_client_settings <0|1> - Toggle client settings enforcement
gmopt_monitor_addons <0|1> - Toggle resource-intensive addon monitoring
gmopt_auto_adjust_settings <0|1> - Toggle automatic settings adjustment
```

---

By following this guide, you should be able to significantly improve your Garry's Mod performance while maintaining good visual quality. The addon is designed to be flexible, allowing you to find the perfect balance between performance and quality for your specific system.
