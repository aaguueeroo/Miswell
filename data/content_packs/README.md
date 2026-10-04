# JSON content packs

Content packs are data-only. They do not load GDScript or run code.

Built-in packs live under `res://data/content_packs/<pack-folder>/`; user-installed packs live under `user://mods/<pack-folder>/`. Each pack has a `manifest.json` with a unique namespaced `id` and a `format_version`. Content is grouped by type under `content/<type>/` and stored in JSON files. The loader scans pack folders and JSON files in sorted order.

Every content document has a stable ID prefixed by its pack ID and a colon. For example, `miswell.base:insomnia` belongs to the `miswell.base` pack. IDs are never replaced implicitly; collisions are rejected. Graph-node documents use `content/problem_graph_nodes/` and define `id`, `title`, `parent_ids`, optional `required_node_ids`, `ability_ids`, `is_category`, and a two-integer `layout` coordinate.

The pack loader is content-type agnostic. Character data can use `content/characters/`; conversation documents go in `content/conversations/`; event and outcome documents go in `content/story_events/`. Keep authored content declarative; runtime behavior belongs in the game, not in mod scripts.

## Conversation documents

A conversation document uses its namespaced ID as `id`, with `title`, `prompt`, optional `player_name` / `opponent_name`, and a non-empty `choices` array. Each choice has a namespaced `id`, `label`, `outcome_id`, optional `description`, `result_message`, `required_effect_id`, and optional `conditions`.

## Story-event documents

A story-event document has a namespaced `id`, `start_policy` (`player_interaction`, `npc_interaction`, `time_triggered`, or `story_triggered`), `trigger_source`, `initiator_id`, and `encounter_id`. Optional timing fields are `opens_on_day`, `opens_at_minute`, `closes_on_day`, `closes_at_minute`, and `trigger_at_minute`; it may also have `daily_action_id`, `repeatable`, and `conditions`. Its `outcomes` array has namespaced outcome IDs, `title`, optional `result_message` / `conditions`, and an `effects` array. Effect kinds include `unlock_problem_graph_node`, `set_boolean_fact`, `adjust_relationship`, `adjust_anxiety`, and `consume_anxiety_effect`.

Condition kinds include `outcome_completed`, `problem_graph_node_completed`, `ability_unlocked`, `fact_exists`, `fact_equals_bool`, `day_range`, `time_range`, `life_stage_equals`, `all_of`, and `any_of`. Conditions and effects are checked and applied by application services; content files cannot invoke scripts.
