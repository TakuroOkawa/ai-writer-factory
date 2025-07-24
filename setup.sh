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
rm -f ./tmp/project_completed.flag 2>/dev/null || true

log_success "✅ 既存セッションと完了ファイルを削除しました"

# 自動切り替えスクリプトの権限設定
if [ -f "./claude-auto-switch.sh" ]; then
    chmod +x ./claude-auto-switch.sh
    log_success "✅ 自動切り替えスクリプトの権限を設定しました"
fi

# セッション1: director + writer1〜3
log_info "🧩 article_team セッションを構築中..."
tmux new-session -d -s article_team -n "team" -c "$(pwd)"

# 2x2の均等な4分割を作成
tmux split-window -h -t article_team:0.0 -p 50  # 左右に50%で分割
tmux split-window -v -t article_team:0.0 -p 50  # 左側を上下に50%で分割
tmux split-window -v -t article_team:0.1 -p 50  # 右側を上下に50%で分割

# レイアウトを整える（念のため）
tmux select-layout -t article_team tiled

AGENT_NAMES=("director" "writer1" "writer2" "writer3")

for i in {0..3}; do
   tmux select-pane -t article_team:0.$i -T "${AGENT_NAMES[$i]}"
   tmux send-keys -t article_team:0.$i "cd $(pwd)" C-m
   tmux send-keys -t article_team:0.$i "export PS1='(\[\033[1;36m\]${AGENT_NAMES[$i]}\[\033[0m\]) \w \$ '" C-m
   tmux send-keys -t article_team:0.$i "echo '=== ${AGENT_NAMES[$i]} セッション開始 ==='" C-m
   
   # Directorはopus（自動切り替え付き）、Writersはsonnet
   if [ $i -eq 0 ]; then
       # Director (opus with auto-switch)
       log_info "🎯 Director: Opusで起動（自動切り替え機能付き）"
       tmux send-keys -t article_team:0.$i "claude --model opus --dangerously-skip-permissions" C-m
       
       # 自動切り替え監視をバックグラウンドで開始
       sleep 2
       ./claude-auto-switch.sh "article_team:0.0" "director" "opus" &
       log_success "✅ Director自動切り替え監視開始"
   else
       # Writers (sonnet)
       log_info "✍️  Writer$i: Sonnetで起動"
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

# CMOの自動切り替え監視をバックグラウンドで開始
sleep 2
./claude-auto-switch.sh "cmo" "CMO" "opus" &
log_success "✅ CMO自動切り替え監視開始"

log_success "✅ CMOセッション作成完了"

# 結果表示
echo ""
log_info "📺 現在の tmux セッション:"
tmux list-sessions
echo ""

echo "📋 ペイン構成:"
echo "  article_team セッション:"
echo "    Pane 0: director (Opus最新版 + 自動切り替え機能)"
echo "    Pane 1: writer1 (Sonnet最新版)"
echo "    Pane 2: writer2 (Sonnet最新版)"
echo "    Pane 3: writer3 (Sonnet最新版)"
echo ""
echo "  cmo セッション:"
echo "    Pane 0: CMO (Opus最新版 + 自動切り替え機能)"
echo ""

# 監視システムの起動
log_info "🔍 監視システムを起動します..."
if [ -f "./watchdog.sh" ]; then
   chmod +x ./watchdog.sh
   tmux new-session -d -s watchdog -c "$(pwd)" "./watchdog.sh"
   log_success "✅ 監視システムが起動しました"
else
   echo "⚠️  watchdog.sh が見つかりません"
fi

echo ""
log_info "🔄 自動切り替え機能について:"
echo "  - Opusリミットに達すると自動的にSonnetに切り替わります"
echo "  - 切り替えログは ./logs/claude_switch.log に記録されます"
echo "  - 手動で切り替えログを確認: tail -f ./logs/claude_switch.log"
echo ""

log_success "🎉 環境構築が完了しました！"