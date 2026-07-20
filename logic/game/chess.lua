local M = {}

local DIRECTIONS = {
    rook = {
        { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
    },
    bishop = {
        { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 },
    },
}

local KNIGHT_STEPS = {
    { 1, 2 }, { 2, 1 }, { 2, -1 }, { 1, -2 },
    { -1, -2 }, { -2, -1 }, { -2, 1 }, { -1, 2 },
}

local KING_STEPS = {
    { 1, 0 }, { 1, 1 }, { 0, 1 }, { -1, 1 },
    { -1, 0 }, { -1, -1 }, { 0, -1 }, { 1, -1 },
}

function M.key(column, row)
    return row * 10 + column
end

function M.inside(column, row)
    return column >= 1 and column <= 8 and row >= 1 and row <= 8
end

local function add_step(attacks, column, row, dc, dr)
    local target_column = column + dc
    local target_row = row + dr
    if M.inside(target_column, target_row) then
        attacks[#attacks + 1] = { column = target_column, row = target_row }
    end
end

local function add_steps(attacks, column, row, steps)
    for i = 1, #steps do
        add_step(attacks, column, row, steps[i][1], steps[i][2])
    end
end

local function add_rays(attacks, board, obstacles, column, row, directions)
    for i = 1, #directions do
        local dc = directions[i][1]
        local dr = directions[i][2]
        local target_column = column + dc
        local target_row = row + dr
        while M.inside(target_column, target_row) do
            attacks[#attacks + 1] = { column = target_column, row = target_row }
            local target_key = M.key(target_column, target_row)
            if board[target_key] or (obstacles and obstacles[target_key]) then
                break
            end
            target_column = target_column + dc
            target_row = target_row + dr
        end
    end
end

function M.attacks(piece, column, row, board, obstacles)
    local attacks = {}
    if piece == "pawn" then
        add_step(attacks, column, row, -1, 1)
        add_step(attacks, column, row, 1, 1)
    elseif piece == "knight" then
        add_steps(attacks, column, row, KNIGHT_STEPS)
    elseif piece == "bishop" then
        add_rays(attacks, board, obstacles, column, row, DIRECTIONS.bishop)
    elseif piece == "rook" then
        add_rays(attacks, board, obstacles, column, row, DIRECTIONS.rook)
    elseif piece == "queen" then
        add_rays(attacks, board, obstacles, column, row, DIRECTIONS.rook)
        add_rays(attacks, board, obstacles, column, row, DIRECTIONS.bishop)
    elseif piece == "king" then
        add_steps(attacks, column, row, KING_STEPS)
    else
        error("unknown chess piece: " .. tostring(piece))
    end
    return attacks
end

local function increment(counts, key, amount)
    counts[key] = (counts[key] or 0) + (amount or 1)
end

local function decode_key(key)
    local row = math.floor(key / 10)
    return key - row * 10, row
end

function M.score_board(board, gambits, obstacles)
    local attack_counts = {}
    local defense_counts = {}
    local relations = {}
    local attack = 0
    local oracle_bonus = 0
    local protection_links = 0

    for source_key, piece in pairs(board) do
        local column, row = decode_key(source_key)
        local cells = M.attacks(piece, column, row, board, obstacles)
        relations[source_key] = {}
        if piece == "bishop" and gambits and gambits.oracle then
            oracle_bonus = oracle_bonus + 1
            increment(defense_counts, source_key)
        end
        for i = 1, #cells do
            local cell = cells[i]
            local target_key = M.key(cell.column, cell.row)
            increment(attack_counts, target_key)
            attack = attack + 1
            if board[target_key] then
                relations[source_key][target_key] = true
                protection_links = protection_links + 1
                increment(defense_counts, target_key)
            end
        end
    end

    local mutual_pairs = 0
    for source_key, targets in pairs(relations) do
        for target_key in pairs(targets) do
            if source_key < target_key and relations[target_key] and relations[target_key][source_key] then
                mutual_pairs = mutual_pairs + 1
                if gambits and gambits.phalanx then
                    increment(defense_counts, source_key)
                    increment(defense_counts, target_key)
                end
            end
        end
    end

    local phalanx_bonus = gambits and gambits.phalanx and mutual_pairs or 0
    local defense = protection_links + phalanx_bonus + oracle_bonus
    return {
        attack = attack,
        defense = defense,
        protection_links = protection_links,
        mutual_pairs = mutual_pairs,
        oracle_bonus = oracle_bonus,
        total = attack * defense,
        attack_counts = attack_counts,
        defense_counts = defense_counts,
    }
end

local function copy_board(board)
    local copy = {}
    for key, piece in pairs(board) do
        copy[key] = piece
    end
    return copy
end

local function add_delta_keys(keys, counts)
    for key in pairs(counts) do
        keys[key] = true
    end
end

function M.preview(piece, column, row, board, gambits, obstacles)
    assert(not board[M.key(column, row)], "preview target must be empty")
    assert(not obstacles or not obstacles[M.key(column, row)], "preview target must not be an obstacle")
    local before = M.score_board(board, gambits, obstacles)
    local hypothetical = copy_board(board)
    hypothetical[M.key(column, row)] = piece
    local after = M.score_board(hypothetical, gambits, obstacles)
    after.delta_total = after.total - before.total

    local keys = {}
    add_delta_keys(keys, before.attack_counts)
    add_delta_keys(keys, after.attack_counts)
    add_delta_keys(keys, before.defense_counts)
    add_delta_keys(keys, after.defense_counts)

    local cells = {}
    for key in pairs(keys) do
        local attack_delta = (after.attack_counts[key] or 0) - (before.attack_counts[key] or 0)
        local defense_delta = (after.defense_counts[key] or 0) - (before.defense_counts[key] or 0)
        if attack_delta ~= 0 or defense_delta ~= 0 then
            local target_column, target_row = decode_key(key)
            cells[#cells + 1] = {
                column = target_column,
                row = target_row,
                attack_delta = attack_delta,
                defense_delta = defense_delta,
            }
        end
    end
    table.sort(cells, function(a, b)
        return a.row == b.row and a.column < b.column or a.row < b.row
    end)
    return cells, after, before
end

local function contains(cells, column, row)
    for i = 1, #cells do
        if cells[i].column == column and cells[i].row == row then
            return true
        end
    end
    return false
end

function M.self_test()
    local blocked_board = {
        [M.key(4, 6)] = "pawn",
    }
    local rook_cells = M.attacks("rook", 4, 4, blocked_board)
    assert(contains(rook_cells, 4, 6), "sliding attacks include the blocking friendly piece")
    assert(not contains(rook_cells, 4, 7), "sliding attacks stop after a blocking piece")

    local rook_board = {
        [M.key(1, 1)] = "rook",
    }
    local rook_score = M.score_board(rook_board)
    assert(rook_score.attack == 14 and rook_score.defense == 0 and rook_score.total == 0,
        "an undefended corner rook starts at fourteen attack times zero defense")

    local blocked_rook_board = {
        [M.key(1, 1)] = "rook",
        [M.key(1, 2)] = "pawn",
    }
    local blocked_score = M.score_board(blocked_rook_board)
    assert(blocked_score.attack == 9, "a pawn blocks the rook ray beyond it")
    assert(blocked_score.protection_links == 1 and blocked_score.defense == 1,
        "every one-way friendly protection adds defense")

    local preview_cells, preview_score = M.preview("pawn", 1, 2, rook_board)
    assert(preview_score.delta_total == 9, "the blocker preview includes its defense bonus")
    assert(contains(preview_cells, 1, 3), "the blocker preview includes lost ray cells")

    local pawn_defends_knight = {
        [M.key(4, 4)] = "pawn",
        [M.key(5, 5)] = "knight",
    }
    local defended_score = M.score_board(pawn_defends_knight)
    assert(defended_score.protection_links == 1 and defended_score.defense == 1,
        "a pawn defending a knight always grants defense")
    assert(defended_score.defense_counts[M.key(5, 5)] == 1,
        "the defended knight receives the defense marker")

    local mutual_rooks = {
        [M.key(1, 1)] = "rook",
        [M.key(1, 8)] = "rook",
    }
    local mutual_score = M.score_board(mutual_rooks, { phalanx = true })
    assert(mutual_score.protection_links == 2 and mutual_score.mutual_pairs == 1
        and mutual_score.defense == 3,
        "Phalanx increases the bonus for a reciprocal protection pair")

    local bishop_score = M.score_board({ [M.key(4, 4)] = "bishop" }, { oracle = true })
    assert(bishop_score.attack == 13, "a central bishop attacks thirteen empty cells")
    assert(bishop_score.defense == 1, "Oracle gives bishops one additional defense")
    assert(bishop_score.total == 13, "Oracle participates in multiplicative scoring")

    local obstacles = { [M.key(1, 3)] = true }
    local obstacle_cells = M.attacks("rook", 1, 1, {}, obstacles)
    assert(contains(obstacle_cells, 1, 3), "a ray reaches the blocking stone")
    assert(not contains(obstacle_cells, 1, 4), "a ray cannot pass through a blocking stone")
    return true
end

return M
