----------------------------------------------------------------------------------------
--  __  __           _                     __   _____                        _
-- |  \/  |         | |                   / _| |  __ \                      | |
-- | \  / | __ _ ___| |_ ___ _ __    ___ | |_  | |__) |   _ _ __  _ __   ___| |_ ___
-- | |\/| |/ _` / __| __/ _ \ '__|  / _ \|  _| |  ___/ | | | '_ \| '_ \ / _ \ __/ __|
-- | |  | | (_| \__ \ ||  __/ |    | (_) | |   | |   | |_| | |_) | |_) |  __/ |_\__ \
-- |_|  |_|\__,_|___/\__\___|_|     \___/|_|   |_|    \__,_| .__/| .__/ \___|\__|___/
--                                                         | |   | |
--                                                         |_|   |_|
-----------------------------------------------------------------------------------------
--[[

    Originally Created By: Faloun
    Programmers: Arrchie, Kuroganashi, Byrne, Tuna
    Testers:Arrchie, Kuroganashi, Haxetc, Patb, Whirlin, Petsmart
    Contributors: Xilkk, Byrne, Blackhalo714

    ASCII Art Generator: http://www.network-science.de/ascii/
    
]]

-- Initialization function for this job file.
-- IMPORTANT: Make sure to also get the Mote-Include.lua file (and its supplementary files) to go with this.
function get_sets()
    mote_include_version = 2

    -- Load and initialize the include file.
    include("Mote-Include.lua")
end

function user_setup()
    -- Alt-F10 - Toggles Kiting Mode.

    --[[
        F9 - Cycle Offense Mode (the offensive half of all 'hybrid' melee modes).
        
        These are for when you are fighting with or without Pet
        When you are IDLE and Pet is ENGAGED that is handled by the Idle Sets
    ]]
    state.OffenseMode:options("Malignance", "Mpaca", "PetEnmity", "Rao", "PetTP", "PetDA")

    --[[
        Ctrl-F9 - Cycle Hybrid Mode (the defensive half of all 'hybrid' melee modes).
        
        Used when you are Engaged with Pet
        Used when you are Idle and Pet is Engaged
    ]]
    state.HybridMode:options("Master", "Pet")

    --[[
        Alt-F12 - Turns off any emergency mode
        
        Ctrl-F10 - Cycle type of Physical Defense Mode in use.
        F10 - Activate emergency Physical Defense Mode. Replaces Magical Defense Mode, if that was active.
    ]]
    state.PhysicalDefenseMode:options("Normal", "PetDT", "Malignance")

    --[[
        Alt-F12 - Turns off any emergency mode

        F11 - Activate emergency Magical Defense Mode. Replaces Physical Defense Mode, if that was active.
    ]]
    state.MagicalDefenseMode:options("PetMDT")

    --[[ IDLE Mode Notes:

        F12 - Update currently equipped gear, and report current status.
        Ctrl-F12 - Cycle Idle Mode.
        
        Will automatically set IdleMode to Idle when Pet becomes Engaged and you are Idle
    ]]
    state.IdleMode:options("Malignance", "Mpaca", "PetTP", "PetEnmity", "Rao", "PetMage")

    --Various Cycles for the different types of PetModes
    state.PetStyleCycleTank = M {"NORMAL", "DD", "MAGIC", "SPAM"}
    state.PetStyleCycleMage = M {"NORMAL", "HEAL", "SUPPORT", "MB", "DD"}
    state.PetStyleCycleDD = M {"NORMAL", "BONE", "SPAM", "OD"}

    --The actual Pet Mode and Pet Style cycles
    --Default Mode is Tank
    state.PetModeCycle = M {"TANK", "DD", "MAGE"}
    --Default Pet Cycle is Tank
    state.PetStyleCycle = state.PetStyleCycleTank

    --Toggles
    --[[
        Alt + E will turn on or off Auto Maneuver
    ]]
    state.AutoMan = M(false, "Auto Maneuver")

    --[[
        //gs c toggle autodeploy
    ]]
    state.AutoDeploy = M(false, "Auto Deploy")

    --[[
        Alt + D will turn on or off Lock Pet DT
        (Note this will block all gearswapping when active)
    ]]
    state.LockPetDT = M(false, "Lock Pet DT")

    --[[
        Alt + (tilda) will turn on or off the Lock Weapon
    ]]
    state.LockWeapon = M(false, "Lock Weapon")

    --[[
        //gs c toggle setftp
    ]]
    state.SetFTP = M(false, "Set FTP")

   --[[
        This will hide the entire HUB
        //gs c hub all
    ]]
    state.textHideHUB = M(false, "Hide HUB")

    --[[
        This will hide the Mode on the HUB
        //gs c hub mode
    ]]
    state.textHideMode = M(false, "Hide Mode")

    --[[
        This will hide the State on the HUB
        //gs c hub state
    ]]
    state.textHideState = M(false, "Hide State")

    --[[
        This will hide the Options on the HUB
        //gs c hub options
    ]]
    state.textHideOptions = M(false, "Hide Options")

    --[[
        This will toggle the HUB lite mode
        //gs c hub lite
    ]]  
    state.useLightMode = M(false, "Toggles Lite mode")

    --[[
        This will toggle the default Keybinds set up for any changeable command on the window
        //gs c hub keybinds
    ]]
    state.Keybinds = M(false, "Hide Keybinds")

    --[[ 
        This will toggle the CP Mode 
        //gs c toggle CP 
    ]] 
    state.CP = M(false, "CP") 
    CP_CAPE = "Aptitude Mantle +1" 

    --[[
        Enter the slots you would lock based on a custom set up.
        Can be used in situation like Salvage where you don't want
        certain pieces to change.

        //gs c toggle customgearlock
        ]]
    state.CustomGearLock = M(false, "Custom Gear Lock")
    --Example customGearLock = T{"head", "waist"}
    customGearLock = T{}

    send_command("bind !f7 gs c cycle PetModeCycle")
    send_command("bind ^f7 gs c cycleback PetModeCycle")
    send_command("bind !f8 gs c cycle PetStyleCycle")
    send_command("bind ^f8 gs c cycleback PetStyleCycle")
	send_command('bind !f9 gs c cycleback OffenseMode')
	send_command("bind !f10 gs c cycleback PhysicalDefenseMode")
	send_command('bind !f12 gs c cycleback IdleMode')
    send_command("bind !e gs c toggle AutoMan")
    send_command("bind !d gs c toggle LockPetDT")
    send_command("bind !f6 gs c predict")
    send_command("bind ^` gs c toggle LockWeapon")
    send_command("bind home gs c toggle setftp")
    send_command("bind PAGEUP gs c toggle autodeploy")
    send_command("bind PAGEDOWN gs c hide keybinds")
    send_command("bind end gs c toggle CP") 
    send_command("bind = gs c clear")

    select_default_macro_book()
	send_command('@wait 4;input /lockstyleset 4')

    -- Adjust the X (horizontal) and Y (vertical) position here to adjust the window
    pos_x = 1400
    pos_y = 100
    setupTextWindow(pos_x, pos_y)
    
