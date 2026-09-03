# 老屋厨房 · First 3D art slice

## Direction and scope

A warm cutaway diorama: oak flooring, sage cabinets, cream plaster, a terracotta rug and pendant,
teal sea through an open window, a battered radio and small faceted characters. The quiet domestic
scene supports the first chapter's uncertain memories without using horror effects.

All meshes and materials are original procedural Godot primitives in `src/art/`. No downloaded
model packs, generated raster artwork, or new runtime dependencies are required. The existing
licensed Noto subset is extended for the new UI. This is an art/proportion pass, not final character
animation or a fully modelled town. Chapters two through six retain their existing text interface.

## Play and ownership

From the chapter-one screen choose **探索 3D 老屋**. Use WASD / arrow keys to move relative to
the fixed camera; approach the door, wall switch, repair area, table, photograph or Shiori to
reveal available actions. E selects the first nearby action or advances dialogue; mouse buttons
select alternatives. Movement pauses during dialogue. Tab or the top-right button opens the
notebook again, where the existing manual save/load and chapter navigation remain available.

`KitchenView` receives the same `ChapterSession`, not a clone. `KitchenInteractions` only filters
proximity; the session remains the authority for action availability and evidence confirmation.
The room projects lamp and arrival state. A mesh/camera never anchors a fact. Closing/reopening
the view retains story state and resets player position. Position/camera are deliberately not
part of the save format; save versions and previous saves remain compatible.

The player has a capsule body, a solid floor and furniture collisions. Open cutaway edges are
bounded. Characters are stylized static figures; walking animation, sound and gamepad controls
are follow-up work. Photo/letter meshes are suggestive props, not readable evidence substitutes.

## Verification

The normal headless suite covers session identity, dialogue lock, proximity rejection, unchanged
facts under camera changes, arrival/lamp projection, floor/counter collisions, keyboard return,
and font coverage. Existing chapter, save and ending tests still run unchanged on four platforms.

`tests/render_kitchen.gd` requires a real display; it explicitly rejects headless dummy rendering.
It stages a deterministic repaired/occupied kitchen and captures overview, detail and gameplay
views, plus the default 1280×720 gameplay layout. The `Render kitchen previews` workflow runs it with Xvfb and Mesa software OpenGL, then
uploads `kitchen-previews`. Locally, on a graphical machine:

```bash
bash scripts/check-godot.sh godot --path . --rendering-method gl_compatibility --script tests/render_kitchen.gd
```

Images are written to ignored `build/previews/`. Review composition, readable dialogue and
controls, visible characters and props, lighting and framing before merge. These renders are
actual engine output, not AI concept art. Physical GPU checks on Fedora, Ubuntu, Windows and
macOS, accessibility and human playtesting remain release requirements.
