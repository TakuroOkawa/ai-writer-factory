#!/bin/bash

# 🔍 AI記事生成システム監視スクリプト

# 設定
CHECK_INTERVAL=30  # 30秒ごとにチェック
TIMEOUT_THRESHOLD=300  # 5分間動きがなければタイムアウト
LOG_DIR="./logs/watchdog"
mkdir -p "$LOG_DIR"

# 最後の活動時刻を記録するファイル
ACTIVITY_FILE="$LOG_DIR/last_activity.txt"
STATE_FILE="$LOG_DIR/system_state.txt"

# 起動時刻を記録
START_TIME=$(date +%s)
GRACE_PERIOD=600  # 起動後10分間は猶予期間

# 監視ログ
log_watchdog() {
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DIR/watchdog.log"
}

# アクティビティをチェック
check_activity() {
   CURRENT_TIME=$(date +%s)
   
   # 起動後の猶予期間中はOKとする
   TIME_SINCE_START=$((CURRENT_TIME - START_TIME))
   if [ $TIME_SINCE_START -lt $GRACE_PERIOD ]; then
       return 0
   fi
   
   # プロジェクトが開始されているか確認
   if [ ! -f "./logs/send_log.txt" ]; then
       # まだプロジェクトが始まっていない
       return 0
   fi
   
   # send_log.txtの最終更新時刻を確認
   if [[ "$OSTYPE" == "darwin"* ]]; then
       # macOS
       LAST_LOG_UPDATE=$(stat -f "%m" "./logs/send_log.txt" 2>/dev/null)
   else
       # Linux
       LAST_LOG_UPDATE=$(stat -c "%Y" "./logs/send_log.txt" 2>/dev/null)
   fi
   
   TIME_DIFF=$((CURRENT_TIME - LAST_LOG_UPDATE))
   
   if [ $TIME_DIFF -gt $TIMEOUT_THRESHOLD ]; then
       return 1  # タイムアウト
   fi
   
   # 作業中ファイルの存在チェック
   WRITERS_WORKING=$(ls ./tmp/writer*_writing.txt 2>/dev/null | wc -l)
   WRITERS_DONE=$(ls ./tmp/writer*_done.txt 2>/dev/null | wc -l)
   
   echo "WORKING=$WRITERS_WORKING,DONE=$WRITERS_DONE,LAST_UPDATE=$TIME_DIFF" > "$STATE_FILE"
   return 0
}

# 停滞を検出して対処
handle_stall() {
   log_watchdog "⚠️ システム停滞を検出！自動復旧を試みます..."
   
   # 1. 現在の状態を確認
   CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null)
   log_watchdog "現在の状態: $CURRENT_STATE"
   
   # 2. 進行状況を確認
   WRITERS_DONE=$(ls ./tmp/writer*_done.txt 2>/dev/null | wc -l)
   
   if [ $WRITERS_DONE -eq 0 ]; then
       # まだ誰も完了していない → Writerに催促
       log_watchdog "記事が1つも完成していません。Writerに催促します。"
       
       for i in 1 2 3; do
           ./agent-send.sh writer$i "【緊急】進捗確認

現在の執筆状況を30秒以内に報告してください。
もし行き詰まっている場合は、以下を実行してください：

1. 現在書いている部分を一旦保存
2. Directorに相談
3. 作業を継続

30秒以内に応答がない場合は、作業を中断していると判断します。" 2>/dev/null
           sleep 2
       done
       
   elif [ $WRITERS_DONE -lt 3 ]; then
       # 一部完了 → Directorに確認を促す
       log_watchdog "一部の記事が完成。Directorに品質チェックを促します。"
       
       ./agent-send.sh director "【システム通知】品質チェック遅延

完了した記事の品質チェックが滞っているようです。
以下を確認してください：

1. Writerからの完了報告を見逃していないか
2. 品質チェックで問題があったか
3. CMOへの報告が必要か

すぐに以下のアクションを取ってください：
- 完了記事があれば品質チェック実施
- 問題があればWriterにフィードバック
- すべて完了していればCMOに報告" 2>/dev/null
       
   else
       # 全部完了 → CMOに最終報告を促す
       log_watchdog "すべての記事が完成。CMOに最終報告を促します。"
       
       ./agent-send.sh cmo "【システム通知】記事制作完了の可能性

すべてのWriterが作業を完了したようです。
Directorからの最終報告を待っているか、
すでに完了している可能性があります。

以下を確認してください：
1. Directorから完了報告は来ていますか？
2. 人間への最終報告は実施しましたか？

もし完了しているなら、最終報告を実行してください。" 2>/dev/null
   fi
   
   # 3. 30秒待って反応を確認
   sleep 30
   
   # 4. それでも動かない場合は、より強い介入
   if ! check_activity; then
       log_watchdog "❌ 通常の復旧失敗。強制的な再開を試みます。"
       
       # Directorに強制的な再割り当てを指示
       ./agent-send.sh director "【緊急対応】システム完全停滞

5分以上システムが停止しています。
以下の緊急対応を実行してください：

1. 各Writerの状況を確認
2. 応答のないWriterのタスクを再割り当て
3. 必要に応じて記事数を削減
4. CMOに状況報告

このメッセージを受け取ったら、必ず何らかのアクションを取ってください。" 2>/dev/null
       
       # CMOにも通知
       tmux send-keys -t cmo C-c
       tmux send-keys -t cmo "echo ''" C-m
       tmux send-keys -t cmo "echo '🚨 システム緊急事態 🚨'" C-m
       tmux send-keys -t cmo "echo 'Directorに緊急対応を指示しました。'" C-m
       tmux send-keys -t cmo "echo '必要に応じて手動介入してください。'" C-m
       
       # デスクトップ通知
       osascript -e 'display notification "AI記事生成システムが停止しています。手動介入が必要かもしれません。" with title "🚨 緊急通知" sound name "Sosumi"' 2>/dev/null
   else
       log_watchdog "✅ システムが再開しました"
   fi
}

# メインループ
log_watchdog "🚀 監視システムを開始します"
log_watchdog "起動後10分間は猶予期間です"
echo "監視中... (Ctrl+C で終了)"

while true; do
   if ! check_activity; then
       handle_stall
   fi
   sleep $CHECK_INTERVAL
done