end

function file_unload()
    send_command("unbind !f7")
    send_command("unbind ^f7")
    send_command("unbind !f8")
    send_command("unbind ^f8")
	send_command('unbind !f9')
    send_command("unbind !e")
    send_command("unbind !d")
    send_command("unbind !f6")
    send_command("unbind ^`")
    send_command("unbind home")
    send_command("unbind PAGEUP")
    send_command("unbind PAGEDOWN")       
    send_command("unbind end")
    send_command("unbind =")
end

function job_setup()
    include("PUP-LIB.lua")
end

function init_gear_sets()
    --Table of Contents
    ---Gear Variables
    ---Master Only Sets
    ---Hybrid Only Sets
    ---Pet Only Sets
    ---Misc Sets

    -------------------------------------------------------------------------
    --  _____                  __      __        _       _     _
    -- / ____|                 \ \    / /       (_)     | |   | |
    --| |  __  ___  __ _ _ __   \ \  / /_ _ _ __ _  __ _| |__ | | ___  ___
    --| | |_ |/ _ \/ _` | '__|   \ \/ / _` | '__| |/ _` | '_ \| |/ _ \/ __|
    --| |__| |  __/ (_| | |       \  / (_| | |  | | (_| | |_) | |  __/\__ \
    -- \_____|\___|\__,_|_|        \/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/
    -------------------------------------------------------------------------
    --[[
        This section is best ultilized for defining gear that is used among multiple sets
        You can simply use or ignore the below
    ]]
	
	gear.Pet = {}
	
	-- Used by strobes and such
	gear.Pet.Enmity = {
		head="Heyoka Cap",
		body="Heyoka Harness",
       	hands="Heyoka Mittens",
	   	legs="Heyoka Subligar +1",
	   	feet="Heyoka Leggings",
	   	left_ear="Rimeice Earring",
		right_ear="Domes. Earring",
		neck="Pup. Collar +2",
	}
	
    Animators = {}
    Animators.Range = "Animator P II"
    Animators.Melee = "Animator P +1"

    --Adjust to your reforge level
    --Sets up a Key, Value Pair
    Artifact_Foire = {}
    Artifact_Foire.Head_PRegen = "Foire Taj +1"
    Artifact_Foire.Body_WSD_PTank = "Foire Tobe +1"
    Artifact_Foire.Hands_Mane_Overload = "Foire Dastanas +1"
    Artifact_Foire.Legs_PCure = "Foire Churidars +1"
    Artifact_Foire.Feet_Repair_PMagic = "Foire Babouches +3"

    Relic_Pitre = {}
    Relic_Pitre.Head_PRegen = "Pitre Taj +2" --Enhances Optimization
    Relic_Pitre.Body_PTP = "Pitre Tobe +3" --Enhances Overdrive
    Relic_Pitre.Hands_WSD = "Pitre Dastanas +2" --Enhances Fine-Tuning
    Relic_Pitre.Legs_PMagic = "Pitre Churidars +3" --Enhances Ventriloquy
    Relic_Pitre.Feet_PMagic = "Pitre Babouches +3" --Role Reversal

    Empy_Karagoz = {}
    Empy_Karagoz.Head_PTPBonus = "Karagoz Capello +1"
    Empy_Karagoz.Body_Overload = "Karagoz Farsetto"
    Empy_Karagoz.Hands = "Karagoz Guanti"
    Empy_Karagoz.Legs_Combat = "Karagoz Pantaloni +1"
    Empy_Karagoz.Feet_Tatical = "Karagoz Scarpe +1"

    Visucius = {}
	
    Visucius.PetDT = {
        name = "Visucius's Mantle",
        augments = {
            'Pet: Haste+10%',
        },
    }
	
    Visucius.PetMagic = {
        name = "Visucius's Mantle",
        augments = {
            'Pet: Haste+10%',
        }
    }
	
	Visucius.WS = {
		name = "Visucius's Mantle",
        augments = {'STR+20','Accuracy+20 Attack+20','STR+10','"Dbl.Atk."+10'}
	}
	
	Visucius.WSDEX = {
		name = "Visucius's Mantle",
        augments = {'DEX+20','Accuracy+20 Attack+20','DEX+10','"Dbl.Atk."+10'}
	}
	
	Visucius.WSCRIT = {
		name = "Visucius's Mantle",
		augments={'STR+20','Accuracy+20 Attack+20','STR+10','Crit.hit rate+10',}
	}
	
	Visucius.Tank = {
		name="Visucius's Mantle",
		augments={'Pet: Regen+10'}
	}
	
	Visucius.TP = { name="Visucius's Mantle", augments={'Pet: Acc.+20 Pet: R.Acc.+20 Pet: Atk.+20 Pet: R.Atk.+20','Accuracy+20 Attack+20','Pet: Attack+10 Pet: Rng.Atk.+10','Pet: Haste+10'}}
	
	PET_TP_GEAR = {
		head={name="Herculean Helm", augments={'Pet: "Store TP+10"'}},
		legs={name="Herculean Trousers", augments={'Pet: "Store TP"+9'}},
		body={name=Relic_Pitre.Body_PTP},
		hands={name="Herculean Gloves", augments={'Pet: "Store TP"+11'}},
		feet={name="Herculean Boots", augments={'Pet: "Store TP"+10'}},
		ring1="Cath Palug Ring",
		ring2="Thurandaut Ring",
		ear1="Enmerkar Earring",
		ear2="Crep. Earring",
		neck="Pup. Collar +2",
		back=Visucius.TP,
		waist="Klouskap Sash +1"
	}
	
	PET_DA_GEAR = set_combine(PET_TP_GEAR, {
		head={name="Taeon Chapeau"},
		body={name="Taeon Tabard"},
		hands={name="Taeon Gloves"},
		legs={name="Taeon Tights"},
		feet={name="Taeon Boots"},
		neck="Shulmanu Collar",
	})
	
	OD_GEAR=set_combine(PET_TP_GEAR, {
		
	})
	
	RAO_SET = {
		head="Rao Kabuto +1",
		body="Rao Togi +1",
		hands="Rao Kote +1",
		legs="Rao Haidate +1",
		feet="Rao Sune-Ate +1"
	}
	
	DT_GEAR = {
       	head="Malignance Chapeau",
		body="Malignance Tabard",
		hands="Malignance Gloves",
		legs="Malignance Tights",
		feet="Malignance Boots",
		ring1="Cath Palug Ring",
		ring2="Thurandaut Ring",
		ear1="Enmerkar Earring",
		ear2="Rimeice Earring",
		waist="Moonbow Belt +1",
		neck="Loricate Torque +1",
    }
	
	-- Used when doing skillchains and you have bonecrusher setup
	sets.DD = {}
	sets.DD.BONE = set_combine(PET_DA_GEAR, {
		hands="Mpaca's Gloves",
		feet="Mpaca's Boots",
		back=Visucius.TP,
		ear1="Domes. Earring",
		ear2="Kyrene's Earring",
		waist="Incarnation Sash",
	})	

    --------------------------------------------------------------------------------
    --  __  __           _               ____        _          _____      _
    -- |  \/  |         | |             / __ \      | |        / ____|    | |
    -- | \  / | __ _ ___| |_ ___ _ __  | |  | |_ __ | |_   _  | (___   ___| |_ ___
    -- | |\/| |/ _` / __| __/ _ \ '__| | |  | | '_ \| | | | |  \___ \ / _ \ __/ __|
    -- | |  | | (_| \__ \ ||  __/ |    | |__| | | | | | |_| |  ____) |  __/ |_\__ \
    -- |_|  |_|\__,_|___/\__\___|_|     \____/|_| |_|_|\__, | |_____/ \___|\__|___/
    --                                                  __/ |
    --                                                 |___/
    ---------------------------------------------------------------------------------
    --This section is best utilized for Master Sets
    --[[
        Will be activated when Pet is not active, otherwise refer to sets.idle.Pet
    ]]
   
	
	sets.Enmity = {
		body="Passion Jacket",
		legs="Tali'ah Sera. +1",
		neck="Unmoving Collar +1",
		ring1="Petrov Ring",
		ear1="Friomisi Earring",
		ear2="Handler's Earring +1",
		gloves="Kurys Gloves",
	}

    -------------------------------------Fastcast
    sets.precast.FC = {
       head="Herculean Helm",
	   body="Taeon Tabard",
	   neck="Baetyl Pendant",
    }

    -------------------------------------Midcast
    sets.midcast = {} --Can be left empty

    sets.midcast.FastRecast = {
       -- Add your set here 
    }
	
	-------------------------------------FLASH
	sets.midcast['Flash'] = sets.Enmity

    -------------------------------------Kiting
    sets.Kiting = {feet = "Hermes' Sandals"}

    -------------------------------------JA
    sets.precast.FC.Utsusemi = set_combine(sets.precast.FC, {neck = "Magoraga Beads", body = "Passion Jacket"})

    -- Precast sets to enhance JAs
    sets.precast.JA = {} -- Can be left empty

    sets.precast.JA["Tactical Switch"] = {feet = Empy_Karagoz.Feet_Tatical}

    sets.precast.JA["Ventriloquy"] = {legs = Relic_Pitre.Legs_PMagic}

    sets.precast.JA["Role Reversal"] = {feet = Relic_Pitre.Feet_PMagic}

    sets.precast.JA["Overdrive"] = {body = Relic_Pitre.Body_PTP}

    sets.precast.JA["Repair"] = {
		head="Rao Kabuto +1",
		body="Rao Togi +1",
		hands="Rao Kote +1",
		legs="Rao Haidate +1",
		feet="Rao Sune-Ate +1",
        ammo = "Automat. Oil +3",
        feet = Artifact_Foire.Feet_Repair_PMagic
    }

    sets.precast.JA["Maintenance"] = set_combine(sets.precast.JA["Repair"], {})

    sets.precast.JA.Maneuver = {
        body = "Karagoz Farsetto +1",
        hands = Artifact_Foire.Hands_Mane_Overload,
        ear1 = "Burana Earring"
    }

    sets.precast.JA["Activate"] = {back = "Visucius's Mantle"}

    sets.precast.JA["Deus Ex Automata"] = sets.precast.JA["Activate"]

	-- Mainly just enmity pieces
    sets.precast.JA["Provoke"] = sets.Enmity
	
	sets.precast.JA["Vallation"] = sets.Enmity
	
	sets.precast.JA["Pflug"] = sets.Enmity

    --Waltz set (chr and vit)
    sets.precast.Waltz = {
       body = "Passion Jacket"
    }

    sets.precast.Waltz["Healing Waltz"] = {}
	
	sets.master_accessories = {
		neck="Pup. Collar +2",
		ring1="Niqmaddu Ring",
		ring2="Gere Ring",
		ear1="Crep. Earring",
		ear2="Cessance Earring",
		waist="Moonbow Belt +1",
		back=Visucius.WSDEX
	}
	
	sets.pet_accessories = {
		ring1="Cath Palug Ring",
	   	ring2="Thurandaut Ring",
		waist="Klouskap Sash +1",
		ear1="Crep. Earring",
		ear2="Enmerkar Earring",
		back=Visucius.TP,
	}

    -------------------------------------WS
    -- Weaponskill sets
    -- Default set for any weaponskill that isn't any more specifically defined
    sets.precast.WS = {
       	head="Mpaca's Cap",
		body="Mpaca's Doublet",
		hands="Mpaca's Gloves",
		legs="Mpaca's Hose",
		feet="Mpaca's Boots",
		neck="Pup. Collar +2",
		ring2="Niqmaddu Ring",
		ring1="Gere Ring",
		ear1="Schere Earring",
		ear2="Brutal Earring",
		waist="Moonbow Belt +1",
		back=Visucius.WS
    }

    -- Specific weaponskill sets.  Uses the base set if an appropriate WSMod version isn't found

    sets.precast.WS["Victory Smite"] = set_combine(sets.precast.WS, {
		head="Blistering Sallet +1",
		ear2="Moonshade Earring",
		hands="Ryuo Tekko +1",
		legs="Heyoka Subligar +1",
		back = Visucius.WSCRIT,
	})
	
	sets.precast.WS["Stringing Pummel"] = set_combine(sets.precast.WS["Victory Smite"], {})

    sets.precast.WS["Shijin Spiral"] = set_combine(sets.precast.WS, {
		body = "Tali'ah Manteel +2",
		ear2="Mache Earring +1",
		back = Visucius.WSDEX
	})

    sets.precast.WS["Howling Fist"] = set_combine(sets.precast.WS["Victory Smite"], {})
	
	sets.precast.WS["Raging Fists"] = set_combine(sets.precast.WS, {})
	
	sets.precast.WS["Evisceration"] = set_combine(sets.precast.WS["Victory Smite"], {
		ear1 = "Mache Earring +1",
		ear2 = "Mache Earring +1",
		back = Visucius.WSDEX
	})
	
	sets.precast.WS["Aeolian Edge"] = set_combine(sets.precast.WS, {
		head="",
		body="Cohort Cloak +1",
		neck="Baetyl Pendant",
		hands={name="Nyame Gauntlets"},
		legs="Nyame Flanchard",
		feet="Nyame Sollerets",
		waist="Orpheus's Sash",
		ear1="Friomisi Earring",
		ear2="Moonshade Earring",
		back="Kaikias' Cape"
	})

    -------------------------------------Engaged
    --[[
        Offense Mode = Mpaca
        Hybrid Mode = Normal
    ]]
	
    sets.engaged.Mpaca = {
       	head="Mpaca's Cap",
		body="Mpaca's Doublet",
		hands="Mpaca's Gloves",
		legs="Mpaca's Hose",
		feet="Mpaca's Boots",
		neck="Pup. Collar +2",
		waist="Moonbow Belt +1",
		back=Visucius.WSDEX,
		ring1="Gere Ring",
		ring2="Niqmaddu Ring",
		ear1="Schere Earring",
		ear2="Cessance Earring",
    }

    -------------------------------------
    --[[
        Offense Mode = Mpaca
        Hybrid Mode = Master
    ]]
    sets.engaged.Mpaca.Master = set_combine(sets.engaged.Mpaca, sets.master_accessories)

    -------------------------------------
    --[[
        Offense Mode = Mpaca
        Hybrid Mode = Pet
    ]]
	
    sets.engaged.Mpaca.Pet = set_combine(sets.engaged.Mpaca, set_combine(sets.pet_accessories, {
		legs="Heyoka Subligar +1",
		waist="Moonbow Belt +1"
	}))
	
	-------------------------------------
    --[[
        Offense Mode = Mpaca
        Hybrid Mode = Normal
    ]]
	
	sets.engaged.PetEnmity = set_combine(sets.engaged.Mpaca.Master, {
		head="Heyoka Cap",
		body="Heyoka Harness",
       	hands="Heyoka Mittens",
	   	legs="Heyoka Subligar +1",
	   	feet="Heyoka Leggings",
	})

    -------------------------------------
    --[[
        Offense Mode = Rao
		Hybrid Mode = Normal
    ]]
	
	sets.engaged.Rao = set_combine(RAO_SET, {
		ear1="Rimeice Earring",
		ear2="Enmerkar Earring",
		ring1="C. Palug Ring",
		ring2="Thurandaut Ring",
		back=Visucius.Tank
	})
	
    sets.engaged.Rao.Master = set_combine(sets.engaged.Rao, sets.master_accessories)
	sets.engaged.Rao.Pet = set_combine(sets.engaged.Rao, sets.pet_accessories)
	
	-------------------------------------
    --[[
        Offense Mode = PetTP
        Hybrid Mode = Normal
    ]]
	
	sets.engaged.PetTP = PET_TP_GEAR
	sets.engaged.PetTP.Master = {
		head={name="Mpaca's Cap"},
		legs="Heyoka Subligar +1",
		body={name=Relic_Pitre.Body_PTP},
		hands="Mpaca's Gloves",
		feet="Mpaca's Boots",
		neck="Pup. Collar +2",
		ring1="Niqmaddu Ring",
		ring2="Gere Ring",
		ear1="Crep. Earring",
		ear2="Brutal Earring",
		waist="Moonbow Belt +1",
		back=Visucius.TP
	}
	sets.engaged.PetTP.Pet = set_combine(sets.engaged.PetTP, sets.pet_accessories)
	
	
	-------------------------------------
    --[[
        Offense Mode = PetDA
        Hybrid Mode = Normal
    ]]
	
	sets.engaged.PetDA = PET_DA_GEAR
	sets.engaged.PetDA.Master = PET_DA_GEAR
	sets.engaged.PetDA.Pet = PET_DA_GEAR
	
	-------------------------------------
    --[[
        Offense Mode = Malignance
        Hybrid Mode = Normal
    ]]
	
	sets.engaged.Malignance = set_combine(DT_GEAR, {})
	sets.engaged.Malignance.Master = set_combine(DT_GEAR, sets.master_accessories)
	sets.engaged.Malignance.Pet = set_combine(DT_GEAR, set_combine(sets.pet_accessories, {
		legs="Heyoka Subligar +1",
		waist="Moonbow Belt +1",
		neck="Pup. Collar +2",
	}))

    ----------------------------------------------------------------
    --  _____     _      ____        _          _____      _
    -- |  __ \   | |    / __ \      | |        / ____|    | |
    -- | |__) |__| |_  | |  | |_ __ | |_   _  | (___   ___| |_ ___
    -- |  ___/ _ \ __| | |  | | '_ \| | | | |  \___ \ / _ \ __/ __|
    -- | |  |  __/ |_  | |__| | | | | | |_| |  ____) |  __/ |_\__ \
    -- |_|   \___|\__|  \____/|_| |_|_|\__, | |_____/ \___|\__|___/
    --                                  __/ |
    --                                 |___/
    ----------------------------------------------------------------

    -------------------------------------Magic Midcast
    sets.midcast.Pet = {
       -- Add your set here 
    }

    sets.midcast.Pet.Cure = {
       -- Add your set here 
    }

    sets.midcast.Pet["Healing Magic"] = {
       --legs="Kara. Pantaloni +1",
    }

    sets.midcast.Pet["Elemental Magic"] = {
       	head={ name="Herculean Helm", augments={'Pet: "Mag.Atk.Bns."+30','Pet: "Regen"+3','Pet: INT+7',}},
	    body={ name="Herculean Vest", augments={'Pet: "Mag.Atk.Bns."+30',}},
	    hands={ name="Herculean Gloves", augments={'Pet: "Mag.Atk.Bns."+15','"Store TP"+3','Pet: INT+10',}},
		legs = Relic_Pitre.Legs_PMagic,
		feet=Relic_Pitre.Feet_PMagic,
	    neck="Pup. Collar +2",
	    waist="Ukko Sash",
	    left_ear="Enmerkar Earring", 
	    right_ear="Burana Earring",
	    left_ring="C. Palug Ring",
	    right_ring="Thurandaut Ring",
	    back={ name="Visucius's Mantle", augments={'Pet: M.Acc.+20 Pet: M.Dmg.+20'}},
    }

    sets.midcast.Pet["Enfeebling Magic"] = {
       -- Add your set here
    }

    sets.midcast.Pet["Dark Magic"] = {
       -- Add your set here
    }

    sets.midcast.Pet["Divine Magic"] = {
       -- Add your set here 
    }

    sets.midcast.Pet["Enhancing Magic"] = {
       -- Add your set here 
    }

    -------------------------------------Idle
    --[[
        This set will become default Idle Set when the Pet is Active 
        and sets.idle will be ignored
        Player = Idle and not fighting
        Pet = Idle and not fighting

        Idle Mode = Idle
    ]]
	
	sets.idle.Mpaca = set_combine(sets.engaged.Mpaca, {})
	
	sets.idle.Malignance = sets.engaged.Malignance.Master
	
    sets.idle.PetDA = sets.engaged.PetDA
	
	sets.idle.PetEnmity = sets.engaged.PetEnmity
	
	sets.idle.PetTP = sets.engaged.PetTP
	
	sets.idle.Rao  = sets.engaged.Rao
	
	sets.idle.PetMage = set_combine(sets.idle.Rao, {
		legs = Relic_Pitre.Legs_PMagic,
		waist = "Ukko Sash",
	})

    -------------------------------------Enmity
    sets.pet = {} -- Not Used

    --Equipped automatically
    sets.pet.Enmity = gear.Pet.Enmity
	
    sets.defense = {}

    sets.defense.Malignance = sets.engaged.Malignance
    sets.defense.PetDT = sets.engaged.Rao

    -------------------------------------WS
    --[[
        WSNoFTP is the default weaponskill set used
    ]]
    sets.midcast.Pet.WSNoFTP = {
        head="Mpaca's Cap",
		body=Relic_Pitre.Body_PTP,
		hands="Mpaca's Gloves",
		legs={ name="Herculean Trousers", augments={'Pet: Accuracy+22 Pet: Rng. Acc.+22','Pet: "Subtle Blow"+5','Pet: DEX+14','Pet: Attack+14 Pet: Rng.Atk.+14',}},
		feet="Mpaca's Boots",
		neck="Pup. Collar +2",
		back=Visucius.TP,
		ear1="Enmerkar Earring",
		ear2="Kyrene's Earring",
		ring1="Thurandaut Ring",
		ring2="C. Palug Ring",
		waist="Klouskap Sash +1",
    }

    --[[
        If we have a pet weaponskill that can benefit from WSFTP
        then this set will be equipped
    ]]
    sets.midcast.Pet.WSFTP = set_combine(sets.midcast.Pet.WSNoFTP, {
		head=Empy_Karagoz.Head_PTPBonus,
		back="Dispersal Mantle",
	})

    --[[
        Base Weapon Skill Set
        Used by default if no modifier is found
    ]]
    sets.midcast.Pet.WS = set_combine(sets.midcast.Pet.WSNoFTP, {})

    --Chimera Ripper, String Clipper
    sets.midcast.Pet.WS["STR"] = set_combine(PET_DA_GEAR, {
		ear2="Kyrene's Earring",
		hands="Karagoz Guanti +1",
	})

    -- Bone crusher, String Shredder
    sets.midcast.Pet.WS["VIT"] =
        set_combine(
        sets.DD.BONE,
        {
            -- Add your gear here that would be different from sets.midcast.Pet.WSNoFTP
            --head = Empy_Karagoz.Head_PTPBonus
			ear2="Kyrene's Earring",
			waist="Incarnation Sash",
        }
    )

    -- Cannibal Blade
    sets.midcast.Pet.WS["MND"] = set_combine(sets.midcast.Pet.WSNoFTP, {})

    -- Armor Piercer, Armor Shatterer
    sets.midcast.Pet.WS["DEX"] = set_combine(sets.midcast.Pet.WSNoFTP, {})

    -- Arcuballista, Daze
    sets.midcast.Pet.WS["DEXFTP"] =
        set_combine(
        sets.midcast.Pet.WSFTP,
        {
            -- Add your gear here that would be different from sets.midcast.Pet.WSFTP
            --head = Empy_Karagoz.Head_PTPBonus,
			--hands="Karagoz Guanti +1",
			--legs="Kara. Pantaloni +1",
			--ear2="Kyrene's Earring"
        }
    )

    ---------------------------------------------
    --  __  __ _             _____      _
    -- |  \/  (_)           / ____|    | |
    -- | \  / |_ ___  ___  | (___   ___| |_ ___
    -- | |\/| | / __|/ __|  \___ \ / _ \ __/ __|
    -- | |  | | \__ \ (__   ____) |  __/ |_\__ \
    -- |_|  |_|_|___/\___| |_____/ \___|\__|___/
    ---------------------------------------------
    -- Town Set
    sets.idle.Town = {
       -- Add your set here
    }

    -- Resting sets
    sets.resting = {
       -- Add your set here
    }
	
end

-- Select default macro book on initial load or subjob change.
function select_default_macro_book()
    -- Default macro set/book
    set_macro_page(1, 8)
end
