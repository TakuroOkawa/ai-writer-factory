#!/bin/bash

# 📊 ステータス管理ユーティリティ
# ライターの作業状況を追跡し、停滞を検出する

# ログ記録
log_status() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p logs
    echo "[$timestamp] STATUS: $message" >> logs/status_manager.log
}

# ステータス更新
update_status() {
    local writer="$1"
    local status="$2"
    local progress="$3"
    
    # ディレクトリ作成
    mkdir -p tmp
    
    # ステータスファイル更新
    echo "$status" > "./tmp/${writer}_status.txt"
    echo "$progress" > "./tmp/${writer}_progress.txt"
    echo "$(date +%s)" > "./tmp/${writer}_last_update.txt"
    
    # ログ記録
    log_status "$writer ステータス更新: $status - $progress"
    
    echo "✅ $writer のステータスを '$status' に更新しました"
    echo "   進捗: $progress"
}

# ステータス表示
show_status() {
    echo ""
    echo "============================="
    echo "📊 記事執筆ステータス一覧"
    echo "============================="
    printf "%-10s | %-12s | %-30s | %-15s\n" "ライター" "ステータス" "進捗" "最終更新"
    echo "--------------------------------------------------------------------------------"
    
    for writer in writer1 writer2 writer3; do
        if [ -f "./tmp/${writer}_status.txt" ]; then
            status=$(cat "./tmp/${writer}_status.txt")
            progress=$(cat "./tmp/${writer}_progress.txt" 2>/dev/null || echo "N/A")
            
            # 最終更新時刻の計算
            if [ -f "./tmp/${writer}_last_update.txt" ]; then
                last_update=$(cat "./tmp/${writer}_last_update.txt")
                current_time=$(date +%s)
                time_diff=$((current_time - last_update))
                
                if [ $time_diff -lt 60 ]; then
                    time_str="${time_diff}秒前"
                elif [ $time_diff -lt 3600 ]; then
                    time_str="$((time_diff / 60))分前"
                else
                    time_str="$((time_diff / 3600))時間前"
                fi
            else
                time_str="N/A"
            fi
            
            # ステータスに応じたアイコン
            case $status in
                "writing") icon="✍️" ;;
                "completed") icon="📝" ;;
                "checking") icon="🔍" ;;
                "revision") icon="🔄" ;;
                "done") icon="✅" ;;
                *) icon="❓" ;;
            esac
            
            printf "%-10s | %-12s | %-30s | %-15s\n" "$writer" "$icon $status" "$progress" "$time_str"
        else
            printf "%-10s | %-12s | %-30s | %-15s\n" "$writer" "⏸️ 待機中" "N/A" "N/A"
        fi
    done
    echo ""
}

