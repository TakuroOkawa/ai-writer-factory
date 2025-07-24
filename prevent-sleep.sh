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
            
            # caffeinateプロセスが生きているかチェック
            if ! kill -0 $CAFFEINATE_PID 2>/dev/null; then
                log_sleep "⚠️  caffeinateプロセスが終了しました。再起動します。"
                caffeinate -i &
                CAFFEINATE_PID=$!
                echo $CAFFEINATE_PID > ./tmp/sleep_prevention.pid
                log_sleep "✅ caffeinateプロセス再起動 (PID: $CAFFEINATE_PID)"
            fi
            
            # ライターが作業中かチェック
            WORKERS_ACTIVE=0
            for writer in writer1 writer2 writer3; do
                if [ -f "./tmp/${writer}_writing.txt" ] || [ -f "./tmp/${writer}_completed.txt" ] || [ -f "./tmp/${writer}_checking.txt" ] || [ -f "./tmp/${writer}_revision.txt" ]; then
                    WORKERS_ACTIVE=1
                    break
                fi
            done
            
            if [ $WORKERS_ACTIVE -eq 0 ]; then
                log_sleep "💤 ライターが作業していません。スリープ防止を終了します。"
                break
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