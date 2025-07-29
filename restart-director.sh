#!/bin/bash

# 🎯 ディレクター専用再起動スクリプト

set -e

# ログ関数
log_info() {
   echo -e "\033[1;32m[情報]\033[0m $1"
}
log_success() {
   echo -e "\033[1;34m[成功]\033[0m $1"
}
log_warning() {
   echo -e "\033[1;33m[警告]\033[0m $1"
}

echo ""
echo "==============================================="
echo "🎯 ディレクター再起動スクリプト"
echo "==============================================="
echo ""

# 1. 現在の状況確認
log_info "📊 現在の状況を確認中..."

if ! tmux has-session -t article_team 2>/dev/null; then
    log_warning "article_teamセッションが見つかりません"
    echo "セットアップスクリプトを実行してください: ./setup.sh"
    exit 1
fi

# 2. ディレクターペインの状態確認
log_info "🔍 ディレクターペインの状態を確認中..."

# ディレクターペインの内容を取得
PANEL_CONTENT=$(tmux capture-pane -t article_team:0.0 -p 2>/dev/null || echo "")

# Claude Codeが動作しているかチェック
if echo "$PANEL_CONTENT" | grep -q "claude code"; then
    log_info "✅ Claude Codeは動作中です"
else
    log_warning "⚠️  Claude Codeが動作していません"
fi

# 3. ディレクターペインの再起動
log_info "🔄 ディレクターペインを再起動中..."

# 現在のプロセスを停止
tmux send-keys -t article_team:0.0 C-c 2>/dev/null || true
sleep 1

# Claude Codeを再起動
tmux send-keys -t article_team:0.0 "claude code" Enter
log_success "✅ Claude Codeを再起動しました"

# 4. 起動待機
log_info "⏳ Claude Codeの起動を待機中..."
sleep 5

# 5. 現在の進捗状況を取得
log_info "📋 現在の進捗状況を取得中..."

# ステータス管理システムから情報を取得
if [ -f "./status-manager.sh" ]; then
    echo ""
    echo "============================="
    echo "📊 現在の進捗状況"
    echo "============================="
    ./status-manager.sh show
    echo ""
fi

# 6. ディレクターに状況を通知
log_info "📤 ディレクターに状況を通知中..."

# 現在のライターの状況を取得
WRITER_STATUS=""
for writer in writer1 writer2 writer3; do
    if [ -f "./tmp/${writer}_status.txt" ] && [ -f "./tmp/${writer}_progress.txt" ]; then
        status=$(cat "./tmp/${writer}_status.txt")
        progress=$(cat "./tmp/${writer}_progress.txt")
        WRITER_STATUS="${WRITER_STATUS}${writer}: ${status} - ${progress}\n"
    fi
done

# 通知メッセージを作成
NOTIFICATION_MESSAGE="【ディレクター再起動完了】

システムが復旧しました。

現在の状況：
${WRITER_STATUS}

品質チェックが必要な記事があれば、チェックをお願いします。
完了後、CMOに最終報告をお願いします。

プロジェクトを完了させてください。"

# メッセージを送信
./agent-send.sh director "$NOTIFICATION_MESSAGE"

log_success "✅ ディレクターに状況を通知しました"

echo ""
echo "==============================================="
echo "🎉 ディレクター再起動完了"
echo "==============================================="
echo ""
echo "✅ ディレクターペインを再起動しました"
echo "✅ 現在の状況を通知しました"
echo ""
echo "📋 次のアクション:"
echo "   1. ディレクターの応答を確認"
echo "   2. 品質チェックの進行状況を監視"
echo "   3. 必要に応じて追加の指示"
echo ""
echo "🔍 進捗確認: ./project-status.sh"
echo "📊 詳細確認: ./status-manager.sh show"
echo "" 