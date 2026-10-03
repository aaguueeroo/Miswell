# World Clock and Encounter Progression Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace fixed day slots with a continuous, pausable world clock and establish choice-based encounters whose resolved outcomes can gate future story events.

**Architecture:** `GameSession` owns serializable playthrough state and composes clock, daily-transition, exploration, encounter, and story-progression coordinators. Presentation sends typed requests and renders view data; completed outcomes update current story state and append to the outcome journal, while optional events that expire without resolving leave no record.

**Tech Stack:** Godot 4.6, GDScript, Godot Resources for content/settings, headless `SceneTree` smoke scripts.

**Spec:** `docs/superpowers/specs/2026-10-03-world-clock-encounter-progression-design.md`

## Global Constraints

- Start at Day 1, 08:00.
- Advance at 2 in-game minutes per real second by default; keep the rate configurable in `GameClockSettings`.
- Show Day from 06:00 inclusive to 20:00 exclusive; show Night otherwise. Night changes the indicator only.
- Increment the day at midnight. Do not implement sleep, wake-up, or time skipping at home.
- Advance the world clock only in exploration mode. Encounters and blocking panels pause it and resume at the same in-game time.
- Location actions resolve immediately and keep the existing once-per-day restriction; remove slot booking and picker UI.
- Reset daily action use at midnight. Preserve the existing anxiety cleanup: subtract 12, clear its temporary effect, and reset its timer.
- Record only resolved outcomes as `{event_id, outcome_id, day_number, minute_of_day}`. Expiring optional events create no missed record or absence-based consequence.
- Keep encounter rules and story effects outside Godot presentation scenes. Route player and NPC/world starts through one encounter coordinator; do not add a global event bus.
- Remove the fixed Day 3 prototype stop. Keep the first battle presentation structural and minimal: player at bottom, choices below, opponent upper right.
- Preserve concurrent map, UI, README, and asset changes. Before touching a shared file, inspect its current diff and build on top of it. Stage only feature hunks in overlapping files with patch staging; if they cannot be isolated safely, defer that file's commit until the concurrent edit is resolved. Keep map composition and art resources out of scope.

## Review Focus

- **Fractional frame deltas and boundary values:** the clock retains fractions, handles 06:00/20:00 inclusivity, and wraps midnight correctly. Pin this in Task 1 clock-rule tests.
- **Large time advances:** one update that crosses multiple midnights applies each day transition once and in order. Pin this in Task 1 and Task 2 tests.
- **Paused simulation modes:** encounter and blocking-panel updates do not advance clock or anxiety, and exploration resumes at the same time. Pin this in Tasks 2 and 6 tests.
- **Optional event expiry:** an unresolved event becomes unavailable without a journal entry, fact, or family trust/follow-up penalty. Pin this in Task 4 tests.
- **Invalid configuration and stale requests:** non-positive clock rates, out-of-range or reversed day/night boundaries must not corrupt time; stale choices fail without mutation; same-day location repeats remain blocked until midnight. Pin these in Tasks 1, 3, and 5 tests.

---

### Task 1: Add pure clock settings, rules, and result values

**Files:**
- Create: `scripts/domain/game_clock_settings.gd`
- Create: `scripts/domain/clock_advance_result.gd`
- Create: `scripts/domain/game_clock_rules.gd`
- Test: `tests/game_clock_rules_smoke.gd`

**Interfaces:**
- Produces `GameClockSettings` with `start_day_number`, `start_minute_of_day`, `game_minutes_per_real_second`, `day_start_minute`, and `night_start_minute`.
- `GameClockSettings.is_valid() -> bool` accepts only positive rates, a start minute in `0..1439`, and boundaries in `0..1439` where `day_start_minute < night_start_minute`.
- Produces `ClockAdvanceResult` with `day_number`, `minute_of_day`, `fractional_game_minutes`, and `midnights_crossed`.
- Produces `GameClockRules.advance(day_number: int, minute_of_day: int, fractional_game_minutes: float, real_delta: float, settings: GameClockSettings) -> ClockAdvanceResult` and `GameClockRules.phase_for_minute(minute_of_day: int, settings: GameClockSettings) -> StringName`; Day is the half-open interval `[day_start_minute, night_start_minute)`.

