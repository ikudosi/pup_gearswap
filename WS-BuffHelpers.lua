--============================================================
-- WS_BUFF_HELPER.lua
--
-- Determines the player's general offensive buff environment
-- specifically for PHYSICAL WEAPON SKILLS.
--
-- Returns:
--      "Low"
--      "Mid"
--      "High"
--
-- IMPORTANT:
-- This is NOT an exact Attack/Defense-cap calculator.
--
-- GearSwap's buffactive tells us WHICH buffs are active, but
-- generally not their exact potency.
--
-- Therefore this helper assesses the real-world strength of
-- the active buff PACKAGE.
--
-- Haste / March / Store TP / Samurai Roll are intentionally
-- ignored because this helper is strictly for WS damage.
--============================================================


--------------------------------------------------------------
-- Basic helper
--------------------------------------------------------------

local function has_buff(name)
    return buffactive[name] ~= nil
end


--------------------------------------------------------------
-- Main function
--------------------------------------------------------------

function get_ws_buff_profile()

    local p = {

        -- Final classification
        level = 'Low',

        -- Attack environment score.
        --
        -- This is NOT "Attack +X".
        -- It represents confidence that we're in a strongly
        -- attack-buffed environment.
        attack_score = 0,

        -- Other WS-relevant categories are deliberately kept
        -- separate because they do NOT indicate attack cap.
        accuracy_score = 0,
        crit_score = 0,
        multiattack_score = 0,

        ------------------------------------------------------
        -- Detected buffs
        ------------------------------------------------------

        berserk = false,
        warcry = false,
        chaos_roll = false,
        minuet_count = 0,

        impetus = false,
        blood_rage = false,
        mighty_strikes = false,

        aggressor = false,
        madrigal = false,

        fighters_roll = false,

        sneak_attack = false,
        trick_attack = false,

        boost = false,
    }


    --========================================================
    -- ATTACK BUFFS
    --========================================================


    ----------------------------------------------------------
    -- BERSERK
    ----------------------------------------------------------
    --
    -- Real effect:
    --
    -- WAR Berserk is a very large percentage Attack increase.
    -- Base effect is +25% Attack and WAR receives additional
    -- increases at higher levels.
    --
    -- For WS-set selection this is one of the strongest
    -- indicators that our Attack/Defense ratio is high.
    --
    ----------------------------------------------------------

    if has_buff('Berserk') then

        p.berserk = true

        -- STRONG attack indicator
        p.attack_score = p.attack_score + 4
    end


    ----------------------------------------------------------
    -- CHAOS ROLL
    ----------------------------------------------------------
    --
    -- Real effect:
    --
    -- Percentage Attack increase.
    --
    -- Actual potency varies enormously with the roll:
    --
    --      weak rolls   = small Attack increase
    --      lucky roll   = very large Attack increase
    --      XI           = extremely large Attack increase
    --
    -- GearSwap's buffactive DOES NOT tell us the roll number.
    --
    -- Because Chaos Roll is normally maintained specifically
    -- as a major Attack buff, we classify its presence as a
    -- STRONG attack indicator, but not as strongly as if we
    -- actually knew it was XI.
    --
    ----------------------------------------------------------

    if has_buff('Chaos Roll') then

        p.chaos_roll = true

        -- STRONG attack indicator
        p.attack_score = p.attack_score + 4
    end


    ----------------------------------------------------------
    -- WARCRY
    ----------------------------------------------------------
    --
    -- Real effect:
    --
    -- Percentage Attack increase.
    --
    -- Potency depends on the WAR level of the player who
    -- supplied Warcry.
    --
    -- Strong, but generally less important than having
    -- Berserk or a good Chaos Roll.
    --
    ----------------------------------------------------------

    if has_buff('Warcry') then

        p.warcry = true

        -- MODERATE/STRONG attack indicator
        p.attack_score = p.attack_score + 3
    end


    ----------------------------------------------------------
    -- MINUET
    ----------------------------------------------------------
    --
    -- Real effect:
    --
    -- FLAT Attack rather than percentage Attack.
    --
    -- Higher-tier Minuets and BRD song-enhancing equipment
    -- can provide very substantial Attack.
    --
    -- GearSwap normally exposes the Minuet status rather than
    -- enough information to determine exact song potency.
    --
    -- buffactive['Minuet'] can indicate multiple Minuets.
    --
    ----------------------------------------------------------

    if has_buff('Minuet') then

        p.minuet_count = buffactive['Minuet'] or 1

        -- One Minuet = meaningful Attack support.
        --
        -- Multiple Minuets = increasingly strong indication
        -- of a high-Attack party configuration.

        if p.minuet_count >= 2 then

            p.attack_score = p.attack_score + 5

        else

            p.attack_score = p.attack_score + 3
        end
    end


    --========================================================
    -- CRITICAL-HIT BUFFS
    --
    -- IMPORTANT:
    --
    -- These affect WS damage for WSs capable of critical hits,
    -- but they DO NOT mean that we're attack capped.
    --
    -- Therefore they DO NOT increase attack_score.
    --========================================================


    ----------------------------------------------------------
    -- IMPETUS
    ----------------------------------------------------------
    --
    -- Real effect:
    --
    -- Consecutively landed attacks increase critical-hit rate.
    --
    -- Can reach a very substantial Crit Rate bonus.
    --
    -- With Bhikku Cyclas, Impetus can additionally provide
    -- Critical Hit Damage.
    --
    -- Extremely important for Victory Smite.
    --
    -- But:
    --
    --      Impetus != Attack buff
    --
    -- Therefore it should influence a Victory Smite-specific
    -- gear decision, but NOT whether we're attack capped.
    --
    ----------------------------------------------------------

    if has_buff('Impetus') then

        p.impetus = true

        -- Very strong crit environment
        p.crit_score = p.crit_score + 5
    end


    ----------------------------------------------------------
    -- BLOOD RAGE
    ----------------------------------------------------------
    --
    -- Real effect:
    --
    -- Large Critical Hit Rate increase.
    --
    -- Excellent for critical-hit WSs.
    -- Does NOT increase Attack.
    --
    ----------------------------------------------------------

    if has_buff('Blood Rage') then

        p.blood_rage = true

        p.crit_score = p.crit_score + 5
    end


    ----------------------------------------------------------
    -- MIGHTY STRIKES
    ----------------------------------------------------------
    --
    -- Real effect:
    --
    -- Forces physical attacks to critical hit.
    --
    -- Massive effect on applicable physical WSs.
    --
    -- Again:
    --
    --      Critical state != Attack-cap state
    --
    ----------------------------------------------------------

    if has_buff('Mighty Strikes') then

        p.mighty_strikes = true

        p.crit_score = p.crit_score + 10
    end


    --========================================================
    -- MULTIATTACK
    --========================================================


    ----------------------------------------------------------
    -- FIGHTER'S ROLL
    ----------------------------------------------------------
    --
    -- Real effect:
    --
    -- Fighter's Roll gives DOUBLE ATTACK, not Triple Attack.
    --
    -- Double Attack can proc on applicable WS hits and can
    -- therefore directly increase WS damage.
    --
    -- But it does NOT increase Attack.
    --
    ----------------------------------------------------------

    if has_buff("Fighter's Roll") then

        p.fighters_roll = true

        p.multiattack_score = p.multiattack_score + 4
    end


    --========================================================
    -- ACCURACY
    --
    -- Track these because they matter to WS performance,
    -- but NEVER use them to decide that we're attack capped.
    --========================================================


    ----------------------------------------------------------
    -- AGGRESSOR
    ----------------------------------------------------------

    if has_buff('Aggressor') then

        p.aggressor = true

        p.accuracy_score = p.accuracy_score + 4
    end


    ----------------------------------------------------------
    -- MADRIGAL
    ----------------------------------------------------------

    if has_buff('Madrigal') then

        p.madrigal = true

        p.accuracy_score = p.accuracy_score + 3
    end


    --========================================================
    -- THF WS ABILITIES
    --========================================================

    if has_buff('Sneak Attack') then
        p.sneak_attack = true
    end


    if has_buff('Trick Attack') then
        p.trick_attack = true
    end


    --========================================================
    -- BOOST
    --========================================================
    --
    -- Boost can affect the next attack/WS depending on job
    -- mechanics.
    --
    -- We expose it to WS-specific logic rather than treating
    -- it as generic evidence of attack cap.
    --========================================================

    if has_buff('Boost') then
        p.boost = true
    end


    --========================================================
    -- FINAL ATTACK-BUFF CLASSIFICATION
    --========================================================
    --
    -- The important distinction:
    --
    -- HIGH means:
    --
    --      "We have enough major Attack support that a
    --       high-buff/PDL-oriented WS set may be appropriate."
    --
    -- It DOES NOT guarantee that Attack is capped against the
    -- current monster.
    --
    -- Target Defense is unknown.
    --
    --========================================================


    if p.attack_score >= 8 then

        p.level = 'High'

    elseif p.attack_score >= 4 then

        p.level = 'Mid'

    else

        p.level = 'Low'
    end


    return p
end


--============================================================
-- Convenience functions
--============================================================

function get_ws_buff_level()

    return get_ws_buff_profile().level
end


function is_high_ws_buff()

    return get_ws_buff_profile().level == 'High'
end


function is_mid_ws_buff()

    return get_ws_buff_profile().level == 'Mid'
end


function is_low_ws_buff()

    return get_ws_buff_profile().level == 'Low'
end

function apply_ws_buff_set(ws_sets, spell)

    if spell.type ~= 'WeaponSkill' then
        return false
    end

    local ws_set = ws_sets[spell.english]

    if not ws_set then
        return false
    end

    local buff_level = get_ws_buff_level()

    if ws_set[buff_level] then
        equip(ws_set[buff_level])
        return true
    end

    return false
end
