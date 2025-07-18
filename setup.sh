#!/bin/bash

# 🛠️ 記事生成プロジェクト用 環境初期化スクリプト

set -e

# ログ関数
log_info() {
    echo -e "\033[1;32m[情報]\033[0m $1"
}
log_success() {
    echo -e "\033[1;34m[成功]\033[0m $1"
}

echo ""
echo "==============================================="
echo "🧠 記事生成プロジェクト 環境構築を開始します"
echo "==============================================="
echo ""

# セッション削除・完了ファイル削除
log_info "🔧 tmux セッションを初期化します..."
tmux kill-session -t article_team 2>/dev/null || true
tmux kill-session -t cmo 2>/dev/null || true

mkdir -p ./tmp
rm -f ./tmp/writer*_done.txt 2>/dev/null || true

log_success "✅ 既存セッションと完了ファイルを削除しました"

# セッション1: director + writer1〜3
log_info "🧩 article_team セッションを構築中..."
tmux new-session -d -s article_team -n "team" -c "$(pwd)"
tmux split-window -h -t article_team
tmux select-pane -t article_team:0.0
tmux split-window -v
tmux select-pane -t article_team:0.1
tmux split-window -v

AGENT_NAMES=("director" "writer1" "writer2" "writer3")

for i in {0..3}; do
    tmux select-pane -t article_team:0.$i -T "${AGENT_NAMES[$i]}"
    tmux send-keys -t article_team:0.$i "cd $(pwd)" C-m
    tmux send-keys -t article_team:0.$i "export PS1='(\[\033[1;36m\]${AGENT_NAMES[$i]}\[\033[0m\]) \w \$ '" C-m
    tmux send-keys -t article_team:0.$i "echo '=== ${AGENT_NAMES[$i]} セッション開始 ==='" C-m
    
    # Directorはopus、Writersはsonnet
    if [ $i -eq 0 ]; then
        # Director (opus)
        tmux send-keys -t article_team:0.$i "claude --model opus --dangerously-skip-permissions" C-m
    else
        # Writers (sonnet)
        tmux send-keys -t article_team:0.$i "claude --model sonnet --dangerously-skip-permissions" C-m
    fi
done

log_success "✅ director + writer セッション構築完了"

# セッション2: CMO
log_info "🎯 CMOセッションを作成します..."
tmux new-session -d -s cmo -n "cmo" -c "$(pwd)"
tmux send-keys -t cmo "export PS1='(\[\033[1;35m\]CMO\[\033[0m\]) \w \$ '" C-m
tmux send-keys -t cmo "echo '=== CMO セッション開始 ==='" C-m
tmux send-keys -t cmo "claude --model opus --dangerously-skip-permissions" C-m

log_success "✅ CMOセッション作成完了"

# 結果表示
echo ""
log_info "📺 現在の tmux セッション:"
tmux list-sessions
echo ""

echo "📋 ペイン構成:"
echo "  article_team セッション:"
echo "    Pane 0: director (Opus最新版)"
echo "    Pane 1: writer1 (Sonnet最新版)"
echo "    Pane 2: writer2 (Sonnet最新版)"
echo "    Pane 3: writer3 (Sonnet最新版)"
echo ""
echo "  cmo セッション:"
echo "    Pane 0: CMO (Opus最新版)"
echo ""

log_success "🎉 環境構築完了！以下のコマンドで作業を開始できます："
echo ""
echo "📌 セッションに入る:"
echo "  tmux attach -t cmo           # CMO"
echo "  tmux attach -t article_team  # director + writers"
echo ""