- [ ] **Step 1: Write the failing clock-rule smoke checks** for default-rate conversion, fractional-minute accumulation, invalid settings (including reversed day/night boundaries), 05:59/06:00 and 19:59/20:00 phase edges, midnight rollover, and an advance crossing more than one midnight. Invalid settings and non-positive delta must return unchanged time.
- [ ] **Step 2: Run the script to confirm it fails**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/game_clock_rules_smoke.gd`

Expected: FAIL because the clock classes and rule methods do not exist yet.

- [ ] **Step 3: Implement the settings, result, and pure rules** with integer day/minute state, a fractional-minute remainder, and correct multi-midnight counting.
- [ ] **Step 4: Run the smoke checks again**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/game_clock_rules_smoke.gd`

Expected: PASS for all configured values and boundary cases.

- [ ] **Step 5: Commit the clock domain types and checks**

```bash
git add scripts/domain/game_clock_settings.gd scripts/domain/clock_advance_result.gd scripts/domain/game_clock_rules.gd tests/game_clock_rules_smoke.gd
git commit -m "feat: add world clock rules"
```

### Task 2: Move session state to a clock-driven daily lifecycle

**Files:**
- Create: `scripts/application/world_clock_coordinator.gd`
- Create: `scripts/application/daily_transition_coordinator.gd`
- Create: `scripts/application/session_update.gd`
- Create: `data/time/game_clock_settings.tres`
- Modify: `scripts/domain/game_state.gd` (export the root type as `GameSessionState`)
- Modify: `scripts/application/game_session.gd`
- Modify: `scripts/infrastructure/content_catalog.gd`
- Modify: `scripts/application/day_loop_coordinator.gd`
- Modify: `scripts/application/dialogue_encounter_coordinator.gd`
- Modify: `scripts/application/world_exploration_coordinator.gd`
- Modify: `scripts/domain/anxiety_rules.gd`
- Modify: `scripts/domain/relationship_rules.gd`
- Modify: `scripts/application/anxiety_coordinator.gd`
- Modify: typed `GameState` references in `scripts/application/game_session.gd`, `scripts/application/day_loop_coordinator.gd`, `scripts/application/dialogue_encounter_coordinator.gd`, `scripts/application/world_exploration_coordinator.gd`, `scripts/application/anxiety_coordinator.gd`, `scripts/domain/relationship_rules.gd`, `scripts/domain/anxiety_rules.gd`, and `scripts/presentation/game_hud.gd`
- Modify: `scripts/presentation/app_root.gd`
- Modify: `scripts/presentation/game_hud.gd` (coordinate with concurrent UI edits before changing this shared file)
- Test: `tests/session_clock_smoke.gd`

**Interfaces:**
- `GameSessionState` owns `day_number`, `minute_of_day`, daily action IDs, anxiety/relationship values, and current simulation values. Story facts/outcomes and active encounter data are added by Tasks 4 and 5. Keep legacy schedule fields only until Task 3 removes the slot flow; do not use them to control the clock.
- `WorldClockCoordinator.advance(real_delta: float) -> ClockAdvanceResult` updates the shared state using settings and retains the fractional-minute remainder.
- `DailyTransitionCoordinator.apply_midnights(count: int) -> void` applies the daily action/schedule reset and anxiety cleanup once per crossed midnight.
- `SessionUpdate` exposes the current `day_number`, `minute_of_day`, `phase`, and `midnights_crossed` for presentation and downstream processing.
- `GameSession` exposes `enum SimulationMode { EXPLORATION, ENCOUNTER, BLOCKING_UI }`, `set_simulation_mode(mode: SimulationMode) -> void`, and `tick(real_delta: float) -> SessionUpdate`; `tick` advances clock/anxiety only in `EXPLORATION` mode and returns current clock view data.