# 停滞検出
check_stalls() {
    local current_time=$(date +%s)
    local stalled_writers=()
    local all_done=1
    local project_completed=0
    
    # プロジェクト完了フラグの確認
    if [ -f "./tmp/project_completed.flag" ]; then
        project_completed=1
    fi
    
    for writer in writer1 writer2 writer3; do
        if [ -f "./tmp/${writer}_status.txt" ] && [ -f "./tmp/${writer}_last_update.txt" ]; then
            status=$(cat "./tmp/${writer}_status.txt")
            last_update=$(cat "./tmp/${writer}_last_update.txt")
            time_diff=$((current_time - last_update))
            
            # ステータス別のタイムアウト設定
            case $status in
                "writing")
                    if [ $time_diff -gt 600 ]; then   # 10分
                        stalled_writers+=("$writer")
                    fi
                    all_done=0
                    ;;
                "completed")
                    if [ $time_diff -gt 600 ]; then   # 10分（3分 → 10分に変更）
                        stalled_writers+=("$writer")
                    fi
                    all_done=0
                    ;;
                "checking")
                    if [ $time_diff -gt 600 ]; then   # 10分（5分 → 10分に変更）
                        stalled_writers+=("$writer")
                    fi
                    all_done=0
                    ;;
                "revision")
                    if [ $time_diff -gt 600 ]; then   # 10分（5分 → 10分に変更）
                        stalled_writers+=("$writer")
                    fi
                    all_done=0
                    ;;
                "done")
                    # done状態でも長時間更新がない場合は停滞とみなす
                    if [ $time_diff -gt 1800 ]; then   # 30分
                        stalled_writers+=("$writer")
                    fi
                    ;;
                *)
                    all_done=0
                    ;;
            esac
        else
            all_done=0
        fi
    done
    
    # 全ライターがdone状態だがプロジェクトが完了していない場合
    if [ $all_done -eq 1 ] && [ $project_completed -eq 0 ]; then
        log_status "全ライター完了状態だがプロジェクト未完了 - Director/CMOの確認が必要"
        echo "⚠️ 全ライターが完了状態ですが、プロジェクトが完了していません"
        echo "   DirectorまたはCMOの確認が必要です"
        return 1
    fi
    
    if [ ${#stalled_writers[@]} -gt 0 ]; then
        log_status "停滞検出: ${stalled_writers[*]}"
        echo "⚠️ 停滞検出: ${stalled_writers[*]}"
        return 1
    fi
    
    return 0
}

# 全ライターのステータスリセット
reset_all_status() {
    echo "🔄 全ライターのステータスをリセットします..."
    for writer in writer1 writer2 writer3; do
        rm -f "./tmp/${writer}_status.txt"
        rm -f "./tmp/${writer}_progress.txt"
        rm -f "./tmp/${writer}_last_update.txt"
    done
    log_status "全ステータスリセット完了"
    echo "✅ 全ステータスをリセットしました"
}

# 特定ライターのステータスリセット
reset_writer_status() {
    local writer="$1"
    if [ -z "$writer" ]; then
        echo "使用方法: $0 reset-writer [writer]"
        exit 1
    fi
    
    rm -f "./tmp/${writer}_status.txt"
    rm -f "./tmp/${writer}_progress.txt"
    rm -f "./tmp/${writer}_last_update.txt"
    
    log_status "$writer ステータスリセット"
    echo "✅ $writer のステータスをリセットしました"
}

# メイン処理
case "$1" in
    "update")
        if [ $# -lt 3 ]; then
            echo "使用方法: $0 update [writer] [status] [progress]"
            echo ""
            echo "利用可能なステータス:"
            echo "  writing   - 執筆中"
            echo "  completed - 完成（チェック待ち）"
            echo "  checking  - Director確認中"
            echo "  revision  - 修正中"
            echo "  done      - 完了"
            exit 1
        fi
        update_status "$2" "$3" "${4:-N/A}"
        ;;
    "show")
        show_status
        ;;
    "check")
        if check_stalls; then
            echo "✅ すべてのライターが正常に進行中です"
            exit 0
        else
            echo "❌ 停滞が検出されました"
            exit 1
        fi
        ;;
    "reset")
        reset_all_status
        ;;
    "reset-writer")
        reset_writer_status "$2"
        ;;
    *)
        echo "📊 ステータス管理ユーティリティ"
        echo ""
        echo "使用方法: $0 {update|show|check|reset|reset-writer}"
        echo ""
        echo "コマンド:"
        echo "  update [writer] [status] [progress]  - ステータス更新"
        echo "  show                                  - ステータス一覧表示"
        echo "  check                                 - 停滞チェック"
        echo "  reset                                 - 全ステータスリセット"
        echo "  reset-writer [writer]                - 特定ライターのリセット"
        echo ""
        echo "利用可能なステータス:"
        echo "  writing   - 執筆中"
        echo "  completed - 完成（チェック待ち）"
        echo "  checking  - Director確認中"
        echo "  revision  - 修正中"
        echo "  done      - 完了"
        echo ""
        echo "例:"
        echo "  $0 update writer1 writing 'H2の執筆中'"
        echo "  $0 update writer1 completed '記事完成、チェック待ち'"
        echo "  $0 show"
        echo "  $0 check"
        ;;
esac 