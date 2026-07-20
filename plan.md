# Balatro Chess — Tiny Defold Prototype
Build a small Defold game played on a standard 8×8 chessboard.
Each round gives the player a hand of chess pieces drawn from their piece deck.
The player selects a piece and hovers it over an empty square before placing it.
The board previews the piece and highlights every square it would attack.
Attacked squares display their score bonus, including squares with placed pieces.
Attacking a square occupied by your own piece counts as defending it.
Example Gambits award bonuses for defense, mutual defense, or longer defense chains.
Progression grows and improves the player's deck of available chess pieces.
Collectible Gambits bend scoring and placement rules during a run.
Build the board, pieces, highlights, and interaction from Defold game objects (GOs), not GUI nodes.
Use [layout.lua](https://github.com/ratrecommends/caterpilled/blob/main/logic/game/layout.lua) to position and align the game objects.
Each level has a target score shown alongside the current score and progress.
Screen layout: equipped Gambits on the left, board in the center, and loose hand figures on the right.
Start each level with an empty board and show `+1` directly on every attacked tile.
Recompute board score as Attack × Defense; Defense starts at 1 and grows through reciprocal protection.

# Defold
Editor server: http://localhost:$(cat .internal/editor.port)/openapi.json
