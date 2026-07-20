local M = {}

M.starting_figures = { "pawn", "pawn" }
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
    {
        target = 1,
        obstacles = OPEN,
        reward = { type = "figure", id = "bishop", name = "BISHOP" },
    },
    {
        target = 35,
        obstacles = O2,
        reward = { type = "gambit", id = "phalanx", name = "PHALANX" },
    },
    {
        target = 55,
        obstacles = OPEN,
        reward = { type = "figure", id = "knight", name = "KNIGHT" },
    },
    {
        target = 120,
        obstacles = O4,
        reward = { type = "figure", id = "queen", name = "QUEEN" },
    },
    {
        target = 245,
        obstacles = O3,
        recovery = true,
        reward = { type = "gambit", id = "oracle", name = "ORACLE" },
    },
    {
        target = 360,
        obstacles = O6,
        reward = { type = "figure", id = "rook", name = "ROOK" },
    },
    { target = 680, obstacles = OPEN },
    { target = 625, obstacles = O5 },
    { target = 700, obstacles = O2,
        reward = { type = "figure", id = "bishop", name = "BISHOP" } },
    { target = 665, obstacles = O7, recovery = true },
    { target = 975, obstacles = OPEN },
    { target = 885, obstacles = O6,
        reward = { type = "figure", id = "knight", name = "KNIGHT" } },
    { target = 1165, obstacles = O3 },
    { target = 985, obstacles = O8 },
    { target = 960, obstacles = OPEN, recovery = true,
        reward = { type = "figure", id = "rook", name = "ROOK" } },
    { target = 1665, obstacles = O7 },
    { target = 1525, obstacles = O2 },
    { target = 1390, obstacles = O9,
        reward = { type = "figure", id = "queen", name = "QUEEN" } },
    { target = 2105, obstacles = OPEN, recovery = true },
    { target = 1965, obstacles = O8 },
    { target = 2370, obstacles = O4,
        reward = { type = "figure", id = "king", name = "KING" } },
    { target = 2240, obstacles = O10, recovery = true },
    { target = 3130, obstacles = OPEN },
    { target = 2475, obstacles = O8,
        reward = { type = "figure", id = "bishop", name = "BISHOP" } },
    { target = 2740, obstacles = O3, recovery = true },
    { target = 2960, obstacles = O11 },
    { target = 3660, obstacles = OPEN,
        reward = { type = "figure", id = "knight", name = "KNIGHT" } },
    { target = 3480, obstacles = O9 },
    { target = 3915, obstacles = O5 },
    { target = 3000, obstacles = O12, recovery = true },
}

function M.self_test()
    assert(#M.starting_figures > 0, "progression needs at least one starting figure")
    assert(#M.configs == 30, "campaign must contain thirty levels")
    local previous_target
    local previous_obstacle_count
    local target_rose = false
    local target_fell = false
    local obstacles_appeared = false
    local obstacles_cleared = false
    for _, config in ipairs(M.configs) do
        assert(config.target > 0, "level target must be positive")
        assert(config.recovery == nil or config.recovery == true,
            "recovery must be true when present")
        if config.reward then
            assert(config.reward.id and config.reward.name,
                "level rewards need an id and name")
            assert(config.reward.type == "figure" or config.reward.type == "gambit",
                "reward must be a figure or gambit")
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
    return true
end

return M
