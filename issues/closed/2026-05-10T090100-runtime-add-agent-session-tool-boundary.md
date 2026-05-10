# App Server agent session tool boundary を追加する

Created: 2026-05-10
Completed: 2026-05-10
Model: GPT-5 Codex

## 背景

PR #13 で `AgentSessionSnapshot`、`ApprovalBoundary`、replay export JSON が runtime core に追加された。次の段階として、App Server / native / wasm / WebView 側が同じ session operation を安全に呼び出せるように、transport-free な tool boundary が必要。

## 要件

- App Server session tool の data/type と deterministic JSON serialization を定義する。
- read-only tool、normal mutating tool、approval-required tool を分ける。
- native / wasm / WebView consumer が参照できる tool name と input/output envelope shape を含める。
- 可能な範囲で execution / planning helper を追加する。
- host-side execution、HTTP server、real LLM call、UI approval prompt は実装しない。
- 既存の `Session`、`ToolRegistry`、`Permission`、`AgentSessionSnapshot`、`ApprovalBoundary` の概念と統合する。
- read-only metadata、normal mutation metadata、approval-required metadata、JSON output の focused test を追加する。

## 解決方法

`app_server_session_tools.mbt` を追加し、`AppServerSessionToolDescriptor`、`AppServerSessionToolPlan`、`AppServerSessionToolInput` を定義した。tool catalog は read-only、normal mutation、approval-required の順に deterministic JSON として出力する。

read-only tool は snapshot / replay export / catalog 参照だけを表す。normal mutation tool は `Session` の既存 transition API に限定して `apply_app_server_session_tool` から適用できるようにした。approval-required tool は host capability 境界を越える操作として descriptor と plan にだけ表現し、実際の host execution や UI approval prompt は adapter 側に残した。

`plan_app_server_session_tool` は pending tool と `ToolRegistry` から required permissions を投影し、granted permissions と比較して missing permissions を deterministic に返す。これにより App Server 側は transport を問わず同じ approval boundary を参照できる。

`app_server_session_tools_wbtest.mbt` で read-only metadata、normal mutation metadata と apply helper、approval-required metadata、catalog / plan JSON を確認した。
