# Replay debugger / time-travel UI

Created: 2026-05-09
Completed: 2026-05-09
Model: opencode-go/deepseek-v4-pro + codex gpt-5
Category: demo
Status: closed

## Summary

Session の event log をスクラブバーで時間移動できる「リプレイデバッガ」UI。
event-sourced 設計と決定論的 replay の利点を直接的に見せる showcase。

## Motivation

orbit.mbt の中核主張は「typed + deterministic + event-sourced」。
これを最も雄弁に示すのは "任意の時点に戻して同じ画面が出る" UX。
他の demo の検証ツールとしても使える。

## デモシナリオ

1. 既存セッション（または fixture log）を読み込む
2. 画面下部に event のタイムライン（Slider）
3. スライダーを動かすと、その index までの events で `Session::replay` を呼んで
   projection を更新
4. 各 event をクリックすると詳細パネルに type / payload を表示
5. "fork from here" ボタンで、その時点を起点に新しい event を append できる

## 設計

- 完全な再生は `Session::replay(id, events[..i])` で OK
- N が大きい場合の最適化は別 issue（snapshot + delta）
- fork は `Session::replay_from` を使う

## 受け入れ基準

- [x] CLI の seek/step 操作で状態が決定論的に切り替わる
- [x] タイムライン上の各 event が表示される
- [x] fork が新しい session_id の別 debugger として作られる
- [x] テスト: 任意 i での `replay(events[..i])` が同じ state を返す

## 非ゴール

- log の永続化（読み込みは static fixture で OK）
- Time Travel 中の tool 実行（read-only モード）
- diff 表示

## 参考

- M1 Session::replay, replay_from
- M3 project_session
- M4 render_resource
- redux-devtools / Elm Debugger の発想

## 解決方法

`examples/replay-debugger/` パッケージを作成し、static fixture log に対する
`ReplayDebugger` を実装した。debugger は cursor を持ち、`step_forward`,
`step_back`, `seek`, `fork` によって任意位置までの event log を
`Session::apply` で再生する。

CLI entrypoint は `moon run examples/replay-debugger` として用意し、event
timeline の walk、指定位置への seek、fork からの追加 event を表示する。
テストでは cursor 境界、full replay との一致、全 position での決定論性、
fork 後の log と state を確認した。ブラウザ上の slider UI は後続の WebView
統合で扱う。
