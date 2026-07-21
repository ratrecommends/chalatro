local chess = require "logic.game.chess"

local M = {}

local RNG_MODULUS = 2147483647
local RNG_MULTIPLIER = 16807

local function make_rng(seed)
    local state = math.floor(seed or 1) % RNG_MODULUS
    if state <= 0 then
        state = 1
    end
    return {
        float = function()
            state = state * RNG_MULTIPLIER % RNG_MODULUS
            return (state - 1) / (RNG_MODULUS - 1)
        end,
        integer = function(_, limit)
            state = state * RNG_MULTIPLIER % RNG_MODULUS
            return math.floor((state - 1) / (RNG_MODULUS - 1) * limit) + 1
        end,
    }
end

local function obstacle_map(config)
    local obstacles = {}
    for i = 1, #(config.obstacles or {}) do
        local cell = config.obstacles[i]
        obstacles[chess.key(cell[1], cell[2])] = true
    end
    return obstacles
end

local function open_cells(obstacles)
    local cells = {}
    for row = 1, 8 do
        for column = 1, 8 do
            local key = chess.key(column, row)
            if not obstacles[key] then
                cells[#cells + 1] = key
            end
        end
    end
    return cells
end

local function shuffle(values, rng)
    for i = #values, 2, -1 do
        local j = rng:integer(i)
        values[i], values[j] = values[j], values[i]
    end
end

local function initial_state(figure_count, cells, placed_count, rng)
    local figure_indices = {}
    for i = 1, figure_count do
        figure_indices[i] = i
    end
    shuffle(figure_indices, rng)

    local shuffled_cells = {}
    for i = 1, #cells do
        shuffled_cells[i] = cells[i]
    end
    shuffle(shuffled_cells, rng)

    local state = { figures = {}, positions = {} }
    for i = 1, placed_count do
        state.figures[i] = figure_indices[i]
        state.positions[i] = shuffled_cells[i]
    end
    return state
end

local function score_state(state, figures, gambits, obstacles)
    local board = {}
    for i = 1, #state.figures do
        board[state.positions[i]] = figures[state.figures[i]]
    end
    return chess.score_board(board, gambits, obstacles)
end

local function selected_figure_indices(state)
    local selected = {}
    for i = 1, #state.figures do
        selected[state.figures[i]] = true
    end
    return selected
end

local function occupied_positions(state, ignored_slot)
    local occupied = {}
    for i = 1, #state.positions do
        if i ~= ignored_slot then
            occupied[state.positions[i]] = true
        end
    end
    return occupied
end

local function mutate(state, figures, cells, rng)
    local mutation_roll = rng.float()
    if mutation_roll < 0.55 then
        local slot = rng:integer(#state.positions)
        local occupied = occupied_positions(state, slot)
        local old_position = state.positions[slot]
        local new_position
        repeat
            new_position = cells[rng:integer(#cells)]
        until not occupied[new_position]
        state.positions[slot] = new_position
        return function()
            state.positions[slot] = old_position
        end
    elseif mutation_roll < 0.78 and #state.positions > 1 then
        local first = rng:integer(#state.positions)
        local second
        repeat
            second = rng:integer(#state.positions)
        until second ~= first
        state.positions[first], state.positions[second] =
            state.positions[second], state.positions[first]
        return function()
            state.positions[first], state.positions[second] =
                state.positions[second], state.positions[first]
        end
    end

    local selected = selected_figure_indices(state)
    if #state.figures == #figures then
        return function() end
    end
    local slot = rng:integer(#state.figures)
    local replacement
    repeat
        replacement = rng:integer(#figures)
    until not selected[replacement]
    local old_figure = state.figures[slot]
    state.figures[slot] = replacement
    return function()
        state.figures[slot] = old_figure
    end
end

local function estimate_peak(config, figures, gambits, placed_count, options)
    local obstacles = obstacle_map(config)
    local cells = open_cells(obstacles)
    assert(placed_count <= #figures, "cannot place more figures than are available")
    assert(placed_count <= #cells, "not enough open cells for the requested figures")

    local restarts = options.restarts or 8
    local iterations = options.iterations or 900
    local seed = (options.seed or 1729) + placed_count * 104729
        + #(config.obstacles or {}) * 1009
    local rng = make_rng(seed)
    local best_score = nil

    for _ = 1, restarts do
        local state = initial_state(#figures, cells, placed_count, rng)
        local score = score_state(state, figures, gambits, obstacles)
        local current_total = score.total
        if not best_score or current_total > best_score.total then
            best_score = score
        end

        for iteration = 1, iterations do
            local undo = mutate(state, figures, cells, rng)
            local candidate = score_state(state, figures, gambits, obstacles)
            local delta = candidate.total - current_total
            local progress = iteration / iterations
            local temperature = math.max(1, (best_score.total + 20) * 0.10 * (1 - progress))
            if delta >= 0 or rng.float() < math.exp(delta / temperature) then
                current_total = candidate.total
                if candidate.total > best_score.total then
                    best_score = candidate
                end
            else
                undo()
            end
        end
    end

    return best_score
end

function M.evaluate(config, figures, gambits, options)
    assert(config and config.target, "difficulty evaluation needs a level config")
    assert(figures and #figures > 0, "difficulty evaluation needs available figures")
    options = options or {}

    local peaks = {}
    local peak_details = {}
    for placed_count = 1, #figures do
        local result = estimate_peak(config, figures, gambits or {}, placed_count, options)
        peaks[placed_count] = result.total
        peak_details[placed_count] = result
    end

    local score_required_pieces
    for placed_count = 1, #figures do
        if peaks[placed_count] >= config.target then
            score_required_pieces = placed_count
            break
        end
    end

    local required_pieces = score_required_pieces
    local full_peak = peaks[#figures]
    local early_peak = #figures > 1 and peaks[#figures - 1] or 0
    local winning_peak = required_pieces and peaks[required_pieces] or 0
    local target_ratio = full_peak > 0
        and config.target / full_peak or math.huge
    local label
    if not required_pieces then
        label = "UNREACHABLE"
    elseif config.recovery then
        label = "RECOVERY"
    elseif required_pieces <= math.max(1, #figures - 2) then
        label = "TOO EASY"
    elseif required_pieces == #figures - 1 then
        label = "RELAXED"
    elseif target_ratio < 0.76 then
        label = "FAIR"
    elseif target_ratio < 0.87 then
        label = "HARD"
    else
        label = "BRUTAL"
    end

    return {
        available_pieces = #figures,
        required_pieces = required_pieces,
        score_required_pieces = score_required_pieces,
        estimated_peaks = peaks,
        peak_details = peak_details,
        early_peak = early_peak,
        full_peak = full_peak,
        winning_peak = winning_peak,
        target = config.target,
        target_ratio = target_ratio,
        label = label,
    }
end

function M.suggest_target(evaluation, desired_pieces, pressure)
    pressure = pressure or 0.82
    assert(desired_pieces >= 1 and desired_pieces <= evaluation.available_pieces,
        "desired piece count must be in the available hand")
    local reachable_peak = evaluation.estimated_peaks[desired_pieces]
    local target = math.floor(reachable_peak * pressure)
    return math.max(1, math.floor((target + 4) / 5) * 5)
end

function M.retarget(evaluation, config, target)
    local required_pieces
    for placed_count = 1, evaluation.available_pieces do
        if evaluation.estimated_peaks[placed_count] >= target then
            required_pieces = placed_count
            break
        end
    end

    evaluation.required_pieces = required_pieces
    evaluation.score_required_pieces = required_pieces
    evaluation.winning_peak = required_pieces
        and evaluation.estimated_peaks[required_pieces] or 0
    evaluation.target = target
    evaluation.target_ratio = evaluation.full_peak > 0
        and target / evaluation.full_peak or math.huge
    if not required_pieces then
        evaluation.label = "UNREACHABLE"
    elseif config.recovery then
        evaluation.label = "RECOVERY"
    elseif required_pieces <= math.max(1, evaluation.available_pieces - 2) then
        evaluation.label = "TOO EASY"
    elseif required_pieces == evaluation.available_pieces - 1 then
        evaluation.label = "RELAXED"
    elseif evaluation.target_ratio < 0.76 then
        evaluation.label = "FAIR"
    elseif evaluation.target_ratio < 0.87 then
        evaluation.label = "HARD"
    else
        evaluation.label = "BRUTAL"
    end
    return evaluation
end

function M.target_for(config, figures, gambits, options)
    if config.fixed_target then
        return config.target, M.evaluate(config, figures, gambits, options)
    end

    local evaluation = M.evaluate(config, figures, gambits, options)
    local desired_pieces = config.recovery and math.max(2, #figures - 1) or #figures
    local pressure = config.recovery and 0.55 or config.hard and 0.84 or 0.72
    local target = M.suggest_target(evaluation, desired_pieces, pressure)
    return target, M.retarget(evaluation, config, target)
end

function M.self_test()
    local evaluation = M.evaluate({ target = 1, obstacles = {} },
        { "pawn", "pawn" }, {}, { restarts = 3, iterations = 120, seed = 7 })
    assert(evaluation.full_peak >= 4, "two pawns should find their known peak score")
    assert(evaluation.required_pieces == 2, "a defended score needs both pawns")
    assert(evaluation.label ~= "UNREACHABLE", "the tutorial must be reachable")

    local recovery = M.evaluate({ target = 1, obstacles = {}, recovery = true },
        { "pawn", "pawn", "bishop" }, {},
        { restarts = 3, iterations = 120, seed = 11 })
    assert(recovery.label == "RECOVERY", "recovery flag should affect the rating")
    local fixed_target = M.target_for({ target = 30, obstacles = {}, fixed_target = true },
        { "pawn", "pawn", "bishop" }, {},
        { restarts = 3, iterations = 120, seed = 13 })
    assert(fixed_target == 30, "fixed opening targets must not be recalibrated")
    return true
end

return M
