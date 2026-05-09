# f4ah6o/orbit

Typed, deterministic, local-first AI agent runtime for MoonBit.

`orbit.mbt` is a MoonBit-native reinterpretation of the agent runtime idea
explored by [`vercel-labs/zero-native`](https://github.com/vercel-labs/zero-native),
designed around typed state machines, event-sourced sessions, hypermedia UI
projections, and offline execution on native and wasm targets.

See [`docs/HANDOFF.md`](docs/HANDOFF.md) for the full project handoff,
philosophy, package layout, and milestone plan (M1 — M6).

## Status

Bootstrap. M1 (Typed Event Runtime) not yet started.

## Issue Management

Issues are managed locally as markdown files in the `issues/` directory, rather than on GitHub Issues.

- **Open** issues live in `issues/`
- **Closed** issues are moved to `issues/closed/`
- **Pending** (blocked) issues are moved to `issues/pending/`

File naming convention: `{YYYY-MM-DDThhmmss}-{category}-{slug}.md`

For the full issue workflow, see [AGENTS.md](./AGENTS.md).

This approach is inspired by [shiguredo/http3-rs](https://github.com/shiguredo/http3-rs/blob/develop/AGENTS.md).
