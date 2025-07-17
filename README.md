# 🧠 記事生成AIプロジェクト（Claude Code）

SEOに強い記事をチームで自動生成する、Claude Codeを活用したプロジェクト構成です。

## 📦 構成概要

このプロジェクトでは、以下の仮想エージェントが連携し、記事を分担生成します。

| エージェント | 役割 |
|-------------|------|
| 👩‍💼 CMO       | 市場戦略・全体方針の立案 |
| 👨‍💼 Director  | 構成・指示・品質要件の整理 |
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

## 🗂 ディレクトリ構成

```
.
├── setup.sh
├── agent-send.sh
├── project-status.sh
├── instructions/
│   ├── cmo.md
│   ├── director.md
│   └── writer.md
├── logs/
│   └── send_log.txt
├── tmp/
│   └── writer*_done.txt
```

---

## 📡 自動連携の流れ

1. CMOに指示を送信  
2. CMOがDirectorに自動指示  
3. DirectorがWriterに指示を展開  
4. 各Writerが記事を執筆し、完了報告  
5. Directorが進捗確認・統合  
6. CMOに報告が返る

これらは Claude Code のチャット機能を通じて**自動で実行されます**。

---

## ✅ 状態の確認

```bash
./project-status.sh
```

- 各ライターの完了状況が `tmp/` 以下のファイルで確認可能
- メッセージ送信履歴は `logs/send_log.txt` に記録されます

---

## 📝 備考

- Claude CLI を複数ペインで同時に扱うため、セッション名やペイン番号には注意
- `launch-agents.sh` は不要になったため削除済み
- `CLAUDE.md` に Claude Code の使い方補足あり
