# Multi-agent orchestration デモ (Planner → Executor → Reviewer)

Created: 2026-05-09
Completed: 2026-05-09
Model: opencode-go/deepseek-v4-pro + codex gpt-5
Category: demo
Status: closed

## Summary

M6 の `AgentRole` / `TaskGraph` / `OrchestratorSession` を使い、
Planner → Executor → Reviewer の 3 段オーケストレーションを実演する demo。

## Motivation

M6 のデータ構造はテストで動作確認済みだが、実際にどんなワークフローを
記述できるかの reference がない。Codex / Claude Code agent の構成を
MoonBit で typed に書ける、という主張のための材料にする。

## デモシナリオ

入力: "implement a fizzbuzz function"

```
[Planner]
  task: "decompose"
  output: ["write fizzbuzz", "write tests", "run tests"]
       └─> 3 child task nodes が TaskGraph に追加される

[Executor #1] write fizzbuzz   ─┐
[Executor #2] write tests       ├─ 並列（DAG 上で並列辺）
[Executor #3] run tests <─ depends_on(#1, #2)

[Reviewer] review final
  output: pass / fail
```

## 設計

- `OrchestratorSession::add_task(role, description)` で TaskGraph に追加
- 各 task は中で Sub `Session` を持ち（M1 の Session）、子セッションの完了で
  親が次へ進む
- `SessionSnapshot` で途中状態をダンプして再開可能にする

## 受け入れ基準

- [x] 上記 fizzbuzz シナリオ相当の fixture テストが通る
- [x] TaskGraph の cycle 検出が触れる（負例テスト）
- [x] SessionSnapshot からの再開で同じ最終状態に到達
- [x] CLI: `moon run examples/orchestration` で task graph と snapshot がダンプされる

## 非ゴール

- 本物の LLM 呼び出し（mock 応答で OK）
- スケジューラ（並列実行は逐次シミュレート）
- 永続化（M5 の MemoryStorage で十分）

## 参考

- M6 AgentRole, TaskNode, TaskGraph, OrchestratorSession
- moonrepo の codex/cc sub-agent 運用パターン

## 解決方法

`examples/orchestration/` パッケージを作成し、Planner → Executor →
Reviewer の fizzbuzz task graph を fixture として実装した。`run_scenario`
は DAG の topological order に従って task ごとの sub `Session` を進め、
各段階の `SessionSnapshot` を返す。

テストでは task 数、cycle 検出、topological order、snapshot round-trip を確認した。
CLI entrypoint は `moon run examples/orchestration` として用意し、task graph と
最終 snapshot 数を表示する。
