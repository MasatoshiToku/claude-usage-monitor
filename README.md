# Claude Usage Monitor

Claude.ai（Pro/Team）3アカウントの使用量をmacOSメニューバーから一覧監視するアプリ。

[Claude-Usage-Tracker](https://github.com/hamed-elfayome/Claude-Usage-Tracker) のフォーク。3アカウント同時表示に特化した改修版。

## 概要

- 3つのClaude.aiアカウントの使用量をメニューバーアイコンで常時表示
- 各アカウントのセッション使用率、週間使用率をリアルタイム監視
- sessionKey期限切れ時のmacOS通知による再認証フロー
- 60秒間隔の自動リフレッシュ

## セットアップ

### 要件
- macOS 13.0+
- Xcode 15.0+

### ビルド
```bash
git clone https://github.com/MasatoshiToku/claude-usage-monitor.git
cd claude-usage-monitor
open "Claude Usage.xcodeproj"
# Xcode で Build & Run (⌘R)
```

### sessionKey の取得

1. ブラウザで [claude.ai](https://claude.ai) にログイン
2. DevTools (F12) → Application → Cookies → `sessionKey` をコピー
3. アプリの Settings → 各プロファイルに sessionKey を設定

## 使い方

- 初回起動で3つのプロファイルが自動作成される
- 各プロファイルに sessionKey を設定すると使用量の監視が開始
- メニューバーアイコンをクリックで詳細表示
- sessionKey 期限切れ時はmacOS通知で再設定を案内

## オリジナルからの変更点

- 3プロファイル固定（作成/削除不可）
- 常時マルチプロファイル表示モード
- デフォルトリフレッシュ間隔: 60秒
- 401検知 → macOS通知による再認証フロー（10分レート制限）
- Sparkle自動更新の削除
- GitHub Star / Feedback プロンプトの削除
- Bundle ID変更（元アプリとのデータ衝突回避）

## 技術スタック

- Swift / SwiftUI
- macOS Menu Bar App (LSUIElement)
- UserNotifications (再認証通知)
- Keychain (sessionKey保存)

## ライセンス

MIT License（[オリジナル](https://github.com/hamed-elfayome/Claude-Usage-Tracker)に準拠）
