------------------------------------------------------------------------------------------------------------------------
------------------------------------------ PUPPETMASTER LIBRARY FILES --------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

require('queues')
res = require('resources')
texts = require('texts')
packets = require('packets')
include("WS-BuffHelpers.lua")

-------------------------------
--------Global Variables-------
-------------------------------

-- Auto Maneuver state is tracked as desired stack counts vs. actual buff counts.
-- Example: desiredManeuvers["Fire Maneuver"] = 2 means AutoMan will maintain 2 Fire Maneuvers.
local desiredManeuvers = {}
local pendingManeuvers = {}
local pendingManeuverTimes = {}
local maneuverProfileInitialized = false

-- A pending maneuver is only a failsafe marker. The normal reconciliation
-- loop already runs about once per second, so this should not delay recovery.
local pendingManeuverTimeout = 1
local pet_is_nuking = false
local skillchain_active = false

-- Populated by get_ws_buff_profile() in WS-BuffHelpers.lua
local ws_buff_level = get_ws_buff_level()

--Default States
Master_State = "Idle"
Pet_State = "Idle"
Hybrid_State = "Idle"

--Various timers
Flashbulb_Timer = 45
Strobe_Timer = 30
Strobe_Recast = 0
Flashbulb_Recast = 0
Flashbulb_Time = 0
Strobe_Time = 0

--Seeds the time used to calculate various functions per second
time_start = os.time()

--Constants in case we decide to change names down the road, will be much easier
const_dd = "DD"
const_tank = "TANK"
const_mage = "MAGE"
const_PetModeCycle = "PetModeCycle"
const_PetStyleCycle = "PetStyleCycle"
const_stateIdle = "Idle"
const_stateHybrid = "Pet+Master"
const_stateEngaged = "Engaged"
const_stateOverdrive = "Overdrive"
const_petOnly = "Pet Only"
const_masterOnly = "Master Only"
const_on = "\\cs(32, 255, 32)ON\\cr"
const_off = "\\cs(255, 32, 32)OFF\\cr"

--- SKILLCHAIN TABLE
SC = {}
SC["Valoredge Frame"] = {}
SC["Sharpshot Frame"] = {}
SC["Harlequin Frame"] = {}
SC["Stormwaker Frame"] = {}

SC["Valoredge Frame"]["Shijin Spiral"] = "Bone Crusher"
SC["Valoredge Frame"]["Ascetic's Fury "] = "Bone Crusher"
SC["Valoredge Frame"]["Final Heaven"] = "Bone Crusher"
SC["Valoredge Frame"]["Howling Fist"] = "String Shredder"
SC["Valoredge Frame"]["Final Heaven"] = "String Shredder"
SC["Valoredge Frame"]["Victory Smite"] = "String Shredder"
SC["Valoredge Frame"]["Stringing Pummel"] = "String Shredder"
SC["Valoredge Frame"]["Asuran Fists"] = "String Shredder"
SC["Valoredge Frame"]["Dragon Kick"] = "String Shredder"

SC["Sharpshot Frame"]["Stringing Pummel"] = "Armor Shatterer"
SC["Sharpshot Frame"]["Victory Smite"] = "Armor Shatterer"
SC["Sharpshot Frame"]["Shijin Spiral"] = "Armor Piercer"
SC["Sharpshot Frame"]["Asuran Fists"] = "Armor Shatterer"
SC["Sharpshot Frame"]["Howling Fist"] = "Arcuballista"
SC["Sharpshot Frame"]["Raging Fists"] = "Arcuballista"
SC["Sharpshot Frame"]["Tornado Kick"] = "Arcuballista"

SC["Sharpshot Frame"]["Dragon Kick"] = "Armor Shatterer"
SC["Sharpshot Frame"]["One Inch Punch"] = "Daze"
SC["Sharpshot Frame"]["Spinning Attack"] = "Armor Shatterer"
SC["Sharpshot Frame"]["Base"] = "Arcuballista"

SC["Harlequin Frame"]["Stringing Pummel"] = "Slapstick"
SC["Harlequin Frame"]["Victory Smite"] = "Magic Mortar"
SC["Harlequin Frame"]["Shijin Spiral"] = "Slapstick"
SC["Harlequin Frame"]["Howling Fist"] = "Knockout"

SC["Stormwaker Frame"]["Stringing Pummel"] = "Slapstick"
SC["Stormwaker Frame"]["Victory Smite"] = "Magic Mortar"
SC["Stormwaker Frame"]["Shijin Spiral"] = "Slapstick"
SC["Stormwaker Frame"]["Howling Fist"] = "Knockout"

------------------------------------
------------Text Window-------------
------------------------------------
--[[
    This gets passed in when the Keybinds is turned on.
    Each one matches to a given variable within the text object
]]
keybinds_on = {}
keybinds_on['key_bind_pet_mode'] = '(ALT+F7)'
keybinds_on['key_bind_pet_style'] = '(ALT+F8)'
keybinds_on['key_bind_idle'] = '(CTRL+F12)'
keybinds_on['key_bind_offense'] = '(F9)'
keybinds_on['key_bind_physical'] = '(CTRL+F10)'
keybinds_on['key_bind_hybrid'] = '(CTRL+F9)'
keybinds_on['key_bind_auto_maneuver'] = '(ALT+E)'
keybinds_on['key_bind_pet_dt'] = '(ALT+D)'
keybinds_on['key_bind_toggle_weaponskill_ftp'] = '(HOME)'
keybinds_on['key_bind_gearswap_clear'] = '(=)'
keybinds_on['key_bind_toggle_auto_deploy'] = '(PAGE UP)'
keybinds_on['key_bind_predict_automaton_setup'] = '(ALT+F6)'

--[[
    This gets passed in when the Keybinds are turned off.
    For not it simply sets the variable to an empty string
    (Researching better way to handle this)
]]
keybinds_off = {}
keybinds_off['key_bind_pet_mode'] = keybinds_on['key_bind_pet_mode']
keybinds_off['key_bind_pet_style'] = keybinds_on['key_bind_pet_style']
keybinds_off['key_bind_idle'] = keybinds_on['key_bind_idle']
keybinds_off['key_bind_offense'] = keybinds_on['key_bind_offense']
keybinds_off['key_bind_physical'] = keybinds_on['key_bind_physical']
keybinds_off['key_bind_hybrid'] = keybinds_on['key_bind_hybrid']
keybinds_off['key_bind_auto_maneuver'] = keybinds_on['key_bind_auto_maneuver']
keybinds_off['key_bind_pet_dt'] = keybinds_on['key_bind_pet_dt']
keybinds_off['key_bind_toggle_weaponskill_ftp'] = keybinds_on['key_bind_toggle_weaponskill_ftp']
keybinds_off['key_bind_gearswap_clear'] = keybinds_on['key_bind_gearswap_clear']
keybinds_off['key_bind_toggle_auto_deploy'] = keybinds_on['key_bind_toggle_auto_deploy']
keybinds_off['key_bind_predict_automaton_setup'] = keybinds_on['key_bind_predict_automaton_setup']

