# File system agent デモ（Permission ゲート付き）

Created: 2026-05-09
Category: demo
Status: open

## Summary

ローカルファイルを読み書きする agent demo。各 tool call が Permission を
要求し、ユーザーが承認するまで `WaitingTool` で停止する UX を示す。

## Motivation

M2 の Permission 列挙体は宣言したが、実際の "approve / deny" gate を
通す例がまだない。zero-native の bridge command security policy に
近い体験を MoonBit 側で表現するための reference。

## デモシナリオ

1. ユーザー: "show me README of this project"
2. agent: `request_tool("read_file", "{path: 'README.md'}")`
3. 画面: 「`ReadFile(README.md)` を許可しますか？ [Allow] [Deny]」
4. Allow → tool 実行 → `AssistantMessage(content)` で内容表示
5. Deny → `Reason("denied by user")` → `Failed`

## 設計

- `PermissionRequest { permission: Permission, call_id: String }` イベントを
  AgentEvent に追加するか、ToolCall の前段に `PermissionGate` 状態を入れるかを検討
- まずは追加せず、UI 側で「pending tool call が ReadFile を要求している」と
  解釈する案で十分
- 拒否時の遷移は `fail("denied by user: <permission>")` を採用

## tools

- `ReadFileTool` (Permission::ReadFile)
- `WriteFileTool` (Permission::WriteFile) ※ wasm では VFS / OPFS シム
- `ListDirTool` (Permission::ReadFile)

## 受け入れ基準

- [ ] 許可フローと拒否フロー両方の fixture テスト
- [ ] WebView 上で `Allow` / `Deny` ボタンが描画される
- [ ] event log に Permission 解決の足跡が残る
- [ ] OPFS 環境で WriteFile demo が動く（最低 wasm side のみ）

## 非ゴール

- ネイティブ FS（後続）
- 細粒度 ACL（path glob とか）
- セキュアサンドボックス（process 分離）

## 参考

- M2 Permission, Tool, ToolRegistry
- M3 available_actions（Allow/Deny を action として projection）