- [ ] **Step 1: Write failing session tests** for Day 1 at 08:00, daily action reset, anxiety cleanup once per midnight (including multiple midnights), and no time/anxiety movement in `ENCOUNTER` or `BLOCKING_UI` mode.
- [ ] **Step 2: Run the session script to confirm failure**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/session_clock_smoke.gd`

Expected: FAIL because the new state/coordinators and mode gate are missing.

- [ ] **Step 3: Migrate the existing root state type to `GameSessionState`, add the settings resource, `SessionUpdate`, and clock/daily coordinators**, then update every typed reference and session composition. Retain existing schedule data temporarily so this commit stays buildable until Task 3 removes the old flow.
- [ ] **Step 4: Run the session smoke checks**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/session_clock_smoke.gd`

Expected: PASS, including exact pause/resume and once-per-midnight reset behavior.

- [ ] **Step 5: Wire clock ticks from the host only in exploration mode** and ensure Home no longer manually increments the day. Expose clock view data to the HUD; replace the slot UI in Task 3.
- [ ] **Step 6: Commit the session clock foundation.** Before editing or staging `game_hud.gd`, ensure the concurrent UI work is committed/cleared or stage only the feature's HUD hunk.

```bash
git add scripts/domain/game_state.gd scripts/domain/anxiety_rules.gd scripts/domain/relationship_rules.gd scripts/application/game_session.gd scripts/application/day_loop_coordinator.gd scripts/application/dialogue_encounter_coordinator.gd scripts/application/world_exploration_coordinator.gd scripts/application/anxiety_coordinator.gd scripts/infrastructure/content_catalog.gd scripts/application/world_clock_coordinator.gd scripts/application/daily_transition_coordinator.gd scripts/application/session_update.gd scripts/presentation/app_root.gd scripts/presentation/game_hud.gd data/time/game_clock_settings.tres tests/session_clock_smoke.gd
git commit -m "feat: add session clock lifecycle"
```

### Task 3: Replace scheduled location actions with immediate actions

**Files:**
- Modify: `scripts/domain/location_definition.gd`
- Modify: `data/locations/*.tres`
- Modify: `scripts/application/world_exploration_coordinator.gd`
- Modify: `scripts/application/dialogue_encounter_coordinator.gd`
- Remove: `scripts/application/day_loop_coordinator.gd`
- Modify: `scripts/presentation/app_root.gd`
- Modify: `scripts/presentation/game_hud.gd`
- Modify: `tests/portrait_city_smoke.gd`
- Test: `tests/location_action_smoke.gd`

**Interfaces:**
- Replace `visit_location(location_id: StringName, slot_index: int)` with `visit_location(location_id: StringName) -> Dictionary`.
- Replace `DialogueEncounterCoordinator.available_slots()` and `begin_or_follow_up(slot_index: int)` with a no-slot `begin_or_follow_up() -> Dictionary` request path.
- Remove `LocationDefinition.available_slots` and slot-related calls/signals from the action path.
- Remove `DayLoopCoordinator`, timeline summaries, `finish_day()`, the Day 3 cutoff, and the Home-to-day-end interaction.
- Add `GameHUD.update_clock(day_number: int, minute_of_day: int, phase: StringName) -> void`; display one compact status value such as `Day 1 · 08:00 · Day`.
- `AppRoot` submits `GameSession.tick(delta)` only when its simulation mode is exploration and tells the session when a blocking panel opens/closes.