--[[
    These below are used to fill in the different sections on the HUB window
    It places varibles within the text object we can access instead of redrawing
    the entire text window everytime

    Variables are placed within a ${variableName|DefaultValue|Format}
    Format can be nil.
    
    _std stands for standard version
]]
    hub_pet_info_std = [[ \cs(255, 115, 0)======= Info ==========\cr
- \cs(125, 125, 0)WS Buff Eff. :\cr ${ws_buff_level}
]]

    hub_pet_skills_std = [[ \cs(255, 115, 0)======= Pet Skills ========\cr
- \cs(125, 125, 0)Maneuver Queue: \cr ${maneuver_queue|0}
- \cs(125, 125, 0)Current Queue: \cr ${current_queue|0}
${current_pet_skills|- No Skills To Track}
]]

    hub_state_std = [[ \cs(255, 115, 0)======= State ============\cr
-\cs(125, 125, 0) ${key_bind_pet_mode} Pet Mode :\cr ${pet_current_mode|TANK}
-\cs(125, 125, 0) ${key_bind_pet_style} Pet Style :\cr ${pet_current_style|NORMAL}
-\cs(125, 125, 0) Combined State :\cr ${player_pet_state|Idle}
]]

    hub_mode_std = [[ \cs(255, 115, 0)======= Mode ============\cr
-\cs(125, 125, 0) ${key_bind_idle} Idle Mode :\cr ${player_current_idle|Idle}
-\cs(125, 125, 0) ${key_bind_offense} Offense Mode :\cr ${player_current_offense|MasterPet}
-\cs(125, 125, 0) ${key_bind_physical} Physical Mode :\cr ${player_current_physical|PetDT}
-\cs(125, 125, 0) ${key_bind_hybrid} Hybrid Mode :\cr ${player_current_hybrid|Normal}
]]

    hub_options_std = [[ \cs(255, 115, 0)======= Options ==========\cr
-\cs(125, 125, 0) ${key_bind_auto_maneuver} Auto Maneuver :\cr ${toggle_auto_maneuver|OFF}
-\cs(125, 125, 0) ${key_bind_pet_dt} Lock Set :\cr ${toggle_lock_pet_dt_set|OFF}
-\cs(125, 125, 0) ${key_bind_toggle_weaponskill_ftp} Weaponskill FTP :\cr ${toggle_weaponskill_ftp|OFF}
-\cs(125, 125, 0) ${key_bind_toggle_auto_deploy} Auto Deploy :\cr ${toggle_auto_deploy|OFF}
-\cs(125, 125, 0) ${key_bind_predict_automaton_setup} Predict Automaton Setup}
-\cs(125, 125, 0) ${key_bind_gearswap_clear} GS Clear Gearswap}
]]

--[[
    This is the Lite version of the hub setup
    _lte stands for Lite version
]]
    hub_pet_info_lte = [[ 
\cs(255, 115, 0)= Pet Info: \cr- \cs(125, 125, 0)WS Buff Eff. :\cr ${ws_buff_level} 
]]

    hub_pet_skills_lte = ''

    hub_state_lte = [[ 
\cs(255, 115, 0)= State: \cr-\cs(125, 125, 0)${key_bind_pet_mode} Pet Mode :\cr ${pet_current_mode|TANK}-\cs(125, 125, 0)${key_bind_pet_style} Pet Style :\cr ${pet_current_style|NORMAL}-\cs(125, 125, 0) Combined State :\cr ${player_pet_state|Idle} 
]]

    hub_mode_lte = [[ 
\cs(255, 115, 0)= Mode: \cr-\cs(125, 125, 0)${key_bind_idle} Idle Mode :\cr ${player_current_idle|Idle}-\cs(125, 125, 0)${key_bind_offense} Offense Mode :\cr ${player_current_offense|MasterPet}-\cs(125, 125, 0)${key_bind_physical} Physical Mode :\cr ${player_current_physical|PetDT}-\cs(125, 125, 0)${key_bind_hybrid} Hybrid Mode :\cr ${player_current_hybrid|Normal} 
]]

    hub_options_lte = [[ 
\cs(255, 115, 0)= Options: \cr-\cs(125, 125, 0)${key_bind_auto_maneuver} AutoMan :\cr ${toggle_auto_maneuver|OFF}-\cs(125, 125, 0)${key_bind_pet_dt} \cs(125, 125, 0) AutoDep :\cr ${toggle_auto_deploy|OFF} 
]]

-- init style
hub_pet_info = hub_pet_info_std
hub_pet_skills = hub_pet_skills_std
hub_state = hub_state_std
hub_mode = hub_mode_std
hub_options = hub_options_std

--[[
    Used to validate that information in the HUB is up to date
]]
function validateTextInformation()

    -- Updates Pet Info and Pet Skills
    if pet.isvalid then
        updatePetSkills()
    end

    --State Information
    main_text_hub.pet_current_mode = state.PetModeCycle.current
    main_text_hub.pet_current_style = state.PetStyleCycle.current
    main_text_hub.player_pet_state = Hybrid_State

    --Mode Information
    main_text_hub.player_current_idle = state.IdleMode.current
    main_text_hub.player_current_offense = state.OffenseMode.current
    main_text_hub.player_current_physical = state.PhysicalDefenseMode.current
    main_text_hub.player_current_hybrid = state.HybridMode.current

    --Options Information
    if state.AutoMan.value then
        main_text_hub.toggle_auto_maneuver = const_on
    else
        main_text_hub.toggle_auto_maneuver = const_off
    end

    if state.LockPetDT.value then
        main_text_hub.toggle_lock_pet_dt_set = const_on
    else
        main_text_hub.toggle_lock_pet_dt_set = const_off
    end

    if state.LockWeapon.value then
        main_text_hub.toggle_lock_weapon = const_on
    else
        main_text_hub.toggle_lock_weapon = const_off
    end

    if state.SetFTP.value then
        main_text_hub.toggle_weaponskill_ftp = const_on
    else
        main_text_hub.toggle_weaponskill_ftp = const_off
    end

    if state.AutoDeploy.value then
        main_text_hub.toggle_auto_deploy = const_on
    else
        main_text_hub.toggle_auto_deploy = const_off
    end
        
    if state.Keybinds.value then
        texts.update(main_text_hub, keybinds_on)
    else 
        texts.update(main_text_hub, keybinds_off)
    end

    main_text_hub.maneuver_queue = get_missing_maneuver_count()
    main_text_hub.current_queue = get_active_maneuver_count()
	
	main_text_hub.ws_buff_level = ws_buff_level

