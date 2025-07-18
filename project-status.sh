#!/bin/bash

echo ""
echo "============================="
echo "📊 システム稼働状況"
echo "============================="

# 監視システムの状態
if tmux has-session -t watchdog 2>/dev/null; then
    echo "🟢 監視システム: 稼働中"
else
    echo "🔴 監視システム: 停止中"
fi

# 最後の活動時刻
if [ -f "./logs/send_log.txt" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        LAST_ACTIVITY=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "./logs/send_log.txt")
    else
        LAST_ACTIVITY=$(date -d @$(stat -c "%Y" "./logs/send_log.txt") "+%Y-%m-%d %H:%M:%S")
    fi
    echo "⏰ 最終活動: $LAST_ACTIVITY"
fi

echo ""
echo "============================="
echo "📝 記事執筆ステータス一覧"
echo "============================="
printf "%-10s | %-8s\n" "ライター" "ステータス"
echo "-----------------------------"

WRITERS=("writer1" "writer2" "writer3")
for writer in "${WRITERS[@]}"; do
    if [[ -f "./tmp/${writer}_writing.txt" ]]; then
        TASK=$(cat "./tmp/${writer}_writing.txt")
        printf "%-10s | ⏳ 執筆中: %s\n" "$writer" "$TASK"
    elif [[ -f "./tmp/${writer}_done.txt" ]]; then
        printf "%-10s | ✅ 完了\n" "$writer"
    else
        printf "%-10s | ⏸️  待機中\n" "$writer"
    fi
done

echo ""

# 監視ログの最新エントリ
if [ -f "./logs/watchdog/watchdog.log" ]; then
    echo "============================="
    echo "📋 監視ログ（最新5件）"
    echo "============================="
    tail -5 ./logs/watchdog/watchdog.log
fi