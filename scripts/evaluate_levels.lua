package.path = "./?.lua;" .. package.path

local difficulty = require "logic.game.difficulty"
local levels = require "logic.game.levels"

local figures = {}
for i = 1, #levels.starting_figures do
    figures[i] = levels.starting_figures[i]
end
local gambits = {}
for id, enabled in pairs(levels.starting_gambits) do
    gambits[id] = enabled
end

local suggest = false
local fast = false
local from_level = 1
local to_level = #levels.configs
local argument_index = 1
while arg and argument_index <= #arg do
    local argument = arg[argument_index]
    if argument == "--suggest" then
        suggest = true
    elseif argument == "--fast" then
        fast = true
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
local options = fast and { restarts = 4, iterations = 350 }
    or { restarts = 10, iterations = 1100 }

assert(difficulty.self_test())
print("LVL  TARGET  HAND  NEED  EARLY  FULL  RATIO  RATING")
for level_index, config in ipairs(levels.configs) do
    if level_index >= from_level and level_index <= to_level then
        options.seed = 20260720 + level_index * 7919
        local evaluation = difficulty.evaluate(config, figures, gambits, options)
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
            level_index, config.target, #figures, required, evaluation.early_peak,
            evaluation.full_peak, evaluation.target_ratio, evaluation.label, suffix))
    end

    local reward = config.reward
    if reward and reward.type == "figure" then
        figures[#figures + 1] = reward.id
    elseif reward and reward.type == "gambit" then
        gambits[reward.id] = true
    end
end