end

--Default To Set Up the Text Window
function setupTextWindow(pos_x, pos_y)
    if main_text_hub ~= nil then
        return
    end
    
    local default_settings = T{}
    default_settings.pos = {}
    default_settings.pos.x = pos_x
    default_settings.pos.y = pos_y
    default_settings.bg = {}
    default_settings.bg.alpha = 200
    default_settings.bg.red = 40
    default_settings.bg.green = 40
    default_settings.bg.blue = 55
    default_settings.bg.visible = true
    default_settings.flags = {}
    default_settings.flags.right = false
    default_settings.flags.bottom = false
    default_settings.flags.bold = true
    default_settings.flags.draggable = true
    default_settings.flags.italic = false
    default_settings.padding = 10
    default_settings.text = {}
    default_settings.text.size = 8
    default_settings.text.font = 'Arial'
    default_settings.text.fonts = {}
    default_settings.text.alpha = 255
    default_settings.text.red = 147
    default_settings.text.green = 161
    default_settings.text.blue = 161
    default_settings.text.stroke = {}
    default_settings.text.stroke.width = 0
    default_settings.text.stroke.alpha = 255
    default_settings.text.stroke.red = 0
    default_settings.text.stroke.green = 0
    default_settings.text.stroke.blue = 0

    --Creates the initial Text Object will use to create the different sections in
    main_text_hub = texts.new('', default_settings)

    --Appends the different sections to the main_text_hub
    texts.append(main_text_hub, hub_pet_info)
    texts.append(main_text_hub, hub_pet_skills)
    texts.append(main_text_hub, hub_state)
    texts.append(main_text_hub, hub_mode)
    texts.append(main_text_hub, hub_options)

    --We then do a quick validation
    validateTextInformation()

    --Finally we show this to the user
    main_text_hub:show()
    hideTextSections()
end

--[[
    This toggle the Hub style
]]
function toggleHubStyle()
    texts.clear(main_text_hub)
    if state.useLightMode.value then
        hud_x_pos = 0     
        hud_y_pos = -3
        hud_font_size = 8
        hud_padding = 4
        hud_alpha = 0
        hud_strokewidth = 2
        hub_pet_info = hub_pet_info_lte
        hub_pet_skills = hub_pet_skills_lte
        hub_state = hub_state_lte
        hub_mode = hub_mode_lte
        hub_options = hub_options_lte
    else
        hud_x_pos = pos_x
        hud_y_pos = pos_y
        hud_font_size = 12
        hud_padding = 10
        hud_alpha = 200
        hud_strokewidth = 0
        hub_pet_info = hub_pet_info_std
        hub_pet_skills = hub_pet_skills_std
        hub_state = hub_state_std
        hub_mode = hub_mode_std
        hub_options = hub_options_std
    end
    texts.pos(main_text_hub, hud_x_pos, hud_y_pos)
    texts.size(main_text_hub, hud_font_size)
    texts.pad(main_text_hub, hud_padding)
    texts.bg_alpha(main_text_hub, hud_alpha)
    texts.stroke_width(main_text_hub, hud_strokewidth) 

    hideTextSections()
end

--[[
    This handles hiding the different sections
]]
function hideTextSections()

    --For now when hiding a section its easier to recreate the entire window
    texts.clear(main_text_hub)

    --Append the different sections need back into the HUB
    texts.append(main_text_hub, hub_pet_info)
    texts.append(main_text_hub, hub_pet_skills)
    
    --Below we check to make sure this is true by default these are false
    if not state.textHideState.value then
        texts.append(main_text_hub, hub_state)

    end
    
    if not state.textHideMode.value then
        texts.append(main_text_hub, hub_mode)

    end
    
    if not state.textHideOptions.value then
        texts.append(main_text_hub, hub_options)
    end
    
    if state.textHideHUB.value == true then
        texts.hide(main_text_hub)
    else 
        texts.show(main_text_hub)
    end

    validateTextInformation()

end

--This handles drawing the Pet Skills for the text box
function updatePetSkills()
    if not pet.isvalid then
        return 
    end

    --Researching a better way to do this section for now we are doing this old way with concating the different sections
    local pet_skills = ''

    -- Strobe recast
    if Strobe_Recast == 0 and (pet.attachments.strobe or pet.attachments["strobe II"]) then
        if buffactive["Fire Maneuver"] then
            pet_skills = pet_skills .. "\\cs(125, 125, 125)-\\cr \\cs(125,0,0)Strobe\\cr \n"
        else
            pet_skills = pet_skills .. "\\cs(125, 125, 125)- Strobe\\cr \n"
        end
    elseif pet.attachments.strobe or pet.attachments["strobe II"] then
        pet_skills = pet_skills .. "\\cs(125, 125, 125)- Strobe (" .. Strobe_Recast .. ")\\cr \n"
    end

    -- Flashbulb recast
    if Flashbulb_Recast == 0 and pet.attachments.flashbulb then
        if buffactive["Light Maneuver"] then
            pet_skills = pet_skills .. "\\cs(125, 125, 125)-\\cr \\cs(255,255,255)Flashbulb\\cr \n"
        else
            pet_skills = pet_skills .. "\\cs(125, 125, 125)- Flashbulb\\cr \n"
        end
    elseif pet.attachments.flashbulb ~= nil then
        pet_skills = pet_skills .. "\\cs(125, 125, 125)- Flashbulb (" .. Flashbulb_Recast .. ")\\cr \n"
    end

    if not pet.attachments.strobe and not pet.attachments["strobe II"] and not pet.attachments.flashbulb then
        pet_skills = pet_skills .. "\\cs(125, 125, 125)- No Skills To Track\\cr \n"
    end

    --Set the Pet Skills section within the HUB
    main_text_hub.current_pet_skills = pet_skills
end

--Prints to the screen in a certain format
function msg(str)
    send_command("@input /echo *-*-*-* " .. str .. " *-*-*-*")
end

------------------------------------
----------Utility Functions---------
------------------------------------

