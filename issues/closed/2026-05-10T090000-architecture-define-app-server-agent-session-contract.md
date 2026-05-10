# App Server agent session contract を定義する

Created: 2026-05-10
Completed: 2026-05-10
Model: GPT-5 Codex

## 背景

orbit.mbt の runtime core は transport-free のまま維持しつつ、App Server や native / wasm / WebView 側が安定して消費できる agent session snapshot が必要。

## 要件

- session identity、current agent state、event log、messages、pending tool lifecycle/request、permissions/approval boundary、resource projection、diagnostics、last action を含む snapshot contract を定義する。
- App Server transport、LLM connector、UI redesign、広範な storage adapter は実装しない。
- approval-required mutation と normal mutation の境界をコードまたはドキュメントで明示する。
- replay/export artifact envelope をコードまたはドキュメントで明示する。
- native / wasm / WebView consumption 向けに deterministic JSON string を返す。
- snapshot JSON fields、waiting tool/pending request、approval metadata、replay/export envelope をテストする。

## 解決方法

`app_server_contract.mbt` を追加し、transport-free な `AgentSessionSnapshot` と `ReplayExportEnvelope` を定義した。snapshot JSON には session identity、state、event log、messages、pending tool request、approval boundary、resource projection、diagnostics、last action を deterministic order で出力する。

normal mutation は pure session event/state mutation、approval-required mutation は tool approval/execution や host capability mutation としてコードコメントと JSON field に分けた。`ToolRegistry` から pending tool の required permissions を投影し、missing permissions や未登録 tool を approval metadata と diagnostics に反映する。

`app_server_contract_wbtest.mbt` で snapshot JSON、waiting tool request、approval metadata、replay/export envelope を確認した。
