# 🧠 記事生成AIプロジェクト（Claude Code）

SEOに強い記事をチームで自動生成する、Claude Codeを活用したプロジェクト構成です。

## 📦 構成概要

このプロジェクトでは、以下の仮想エージェントが連携し、記事を分担生成します。

| エージェント | 役割 |
|-------------|------|
| 👩‍💼 CMO       | 市場戦略・全体方針の立案・クエリ戦略・トピッククラスター設計 |
| 👨‍💼 Director  | 構成・指示・品質要件の整理・記事構成設計 |
| ✍️ Writer1〜3 | 記事の執筆と仕上げ |

## 🚀 セットアップ手順

### 1. 前提環境

- Node.js（最新版 LTS）: https://nodejs.org/ja
- Claude CLI: `npm install -g @anthropic-ai/claude-code`
- `tmux` がインストール済みであること
- macOS ターミナルでの動作を想定（zsh/bash）

### 2. セットアップスクリプトの実行

```bash
chmod +x setup.sh
./setup.sh
```

成功すると、以下の tmux セッションが自動構成されます：

- `cmo`：CMO（単独）
- `article_team`：Director + Writer1〜3（各ペイン）

各ペインでは Claude CLI が自動起動します。

### 3. セッションに入る

```bash
tmux attach -t cmo
# または
tmux attach -t article_team
```

---

## ✉️ メッセージ送信方法

人間から任意のエージェントに指示を出したい場合は `agent-send.sh` を使います：

```bash
./agent-send.sh [エージェント名] "メッセージ"
```

例：

```bash
./agent-send.sh cmo "あなたはCMOです。歯科医院向けのSEO記事を大量に作ってください。"
```

利用可能エージェントは以下で確認できます：

```bash
./agent-send.sh --list
```

---

## 📊 ステータス管理システム

### 進捗状況の確認

```bash
# 全ライターのステータス表示
./status-manager.sh show

# 停滞チェック
./status-manager.sh check

# ステータス更新（ライター用）
./status-manager.sh update writer1 writing "H2の執筆中"

# 全ステータスリセット
./status-manager.sh reset
```

### ステータスの種類

| ステータス | 説明 | タイムアウト |
|-----------|------|-------------|
| writing | 執筆中 | 10分 |
| completed | 完成（チェック待ち） | 3分 |
| checking | Director確認中 | 5分 |
| revision | 修正中 | 5分 |
| done | 完了 | なし |

---

## 🛡️ 監視システム

### 自動監視

```bash
# 監視システムの開始
./watchdog.sh
```

- 30秒ごとに各ライターの進捗をチェック
- 停滞を検出すると自動的に介入メッセージを送信
- プロジェクト完了時に自動停止
- 改善されたメッセージ送信機能により、より確実な介入が可能
- **自動再開機能**: プロジェクト完了後、新しいプロジェクト開始時に自動的に監視を再開

### 監視ログの確認

```bash
# 監視ログの最新エントリ
tail -f logs/watchdog/watchdog.log

# ステータス管理ログ
tail -f logs/status_manager.log
```

---

## 🗂 ディレクトリ構成

```
.
├── setup.sh                    # セットアップスクリプト
├── agent-send.sh              # エージェント間メッセージ送信
├── status-manager.sh          # ステータス管理システム
├── watchdog.sh                # 監視システム
├── project-status.sh          # プロジェクト状況表示
├── instructions/              # エージェント指示書
│   ├── cmo.md
│   ├── director.md
│   └── writer.md
├── logs/                      # ログファイル
│   ├── send_log.txt          # メッセージ送信履歴
│   ├── status_manager.log    # ステータス管理ログ
│   └── watchdog/             # 監視ログ
├── tmp/                       # 一時ファイル
│   ├── writer*_status.txt    # ライターステータス
│   ├── writer*_progress.txt  # 進捗状況
│   ├── writer*_last_update.txt # 最終更新時刻
│   └── project_completed.flag # プロジェクト完了フラグ
└── articles/                  # 生成された記事
```