--Used to calculate the Combined State of you and your pet
function TotalSCalc()

    --Figures out state when Pet Mode is DD
    if state.PetModeCycle.current == const_dd then
        if buffactive["Overdrive"] then -- Overdrive Mode
            Hybrid_State = const_stateOverdrive
        elseif Master_State == const_stateIdle and Pet_State == const_stateIdle then --Idle
            Hybrid_State = const_stateIdle
        elseif Master_State == const_stateIdle and Pet_State == const_stateEngaged then --Pet Only
            Hybrid_State = const_petOnly
        elseif Master_State == const_stateEngaged and Pet_State == const_stateEngaged then --Pet+Master
            Hybrid_State = const_stateHybrid
        elseif Master_State == const_stateEngaged and Pet_State == const_stateIdle then -- Master Only
            Hybrid_State = const_masterOnly
        end
    --Figures out state when Pet Mode is TANK
    elseif state.PetModeCycle.current == const_tank then
        if Pet_State == const_stateIdle then -- Idle
            Hybrid_State = const_stateIdle
        elseif state.PetStyleCycle.value ~= "DD" and state.PetStyleCycle.value ~= "SPAM" then --TANK and auto sets to hybrid to DD since we are not using style DD or SPAM
            Hybrid_State = const_tank
            -- handle_set({"IdleMode", "Idle"})
            --handle_set({"HybridMode", "DT"})
        end
    --Figures out state when Pet Mode is MAGE
    elseif state.PetModeCycle.current == const_mage then
        if Master_State == const_stateIdle then --Idle
            Hybrid_State = const_stateIdle
        else
            Hybrid_State = const_masterOnly --Master Only Offense Mode
            handle_set({"OffenseMode", state.OffenseMode.current})
        end
    end

    --player_pet_state is the Combined State on the HUB
    main_text_hub.player_pet_state = Hybrid_State
end

--Attempts to determine the Puppet Mode and Style
function determinePuppetType()
    local head = pet.head
    local frame = pet.frame

    local ValHead = "Valoredge Head"
    local ValFrame = "Valoredge Frame"

    local HarHead = "Harlequin Head"
    local HarFrame = "Harlequin Frame"

    local SharpHead = "Sharpshot Head"
    local SharpFrame = "Sharpshot Frame"

    local StormHead = "Stormwaker Head"
    local StormFrame = "Stormwaker Frame"

    local SoulHead = "Soulsoother Head"
    local SpiritHead = "Spiritreaver Head"

    --This is based mostly off of the frames from String Theory
    --https://www.bg-wiki.com/bg/String_Theory#Automaton_Frame_Setups

    --Determine Head first, then further determine by body and attachments
    if head == HarHead then --Harlequin Predictions
        if frame == HarFrame and (pet.attachments.strobe == true or pet.attachments.flashbulb == true) then --Magic Tank
            handle_set({const_PetModeCycle, const_tank})
            handle_set({const_PetStyleCycle, "MAGIC"})
        elseif frame == HarFrame then -- Default
            handle_set({const_PetModeCycle, const_dd})
            handle_set({const_PetStyleCycle, "NORMAL"})
        else
            msg("Unable to determine Mode/Style for Puppet Head: (" .. head .. ") Puppet Frame: (" .. frame .. ")")
        end
    elseif head == ValHead then --Valoredge Predictions
        if frame == SharpFrame then
            if (pet.attachments.strobe == true or pet.attachments.flashbulb == true) then -- DD Tank
                handle_set({const_PetModeCycle, const_tank})
                handle_set({const_PetStyleCycle, const_dd})
            else -- Default
                handle_set({const_PetModeCycle, const_dd})
                handle_set({const_PetStyleCycle, "NORMAL"})
            end
        elseif frame == ValFrame then -- Default Standard Tank
            if 
                pet.attachments.inhibitor == true 
                or pet.attachments.attuner == true 
                and (not pet.attachments.strobe or not pet.attachments['strobe ii']) then -- Bone Slayer
                handle_set({const_PetModeCycle, const_dd})
                handle_set({const_PetStyleCycle, "BONE"})
            else -- Standard Tank
                handle_set({const_PetModeCycle, const_tank})
                handle_set({const_PetStyleCycle, "NORMAL"})
            end
        else
            msg("Unable to determine Mode/Style for Puppet Head: (" .. head .. ") Puppet Frame: (" .. frame .. ")")
        end
    elseif head == SharpHead then -- Sharpshooter Prediction
        if frame == SharpFrame then -- SPAM DD
            if (pet.attachments.inhibitor == true or pet.attachments["inhibitor II"] == true) then
                handle_set({const_PetModeCycle, const_dd})
                handle_set({const_PetStyleCycle, "NORMAL"})
            else
                handle_set({const_PetModeCycle, const_dd})
                handle_set({const_PetStyleCycle, "SPAM"})
            end
        else
            msg("Unable to determine Mode/Style for Puppet Head: (" .. head .. ") Puppet Frame: (" .. frame .. ")")
        end
    elseif head == StormHead then --Stormwaker Prediction
        if frame == StormFrame then -- RDM
            handle_set({const_PetModeCycle, const_mage})
            handle_set({const_PetStyleCycle, "SUPPORT"})
        else
            msg("Unable to determine Mode/Style for Puppet Head: (" .. head .. ") Puppet Frame: (" .. frame .. ")")
        end
    elseif head == SoulHead then -- Soulsoother Prediction
        if frame == StormFrame then -- WHM
            handle_set({const_PetModeCycle, const_mage})
            handle_set({const_PetStyleCycle, "HEAL"})
        elseif frame == ValFrame then -- Turtle Tank
            handle_set({const_PetModeCycle, const_tank})
            handle_set({const_PetStyleCycle, "NORMAL"})
        else
            msg("Unable to determine Mode/Style for Puppet Head: (" .. head .. ") Puppet Frame: (" .. frame .. ")")
        end
    elseif head == SpiritHead then -- Spiritweaver Prediction
        if frame == StormFrame then -- BLM
            handle_set({const_PetModeCycle, const_mage})
            handle_set({const_PetStyleCycle, "MB"})
        else
            msg("Unable to determine Mode/Style for Puppet Head: (" .. head .. ") Puppet Frame: (" .. frame .. ")")
        end
    end
end

function reset_timers()
    desiredManeuvers = {}
    pendingManeuvers = {}
    maneuverProfileInitialized = false
end

--Watching for Zone Changes to reset certain sections
windower.raw_register_event("zone change", reset_timers)

