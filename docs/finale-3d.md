# Final arc: 3D presentation

Chapters 3–6 now share the existing FinaleSession through an optional continuous 3D view.
Enter with the chapter's 3D button. WASD/arrows/left stick move; E/A chooses the first nearby
action or advances dialogue. Alternative choices use the displayed buttons. Tab/B returns
to the notebook for manual save/load. There is no autosave or saved player position.

## Sets and evidence boundaries

- Chapter 3 uses a compact photo-studio workspace for letters, scanner/photos, report/map,
  diagram and conversation. References to the convenience store/lighthouse remain in dialogue.
  Shiori leaves only after the committed refusal violation. Photos are abstract props, not new
  identifiable portraits or evidence.
- Chapter 4 uses a bounded breakwater with backup cabinet, ladder handle, covered observation
  stand and an exit point. The playable slab is a staging space, not an exact engineering model.
  Lamp and ladder reflect committed preparations only during the historical window. The status
  names the window and the idle text preserves the early-confirmation warning. The far platform
  and sister are never drawn: the explicit observation is conveyed by the existing dialogue.
  Free movement cannot confirm a route or sister's fate. Closed windows return to the present.
- Chapter 5 combines the evening store and archive workspace: source packet, telephone, old
  report plus separate correction, family table. Sealing leaves the records intact. Identity
  verification remains textual, with no graphic imagery. No sister appears just because a
  contact letter was sent.
- Chapter 6 places the memorial, camera and bus stop together. The inscription marker appears
  only after writing; the actual fact-appropriate wording is in dialogue/notebook. Shiori's
  presence respects the earlier boundary choice. All four endings play their original lines
  and leave a named completion screen; the autumn kitchen epilogue is textual, not a new cutscene.

All art is original code-native low-poly geometry. No imported models or plugins. The last four
sets are silent, like the keeper office; audio design and voice acting are outstanding. These are
playable prototype sets, not finished cinematic environments. Default visual review is 1280×720;
the text notebook remains the smaller-window/accessibility fallback.

## Architecture and tests

`finale_interactions.gd` maps every authored action to a reachable area, intersected with
`session.can_act`. `finale_view.gd` replaces only presentation nodes on chapter change and resets
the physical avatar. No domain, story, save schema or event log changes. Returning to records,
loading or restarting disposes the old 3D view to prevent hidden input and stale session use.

The mandatory headless suite traverses all four endings through actual spatial action buttons,
tests pending observations, room disposal, relationship art, remote-action rejection and nested
navigation. Existing domain tests retain exhaustive route/save checks. The visual workflow
renders legally played routes with Mesa/Xvfb and checks screen bounds for visible dialogue and
action controls. Its `finale-previews` artifact retains screenshots for 14 days. Physical GPU,
controller and audio QA across all target machines remains a separate production step.
