local M = {}

M.starting_gambits = {}

local OPEN = {}
local O2 = { { 4, 4 }, { 5, 5 } }
local O3 = { { 3, 3 }, { 6, 4 }, { 4, 6 } }
local O4 = { { 2, 4 }, { 4, 6 }, { 5, 3 }, { 7, 5 } }
local O5 = { { 2, 3 }, { 3, 6 }, { 5, 2 }, { 6, 5 }, { 7, 7 } }
local O6 = { { 2, 2 }, { 2, 7 }, { 4, 4 }, { 5, 5 }, { 7, 2 }, { 7, 7 } }
local O7 = {
    { 2, 3 }, { 2, 6 }, { 4, 2 }, { 4, 7 }, { 6, 2 }, { 6, 7 }, { 7, 5 },
}
local O8 = {
    { 2, 2 }, { 2, 7 }, { 3, 4 }, { 4, 6 },
    { 5, 3 }, { 6, 5 }, { 7, 2 }, { 7, 7 },
}
local O9 = {
    { 2, 2 }, { 2, 6 }, { 3, 4 }, { 4, 7 }, { 5, 2 },
    { 5, 5 }, { 6, 3 }, { 7, 6 }, { 7, 8 },
}
local O10 = {
    { 2, 2 }, { 2, 5 }, { 2, 8 }, { 3, 3 }, { 4, 6 },
    { 5, 3 }, { 6, 6 }, { 7, 1 }, { 7, 4 }, { 7, 7 },
}
local O11 = {
    { 1, 4 }, { 2, 2 }, { 2, 7 }, { 3, 5 }, { 4, 3 }, { 5, 6 },
    { 6, 2 }, { 6, 8 }, { 7, 4 }, { 8, 1 }, { 8, 7 },
}
local O12 = {
    { 1, 3 }, { 1, 6 }, { 2, 8 }, { 3, 2 }, { 3, 5 }, { 4, 7 },
    { 5, 3 }, { 6, 1 }, { 6, 6 }, { 7, 4 }, { 8, 2 }, { 8, 7 },
}

-- Targets are calibrated with scripts/evaluate_levels.lua. Difficulty moves in
-- waves, with recovery levels intentionally using lower score pressure.
M.configs = {
    { target = 1, obstacles = OPEN, fixed_target = true,
        figures = { "pawn", "pawn" } },
    { target = 30, obstacles = O2, fixed_target = true,
        figures = { "pawn", "pawn", "bishop" } },
    { target = 60, obstacles = OPEN, fixed_target = true,
        figures = { "pawn", "knight", "bishop" } },
    { target = 100, obstacles = O4, hard = true, fixed_target = true,
        figures = { "pawn", "pawn", "knight", "rook" } },
    { target = 60, obstacles = O3, recovery = true,
        figures = { "pawn", "bishop", "bishop", "knight" } },
    { target = 70, obstacles = O6, figures = { "pawn", "pawn", "queen" } },
    { target = 165, obstacles = OPEN,
        figures = { "rook", "pawn", "bishop", "king" } },
    { target = 145, obstacles = O5, hard = true,
        figures = { "knight", "knight", "pawn", "bishop" } },
    { target = 75, obstacles = O2, figures = { "rook", "rook", "pawn" } },
    { target = 90, obstacles = O7, recovery = true,
        figures = { "queen", "bishop", "pawn", "knight" } },
    { target = 220, obstacles = OPEN,
        figures = { "king", "pawn", "pawn", "bishop", "knight" } },
    { target = 160, obstacles = O6, hard = true,
        figures = { "rook", "bishop", "bishop", "pawn" } },
    { target = 195, obstacles = O3,
        figures = { "queen", "rook", "pawn", "pawn" } },
    { target = 175, obstacles = O8,
        figures = { "knight", "knight", "bishop", "rook" } },
    { target = 120, obstacles = OPEN, recovery = true,
        figures = { "king", "queen", "pawn", "bishop" } },
    { target = 425, obstacles = O7, hard = true,
        figures = { "rook", "rook", "knight", "pawn", "king" } },
    { target = 360, obstacles = O2,
        figures = { "queen", "bishop", "bishop", "knight", "pawn" } },
    { target = 305, obstacles = O9,
        figures = { "king", "king", "rook", "bishop", "pawn" } },
    { target = 235, obstacles = OPEN, recovery = true,
        figures = { "queen", "knight", "knight", "rook", "pawn" } },
    { target = 390, obstacles = O8, hard = true,
        figures = { "rook", "bishop", "knight", "pawn", "pawn", "king" } },
    { target = 330, obstacles = O4,
        figures = { "queen", "queen", "pawn", "bishop" } },
    { target = 180, obstacles = O10, recovery = true,
        figures = { "rook", "rook", "bishop", "bishop", "king" } },
    { target = 470, obstacles = OPEN,
        figures = { "queen", "rook", "knight", "bishop", "pawn" } },
    { target = 530, obstacles = O8, hard = true,
        figures = { "king", "queen", "bishop", "bishop", "pawn", "pawn" } },
    { target = 305, obstacles = O3, recovery = true,
        figures = { "rook", "rook", "knight", "knight", "bishop", "pawn" } },
    { target = 625, obstacles = O11,
        figures = { "queen", "rook", "rook", "king", "pawn", "pawn" } },
    { target = 680, obstacles = OPEN,
        figures = { "queen", "bishop", "bishop", "knight", "king", "pawn" } },
    { target = 815, obstacles = O9, hard = true,
        figures = { "rook", "rook", "bishop", "knight", "king", "pawn", "pawn" } },
    { target = 1000, obstacles = O5,
        figures = { "queen", "queen", "rook", "bishop", "knight", "pawn" } },
    { target = 620, obstacles = O12, recovery = true,
        figures = { "queen", "rook", "rook", "bishop", "bishop", "knight", "king" } },
}

