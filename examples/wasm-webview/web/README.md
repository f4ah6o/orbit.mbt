# wasm-webview App Server contract demo

End-to-end reference client for the orbit.mbt session contract in the browser via
MoonBit wasm-gc. The demo is intentionally transport-free: the wasm module
exports stable strings/functions that a native shell, WebView, or browser host
can call without adding an App Server transport.

## Prerequisites

- MoonBit toolchain: https://www.moonbitlang.com/download/
- A browser with WebAssembly GC + stringref support (Chrome 119+, Edge 119+, Firefox 133+)

## Build

From the repository root:

```sh
moon build --target wasm-gc
cp _build/wasm-gc/debug/build/examples/wasm-webview/wasm-webview.wasm examples/wasm-webview/web/
```

## Serve

```sh
cd examples/wasm-webview/web
python3 -m http.server 8000
# or: npx serve .
```

Open http://localhost:8000 in your browser.

The wasm-gc package enables JS builtin strings, so custom hosts should instantiate
the module with:

```js
{
  builtins: ["js-string"],
  importedStringConstants: "_",
}
```

## Exported bridge

`examples/wasm-webview/bridge.mbt` exports:

- `boot()` / `reset_demo()` for lifecycle setup
- `dispatch_event(kind, payload)` for demo actions
- `get_resource_html()` / `get_html()` for the `Resource` projection HTML
- `get_resource_json()` for the projected hypermedia resource JSON
- `get_snapshot_json()` for `AgentSessionSnapshot` JSON
- `get_session_tool_catalog_json()` for App Server session tool descriptors
- `get_execute_tool_plan_json()` for the pending `execute_tool_request` plan
- `get_replay_export_json()` for `ReplayExportEnvelope` JSON

The bridge registers one demo-only tool, `demo.read`, with
`FileRead("/demo/session.txt")`. It is never executed by the bridge. It only lets
the snapshot and plan JSON show the approval boundary that native/wasm/WebView
hosts need to honor before crossing into host capabilities.

## Demo Flow

The page shows the same session through five consumer-facing artifacts:

- **Resource HTML**: `render_resource(project(session))`
- **Event Log**: browser-side log of calls into the wasm bridge
- **AgentSessionSnapshot JSON**: App Server session contract
- **Resource Projection JSON**: deterministic hypermedia resource
- **Session Tool Catalog / Plan / Replay JSON**: tool boundary and replay export

Use the toolbar buttons to drive the session state machine:

1. **Start** — transitions Idle → Running
2. **User Message** — appends a user message (payload = message text)
3. **Request Tool** — Running → WaitingTool (`demo.read`; payload is ignored)
4. **Respond Tool** — WaitingTool → Running (payload = tool output)
5. **End** — transitions Running → Idle

`dispatch_event()` applies normal session mutations through
`apply_app_server_session_tool()`. Approval-required operations are not executed;
the demo exposes their catalog and plan JSON so adapters can decide what UI or
host capability flow to run.

Invalid transitions (e.g., sending a message while Idle) cause the session to enter Failed state.

## Notes

- The `js_emit_html` extern is stubbed (`fn js_emit_html(_html : String) -> Unit { () }`)
  due to a compiler assertion failure with inline WAT wasm imports.
  Instead, JS calls `get_html()` after each action to read the rendered HTML and
  inject it into the DOM.

- When the compiler supports `extern "wasm" fn ... = #|...|#` inline WAT,
  the bridge can be updated to use push-based rendering via `emit_html`.