- [ ] **Step 1: Write failing action checks** for immediate location resolution, immediate family encounter start without a slot choice, repeat rejection on the same day, and successful repeat after a day reset.
- [ ] **Step 2: Run the action smoke script to confirm failure**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/location_action_smoke.gd`

Expected: FAIL because location actions still require slots.

- [ ] **Step 3: Remove location slot restrictions and resolve location effects on interaction** while preserving location IDs, messages, anxiety changes, and relationship effects.
- [ ] **Step 4: Remove slot assignment from the family conversation and direct location flows**, then delete `DayLoopCoordinator` and the schedule state. Home does not sleep or skip time; the clock alone rolls the day.
- [ ] **Step 5: Replace the slot strip/picker with the clock label**; preserve the shared UI/asset changes already in progress in `game_hud.gd`.
- [ ] **Step 6: Run the action and existing portrait-city smoke checks**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/location_action_smoke.gd`

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/portrait_city_smoke.gd`

Expected: PASS; no slot controls remain and the clock label changes while free exploration continues.

- [ ] **Step 7: Commit the direct-action and clock-HUD migration**

```bash
git add scripts/domain/location_definition.gd data/locations/home.tres data/locations/school.tres data/locations/supermarket.tres data/locations/gym.tres scripts/application/world_exploration_coordinator.gd scripts/application/dialogue_encounter_coordinator.gd scripts/application/day_loop_coordinator.gd scripts/presentation/app_root.gd scripts/presentation/game_hud.gd tests/location_action_smoke.gd tests/portrait_city_smoke.gd
git commit -m "feat: resolve exploration actions immediately"
```

### Task 4: Add outcome records and optional-event eligibility

**Files:**
- Create: `scripts/domain/encounter_definition.gd`
- Create: `scripts/domain/encounter_choice_definition.gd`
- Create: `scripts/domain/story_outcome_record.gd`
- Create: `scripts/domain/story_outcome_definition.gd`
- Create: `scripts/domain/story_effect_definition.gd`
- Create: `scripts/domain/story_event_definition.gd`
- Create: `scripts/domain/story_condition_definition.gd`
- Create: `scripts/application/story_progression_coordinator.gd`
- Modify: `scripts/domain/game_state.gd`
- Remove: `scripts/domain/dialogue_choice_definition.gd`
- Remove: `scripts/domain/dialogue_definition.gd`
- Modify: `scripts/application/dialogue_encounter_coordinator.gd`
- Modify: `scripts/application/game_session.gd`
- Modify: `scripts/infrastructure/content_catalog.gd`
- Create: `data/encounters/family_good_news.tres`
- Remove: `data/dialogue/family_encounter.tres`
- Test: `tests/story_progression_smoke.gd`

**Interfaces:**
- `EncounterDefinition` contains an `encounter_id`, participant IDs, prompt/presentation values, and `Array[EncounterChoiceDefinition]`.
- `EncounterChoiceDefinition` contains a `choice_id`, presentation text, availability requirements, and an `outcome_id`; each choice resolves one outcome. Multi-step conversation behavior is deferred for later design.
- `StoryOutcomeRecord` contains `event_id`, `outcome_id`, `day_number`, and `minute_of_day`.
- `StoryOutcomeDefinition` contains an `outcome_id` and ordered `Array[StoryEffectDefinition]`. Initial typed effects cover relationship adjustment, anxiety adjustment, story-fact assignment, and consuming an active anxiety effect.
- `StoryEventDefinition` contains event/handler kind, trigger source/start policy, eligibility conditions, optional open/close bounds, an encounter ID, and allowed outcome IDs.
- `StoryProgressionCoordinator.is_event_available(event_id: StringName, source: StringName) -> bool` checks current session conditions without recording non-completion.
- `StoryProgressionCoordinator.apply_outcome(event_id: StringName, outcome_id: StringName) -> bool` validates, applies effects, and appends a record once; duplicate or invalid applications return `false` without mutation.
- `StoryConditionDefinition` represents fact comparisons, completed event-outcome checks, day/time ranges, and `all_of`/`any_of` composition; it may also compare the session's current `life_stage_id` when that value is present. An expired optional event produces no `StoryOutcomeRecord` and no absence-based fact.
- Each available encounter choice resolves one valid `outcome_id`, applies its durable effects, and appends one `StoryOutcomeRecord`.

- [ ] **Step 1: Write failing story checks** for a completed outcome applying once and enabling a later event, event-window expiry with no record/fact or follow-up penalty, and repeated application with no duplicate effects.
- [ ] **Step 2: Run the story smoke script to confirm failure**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/story_progression_smoke.gd`