--Traverses a table to see if it contains the given element
function table.contains(table, element)
    for _, value in pairs(table) do
        if string.lower(value) == string.lower(element) then
            return true
        end
    end
    return false
end

--Takes a condition and returns a given value based on if it is true or false
function ternary(cond, T, F)
    if cond then
        return T
    else
        return F
    end
end

function should_swap_to_mb_gear()
	return pet_is_nuking and state.PetStyleCycleMage.value:lower() == 'mb' and skillchain_active
end

----------------------------------------------------
----------Windower Hooks/Custom Gearswap------------
----------------------------------------------------

--Used to determine what Hybrid Mode to use when Player Idle and Pet is Engaged
function user_customize_idle_set(idleSet)

    -- Never replace the Town idle set.
    if areas.Cities:contains(world.area) then
        return idleSet
    end

    if Master_State:lower() == const_stateIdle:lower()
        and Pet_State:lower() == const_stateEngaged:lower() then

        if state.HybridMode.current == "Normal" then
            return idleSet
        else
            idleSet = sets.engaged[state.OffenseMode.current][state.HybridMode.current]
            return idleSet
        end
    else
        return idleSet
    end
end

--Used to determine what Hybrid Mode to use when Player is engaged for trusts only and Pet is Engaged
function user_customize_melee_set(meleeSet)
    
	if should_swap_to_mb_gear() then
		return sets.midcast.PetMagicBurst
	end
	
    if (Master_State:lower() == const_stateEngaged:lower()) and Pet_State:lower() == const_stateEngaged:lower() then
        if state.HybridMode.current == "Normal" then --If Hybrid Mode is Normal then simply return the set
            --meleeSet = sets.idle.Pet.Engaged
			meleeSet = sets.engaged[state.OffenseMode.current][state.HybridMode.current]
            return meleeSet
        else
            --meleeSet = sets.idle.Pet.Engaged[state.HybridMode.current] --When Pet is engaged we pass in the Hybrid Mode to match to an existing set
			meleeSet = sets.engaged[state.OffenseMode.current][state.HybridMode.current]
            return meleeSet
        end
    else --Otherwise return the idleSet with no changes from us
        return meleeSet
    end
end

function job_pet_precast(spell, action, spellMap, eventArgs)
	if spell.type == "BlackMagic" or spell.type == 'Elemental Magic' then
		pet_is_nuking = true
		
		if should_swap_to_mb_gear() then
			equip(sets.midcast.PetMagicBurst)
		end
	end
end

function job_pet_midcast(spell, action, spellMap, eventArgs)
	
	if spell.type == "BlackMagic" or spell.type == 'Elemental Magic' then
		pet_is_nuking = true
		
		if should_swap_to_mb_gear() then
			equip(sets.midcast.PetMagicBurst)
		end
	end

	if state.PetStyleCycleMage.value:lower() ~= 'mb' then
		eventArgs.handled = true
	end
end

function job_precast(spell, action, spellMap, eventArgs)
    if spell.english == "Activate" or spell.english == "Deus Ex Automata" then
        TotalSCalc()
        determinePuppetType()
    elseif string.find(spell.english, "Maneuver") then
        equip(sets.precast.JA.Maneuver)
    elseif sets.precast.JA[spell.english] then
		equip(sets.precast.JA[spell.english])
    elseif sets.precast.WS[spell.english] then
        equip(sets.precast.WS[spell.english])
    end
end

function job_post_precast(spell, action, spellMap, eventArgs)
	apply_ws_buff_set(sets.precast.WS, spell)
end

--Puppet Weaponskill Modifiers
Modifier = {}

Modifier["String Shredder"] = "VIT"
Modifier["Bone Crusher"] = "VIT"
Modifier["Armor Shatterer"] = "DEX"
Modifier["Armor Piercer"] = "DEX"
Modifier["Arcuballista"] = "DEXFTP"
Modifier["Daze"] = "DEXFTP"
Modifier["Slapstick"] = "DEX"
Modifier["Knockout"] = "AGI"

function job_aftercast(spell, action, spellMap, eventArgs)

    -- If an AutoMan maneuver attempt was interrupted, release the pending marker.
    -- The reconciliation loop will retry it on a later tick.
    if string.find(spell.english, "Maneuver") and spell.interrupted == true then
        if (pendingManeuvers[spell.english] or 0) > 0 then
            pendingManeuvers[spell.english] = pendingManeuvers[spell.english] - 1
        end
    end
	
    if pet.isvalid and ((state.PetModeCycle.value ~= 'MAGE' and state.PetModeCycle.value ~= "TANK") and  state.PetStyleCycleDD.value ~= 'SPAM') then
        if SC[pet.frame][spell.english] and pet.tp >= 850 and Pet_State == "Engaged" then
            ws = SC[pet.frame][spell.english]
            modif = Modifier[ws]

            --If its a valid modif
            if modif then
                equip(sets.midcast.Pet.WS[modif])
            else --Otherwise equip the default Weapon Skill Set
                equip(sets.midcast.Pet.WSNoFTP)
            end

            eventArgs.handled = true
        else
			handle_equipping_gear(player.status, Pet_State)
			--equip(sets.engaged[state.OffenseMode.current][state.HybridMode.current])
        end
    else
		if should_swap_to_mb_gear() then
			equip(sets.midcast.PetMagicBurst)
		else
			handle_equipping_gear(player.status, Pet_State)
		end
    end
	
	if spell.english == "Deploy" then
		swap_pet_ws_gear()
	end
end

--This watches for when the Player changes to idle/engaged/resting
function job_status_change(new, old)
    if new == "Engaged" then
        Master_State = const_stateEngaged
        TotalSCalc()
    else
        Master_State = const_stateIdle
        
        if state.CP.value == true then --Fail safe to make sure back is enabled after a fight is over
            enable("back") 
        end 

        TotalSCalc()
    end

	if pet_is_nuking == false then
		swap_pet_ws_gear()
	end
    --handle_equipping_gear(player.status, Pet_State)
	--equip(sets.engaged[state.OffenseMode.current][state.HybridMode.current])
end

function job_pet_status_change(new, old, eventArgs)
    if new == "Engaged" then
        Pet_State = const_stateEngaged
        TotalSCalc()
		
		swap_pet_ws_gear()
    else
        Pet_State = const_stateIdle
        TotalSCalc()
    end
end

--Pet Weapon Skills we are checking against in job_pet_aftercast
AutomatonWeaponSkills =
    T {
    "Slapstick",
    "Knockout",
    "Magic Mortar",
    "Chimera Ripper",
    "String Clipper",
    "Cannibal Blade",
    "Bone Crusher",
    "String Shredder",
    "Arcuballista",
    "Daze",
    "Armor Piercer",
    "Armor Shatterer"
}

