
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
-- Target-side offensive state
--------------------------------------------------------------
--
-- Monster abilities are not player buffs, so they cannot be read
-- from buffactive.  We watch incoming action packets instead.
--
-- Only target-side effects that improve our physical WS damage
-- are tracked here.  A monster's Attack increase, for example,
-- does not belong in this calculation because it does not make
-- our WS hit harder.
--
-- Berserk is especially relevant because it lowers the monster's
-- Defense by 25%.  This makes the monster easier to damage.
--
-- The score below is a HEURISTIC conversion into this helper's
-- existing Low/Mid/High scale.  It is NOT "Attack +4" and it is
-- not intended to reproduce the pDIF formula.
--============================================================

local ws_target_state = {
    id = nil,
    effects = {},
}

local target_effects = {
    -- These monster abilities grant the Berserk status/effect.
    -- Berserk is +25% Attack / -25% Defense, so from OUR
    -- perspective the important part is the target's Defense loss.
    --
    -- The defense_score is intentionally a heuristic bridge to
    -- this helper's existing Low/Mid/High system.
    -- defense_reduction is the actual documented effect and is
    -- exposed in the tracked state for debugging/future logic.
    ['Berserk'] = {
        defense_reduction = 0.25,
        defense_score = 2,
        duration = 180,
    },

    -- Rams and Sheep use Rage; Rage gives the Berserk effect.
    ['Rage'] = {
        defense_reduction = 0.25,
        defense_score = 2,
        duration = 180,
    },

    -- Wivre use Boiling Blood. It grants Haste + Berserk, and
    -- the Berserk portion lowers the Wivre's Defense.
    ['Boiling Blood'] = {
        defense_reduction = 0.25,
        defense_score = 2,
        duration = 180,
    },
}

local function clear_ws_target_state()
    ws_target_state.id = nil
    ws_target_state.effects = {}
end


local function refresh_ws_target()

    local target = windower.ffxi.get_mob_by_target('t')

    if not target then
        clear_ws_target_state()
        return
    end

    if ws_target_state.id ~= target.id then
        ws_target_state.id = target.id
        ws_target_state.effects = {}
    end

    local now = os.time()

    for name, effect in pairs(ws_target_state.effects) do
        if effect.expires_at and effect.expires_at <= now then
            ws_target_state.effects[name] = nil
        end
    end
end


local function get_monster_ability_from_action(act)

    if not act or not act.targets or not act.targets[1] then
        return nil
    end

    if not act.targets[1].actions or not act.targets[1].actions[1] then
        return nil
    end

    local ability_id = act.targets[1].actions[1].param

    if not ability_id then
        return nil
    end

    return res.monster_abilities[ability_id]
end


local function track_target_ability(act)

    if not act or not act.actor_id then
        return
    end

    -- We only care about abilities used by our current target.
    local target = windower.ffxi.get_mob_by_target('t')

    if not target or target.id ~= act.actor_id then
        return
    end

    local ability = get_monster_ability_from_action(act)

    if not ability or not ability.english then
        return
    end

    local effect = target_effects[ability.english]

    if not effect then
        return
    end

    ws_target_state.id = target.id
    ws_target_state.effects[ability.english] = {
        expires_at = os.time() + effect.duration,
        defense_score = effect.defense_score,
        defense_reduction = effect.defense_reduction,
    }
end


-- Register this once because the helper can be included by more
-- than one GearSwap file/library.
if not _WS_BUFF_HELPER_ACTION_REGISTERED then

    _WS_BUFF_HELPER_ACTION_REGISTERED = true

    windower.register_event('action', track_target_ability)
end


local function get_target_defense_score()

    refresh_ws_target()

    local score = 0

    for _, effect in pairs(ws_target_state.effects) do
        score = score + (effect.defense_score or 0)
    end

    return score
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

        -- Target-side Defense reductions that improve our WS
        -- damage.  This is kept separate from player Attack.
        target_defense_score = 0,
        target_berserk = false,

        -- Combined environment score used only for the final
        -- Low/Mid/High classification.
        effective_attack_score = 0,

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
    --========================================================
    -- TARGET-SIDE EFFECTS
    --========================================================
    --
    -- Enemy Defense reductions are offensive conditions for our
    -- WS, but they are deliberately kept separate from the
    -- player's Attack buffs.
    --
    -- Example:
    --
    --      Player buffs:      attack_score = 4
    --      Target Berserk:    target_defense_score = 2
    --      Effective score:   6
    --
    -- This does NOT mean we have "Attack +6".  It is simply a
    -- common scale for deciding which WS set to use.
    --========================================================

    p.target_defense_score = get_target_defense_score()

    p.target_berserk =
        ws_target_state.effects['Berserk'] ~= nil or
        ws_target_state.effects['Rage'] ~= nil or
        ws_target_state.effects['Boiling Blood'] ~= nil

    -- True when any tracked target effect is currently reducing
    -- the monster's Defense. This is useful for debugging and
    -- for WS-specific logic later.
    p.target_defense_reduction = 0

    for _, effect in pairs(ws_target_state.effects) do
        p.target_defense_reduction =
            math.max(p.target_defense_reduction, effect.defense_reduction or 0)
    end

    p.effective_attack_score =
        p.attack_score + p.target_defense_score


    --========================================================
    -- FINAL ATTACK-BUFF CLASSIFICATION
    --========================================================
    --
    -- HIGH means:
    --
    --      "The combined player-buff + target-defense
    --       environment is strong enough that a high-buff/PDL-
    --       oriented WS set may be appropriate."
    --
    -- It still does NOT guarantee Attack is capped.
    -- The score remains a heuristic, not an exact pDIF model.
    --========================================================

    if p.effective_attack_score >= 8 then

        p.level = 'High'

    elseif p.effective_attack_score >= 4 then

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
