#!/bin/bash

# 📊 ライター進捗ステータス表示スクリプト

WRITERS=("writer1" "writer2" "writer3")
DONE_DIR="./tmp"

echo ""
echo "============================="
echo "📝 記事執筆ステータス一覧"
echo "============================="
printf "%-10s | %-8s\n" "ライター" "ステータス"
echo "-----------------------------"

for writer in "${WRITERS[@]}"; do
    done_file="$DONE_DIR/${writer}_done.txt"
    if [[ -f "$done_file" ]]; then
        printf "%-10s | ✅ 完了\n" "$writer"
    else
        printf "%-10s | ⏳ 未完了\n" "$writer"
    fi
done

echo ""
