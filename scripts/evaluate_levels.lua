package.path = "./?.lua;" .. package.path

local difficulty = require "logic.game.difficulty"
local gambits = require "logic.game.gambits"
local levels = require "logic.game.levels"

local owned_gambits = {}
for id, enabled in pairs(levels.starting_gambits) do
    owned_gambits[id] = enabled
end

local suggest = false
local fast = false
local no_gambits = false
local all_paths = false
local from_level = 1
local to_level = #levels.configs
local argument_index = 1
while arg and argument_index <= #arg do
    local argument = arg[argument_index]
    if argument == "--suggest" then
        suggest = true
    elseif argument == "--fast" then
        fast = true
    elseif argument == "--no-gambits" then
        no_gambits = true
    elseif argument == "--all-paths" then
        all_paths = true
    elseif argument == "--from" then
        argument_index = argument_index + 1
        from_level = assert(tonumber(arg[argument_index]), "--from needs a level number")
    elseif argument == "--to" then
        argument_index = argument_index + 1
        to_level = assert(tonumber(arg[argument_index]), "--to needs a level number")
    else
        error("unknown argument: " .. tostring(argument))
    end
    argument_index = argument_index + 1
end
local options = fast and { restarts = 2, iterations = 250 }
    or { restarts = 4, iterations = 500 }

assert(difficulty.self_test())

local function owned_signature(owned)
    local ids = {}
    for id, enabled in pairs(owned) do
        if enabled then
            ids[#ids + 1] = id
        end
    end
    table.sort(ids)
    return table.concat(ids, ",")
end

local function add_choice_states(states, level_index)
    local next_states = {}
    local seen = {}
    for i = 1, #states do
        local choices = gambits.reward_choices(states[i], level_index)
        for choice_index = 1, #choices do
            local owned = {}
            for id, enabled in pairs(states[i]) do
                owned[id] = enabled
            end
            owned[choices[choice_index].id] = true
            local signature = owned_signature(owned)
            if not seen[signature] then
                seen[signature] = true
                next_states[#next_states + 1] = owned
            end
        end
    end
    return next_states
end

if all_paths then
    local states = { {} }
    print("LVL  PATHS      TARGETS  WANT  BEFORE  REACH     PRESS  VERDICT")
    for level_index, config in ipairs(levels.configs) do
        local figures = config.figures
        if level_index >= from_level and level_index <= to_level then
            local desired = config.recovery and math.max(2, #figures - 1) or #figures
            local max_before = 0
            local min_reachable = math.huge
            local min_target = math.huge
            local max_target = 0
            local min_pressure = math.huge
            local max_pressure = 0
            for state_index = 1, #states do
                local path_options = { restarts = 4, iterations = 500,
                    seed = 20260720 + level_index * 7919 + state_index * 101 }
                local effective_target, evaluation = difficulty.target_for(config, figures,
                    states[state_index], path_options)
                local reachable = evaluation.estimated_peaks[desired]
                max_before = math.max(max_before,
                    desired > 1 and evaluation.estimated_peaks[desired - 1] or 0)
                min_reachable = math.min(min_reachable, reachable)
                min_target = math.min(min_target, effective_target)
                max_target = math.max(max_target, effective_target)
                min_pressure = math.min(min_pressure, effective_target / reachable)
                max_pressure = math.max(max_pressure, effective_target / reachable)
            end
            local desired_pressure = config.recovery and 0.55
                or config.hard and 0.84 or 0.72
            local verdict
            if level_index == 1 then
                verdict = "TUTORIAL"
            elseif max_pressure > desired_pressure + 0.08 then
                verdict = "TOO HARD"
            elseif not config.recovery and min_pressure < desired_pressure - 0.10 then
                verdict = "TOO EASY"
            else
                verdict = "OK"
            end
            local targets = min_target == max_target and tostring(min_target)
                or string.format("%d-%d", min_target, max_target)
            local pressures = string.format("%.2f-%.2f", min_pressure, max_pressure)
            print(string.format("%3d  %5d  %11s  %4d  %6d  %5d  %8s  %s",
                level_index, #states, targets, desired, max_before,
                min_reachable, pressures, verdict))
        end
        if config.hard then
            states = add_choice_states(states, level_index)
        end
    end
    return
end

print("LVL  TARGET  HAND  NEED  EARLY  FULL  RATIO  RATING")
for level_index, config in ipairs(levels.configs) do
    local figures = config.figures
    if level_index >= from_level and level_index <= to_level then
        options.seed = 20260720 + level_index * 7919
        local effective_target, evaluation = difficulty.target_for(config, figures,
            owned_gambits, options)
        local required = evaluation.required_pieces
            and tostring(evaluation.required_pieces) or "-"
        local suffix = ""
        if suggest then
            local desired = config.recovery and math.max(2, #figures - 1) or #figures
            local pressure = config.recovery and 0.65 or 0.74
            suffix = string.format("  SUGGEST %s (need %d)",
                tostring(difficulty.suggest_target(evaluation, desired, pressure)), desired)
        end
        print(string.format("%3d  %6d  %4d  %4s  %5d  %4d  %5.2f  %-11s%s",
            level_index, effective_target, #figures, required, evaluation.early_peak,
            evaluation.full_peak, evaluation.target_ratio, evaluation.label, suffix))
    end

    if config.hard and not no_gambits then
        local choices = gambits.reward_choices(owned_gambits, level_index)
        owned_gambits[choices[1].id] = true
    end
end