Expected: FAIL because the story event/outcome types and coordinator are missing.

- [ ] **Step 3: Implement generic encounter/choice resources, stable event/outcome definitions, typed effects, serializable condition types, and the outcome journal**; store mutable/cumulative values in story state and use completed outcomes for outcome-specific gates. Add an optional `life_stage_id` query value without implementing life-stage transitions.
- [ ] **Step 4: Migrate the family encounter resource to named outcomes and typed effects**; remove the experimental overthink reply, remove the Day 1 missed-opportunity trust penalty, and make the Day 2 follow-up neutral when no Day 1 outcome exists.
- [ ] **Step 5: Run story progression checks**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/story_progression_smoke.gd`

Expected: PASS; resolved outcomes are recorded once, and expired/unplayed optional content leaves story state unchanged.

- [ ] **Step 6: Commit the story outcome and eligibility layer**

```bash
git add scripts/domain/encounter_definition.gd scripts/domain/encounter_choice_definition.gd scripts/domain/story_outcome_record.gd scripts/domain/story_outcome_definition.gd scripts/domain/story_effect_definition.gd scripts/domain/story_event_definition.gd scripts/domain/story_condition_definition.gd scripts/domain/game_state.gd scripts/application/dialogue_encounter_coordinator.gd scripts/application/story_progression_coordinator.gd scripts/application/game_session.gd scripts/infrastructure/content_catalog.gd data/encounters/family_good_news.tres tests/story_progression_smoke.gd
git add -u scripts/domain/dialogue_choice_definition.gd scripts/domain/dialogue_definition.gd data/dialogue/family_encounter.tres
git commit -m "feat: record resolved story outcomes"
```

### Task 5: Route all encounter starts through a battle presentation

**Files:**
- Create: `scripts/domain/encounter_start_request.gd`
- Create: `scripts/application/encounter_coordinator.gd`
- Create: `scripts/presentation/battle_presenter.gd`
- Create: `scenes/battle/battle_scene.tscn`
- Remove: `scripts/application/dialogue_encounter_coordinator.gd`
- Modify: `scripts/application/game_session.gd`
- Modify: `scripts/application/story_progression_coordinator.gd`
- Modify: `scripts/presentation/app_root.gd`
- Modify: `scripts/presentation/game_hud.gd`
- Test: `tests/encounter_flow_smoke.gd`

**Interfaces:**
- `EncounterStartRequest` contains `event_id`, `encounter_id`, `initiator_id`, and `trigger_source`.
- `EncounterCoordinator.begin_encounter(request: EncounterStartRequest) -> Dictionary` loads an `EncounterDefinition`, validates event availability, and returns an encounter view or a failure result; `choose(choice_id: StringName) -> Dictionary` validates the active choice and returns the next view or completed outcome.
- `GameSession.begin_encounter(request: EncounterStartRequest) -> Dictionary` sets mode to `ENCOUNTER` on success. A completed choice stays paused while its result panel is visible; the host returns to `EXPLORATION` after that blocking panel closes. Invalid choices do not change mode or state.
- NPC/time/story triggers return `EncounterStartRequest` values to the host, which routes them through the same coordinator as player interactions.
- `BattleScene` presents player/avatar area at the bottom, response options below, and opposing participant upper right. It displays returned view data and emits choice IDs only.

- [ ] **Step 1: Write failing encounter-flow checks** for player-started and NPC/world-started requests reaching the same active encounter, valid/invalid choice results, completion, and clock pause/resume.
- [ ] **Step 2: Run the encounter smoke script to confirm failure**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/encounter_flow_smoke.gd`

Expected: FAIL because the unified coordinator and battle scene do not exist.

