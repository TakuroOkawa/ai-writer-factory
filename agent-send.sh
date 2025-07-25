#!/bin/bash

# 🚀 Claude CLIエージェント間メッセージ送信ユーティリティ
#
# このスクリプトは、人間またはClaudeエージェント自身が使用して、
# 他のエージェント（CMO, director, writerなど）に自然言語で指示を送るためのツールです。
#
# 内部的に Claude Code は bash コマンドを実行できるため、
# 各エージェントが ./agent-send.sh を呼び出すことで、
# 他のエージェントに自動で指示を送ることができます。
#
# 例:
#   ./agent-send.sh cmo "記事を大量生産してください"
#   ./agent-send.sh writer1 "以下の構成で本文を書いてください..."

# エージェント→tmuxターゲット マッピング
get_agent_target() {
    case "$1" in
        "cmo") echo "cmo" ;;
        "director") echo "article_team:0.0" ;;
        "writer1") echo "article_team:0.1" ;;
        "writer2") echo "article_team:0.2" ;;
        "writer3") echo "article_team:0.3" ;;
        *) echo "" ;;
    esac
}

show_usage() {
    cat << EOF
🤖 Claudeエージェント宛にメッセージを送信します。

使用方法:
  $0 [エージェント名] [メッセージ]
  $0 --list

利用可能エージェント:
  cmo       - マーケティング責任者
  director  - 編集責任者
  writer1   - ライター1
  writer2   - ライター2
  writer3   - ライター3

使用例:
  $0 cmo "SEO記事を作成してください"
  $0 writer1 "以下の構成に従って本文を書いてください"

EOF
}

# エージェント一覧表示
show_agents() {
    echo "📋 利用可能なエージェント:"
    echo "=========================="
    echo "  cmo      → cmo:0            (マーケティング責任者)"
    echo "  director → article_team:0.0 (編集責任者)"
    echo "  writer1  → article_team:0.1 (ライター1)"
    echo "  writer2  → article_team:0.2 (ライター2)" 
    echo "  writer3  → article_team:0.3 (ライター3)"
}

# ログ記録
log_send() {
    local agent="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    mkdir -p logs
    echo "[$timestamp] $agent: SENT - \"$message\"" >> logs/send_log.txt
}


# メッセージ送信
send_message() {
    local target="$1"
    local message="$2"
    local max_retries=3
    local retry_count=0

    echo "📤 送信中: $target ← '$message'"

    # CMOへの新しいプロジェクト指示の場合は完了フラグを削除
    if [[ "$target" == "cmo" && "$message" == *"プロジェクト"* ]]; then
        if [ -f "./tmp/project_completed.flag" ]; then
            rm -f "./tmp/project_completed.flag"
            echo "🔄 新しいプロジェクト開始を検知。完了フラグを削除しました。"
        fi
    fi

    while [ $retry_count -lt $max_retries ]; do
        # Claude Codeのプロンプトを一度クリア
        tmux send-keys -t "$target" C-c
        sleep 1

        # 確実にクリアするために再度C-c
        tmux send-keys -t "$target" C-c
        sleep 0.5

        # プロンプトが表示されるまで待機
        sleep 2

        # メッセージ送信（改行文字をエスケープ）
        tmux send-keys -t "$target" "$message"
        sleep 1

        # エンター押下
        tmux send-keys -t "$target" C-m
        sleep 1

        # 送信確認のため少し待機
        sleep 2

        # 送信確認（ペインの内容をチェック）
        if check_message_sent "$target" "$message"; then
            echo "✅ メッセージ送信確認済み"
            return 0
        else
            retry_count=$((retry_count + 1))
            echo "⚠️  送信確認失敗 (試行 $retry_count/$max_retries)"
            if [ $retry_count -lt $max_retries ]; then
                sleep 3
            fi
        fi
    done

    echo "❌ メッセージ送信失敗 (最大試行回数到達)"
    return 1
}

# メッセージ送信確認
check_message_sent() {
    local target="$1"
    local message="$2"
    local check_count=0
    local max_checks=5

    while [ $check_count -lt $max_checks ]; do
        # ペインの内容を取得
        local pane_content=$(tmux capture-pane -t "$target" -p 2>/dev/null)
        
        # メッセージが表示されているかチェック
        if echo "$pane_content" | grep -q "$message"; then
            return 0
        fi
        
        # プロンプトが表示されているかチェック
        if echo "$pane_content" | grep -q ">"; then
            return 0
        fi
        
        check_count=$((check_count + 1))
        sleep 1
    done
    
    return 1
}

# ターゲット存在確認
check_target() {
    local target="$1"
    local session_name="${target%%:*}"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "❌ セッション '$session_name' が見つかりません"
        return 1
    fi

    return 0
}

# メイン処理
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    if [[ "$1" == "--list" ]]; then
        show_agents
        exit 0
    fi

    if [[ $# -lt 2 ]]; then
        show_usage
        exit 1
    fi

    local agent_name="$1"
    local message="$2"

    # ターゲット取得
    local target
    target=$(get_agent_target "$agent_name")

    if [[ -z "$target" ]]; then
        echo "❌ エラー: 不明なエージェント '$agent_name'"
        echo "利用可能エージェント: $0 --list"
        exit 1
    fi

    if ! check_target "$target"; then
        exit 1
    fi

    send_message "$target" "$message"
    log_send "$agent_name" "$message"

    echo "✅ 送信完了: $agent_name に '$message'"
    return 0
}

main "$@"
