local M = {}

M.definitions = {
    {
        id = "phalanx",
        animation = "gambit_phalanx",
        name = "PHALANX",
        description = {
            "Reciprocal defending pairs gain",
            "+1 additional Defense.",
        },
    },
    {
        id = "oracle",
        animation = "gambit_oracle",
        name = "ORACLE",
        description = {
            "Each Bishop on the board",
            "adds +1 Defense.",
        },
    },
    {
        id = "royal_guard",
        animation = "gambit_royal_guard",
        name = "ROYAL GUARD",
        description = {
            "Each figure defended by a King",
            "adds +1 Attack.",
        },
    },
    {
        id = "cavalry",
        animation = "gambit_cavalry",
        name = "CAVALRY",
        description = {
            "Each Knight on the board",
            "adds +2 Attack.",
        },
    },
    {
        id = "bastion",
        animation = "gambit_bastion",
        name = "BASTION",
        description = {
            "Each Rook on the board",
            "adds +1 Defense.",
        },
    },
    {
        id = "regency",
        animation = "gambit_regency",
        name = "REGENCY",
        description = {
            "Each Queen on the board",
            "adds +2 Attack.",
        },
    },
    {
        id = "vanguard",
        animation = "gambit_vanguard",
        name = "VANGUARD",
        description = {
            "Each Pawn on the board",
            "adds +1 Defense.",
        },
    },
    {
        id = "concord",
        animation = "gambit_concord",
        name = "CONCORD",
        description = {
            "Each different figure type",
            "adds +1 Attack.",
        },
    },
}

local by_id = {}
for i = 1, #M.definitions do
    by_id[M.definitions[i].id] = M.definitions[i]
end

function M.by_id(id)
    return by_id[id]
end

function M.reward_choices(owned, level_index)
    local available = {}
    for i = 1, #M.definitions do
        local definition = M.definitions[i]
        if not owned[definition.id] then
            available[#available + 1] = definition
        end
    end
    assert(#available >= 2, "hard level needs two unowned gambit choices")

    local first_index = ((level_index or 1) * 3 - 1) % #available + 1
    local second_index = first_index % #available + 1
    return { available[first_index], available[second_index] }
end

function M.self_test()
    assert(#M.definitions >= 8, "campaign needs a varied gambit pool")
    local seen = {}
    for i = 1, #M.definitions do
        local definition = M.definitions[i]
        assert(definition.id and definition.name and definition.animation,
            "gambits need an id, name, and animation")
        assert(#definition.description >= 2, "gambits need a useful description")
        assert(not seen[definition.id], "gambit ids must be unique")
        seen[definition.id] = true
    end
    local choices = M.reward_choices({}, 4)
    assert(#choices == 2 and choices[1].id ~= choices[2].id,
        "hard rewards need two distinct choices")
    return true
end

return M