function job_pet_aftercast(spell)

    --If pet just finished a weapon skill we want to temporarily block it from going back into weapon skill gear
    if table.contains(AutomatonWeaponSkills, spell.name) then
        justFinishedWeaponSkill = true
    end
	
	if spell.type == "BlackMagic" or spell.type == 'Elemental Magic' then
		pet_is_nuking = false
	end

    handle_equipping_gear(player.status, pet.status)
	--equip(sets.engaged[state.OffenseMode.current][state.HybridMode.current])
end

-- Auto Maneuver reconciliation
--
-- GearSwap's buffactive stores repeated buffs as a count (e.g. two Marches == 2).
-- We use the same model for Maneuvers so Fire x2 is different from Fire x1.
local maneuverNames = {
    "Fire Maneuver",
    "Ice Maneuver",
    "Wind Maneuver",
    "Earth Maneuver",
    "Thunder Maneuver",
    "Water Maneuver",
    "Light Maneuver",
    "Dark Maneuver"
}

function get_active_maneuver_stack(name)
    local count = buffactive[name]

    if count == nil then
        count = buffactive[name:lower()]
    end

    if count == true then
        return 1
    end

    return tonumber(count) or 0
end

function get_active_maneuver_count()
    local total = 0

    for _, maneuver in ipairs(maneuverNames) do
        total = total + get_active_maneuver_stack(maneuver)
    end

    return total
end

function get_missing_maneuver_count()
    local missing = 0

    for maneuver, desiredCount in pairs(desiredManeuvers) do
        local actualCount = get_active_maneuver_stack(maneuver)
        local difference = desiredCount - actualCount

        if difference > 0 then
            missing = missing + difference
        end
    end

    return missing
end

function initialize_maneuver_profile()
    desiredManeuvers = {}
    pendingManeuvers = {}
    pendingManeuverTimes = {}

    for _, maneuver in ipairs(maneuverNames) do
        local count = get_active_maneuver_stack(maneuver)
        if count > 0 then
            desiredManeuvers[maneuver] = count
        end
    end

    maneuverProfileInitialized = true
end

function maneuver_recast_ready(maneuver)
    for id, ability in pairs(res.job_abilities) do
        if ability.en == maneuver then
            local recasts = windower.ffxi.get_ability_recasts()
            return (recasts[ability.recast_id] or 0) <= 0
        end
    end

    -- If the resource entry cannot be found, let the game process the command.
    return true
end

function find_missing_maneuver()
    -- Do not exceed PUP's three active maneuver slots.
    if get_active_maneuver_count() >= 3 then
        return nil
    end

    -- Walk in a deterministic order rather than pairs(), so the behavior is stable.
    for _, maneuver in ipairs(maneuverNames) do
        local desiredCount = desiredManeuvers[maneuver] or 0
        local actualCount = get_active_maneuver_stack(maneuver)
        local pendingCount = pendingManeuvers[maneuver] or 0

        -- Account for a cast already in flight, so we don't issue duplicate casts.
        if actualCount + pendingCount < desiredCount then
            return maneuver
        end
    end

    return nil
end

function reconcile_maneuvers()
    if not state.AutoMan.value
        or not maneuverProfileInitialized
        or player.hp <= 0
        or not pet.isvalid
        or areas.Cities:contains(world.area)
    then
        return
    end

    -- Clear stale pending markers. This is only a failsafe; the normal
    -- reconciliation loop still runs about once per second.
    local now = os.time()
    for maneuver, started in pairs(pendingManeuverTimes) do
        if now - started >= pendingManeuverTimeout then
            pendingManeuvers[maneuver] = nil
            pendingManeuverTimes[maneuver] = nil
        end
    end

    if midaction() then
        return
    end
	
	local activeManeuverCount = get_active_maneuver_count()

	if activeManeuverCount >= 3 then
		-- Three active maneuvers is the hard cap. If the desired profile
		-- is somehow out of sync, accept the current three as the profile
		-- instead of leaving a permanent phantom maneuver in the HUD queue.
		if get_missing_maneuver_count() > 0 then
			initialize_maneuver_profile()
		else
			pendingManeuvers = {}
		end
		return
	end
	
    local maneuver = find_missing_maneuver()
    if not maneuver then
        return
    end

    if not maneuver_recast_ready(maneuver) then
        return
    end

    pendingManeuvers[maneuver] = (pendingManeuvers[maneuver] or 0) + 1
    pendingManeuverTimes[maneuver] = os.time()
    send_command('input /ja "' .. maneuver .. '" <me>')
end

function job_buff_change(status, gain, eventArgs)
    
    if status == "sleep" and gain then
        equip(set_combine(sets.defense.PDT, {neck = "Opo-opo Necklace"}))
        eventArgs.handled = true
    elseif status == "doom" and gain then
        send_command("input /p I have befallen to ~~~DOOM~~~ may my end not come to quickly.")
    elseif status == "doom" and gain == false then
        send_command("input /p I have avoided the grips of ~~~DOOM~~~ may Altana be praised! ")
    end

    if not status:contains("Maneuver") then
        return
    end

    if gain then
        -- A gain caused by our own reconciliation satisfies one pending cast.
        if (pendingManeuvers[status] or 0) > 0 then
            pendingManeuvers[status] = pendingManeuvers[status] - 1
            if pendingManeuvers[status] <= 0 then
                pendingManeuvers[status] = nil
                pendingManeuverTimes[status] = nil
            end
        elseif state.AutoMan.value and maneuverProfileInitialized then
            -- A manually applied maneuver changes the desired profile to the new
            -- actual stack count. This lets AutoMan continue maintaining it.
            desiredManeuvers[status] = get_active_maneuver_stack(status)
        end
    else
        -- A maneuver disappearing means it is genuinely missing now.
        -- Drop any old pending marker so the existing ~1s reconciliation
        -- loop can immediately make it eligible for reapplication.
        pendingManeuvers[status] = nil
        pendingManeuverTimes[status] = nil

    end
end

