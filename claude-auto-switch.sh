#!/bin/bash

# 🤖 Claude自動切り替えスクリプト
# Opusのリミットに達した時にSonnetに自動切り替え

# 設定
OPUS_MODEL="opus"
SONNET_MODEL="sonnet"
LOG_FILE="./logs/claude_switch.log"

# ログ関数
log_switch() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p ./logs
    echo "[$timestamp] $message" >> "$LOG_FILE"
    echo "$message"
}

# Claude CLIを起動（自動切り替え機能付き）
start_claude_with_auto_switch() {
    local session_name="$1"
    local pane_name="$2"
    local initial_model="$3"
    
    log_switch "🚀 $pane_name セッション開始: $initial_model モデルで起動"
    
    # 最初のモデルで起動
    tmux send-keys -t "$session_name" "claude --model $initial_model --dangerously-skip-permissions" C-m
    
    # エラーハンドリング用の監視ループ
    while true; do
        # 5分ごとにエラーをチェック（負荷軽減）
        sleep 300
        
        # エラーメッセージをチェック
        local error_output=$(tmux capture-pane -t "$session_name" -p 2>/dev/null | tail -5)
        
        # Opusリミットエラーを検出
        if echo "$error_output" | grep -q "rate limit\|limit exceeded\|quota exceeded"; then
            log_switch "⚠️  $pane_name: Opusリミット検出、Sonnetに切り替え中..."
            
            # 現在のセッションをクリア
            tmux send-keys -t "$session_name" C-c
            sleep 2
            tmux send-keys -t "$session_name" C-c
            sleep 1
            
            # Sonnetで再起動
            tmux send-keys -t "$session_name" "claude --model $SONNET_MODEL --dangerously-skip-permissions" C-m
            log_switch "✅ $pane_name: Sonnetに切り替え完了"
            
            # 切り替え完了メッセージを送信
            tmux send-keys -t "$session_name" "echo '🔄 OpusリミットによりSonnetに自動切り替えしました。作業を継続してください。'" C-m
            sleep 2
            tmux send-keys -t "$session_name" C-m
            
            break
        fi
        
        # セッションが終了しているかチェック
        if ! tmux has-session -t "$session_name" 2>/dev/null; then
            log_switch "📴 $pane_name: セッション終了を検出"
            break
        fi
    done
}

# 使用方法
show_usage() {
    cat << EOF
🤖 Claude自動切り替えスクリプト

使用方法:
  $0 [セッション名] [ペイン名] [初期モデル]

例:
  $0 cmo "CMO" opus
  $0 article_team:0.0 "director" opus

EOF
}

# メイン処理
main() {
    if [ $# -ne 3 ]; then
        show_usage
        exit 1
    fi
    
    local session_name="$1"
    local pane_name="$2"
    local initial_model="$3"
    
    log_switch "🔄 自動切り替え監視開始: $pane_name ($initial_model → $SONNET_MODEL)"
    start_claude_with_auto_switch "$session_name" "$pane_name" "$initial_model"
}

# スクリプト実行
main "$@" 