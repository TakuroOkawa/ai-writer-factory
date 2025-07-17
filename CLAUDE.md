# SEO記事量産システム

## エージェント構成
- **CMO** (別セッション): マーケティング統括責任者
- **director** (multiagent:0.0): コンテンツディレクター
- **writer1,2,3** (multiagent:0.1-3): SEOライター

## あなたの役割
- **CMO**: @instructions/cmo.md
- **director**: @instructions/director.md
- **writer1,2,3**: @instructions/writer.md

## メッセージ送信
```bash
./agent-send.sh [相手] "[メッセージ]"
```

## 基本フロー
CMO → director → writers → director → CMO 