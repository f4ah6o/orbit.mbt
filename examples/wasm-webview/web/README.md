# wasm-webview demo

End-to-end demo of orbit.mbt in the browser via MoonBit wasm-gc.

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

## Demo

The page has two panes:

- **Left pane ("#app")**: shows the session HTML rendered by `session_viewer()`
- **Right pane ("#log")**: event log showing every dispatched action

Use the toolbar buttons to drive the session state machine:

1. **Start** — transitions Idle → Running
2. **User Message** — appends a user message (payload = message text)
3. **Request Tool** — Running → WaitingTool (payload = tool name)
4. **Respond Tool** — WaitingTool → Running (payload = tool output)
5. **End** — transitions Running → Idle

Invalid transitions (e.g., sending a message while Idle) cause the session to enter Failed state.

## Notes

- The `js_emit_html` extern is stubbed (`fn js_emit_html(_html : String) -> Unit { () }`)
  due to a compiler assertion failure with inline WAT wasm imports.
  Instead, JS calls `get_html()` after each action to read the rendered HTML and
  inject it into the DOM.

- When the compiler supports `extern "wasm" fn ... = #|...|#` inline WAT,
  the bridge can be updated to use push-based rendering via `emit_html`.
