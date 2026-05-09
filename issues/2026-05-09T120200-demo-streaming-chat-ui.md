# Streaming chat UI デモ

Created: 2026-05-09
Category: demo
Status: open

## Summary

`StreamChunk` イベントを連続発火し、HTML projection が逐次更新される様を見せる demo。
wasm-webview デモの上に乗る形で、`mhx` 風の partial swap UX を MoonBit 側で実現する。

## Motivation

M4 で `collect_stream_chunks` は実装済みだが、リアルタイムに描画される
体験を示す reference がまだない。LLM streaming や tool stdout の擬似体験として有用。

## デモシナリオ

1. "generate poem" ボタンを押す
2. agent が 200ms ごとに `StreamChunk("...")` を append する
3. 画面の assistant bubble が伸びていく
4. 最後に `AssistantMessage(full_text)` で確定 → bubble が "確定済み" に切り替わる

## 設計ポイント

- 1 イベント追加ごとに full re-render は重いので、projection に
  「最後の chunk からの差分」を返す API を別途検討する（後続 issue 化可）
- まずは full re-render ベースで OK
- timer は wasm-webview 側 (`setInterval`) から MoonBit へ tick する

## 受け入れ基準

- [ ] `StreamChunk` を 10〜30 個 push しても破綻しない
- [ ] 画面に文字が増えていく様が確認できる
- [ ] 最終確定後に event log と画面が一致する
- [ ] テスト: chunks の集約結果が `collect_stream_chunks` と一致

## 非ゴール

- 本物の SSE / WebSocket
- 中断・キャンセル（別 issue）
- backpressure

## 依存

- demo-wasm-webview-bridge が先にあるとよい（後追いでも可）
