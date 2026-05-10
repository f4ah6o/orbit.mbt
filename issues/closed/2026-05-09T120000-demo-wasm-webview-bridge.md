# MoonBit → wasm → WebView デモ

Created: 2026-05-09
Completed: 2026-05-10
Model: GPT-5 Codex
Category: demo
Status: closed

## Summary

orbit.mbt をブラウザ／WebView 上で動かす最小エンドツーエンドデモを作る。
MoonBit → wasm-gc にコンパイルし、`Session` の event stream と
`render_resource` 由来の HTML projection を WebView に投影する。

## Motivation

M1–M6 でランタイムは揃ったが、実際に画面に出る形のリファレンス実装がまだない。
zero-native (Zig + WebView) に対応する MoonBit 版「ローカル native shell ＋
hypermedia UI」のミニマル版を提示することで:

- runtime の wasm 互換性を CI で担保できる
- `render_resource` の実用性を確認できる
- 後続 demo (chat, fs-agent, replay-debugger) のテンプレートになる

## 構成

```
examples/wasm-webview/
  src/
    bridge.mbt        // JS ↔ MoonBit 境界 (extern "wasm")
    main.mbt          // Session 初期化と event loop
  web/
    index.html        // WebView host
    bootstrap.js      // wasm load + DOM patch
    style.css
  moon.pkg.json
  README.md
```

## Bridge 設計

- MoonBit 側: `pub extern "wasm" fn emit_html(html : String) -> Unit`
- JS 側: import object で `emit_html` を提供し、`#app` の innerHTML に注入
- 入力イベント (button click など) は `dispatch_event(kind : String, payload : String)` の
  単一エントリで MoonBit に渡す
- payload は JSON ではなく当面はプレーン文字列（typed parser は別 issue）

## デモシナリオ

1. ブラウザロードで `Session::create("demo").start()` が走る
2. ボタン: "send user message" → `send_user_message("hello")` → projection 再描画
3. ボタン: "request tool" → `ToolCall` イベント → `WaitingTool` 状態の HTML が出る
4. ボタン: "respond tool" → `Running` に戻る
5. event log（右ペイン）に逐次追記される

## 受け入れ基準

- [x] `moon build --target wasm-gc` が通る
- [x] `examples/wasm-webview/web/` を静的サーブして Chromium / WKWebView で動作
- [x] ボタン操作で AgentState の遷移が画面に反映される
- [x] event log がリアルタイムに増える
- [x] README に手順（build / serve / open）が書かれている

## 非ゴール

- ネイティブシェル（Tauri/CEF/Zig 連携）
- 本物の LLM 呼び出し
- 永続化 (M5 の StorageBackend は in-memory のみ)
- バンドラ統合 (vite/webpack)

## 参考

- M3 `project_session`, `available_actions`
- M4 `render_resource`, `session_viewer`
- vercel-labs/zero-native の `examples/hello`, `examples/webview`

## 解決方法

既に merge 済みの App Server agent session contract / tool boundary / demo session contract に乗せて、`examples/wasm-webview/` を最小の browser / WebView 参照実装として完成扱いにした。

MoonBit 側は `bridge.mbt` で `Session::create("demo")` を保持し、`dispatch_event(kind, payload)` から `start_session`、`append_user_message`、`record_tool_request`、`record_tool_result`、`end_session` を `apply_app_server_session_tool()` 経由で適用する。`examples/wasm-webview/moon.pkg` の wasm-gc link 設定で `boot`、`dispatch_event`、各 getter を明示 export し、JS builtin string を有効にしたうえで、`render_resource(project(session))` の HTML、resource JSON、`AgentSessionSnapshot` JSON、session tool catalog、`execute_tool_request` plan、replay export を JS host から呼べる stable surface として公開している。

Web 側は `bootstrap.js` で wasm を読み込み、各ボタン操作後に export を再読込して `#app` と各 JSON pane を更新し、右ペインの event log に操作履歴を追記する。README には build / serve / open の手順と、transport-free な bridge の exported surface を記載した。

`pub extern "wasm" fn emit_html(html : String) -> Unit` は現行 compiler の inline WAT import assertion failure を避けるため、push 型 import ではなく JS が `get_resource_html()` を pull する構成にしている。この制約は README の Notes に明記した。