function M.self_test()
    assert(#M.configs == 30, "campaign must contain thirty levels")
    local known_figures = {
        pawn = true, knight = true, bishop = true,
        rook = true, queen = true, king = true,
    }
    local figure_sets = {}
    local hard_level_count = 0
    local previous_target
    local previous_obstacle_count
    local target_rose = false
    local target_fell = false
    local obstacles_appeared = false
    local obstacles_cleared = false
    for _, config in ipairs(M.configs) do
        assert(config.target > 0, "level target must be positive")
        assert(config.figures and #config.figures > 0,
            "every level needs its own figure set")
        local signature_figures = {}
        for i = 1, #config.figures do
            local figure = config.figures[i]
            assert(known_figures[figure], "level contains an unknown figure")
            signature_figures[i] = figure
        end
        table.sort(signature_figures)
        local signature = table.concat(signature_figures, ",")
        assert(not figure_sets[signature], "every level needs a unique figure set")
        figure_sets[signature] = true
        assert(config.recovery == nil or config.recovery == true,
            "recovery must be true when present")
        assert(config.hard == nil or config.hard == true,
            "hard must be true when present")
        assert(config.fixed_target == nil or config.fixed_target == true,
            "fixed_target must be true when present")
        assert(not config.reward, "hard levels award gambit choices dynamically")
        if config.hard then
            hard_level_count = hard_level_count + 1
        end

        local occupied = {}
        for i = 1, #(config.obstacles or {}) do
            local cell = config.obstacles[i]
            assert(cell[1] >= 1 and cell[1] <= 8 and cell[2] >= 1 and cell[2] <= 8,
                "level obstacle must be on the chess board")
            local key = cell[2] * 10 + cell[1]
            assert(not occupied[key], "level obstacles must not overlap")
            occupied[key] = true
        end

        local obstacle_count = #(config.obstacles or {})
        if previous_target then
            target_rose = target_rose or config.target > previous_target
            target_fell = target_fell or config.target < previous_target
            obstacles_appeared = obstacles_appeared
                or previous_obstacle_count == 0 and obstacle_count > 0
            obstacles_cleared = obstacles_cleared
                or previous_obstacle_count > 0 and obstacle_count == 0
        end
        previous_target = config.target
        previous_obstacle_count = obstacle_count
    end
    assert(target_rose and target_fell, "level targets must rise and fall")
    assert(obstacles_appeared and obstacles_cleared,
        "campaign needs transitions between open and obstacle levels")
    assert(hard_level_count == 7, "campaign needs seven hard reward levels")
    return true
end

return M
