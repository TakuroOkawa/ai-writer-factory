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
    # プロジェクト完了フラグがあれば一時停止（削除されるまで待機）
    if [ -f "./tmp/project_completed.flag" ]; then
        log_watchdog "📢 プロジェクト完了を検知。新しいプロジェクト開始を待機中..."
        echo "✅ プロジェクトが完了しました。新しいプロジェクト開始を待機中..."
        
        # 完了フラグが削除されるまで待機（負荷軽減のため60秒間隔）
        while [ -f "./tmp/project_completed.flag" ]; do
            sleep 60  # 10秒 → 60秒に変更して負荷軽減
        done
        
        log_watchdog "🔄 新しいプロジェクト開始を検知。監視を再開します。"
        echo "🔄 新しいプロジェクトが開始されました。監視を再開します。"
        
        # 新しいプロジェクトの開始時刻を記録
        START_TIME=$(date +%s)
        return 0
    fi
    
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
   
   # ステータス管理システムを使用して停滞チェック
   if [ -f "./status-manager.sh" ]; then
       if ! ./status-manager.sh check >/dev/null 2>&1; then
           # 停滞が検出された場合
           return 1
       fi
   else
       # 従来の方法（後方互換性のため）
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
   fi
   
   return 0
}

# 停滞を検出して対処
handle_stall() {
   log_watchdog "⚠️ システム停滞を検出！自動復旧を試みます..."
   
   # 1. 現在の状態を確認
   if [ -f "./status-manager.sh" ]; then
       CURRENT_STATUS=$(./status-manager.sh show 2>/dev/null)
       log_watchdog "現在のステータス: $CURRENT_STATUS"
   else
       CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null)
       log_watchdog "現在の状態: $CURRENT_STATE"
   fi
   
   # 2. 進行状況を確認（新しいステータス管理システムを使用）
   if [ -f "./status-manager.sh" ]; then
       # 新しいステータス管理システムを使用
       WRITERS_DONE=0
       WRITERS_COMPLETED=0
       WRITERS_CHECKING=0
       
       for writer in writer1 writer2 writer3; do
           if [ -f "./tmp/${writer}_status.txt" ]; then
               status=$(cat "./tmp/${writer}_status.txt")
               case $status in
                   "done") WRITERS_DONE=$((WRITERS_DONE + 1)) ;;
                   "completed") WRITERS_COMPLETED=$((WRITERS_COMPLETED + 1)) ;;
                   "checking") WRITERS_CHECKING=$((WRITERS_CHECKING + 1)) ;;
               esac
           fi
       done
       
       if [ $WRITERS_DONE -eq 0 ] && [ $WRITERS_COMPLETED -eq 0 ]; then
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
           
       elif [ $WRITERS_COMPLETED -gt 0 ]; then
           # 完了待ちの記事がある → Directorに確認を促す
           log_watchdog "完了した記事があります。Directorに品質チェックを促します。"
           
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
           
       elif [ $WRITERS_DONE -eq 3 ]; then
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
   else
       # 従来の方法（後方互換性のため）
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
   fi
   
   # 3. 段階的な復旧手順
   log_watchdog "🔄 段階的な復旧手順を開始します..."
   
   # ステップ1: エージェントの健康状態チェック
   local agents_to_restart=()
   
   # Directorの健康状態チェック
   if ! check_agent_health "director" "article_team:0.0"; then
       agents_to_restart+=("director:article_team:0.0")
   fi
   
   # Writerの健康状態チェック
   for i in 1 2 3; do
       if ! check_agent_health "writer$i" "article_team:0.$i"; then
           agents_to_restart+=("writer$i:article_team:0.$i")
       fi
   done
   
   # CMOの健康状態チェック
   if ! check_agent_health "cmo" "cmo:0.0"; then
       agents_to_restart+=("cmo:cmo:0.0")
   fi
   
   # ステップ2: 問題のあるエージェントを再起動
   if [ ${#agents_to_restart[@]} -gt 0 ]; then
       log_watchdog "🔄 問題のあるエージェントを再起動: ${agents_to_restart[*]}"
       
       for agent_info in "${agents_to_restart[@]}"; do
           IFS=':' read -r agent target <<< "$agent_info"
           restart_agent "$agent" "$target"
       done
       
       # 再起動後の安定化待機
       sleep 15
   fi
   
   # ステップ3: 30秒待って反応を確認
   sleep 30
   
   # ステップ4: それでも動かない場合は、より強い介入
   if ! check_activity; then
       log_watchdog "❌ 自動復旧失敗。手動介入を促します。"
       
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

# エージェント監視強化
check_agent_health() {
    local agent="$1"
    local target="$2"
    local health_status=0
    
    # 1. tmuxセッションの存在確認
    if ! tmux has-session -t "${target%%:*}" 2>/dev/null; then
        log_watchdog "❌ $agent: tmuxセッションが存在しません"
        return 1
    fi
    
    # 2. プロセス状態確認
    local pane_pid=$(tmux list-panes -t "$target" -F "#{pane_pid}" 2>/dev/null | head -1)
    if [ -z "$pane_pid" ]; then
        log_watchdog "❌ $agent: ペインPIDが取得できません"
        return 1
    fi
    
    # 3. Claudeプロセスの確認
    local claude_processes=$(ps aux | grep claude | grep -v grep | wc -l)
    if [ $claude_processes -eq 0 ]; then
        log_watchdog "❌ $agent: Claudeプロセスが存在しません"
        return 1
    fi
    
    # 4. 応答性テスト
    if ! test_agent_response "$target"; then
        log_watchdog "❌ $agent: 応答テスト失敗"
        return 1
    fi
    
    log_watchdog "✅ $agent: 正常動作中"
    return 0
}

# エージェント応答テスト
test_agent_response() {
    local target="$1"
    local test_message="test_response_$(date +%s)"
    
    # テストメッセージ送信
    tmux send-keys -t "$target" C-c
    sleep 1
    tmux send-keys -t "$target" "$test_message" C-m
    sleep 3
    
    # 応答確認
    local pane_content=$(tmux capture-pane -t "$target" -p 2>/dev/null)
    if echo "$pane_content" | grep -q "$test_message"; then
        return 0
    fi
    
    return 1
}

# エージェント自動再起動
restart_agent() {
    local agent="$1"
    local target="$2"
    
    log_watchdog "🔄 $agent を再起動します..."
    
    case "$agent" in
        "director")
            tmux send-keys -t "$target" C-c
            sleep 2
            tmux send-keys -t "$target" "claude --model opus --dangerously-skip-permissions" C-m
            ;;
        "writer1"|"writer2"|"writer3")
            tmux send-keys -t "$target" C-c
            sleep 2
            tmux send-keys -t "$target" "claude --model sonnet --dangerously-skip-permissions" C-m
            ;;
        "cmo")
            tmux send-keys -t "$target" C-c
            sleep 2
            tmux send-keys -t "$target" "claude --model opus --dangerously-skip-permissions" C-m
            ;;
    esac
    
    # 再起動後の安定化待機
    sleep 10
    
    # 再起動確認
    if check_agent_health "$agent" "$target"; then
        log_watchdog "✅ $agent 再起動成功"
        return 0
    else
        log_watchdog "❌ $agent 再起動失敗"
        return 1
    fi
}

# メインループ
log_watchdog "🚀 監視システムを開始します"
log_watchdog "起動後10分間は猶予期間です"
log_watchdog "自動復旧機能: 有効"
log_watchdog "エージェント監視: 有効"
log_watchdog "メッセージ送信確認: 有効"
echo "監視中... (Ctrl+C で終了)"

while true; do
   # 定期的なエージェント健康状態チェック
   if [ $((SECONDS % 300)) -eq 0 ]; then  # 5分ごと
       log_watchdog "🔍 定期健康状態チェックを実行中..."
       
       # Directorの健康状態チェック
       if ! check_agent_health "director" "article_team:0.0"; then
           log_watchdog "⚠️  Directorの健康状態に問題を検知"
       fi
       
       # CMOの健康状態チェック
       if ! check_agent_health "cmo" "cmo:0.0"; then
           log_watchdog "⚠️  CMOの健康状態に問題を検知"
       fi
   fi
   
   # 通常の活動チェック
   if ! check_activity; then
       handle_stall
   fi
   
   sleep $CHECK_INTERVAL
done