-- Toggles -- SE Macros: /console gs c "command"
function job_self_command(command, eventArgs)
	
	if command[1] == 'skillchain_on' then
        skillchain_active = true
    elseif command[1] == 'skillchain_off' then
        skillchain_active = false
    end
	
    if command[1]:lower() == "automan" then --Toggles AutoMan
        state.AutoMan:toggle()

        if state.AutoMan.value then
            -- Capture the current maneuver stacks as the profile to maintain.
            initialize_maneuver_profile()
        else
            desiredManeuvers = {}
            pendingManeuvers = {}
            maneuverProfileInitialized = false
        end

        validateTextInformation()

    elseif command[1]:lower() == "predict" then --Predict Command
        determinePuppetType()

    elseif command[1]:lower() == "hub" or command[1]:lower() == "hide" then --First variable is hide lets find out what
        if command[2]:lower() == "mode" then --Hides the Mode
            state.textHideMode:toggle()
            hideTextSections()

        elseif command[2]:lower() == "state" then --Hides/Shows the State
            state.textHideState:toggle()
            hideTextSections()

        elseif command[2]:lower() == "all" then -- Hides/Shows the HUB
            state.textHideHUB:toggle()

            if state.textHideHUB.value == true then
                texts.hide(main_text_hub)
            else 
                texts.show(main_text_hub)
            end

            hideTextSections()
        elseif command[2]:lower() == "keybinds" then --Hides/Show Keybinds
            state.Keybinds:toggle()

            if state.Keybinds.value then
                texts.update(main_text_hub, keybinds_on) --If ON then we pass in Table for keybinds to update the variables
            else 
                texts.update(main_text_hub, keybinds_off) --Otherwise we set them to blank
            end

            hideTextSections()
        elseif command[2]:lower() == "options" then --Hides/Show Options
            state.textHideOptions:toggle()
            hideTextSections()
        elseif command[2]:lower() == "lite" then --Hides/Show Options
            state.useLightMode:toggle()         
            toggleHubStyle()      
        end     
    elseif command[1]:lower() == "setftp" then --Set the FTP toggle
        state.SetFTP:toggle()
        validateTextInformation()
    elseif command[1]:lower() == "customgearlock" then --Set the customgearlock
        state.CustomGearLock:toggle()
        validateTextInformation()
    elseif command[1]:lower() == "clear" then
		pet_is_nuking = false
        desiredManeuvers = {}
        pendingManeuvers = {}
        maneuverProfileInitialized = false
		handle_equipping_gear(player.status, pet.status)
		msg('Maneuvers have been reset')
	elseif command[1] == 'setWSFTP' then
		equip(sets.midcast.Pet.WSFTP)
	elseif command[1] == 'setWSNONFTP' then
		equip(sets.midcast.Pet.WSNoFTP)
	elseif command[1] == 'setBoneWS' then
		equip(sets.DD.BONE)
	elseif command[1] == 'resetGear' then
		handle_equipping_gear(player.status, pet.status)
    end
end

--Defaults
DefaultPetWeaponSkillLockOutTimer = 8 -- This will be the time that is changeable by the player
justFinishedWeaponSkill = false
petWeaponSkillLock = false
startedPetWeaponSkillTimer = false
petWeaponSkillRecast = 0
petWeaponSkillTime = 0

windower.register_event(
    "prerender",
    function()

        --Items we want to check every second
        if os.time() > time_start then
			
            time_start = os.time()
			
			ws_buff_level = get_ws_buff_level()

            -- Reconcile the desired maneuver stack counts against the actual
            -- buff counts. This repairs missing/expired maneuvers without relying
            -- on a queue surviving perfectly for hours.
            reconcile_maneuvers()

            if state.AutoMan.value and not maneuverProfileInitialized then
                initialize_maneuver_profile()
            end

            if pet.isvalid and player.hpp > 0 then
                --Double check current Pet Status and Player Status
                --In some cases Mote's doesn't recognize a pet's status change
                Pet_State = pet.status
                Master_State = player.status

                --If we are in auto deploy and engaged we are going check if we have changed targets
                if Master_State == const_stateEngaged and state.AutoDeploy.value == true and pet.status ~= const_stateEngaged then
                    send_command('input /pet "Deploy" <t>')
                else
                    autoDeployPending = false
                end
            end
            
            if state.PetModeCycle.value == const_tank and Pet_State == const_stateEngaged and state.PetModeCycle.value:lower() == "tank" then
                if buffactive["Fire Maneuver"] and (pet.attachments.strobe or pet.attachments["strobe II"]) then
                    if Strobe_Recast <= 2 then
                        equip(sets.pet.Enmity)
                    end
                end

                if buffactive["Light Maneuver"] and pet.attachments.flashbulb == true then
                    if Flashbulb_Recast <= 2 then
                        equip(sets.pet.Enmity)
                    end
                end
            end

            if Strobe_Recast > 0 then
                Strobe_Recast = Strobe_Timer - (os.time() - Strobe_Time)
            end

            if Flashbulb_Recast > 0 then
                Flashbulb_Recast = Flashbulb_Timer - (os.time() - Flashbulb_Time)
            end

            updatePetSkills()
            validateTextInformation()
            
        end
    end
)

function swap_pet_ws_gear()

	if pet_is_nuking then
		return
	end
	
	if pet.status == 'Engaged' and pet.tp >= 1000 and (pet.isvalid and player.hpp > 0) then	
		if
	        pet.isvalid and state.PetModeCycle.value:lower() ~= "mage" and state.PetModeCycle.value:lower() ~= "tank" and
	            (state.PetStyleCycle.value:lower() ~= "spam" 
	             or state.PetStyleCycle.value:lower() == "dd" 
	             or state.PetModeCycle.value:lower() == "dd" 
	             or state.PetStyleCycle.value:lower() == "bone")
	            and (Master_State:lower() == "idle" or state.PetStyleCycle.value:lower() == "od")
	 	then
			if (Master_State:lower() == "idle" or state.PetStyleCycle.value:lower() == "od") then
				if pet.frame == "Valoredge Frame" and not state.SetFTP.value then
					send_command('gs c setBoneWS')
				else
					if state.SetFTP.value then
	                    send_command('gs c setWSFTP')
	                else
	                    send_command('gs c setWSNONFTP')
	                end
				end
			end					
		end
		
	else
		--We have passed the allowed time without the puppet using a weapon skill, locking till next round
	    petWeaponSkillRecast = 0
	    petWeaponSkillLock = true
	    send_command('gs c resetGear')
	end
end

