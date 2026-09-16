# Codex workflow for IX-Ray

## General rule

Use configured subagents automatically when appropriate.

Do not ask the user which model or agent should handle a task.
Choose the appropriate workflow yourself.

The main Codex agent is responsible for coordinating the task and
delivering the final result.

## Advisor

Use the configured `advisor` subagent before implementation when:

- the root cause is unclear;
- engine C++ behavior must be traced;
- multiple subsystems interact;
- the task changes game mechanics;
- architectural or shared infrastructure changes are involved;
- multiple plausible implementations exist;
- existing behavior must be reverse-engineered;
- subtle regressions are possible.

The advisor is intended for difficult analysis, architecture,
root-cause investigation, and planning.

Use its findings as input to implementation.

Do not invoke the advisor for:

- trivial XML changes;
- straightforward LTX / DLTX edits;
- formatting;
- simple renames;
- obvious mechanical edits;
- routine file synchronization.

## Implementation

The main agent handles substantial implementation.

For significant C++ work, the main agent should implement the chosen
approach after the advisor has resolved architectural uncertainty.

### Worker

Use the configured `worker` subagent for routine implementation that
requires some reasoning but does not involve architectural decisions.

Typical tasks:

- multi-file XML/LTX/DLTX changes with a known design;
- straightforward configuration work;
- adapting an existing implementation pattern;
- routine non-architectural refactoring;
- independent implementation subtasks.

Do not delegate architectural decisions to the worker.

### Mechanical worker

Use the configured `mechanical` subagent for trivial, deterministic,
well-scoped edits where the desired result is already known.

Typical tasks:

- adding DLTX overrides following an existing nearby pattern;
- changing known XML/LTX values;
- repetitive icon/grid overrides;
- simple renames;
- repetitive file edits;
- small documentation changes.

Do not use the mechanical worker when values or behavior must be inferred,
when the correct implementation is unclear, or when engine behavior must
be investigated.

If a mechanical task becomes ambiguous, return it to the main agent
instead of guessing.

## Review

After substantial or risky C++ engine changes, use the configured
`reviewer` subagent for an independent review before considering
the task complete.

Review should focus on:

- correctness;
- regressions;
- missed call paths;
- invalid assumptions;
- interactions between C++, Lua, XML, LTX and DLTX;
- compatibility with existing IX-Ray / STCoP behavior;
- unnecessary duplication;
- edge cases.

Fix definite correctness or regression issues before finishing.

Do not automatically implement purely stylistic reviewer suggestions.

## Task sizing

Use the simplest workflow adequate for the task.

Typical examples:

### Simple data/config change

Main agent or normal worker only.

Examples:
- XML layout change;
- DLTX upgrade value;
- text or encoding fix;
- texture descriptor change.

### Normal implementation

Main agent performs analysis and implementation.
Normal workers may handle mechanical subtasks.

### Difficult engine change

advisor
→ main agent implementation
→ reviewer

Examples:
- inventory grid behavior;
- drag/drop calculations;
- protection or damage mechanics;
- artifact/immunity calculations;
- cross-system UI parameters;
- unclear engine/config source of truth.

## Project documentation

Always follow `/home/tmz/Projects/ixray-docs/README.md` and its router.

When a task matches a routed domain, read the referenced document
before making the first change.
