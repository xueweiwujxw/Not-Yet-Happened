# Dialogue performance completion review

Reviewed the final runtime, production adapter, manifests, source assets, CI changes and tests.
The change is limited to dialogue presentation and audition production; chapter text, domain
facts, event logs and save revisions remain unchanged.

## Findings and resolution

- Multi-speaker recordings were selected per story block. The spatial UI now selects exact
  speaker/text turns and cancels queued playback before advancing; narration stays silent.
- Refresh must preserve the local turn while a canonical advance must reset it, even for
  repeated text. The cursor preserves refresh state and the view explicitly clears it before
  advancing to a new block. Only the final turn commits the canonical event.
- Generation failures must not publish a partial catalog. Candidates are resumable with
  recipe/content hashes, bounded transient retries and catalog publication after all takes.
- Legacy voice assets remain for compatibility tests, but the new UI never falls back to them.
- An earlier intermittent ObjectDB shutdown warning was investigated with a verbose full run
  and an actual rendered run. Neither final run reproduced it; no warnings were suppressed.

## Validation

- Godot 4.5.1: all 29 suites passed, including turn progression, facts/save compatibility,
  replay/cancellation, full 87-turn coverage, audio decoding and provenance checksums.
- Python: all 8 offline production tests passed.
- Actual 1280x720 Godot captures show arrival speakers 栞 / 林澈 / 栞 with one turn per input,
  separate nameplate and turn count. Captures use Mesa software rendering; its unsupported
  V-Sync warning is a display-driver limitation, not an application diagnostic.
- `git diff --check` passed. No caches, build products or credentials are included.

## Decision and limitations

No blocking code-review findings remain. Submit for PR review; do not claim a main-branch merge.
This branch depends on the playability/guidance branch (PR #30).

All 87 source recordings use explicit zh-CN voices, but automated validation does not establish
natural acting or native pronunciation. Listening approval remains pending. Female roles share
two available voices, and child casting is provisional. Auditions retain the existing default-off
setting. The reading cursor is local: returning from the notebook or loading restarts the current
canonical block. Scene staging still follows that block rather than individual speaker turns.
