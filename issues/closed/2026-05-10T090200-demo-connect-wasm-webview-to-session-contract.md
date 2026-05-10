# wasm-webview demo を App Server session contract に接続する

Created: 2026-05-10
Completed: 2026-05-10
Model: GPT-5 Codex

## 背景

PR #13 で `AgentSessionSnapshot` と replay export JSON、PR #14 で App Server session tool boundary が追加された。既存の `examples/wasm-webview/` は `session_viewer()` HTML だけを返す demo だったため、native / wasm / WebView consumer が参照できる session contract demo に更新する必要があった。

## 要件

- 既存の wasm-webview demo bridge と README を確認する。
- demo から `AgentSessionSnapshot` JSON、resource projection HTML、App Server session tool catalog / plan JSON、replay export JSON を参照できるようにする。
- native / wasm / WebView consumer 向けに snapshot / render / action / replay の流れを明示する。
- transport、production WebView shell、real LLM call、host tool execution は実装しない。
- stable string/function export を優先し、bundler は追加しない。
- 可能なら focused test を追加する。

## 解決方法

`examples/wasm-webview/bridge.mbt` を App Server session contract の reference client として更新した。通常の action は `apply_app_server_session_tool()` 経由で session に適用し、`get_snapshot_json()`、`get_resource_html()`、`get_resource_json()`、`get_session_tool_catalog_json()`、`get_execute_tool_plan_json()`、`get_replay_export_json()` を stable export として追加した。

demo 専用の `demo.read` tool を登録し、`FileRead("/demo/session.txt")` permission を metadata として公開することで、実際の host execution を行わずに pending tool の approval boundary と plan JSON を確認できるようにした。

browser 側は各 action 後に resource HTML、snapshot JSON、resource JSON、session tool catalog、`execute_tool_request` plan、replay export を再読込する構成にした。README には native / wasm / WebView consumer が辿る snapshot / render / action / replay flow と、transport-free であることを追記した。

`examples/wasm-webview/bridge_wbtest.mbt` で初期 artifact、pending tool snapshot、approval-required plan、replay export を確認した。