- [ ] **Step 3: Add the request type and generalize the dialogue application service into `EncounterCoordinator`**; each choice resolves immediately to one story outcome.
- [ ] **Step 4: Add the minimal `BattleScene` presenter** with avatar/participant placeholders and choice controls; keep all encounter resolution in the application/domain layer.
- [ ] **Step 5: Route player interactions and eligible NPC/world requests through `GameSession.begin_encounter`** and verify the simulation mode pauses time until resolution.
- [ ] **Step 6: Run encounter checks**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/encounter_flow_smoke.gd`

Expected: PASS for both start sources and exact clock pause/resume behavior.

- [ ] **Step 7: Commit the shared encounter flow and battle scene**

```bash
git add scripts/domain/encounter_start_request.gd scripts/application/encounter_coordinator.gd scripts/presentation/battle_presenter.gd scenes/battle/battle_scene.tscn scripts/application/game_session.gd scripts/application/story_progression_coordinator.gd scripts/presentation/app_root.gd scripts/presentation/game_hud.gd tests/encounter_flow_smoke.gd
git add -u scripts/application/dialogue_encounter_coordinator.gd
git commit -m "feat: add battle-style encounter scene"
```

### Task 6: Integrate timed event requests and update prototype handoff

**Files:**
- Modify: `scripts/application/game_session.gd`
- Modify: `scripts/application/story_progression_coordinator.gd`
- Modify: `scripts/presentation/app_root.gd`
- Modify: `README.md` only after the concurrent README edit is resolved and preserved
- Test: `tests/world_loop_smoke.gd`

**Interfaces:**
- `GameSession.tick(real_delta: float) -> SessionUpdate` returns clock view state, crossed-day transition results, and typed NPC/world encounter-start requests produced by time/story conditions. Add `encounter_requests: Array[EncounterStartRequest]` to `SessionUpdate` in this task.
- The host dispatches at most one eligible encounter request at a time through `EncounterCoordinator`; it does not inspect event definitions or author outcomes.
- `StoryProgressionCoordinator.evaluate_time_events() -> Array[EncounterStartRequest]` is deterministic for a given `GameSessionState` and does not produce requests for expired/completed one-shot events.

- [ ] **Step 1: Write failing integration checks** for a time-triggered NPC event, event de-duplication, no slot UI, clock label update, day progression beyond Day 3, and a missed optional family event having no future effect.
- [ ] **Step 2: Run the integration script to confirm failure**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/world_loop_smoke.gd`

Expected: FAIL until host routing and end-to-end content are connected.

- [ ] **Step 3: Wire clock updates to timed event evaluation and route returned requests through the encounter coordinator**; prevent duplicate one-shot starts without writing missed-event history.
- [ ] **Step 4: Update the README controls/status description only after the concurrent README edit is committed or otherwise resolved**; preserve its map/asset instructions. If it is still active, leave README.md untouched and defer this documentation edit.
- [ ] **Step 5: Run all new smoke scripts plus the existing prototype smoke check**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/game_clock_rules_smoke.gd`

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/session_clock_smoke.gd`

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/location_action_smoke.gd`

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/story_progression_smoke.gd`

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/encounter_flow_smoke.gd`

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/world_loop_smoke.gd`

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/portrait_city_smoke.gd`

Expected: PASS for all checks; the game continues past Day 3, displays time/phase, pauses during encounters/UI, and records only completed outcomes.

- [ ] **Step 6: Review the final diff for slot references, scene-to-domain writes, duplicate outcome application, and shared asset changes**
- [ ] **Step 7: Commit the integrated world loop**

```bash
git add scripts/application/game_session.gd scripts/application/story_progression_coordinator.gd scripts/presentation/app_root.gd tests/world_loop_smoke.gd
git commit -m "feat: integrate continuous world day loop"
```

If the README update is made after the concurrent edit is resolved, commit that README change separately after confirming its staged diff contains no unrelated asset instructions.
