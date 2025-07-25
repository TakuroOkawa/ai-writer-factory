#!/bin/bash

# 😴 スリープ防止スクリプト
# 執筆中にPCがスリープしないようにする

# 設定
LOG_FILE="./logs/sleep_prevention.log"
CHECK_INTERVAL=60  # 1分ごとにチェック

# ログ関数
log_sleep() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p ./logs
    echo "[$timestamp] $message" >> "$LOG_FILE"
    echo "$message"
}

# スリープ防止開始
start_sleep_prevention() {
    log_sleep "🚀 スリープ防止機能を開始します"
    
    # macOSの場合
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_sleep "🍎 macOS用スリープ防止を開始"
        
        # caffeinateコマンドでスリープ防止
        caffeinate -i &
        CAFFEINATE_PID=$!
        
        log_sleep "✅ caffeinateプロセス開始 (PID: $CAFFEINATE_PID)"
        
        # プロセスIDを保存
        echo $CAFFEINATE_PID > ./tmp/sleep_prevention.pid
        
        # 監視ループ
        while true; do
            sleep $CHECK_INTERVAL
            
            # プロジェクト完了フラグをチェック
            if [ -f "./tmp/project_completed.flag" ]; then
                log_sleep "📢 プロジェクト完了を検知。スリープ防止を終了します。"
                break
            fi
            
            # 全エージェントが完了状態かチェック
            ALL_COMPLETED=1
            if [ -f "./status-manager.sh" ]; then
                # ライターの完了状態をチェック
                for writer in writer1 writer2 writer3; do
                    if [ -f "./tmp/${writer}_status.txt" ]; then
                        status=$(cat "./tmp/${writer}_status.txt")
                        if [ "$status" != "done" ]; then
                            ALL_COMPLETED=0
                            break
                        fi
                    else
                        ALL_COMPLETED=0
                        break
                    fi
                done
                
                # 全ライターが完了し、かつプロジェクト完了フラグがある場合
                if [ $ALL_COMPLETED -eq 1 ] && [ -f "./tmp/project_completed.flag" ]; then
                    log_sleep "🎉 全エージェントが完了状態です。スリープ防止を終了します。"
                    break
                fi
            fi
            
            # caffeinateプロセスが生きているかチェック
            if ! kill -0 $CAFFEINATE_PID 2>/dev/null; then
                log_sleep "⚠️  caffeinateプロセスが終了しました。再起動します。"
                caffeinate -i &
                CAFFEINATE_PID=$!
                echo $CAFFEINATE_PID > ./tmp/sleep_prevention.pid
                log_sleep "✅ caffeinateプロセス再起動 (PID: $CAFFEINATE_PID)"
            fi
            
            # 全エージェント（ライター、ディレクター、CMO）の状態をチェック
            WORKERS_ACTIVE=0
            PROJECT_ACTIVE=0
            AGENTS_ACTIVE=0
            
            # プロジェクトが開始されているかチェック（send_log.txtの存在）
            if [ -f "./logs/send_log.txt" ]; then
                PROJECT_ACTIVE=1
            fi
            
            # tmuxセッションの存在をチェック
            TMUX_SESSIONS=$(tmux list-sessions 2>/dev/null | grep -E "(article_team|cmo)" | wc -l)
            if [ $TMUX_SESSIONS -gt 0 ]; then
                AGENTS_ACTIVE=1
            fi
            
            # ステータス管理システムが利用可能な場合
            if [ -f "./status-manager.sh" ]; then
                # 各ライターのステータスをチェック
                for writer in writer1 writer2 writer3; do
                    if [ -f "./tmp/${writer}_status.txt" ]; then
                        status=$(cat "./tmp/${writer}_status.txt")
                        case $status in
                            "writing"|"completed"|"checking"|"revision")
                                WORKERS_ACTIVE=1
                                break
                                ;;
                        esac
                    fi
                done
                
                # プロジェクトが開始されているがライターが作業していない場合
                if [ $PROJECT_ACTIVE -eq 1 ] && [ $WORKERS_ACTIVE -eq 0 ]; then
                    log_sleep "⚠️  プロジェクト開始済みだがライターが作業していません"
                    if [ $AGENTS_ACTIVE -eq 1 ]; then
                        log_sleep "🔍 ディレクター/CMOが活動中。監視システムに復旧を任せます。スリープ防止を継続します。"
                        # スリープ防止を継続（監視システムが復旧を試みる）
                    else
                        log_sleep "💤 エージェントが活動していません。スリープ防止を終了します。"
                        break
                    fi
                elif [ $PROJECT_ACTIVE -eq 0 ]; then
                    log_sleep "💤 プロジェクトが開始されていません。スリープ防止を終了します。"
                    break
                fi
            else
                # 従来の方法（後方互換性のため）
                for writer in writer1 writer2 writer3; do
                    if [ -f "./tmp/${writer}_writing.txt" ] || [ -f "./tmp/${writer}_completed.txt" ] || [ -f "./tmp/${writer}_checking.txt" ] || [ -f "./tmp/${writer}_revision.txt" ]; then
                        WORKERS_ACTIVE=1
                        break
                    fi
                done
                
                if [ $WORKERS_ACTIVE -eq 0 ] && [ $AGENTS_ACTIVE -eq 0 ]; then
                    log_sleep "💤 ライターとエージェントが作業していません。スリープ防止を終了します。"
                    break
                fi
            fi
        done
        
        # スリープ防止終了
        if [ -n "$CAFFEINATE_PID" ]; then
            kill $CAFFEINATE_PID 2>/dev/null
            log_sleep "🛑 caffeinateプロセス終了 (PID: $CAFFEINATE_PID)"
        fi
        
    else
        log_sleep "⚠️  このOSではスリープ防止機能がサポートされていません"
        log_sleep "💡 手動でスリープ設定を無効にしてください"
    fi
    
    # PIDファイルを削除
    rm -f ./tmp/sleep_prevention.pid
    
    log_sleep "✅ スリープ防止機能を終了しました"
}

# スリープ防止停止
stop_sleep_prevention() {
    if [ -f "./tmp/sleep_prevention.pid" ]; then
        local pid=$(cat ./tmp/sleep_prevention.pid)
        if kill -0 $pid 2>/dev/null; then
            kill $pid
            log_sleep "🛑 スリープ防止プロセスを停止しました (PID: $pid)"
        fi
        rm -f ./tmp/sleep_prevention.pid
    else
        log_sleep "ℹ️  スリープ防止プロセスは実行されていません"
    fi
}

# 使用方法
show_usage() {
    cat << EOF
😴 スリープ防止スクリプト

使用方法:
  $0 start    # スリープ防止開始
  $0 stop     # スリープ防止停止
  $0 status   # 現在の状態確認

EOF
}

# メイン処理
main() {
    case "$1" in
        "start")
            start_sleep_prevention
            ;;
        "stop")
            stop_sleep_prevention
            ;;
        "status")
            if [ -f "./tmp/sleep_prevention.pid" ]; then
                local pid=$(cat ./tmp/sleep_prevention.pid)
                if kill -0 $pid 2>/dev/null; then
                    echo "✅ スリープ防止機能が動作中 (PID: $pid)"
                else
                    echo "❌ スリープ防止プロセスが異常終了"
                    rm -f ./tmp/sleep_prevention.pid
                fi
            else
                echo "ℹ️  スリープ防止機能は停止中"
            fi
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@" 