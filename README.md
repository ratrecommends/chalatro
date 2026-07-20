# Chalatro

A tiny Defold prototype for a chess-placement roguelike.

## Play

1. Build and run the project from Defold.
2. Either drag a statue from the **HAND** onto the board, or click it to select it and click a board cell.
3. Hover over an empty board cell while dragging or after selection to preview gained and blocked attack rays.
4. Read the preview as **Attack × Defense = Score**.
5. Release over—or click—the board cell to place the statue.
6. Reach the level target, then click the score panel to begin the next level.

All visible elements—including labels and panels—are Defold game objects rather than GUI nodes. The layout is calculated with `logic/game/layout.lua`.

## Active Gambits

- **Defense:** every friendly protection link adds +1 Defense.
- **Phalanx:** each reciprocal protection pair adds another +1 Defense.
- **Laurel:** each attacked tile adds +1 Attack.
- **Oracle:** placing a Bishop adds +1 Defense.

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
search.
