# Problem Graph Architecture and Implementation Plan

**Date:** 2026-10-03  
**Status:** Implementing  
**Project:** Miswell Godot prototype

## Architecture

- Keep graph definitions as data. A generic content-pack loader discovers JSON files in built-in packs and `user://mods/<pack>/content/<type>/`, so future conversations, characters, and other authored content can use the same extension point without executing mod scripts.
- Give every pack and node a stable namespaced ID. Reject duplicate IDs, invalid documents, and graph edges to unknown nodes; never let mod content override a core ID implicitly.
- Keep graph state in the active `GameSessionState` and save only acquired node IDs. Draw edges from parent IDs, but keep acquisition rules separate: story outcomes explicitly grant nodes and may declare prerequisites. This lets shared nodes such as Insomnia have two incoming edges and one persistent identity.
- Compose a session-owned `ProblemGraphCoordinator`. Story outcomes call it through a typed effect; it exposes completed nodes and abilities implied by those nodes. Ability definitions and conversation content remain authoring work for later.
- Show the graph through a presentation-only graph scene. A mobile HUD button and desktop `G` shortcut open it; Escape and the close button return to exploration. Opening the graph uses the existing blocking-UI mode so world time pauses.
- Expose force-completion only in debug builds. The debug command bypasses authored prerequisites but still requires a known, non-category node.

## Initial graph content

Use the early sketch from the Unhealth Graph page, with the player's Health → Anxiety / Depression structure and the clarification that Anxiety and Depression share one Insomnia node. The remaining rough-sketch branches are Anxiety → Schizophrenia → Visual Hallucinations / Auditory Hallucinations, Anxiety → Paranoia, and Depression → Self-harm / Anorexia → Self Distortion. These are fictional game labels, not clinical progression claims. Health is a category/root, not an acquired condition.

## Implementation sequence

1. Add JSON content-pack discovery and built-in graph node definitions with namespaced IDs and presentation layout coordinates.
2. Add graph definition/state/rules and session coordinator; connect story outcome effects and expose ability lookup.
3. Serialize acquired node IDs with backward-compatible defaults for existing saves.
4. Add the graph scene, node/edge presentation, debug completion route, and desktop/mobile open/close input.
5. Inspect the final diff and run the project's available Godot parse/launch validation if the engine is available.

## Scope

No graph balancing, final UI design, conversation content, ability implementations, medical accuracy claims, general-purpose scripting API, or mod sandbox/security system is part of this implementation.
