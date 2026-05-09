# Tool-use chat デモ

Created: 2026-05-09
Category: demo
Status: open

## Summary

ユーザーメッセージから tool 呼び出し → tool 結果 → assistant 応答という
古典的な agent loop の最小版を、orbit.mbt の primitives だけで組み立てる。

## Motivation

M2 で `Tool` trait と `ToolRegistry` が揃ったので、Session の遷移と
tool dispatch を組み合わせた end-to-end の挙動を示す reference が必要。

## 構成

```
examples/tool-chat/
  src/
    tools.mbt   // EchoTool, ClockTool, AddTool 等の demo Tool
    loop.mbt    // step(session) -> session の小さな評価ループ
    main.mbt    // CLI 駆動のシナリオ
  README.md
```

## デモシナリオ

1. ユーザー: "what time is it?"
2. agent: `request_tool("clock", "{}")` → `WaitingTool`
3. registry が `ClockTool::execute` を呼び `ExecResult { output: "2026-05-09T..." }` を返す
4. `respond_tool` で `Running` に戻り `AssistantMessage` を append

## 受け入れ基準

- [ ] 3 種類以上の demo Tool（EchoTool / ClockTool / AddTool）
- [ ] 入力 → tool dispatch → 出力 を 1 関数で書ける `step` API
- [ ] CLI で対話的に実行できる（または fixture で再現できる）
- [ ] event log に ToolCall / ToolResult が正しく刻まれている
- [ ] テスト: 同じ入力列から同じ event log が決定論的に再生される

## 非ゴール

- 本物の LLM 呼び出し（後続 issue）
- 並列 tool 実行
- streaming（別 demo）

## 参考

- M1 Session / AgentEvent
- M2 Tool / ToolRegistry / Permission
