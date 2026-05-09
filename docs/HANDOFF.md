# MoonBit Native Agent Runtime — Project Handoff

## Goal

Build a MoonBit-native alternative/reinterpretation of:

- https://github.com/vercel-labs/zero-native

But NOT as a direct port.

The objective is:

> A typed, deterministic, local-first AI agent runtime and UI platform.

Core direction:

- typed state machine
- local tool execution
- hypermedia-driven UI
- event-stream architecture
- deterministic runtime
- wasm/native dual target
- lightweight desktop/runtime architecture
- multi-agent orchestration compatibility

This project should align with existing ecosystem concepts:

- tmpx.mbt
- mhx.mbt
- papyr.mbt
- FWD concepts
- typed Reason diagnostics
- deterministic fixture-first workflows

---

# Non-Goals

Do NOT:

- clone Electron app structures
- reproduce React-heavy architecture
- create adhoc JSON event systems
- build opaque async state machines
- tightly couple UI and orchestration
- rely on uncontrolled mutable runtime state

---

# High-Level Architecture

```text
agent-runtime.mbt
  core runtime/event system/state machine

agent-protocol.mbt
  typed protocol/events/messages/tools/reasons

agent-ui.mbt
  tmpx + mhx rendering layer

agent-local.mbt
  filesystem/opfs/sqlite/duckdb/cache/indexing

agent-tools.mbt
  local tool execution abstraction

agent-orchestrator.mbt
  planner/executor/reviewer multi-agent flows
```

---

# Core Philosophy

## 1. Illegal States Unrepresentable

All runtime transitions must be represented using typed ADTs.

Avoid:

```json
{
  "status": "maybe_running"
}
```

Prefer:

```moonbit
enum AgentState {
  Idle
  Running(RunContext)
  WaitingTool(ToolRequest)
  Failed(Reason)
}
```

---

## 2. Deterministic Runtime

The runtime must support:

- reproducible event replay
- fixture-driven tests
- stable serialization
- deterministic outputs
- explicit transitions

No hidden async mutation.

---

## 3. Event-Sourced Agent Runtime

Everything should be representable as events.

Example:

```moonbit
enum AgentEvent {
  UserMessage(UserMessage)
  AssistantMessage(AssistantMessage)

  ToolCall(ToolRequest)
  ToolResult(ToolResponse)

  Transition(StateId, StateId)

  Reason(ReasonV1)

  StreamChunk(String)

  SessionStarted(SessionId)
  SessionEnded(SessionId)
}
```

---

# Hypermedia-Oriented UI

UI should NOT be "component state first".

UI should consume runtime resources.

Example resource:

```json
{
  "state": "waiting_tool",

  "messages": [...],

  "available_actions": [
    {
      "rel": "approve_tool",
      "method": "POST",
      "href": "/session/123/actions/approve"
    }
  ],

  "reasons": [...],

  "links": [...]
}
```

The UI layer should:

- render from resource projections
- avoid client-side business logic
- support streaming updates
- support SSR
- support local-only execution

Use:

- tmpx.mbt
- mhx.mbt

---

# Tool Execution Model

Tool execution must be explicit and typed.

Example:

```moonbit
trait Tool {
  fn metadata() -> ToolMetadata
  fn execute(input : Json) -> ToolResult
}
```

Tool execution lifecycle:

```text
requested
 -> approved
 -> executing
 -> completed
 -> failed
```

Never execute arbitrary tool actions implicitly.

---

# Permission Model

Design explicit permission boundaries.

Examples:

- filesystem read
- filesystem write
- shell execution
- network access
- clipboard access

Permissions should be:

- session-scoped
- explicit
- inspectable
- serializable

Example:

```moonbit
enum Permission {
  FileRead(Path)
  FileWrite(Path)
  ShellExec(Command)
  HttpAccess(Host)
}
```

---

# Local-First Runtime

Primary targets:

- native
- wasm
- browser local runtime

Support:

- OPFS
- sqlite/duckdb
- local indexing
- offline execution
- cached sessions

Avoid mandatory cloud dependencies.

---

# Multi-Agent Orchestration Compatibility

Must support orchestrator-style execution.

Compatible with concepts like:

```text
planner
 -> dispatcher
 -> runner
 -> reviewer
 -> decider
```

Suggested structure:

```moonbit
enum AgentRole {
  Planner
  Executor
  Reviewer
  Strategist
}
```

Session state should be serializable:

```yaml
session:
  state:
  agents:
  tasks:
  transitions:
```

---

# Streaming

Streaming should be event-based.

Avoid mutable UI append logic.

Example:

```moonbit
StreamChunk(
  session_id,
  message_id,
  delta
)
```

Renderer reconstructs state from event stream.

---

# Suggested Packages

## agent-runtime.mbt

Responsibilities:

- event loop
- state transitions
- session runtime
- replay
- deterministic execution

## agent-protocol.mbt

Responsibilities:

- typed protocol
- tool contracts
- serialization
- reason schema
- event schema

## agent-ui.mbt

Responsibilities:

- tmpx rendering
- mhx integration
- streaming projections
- hypermedia resources

## agent-local.mbt

Responsibilities:

- filesystem abstraction
- OPFS
- sqlite
- duckdb
- indexing/cache

## agent-tools.mbt

Responsibilities:

- tool registry
- execution
- permissions
- tool lifecycle

## agent-orchestrator.mbt

Responsibilities:

- multi-agent dispatch
- planner/reviewer flows
- orchestration graph
- session coordination

---

# Initial Milestones

## M1 — Typed Event Runtime

Deliver:

- AgentEvent
- AgentState
- session runtime
- deterministic replay
- tests

## M2 — Tool Execution

Deliver:

- tool registry
- typed execution
- permissions
- explicit lifecycle

## M3 — Hypermedia Projection

Deliver:

- runtime -> resource projection
- available actions
- reason projection
- JSON fixtures

## M4 — tmpx/mhx UI

Deliver:

- SSR UI
- streaming updates
- session viewer
- action execution

## M5 — Local Runtime

Deliver:

- OPFS
- sqlite/duckdb
- offline sessions
- cache/indexing

## M6 — Multi-Agent Runtime

Deliver:

- planner/reviewer/executor
- orchestration graph
- session.yaml support

---

# Testing Philosophy

Fixture-first.

Requirements:

- deterministic snapshots
- stable JSON
- no wall-clock dependency
- no hidden random state

Prefer:

```text
fixtures/
goldens/
replay/
```

over UI screenshot testing.

---

# Recommended Naming Candidates

- orbit.mbt
- relay.mbt
- conductor.mbt
- cockpit.mbt
- pilot.mbt
- lumen.mbt

Current preferred direction:

```text
orbit.mbt
```

because it implies:

- orchestrated motion
- local system
- agent coordination
- event flow
- runtime center
