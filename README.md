# Chalatro

A tiny Defold prototype for a chess-placement roguelike.

## Play

1. Build and run the project from Defold.
2. Either drag a statue from the **HAND** onto the board, or click it to select it and click a board cell.
3. Hover over an empty board cell while dragging or after selection to preview gained and blocked attack rays.
4. Read the preview as **Attack × Defense = Score**.
5. Release over—or click—the board cell to place the statue.
6. Reach the level target to complete the level. Hard trials then offer a choice of one of two Gambits.

All visible elements—including labels and panels—are Defold game objects rather than GUI nodes. The layout is calculated with `logic/game/layout.lua`.

## Active Gambits

- **Phalanx:** each reciprocal defending pair adds +1 Defense.
- **Oracle:** each Bishop adds +1 Defense.
- **Royal Guard:** each figure defended by a King adds +1 Attack.
- **Cavalry:** each Knight adds +2 Attack.
- **Bastion:** each Rook adds +1 Defense.
- **Regency:** each Queen adds +2 Attack.
- **Vanguard:** each Pawn adds +1 Defense.
- **Concord:** each different figure type adds +1 Attack.

Hard trials use a darker board theme and reward one Gambit chosen from two described options. Normal trials have no reward; every level supplies its own puzzle-specific piece set.

Generated production assets live in `assets/images/`; their source sheets and concept iterations live in `art/`.

The displayed score is recomputed from the entire current board. Adding a blocker can remove a sliding piece's attack cells and lower the total score.

## Level Evaluation

Run the deterministic campaign evaluator from the project root:

```sh
lua scripts/evaluate_levels.lua --fast
```

The report estimates the best score at every playable figure count, then shows
the minimum figures estimated to reach the score target. This is a balancing
measurement, not an additional win condition. `RATIO` compares the target with
the estimated full-hand peak. Use `--suggest` to print recalibrated targets, or
`--from 11 --to 20` to evaluate a smaller campaign range with the deeper default
search used by runtime target calibration.

The opening four levels use exact, fixed targets. Later targets are recalibrated
when a level loads against the player's collected Gambits: normal levels use
72% pressure, hard trials 84%, and recovery levels 55%.

Use `--no-gambits` to evaluate the campaign's worst-case baseline without any
reward bonuses.

Use `--all-paths` to evaluate every reachable hard-trial reward path and print
a target-pressure verdict and breadth-oriented suggestion across all choices.