---

## 📡 自動連携の流れ

1. CMOに指示を送信  
2. CMOがDirectorに自動指示  
3. DirectorがWriterに指示を展開  
4. 各Writerが記事を執筆し、ステータス更新
5. Directorが品質チェック・統合  
6. CMOに報告が返る
7. プロジェクト完了フラグ作成でシステム停止

これらは Claude Code のチャット機能を通じて**自動で実行されます**。

---

## 🎯 記事品質の特徴

### 文章構成のバランス
- **文章**: 理由・心理・事例・物語的説明
- **箇条書き**: 手順・比較・チェックリスト・具体例
- **表**: 数値データ・スケジュール・比較表

### 信頼性の確保
- 架空の成功事例・患者口コミは禁止
- 客観的データ・理論的根拠を重視
- 具体的な医院名は使用しない

### 自然な表現
- 文末の「です：」「になります：」を避ける
- 読みやすく実践的な内容

---

## 💡 実際の使用例

### プロジェクト開始

```bash
# 1. セットアップ
./setup.sh

# 2. 監視システム開始（初回のみ）
./watchdog.sh

# 3. CMOにプロジェクト指示
./agent-send.sh cmo "歯科医院のGoogle口コミ戦略について5記事作成してください。プロジェクト名はdental-google-reviewsです。"
```

**注意**: 監視システムは一度起動すれば、プロジェクト完了後も自動的に新しいプロジェクトを待機します。手動で再起動する必要はありません。

### 進捗確認

```bash
# リアルタイム状況確認
./project-status.sh

# 詳細ステータス
./status-manager.sh show

# 停滞チェック
./status-manager.sh check
```

### 結果確認

```bash
# 生成された記事の確認
ls -la articles/$(date +%Y%m%d)_dental-google-reviews/

# CMOレポートの確認
cat articles/$(date +%Y%m%d)_dental-google-reviews/seo_project_report.md
```

---

## ✅ 状態の確認

```bash
# プロジェクト全体の状況
./project-status.sh

# 詳細なステータス表示
./status-manager.sh show

# 停滞チェック
./status-manager.sh check
```

- 各ライターのステータスは `tmp/` 以下のファイルで管理
- メッセージ送信履歴は `logs/send_log.txt` に記録
- 監視ログは `logs/watchdog/` に保存

---

## 🔧 トラブルシューティング

### システムが停止しない場合

```bash
# 手動でプロジェクト完了フラグを作成
touch ./tmp/project_completed.flag

# 監視システムを手動停止
tmux kill-session -t watchdog 2>/dev/null
```

### ステータスがリセットしたい場合

```bash
# 全ステータスリセット
./status-manager.sh reset

# 特定ライターのリセット
./status-manager.sh reset-writer writer1
```

### メッセージが送信されない場合

```bash
# エージェントセッションの再起動
tmux kill-session -t cmo 2>/dev/null
tmux kill-session -t article_team 2>/dev/null
./setup.sh
```

### 監視システムが検知しない場合

```bash
# 監視システムの再起動
tmux kill-session -t watchdog 2>/dev/null
./watchdog.sh
```

---

## 📝 備考

- Claude CLI を複数ペインで同時に扱うため、セッション名やペイン番号には注意
- ステータス管理システムにより、停滞の早期発見と適切な介入が可能
- 監視システムにより、長時間の停滞を自動検出
- `CLAUDE.md` に Claude Code の使い方補足あり
- 記事はプロジェクト別フォルダ（`YYYYMMDD_project-name/`）に保存
- CMOのレポートも各プロジェクトフォルダ内に保存される
- プロジェクト名はCMOへの指示時に指定（例：`dental-google-reviews`）
- 改善されたメッセージ送信機能により、より確実なエージェント間通信が可能
- **監視システムの自動再開**: プロジェクト完了後、新しいプロジェクト開始時に自動的に監視を再開（手動操作不要）