windower.register_event(
    "incoming text",
    function(original, modified, mode)

        -- Checking timer for enmity sets
        if buffactive["Fire Maneuver"] then
            if original:contains(pet.name) and original:contains("Provoke") then
				Strobe_Time = os.time()
                Strobe_Recast = Strobe_Timer
				
                add_to_chat(204, "*-*-*-*-*-*-*-*-* [ Strobe done ] *-*-*-*-*-*-*-*-*")
                handle_equipping_gear(player.status, pet.status)
				--equip(sets.engaged[state.OffenseMode.current][state.HybridMode.current])
            end
        end

        if buffactive["Light Maneuver"] then
            if original:contains(pet.name) and original:contains("Flashbulb") then
				Flashbulb_Time = os.time()
                Flashbulb_Recast = Flashbulb_Timer
				
                add_to_chat(204, "*-*-*-*-*-*-*-*-* [ Flashbulb done ] *-*-*-*-*-*-*-*-*")
                handle_equipping_gear(player.status, pet.status)
				--equip(sets.engaged[state.OffenseMode.current][state.HybridMode.current])
            end
        end

        return modified, mode
    end
)

--Passes state changes for cycle commands
--handle_update is always called when a job state is changed
--Best to adjust gear in job_handle_update which is an override for the job file
function job_state_change(stateField, newValue, oldValue)
	    --[[
        stateField is the Mode that could be passed in that is changing
        This could include PhysicalDefenseMode, OffenseMode, PetModeCycle -- etc
        If you provide a description then that is what will be passed in
        
        For example:
        state.AutoDeploy = M(false, "Auto Deploy")

        The second portion is a description so that is what the stateField would equal if this passed in

        Then we are given the newValue what it is changing to
        Then we are given the oldValue what it is changing from
    ]]

    if stateField == const_PetModeCycle then --Handles PetModeCycle Changes
        --Depending on the Pet Mode we are changing too these each have their own style to use
        if newValue == const_tank then --Sets PetStyleCycle to Tank if we are going to Tank Mode
            state.PetStyleCycle = state.PetStyleCycleTank
        elseif newValue == const_dd then --Sets PetStyleCycle to DD if we are going to DD Mode
            state.PetStyleCycle = state.PetStyleCycleDD
        elseif newValue == const_mage then --Sets PetStyleCycle to Mage if we are going to MAGE Mode
            state.PetStyleCycle = state.PetStyleCycleMage
        else
            --In the off chance we can't find this the new style added this is displayed
            msg("No Style found for: " .. newValue) 
        end

        --Update the Mode/Style to show properly on HUB
        main_text_hub.pet_current_mode = state.PetModeCycle.current
        main_text_hub.pet_current_style = state.PetModeCycle.current

        --Update gear
        handle_equipping_gear(player.status, Pet_State)
		--equip(sets.engaged[state.OffenseMode.current][state.HybridMode.current])
    elseif stateField == const_PetStyleCycle then
        main_text_hub.pet_current_style = newValue
    elseif stateField == "Auto Maneuver" then --Updates HUB for Auto Maneuver
        if newValue == true then
            main_text_hub.toggle_auto_maneuver = const_on
        else
            main_text_hub.toggle_auto_maneuver = const_off
        end
        
    elseif stateField == "Lock Pet DT" then
        --This command overrides everything and blocks all gear changes
        --Will lock until turned off or Pet is disengaged
        if newValue == true then
            equip(sets.pet.EmergencyDT)
            disable(
                "main",
                "sub",
                "range",
                "ammo",
                "head",
                "neck",
                "lear",
                "rear",
                "body",
                "hands",
                "lring",
                "rring",
                "back",
                "waist",
                "legs",
                "feet"
            )

            main_text_hub.toggle_lock_pet_dt_set = const_on
        else
            enable(
                "main",
                "sub",
                "range",
                "ammo",
                "head",
                "neck",
                "lear",
                "rear",
                "body",
                "hands",
                "lring",
                "rring",
                "back",
                "waist",
                "legs",
                "feet"
            )

            main_text_hub.toggle_lock_pet_dt_set = const_off
        end

    elseif stateField == "Lock Weapon" then --Updates HUB and disables/enables window for Lock Weapon
        if newValue == true then
            disable("main")
            main_text_hub.toggle_lock_weapon = const_on
        else
            enable("main")
            main_text_hub.toggle_lock_weapon = const_off
        end
    elseif stateField == "Custom Gear Lock" then --Updates HUB and disables/enables gear from custom lock
        if newValue == true then
            main_text_hub.toggle_custom_gear_lock = const_on
            disable(customGearLock)
        else
            main_text_hub.toggle_custom_gear_lock = const_off
            enable(customGearLock)
            handle_equipping_gear(player.status, Pet_State)
        end
    elseif stateField == 'Auto Deploy' then --Updates HUB for Auto Deploy
        if newValue == true then
            main_text_hub.toggle_auto_deploy = const_on
        else
            main_text_hub.toggle_auto_deploy = const_off
        end
    elseif stateField == 'Hide HUB' then --Hides or Shows the entire HUB Window
        if newValue == true then
            texts.hide(main_text_hub)
        else 
            texts.show(main_text_hub)
        end
    elseif stateField == 'Hide Mode' then --Handles hide/show Mode Section
        hideTextSections()
    elseif stateField == 'Hide State' then --Handles hide/show State Section
        hideTextSections()
    elseif stateField == 'Hide Options' then --Handles hide/show Options Section
        hideTextSections()
    elseif stateField == 'Hide Keybinds' then --Handles hide/show Keybinds
        if newValue == true then
            texts.update(main_text_hub, keybinds_on)
        else 
            texts.update(main_text_hub, keybinds_off)
        end
    elseif stateField == 'Offense Mode' then --Updates HUB for Offense Mode
        main_text_hub.player_current_offense = newValue
    elseif stateField == 'Physical Defense Mode' then -- Updates HUB for Physical Defense Mode
        main_text_hub.player_current_physical = newValue
    elseif stateField == 'Hybrid Mode' then --Updates HUB for Hybrid Mode
        main_text_hub.player_current_hybrid = newValue
    elseif stateField == 'Idle Mode' then -- Updates HUB for Idle Mode
        main_text_hub.player_current_idle = newValue
    end
end

-- Set eventArgs.handled to true if we don't want the automatic display to be run.
--This will display gear and run when F12 is pressed
function display_current_job_state(eventArgs)
    local msg = ""

    if state.PetModeCycle.value ~= "None" then
        msg = msg .. "Pet Mode: (" .. state.PetModeCycle.value .. ")"
    end

    if state.PetStyleCycle.value ~= "None" then
        msg = msg .. ", Pet Style: (" .. state.PetStyleCycle.value .. ")"
    end

    TotalSCalc()
    handle_equipping_gear(player.status, Pet_State)

    add_to_chat(122, msg)
end

function sub_job_change(new, old)
    determinePuppetType()
end
