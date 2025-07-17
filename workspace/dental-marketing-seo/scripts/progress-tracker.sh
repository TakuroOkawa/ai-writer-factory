#!/bin/bash

# 歯科医院SEO記事制作進捗管理スクリプト

echo "=== 歯科医院SEO記事制作進捗ダッシュボード $(date +%Y/%m/%d) ==="
echo ""

# プロジェクトディレクトリ設定
PROJECT_DIR="./workspace/dental-marketing-seo"
ARTICLES_DIR="$PROJECT_DIR/articles"

# 各ライターの進捗状況チェック
echo "📝 ライター別進捗状況"
echo "================================"

for writer in writer1 writer2 writer3; do
    echo "🔍 $writer の状況:"
    
    # 作業中ファイルの確認
    if [ -f "$PROJECT_DIR/tmp/${writer}_writing.txt" ]; then
        TASK=$(cat "$PROJECT_DIR/tmp/${writer}_writing.txt" 2>/dev/null || echo "不明")
        STARTED=$(stat -f "%Sm" "$PROJECT_DIR/tmp/${writer}_writing.txt" 2>/dev/null || echo "不明")
        echo "   🔄 作業中: $TASK"
        echo "   📅 開始日時: $STARTED"
    elif [ -f "$PROJECT_DIR/tmp/${writer}_done.txt" ]; then
        COMPLETED=$(cat "$PROJECT_DIR/tmp/${writer}_done.txt" 2>/dev/null || echo "不明")
        echo "   ✅ 完了: $COMPLETED"
        echo "   📋 次タスク待ち"
    else
        echo "   ⏰ タスク待ち（アサイン必要）"
    fi
    
    # 完成記事数チェック
    COMPLETED_COUNT=$(find "$ARTICLES_DIR/$writer" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    echo "   📊 完成記事数: $COMPLETED_COUNT 記事"
    echo ""
done

# 全体進捗状況
echo "🎯 全体進捗状況"
echo "================================"

# 今週の目標記事数
WEEK_TARGET=3
TOTAL_COMPLETED=$(find "$ARTICLES_DIR" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
PROGRESS_PERCENT=$(($TOTAL_COMPLETED * 100 / $WEEK_TARGET))

echo "📈 週間目標: $TOTAL_COMPLETED/$WEEK_TARGET 記事 (${PROGRESS_PERCENT}%)"

# 品質チェック待ち
REVIEW_QUEUE=$(find "$PROJECT_DIR/tmp" -name "review_queue_*.txt" 2>/dev/null | wc -l | tr -d ' ')
echo "📋 品質チェック待ち: $REVIEW_QUEUE 記事"

# 各記事の状況
echo ""
echo "📚 記事別進捗状況"
echo "================================"

# Writer1: Hub記事
if [ -f "$ARTICLES_DIR/writer1/歯科医院集客完全ガイド2025.md" ]; then
    echo "✅ Hub記事: 歯科医院の集客完全ガイド2025（Writer1）"
else
    echo "🔄 Hub記事: 歯科医院の集客完全ガイド2025（Writer1）- 制作中"
fi

# Writer2: 成功事例記事
if [ -f "$ARTICLES_DIR/writer2/歯科医院集客成功事例10選.md" ]; then
    echo "✅ 成功事例記事: 歯科医院集客の成功事例10選（Writer2）"
else
    echo "🔄 成功事例記事: 歯科医院集客の成功事例10選（Writer2）- 制作中"
fi

# Writer3: SEO・MEO記事
if [ -f "$ARTICLES_DIR/writer3/歯科医院SEO-MEO対策ガイド.md" ]; then
    echo "✅ SEO・MEO記事: 歯科医院のSEO対策とMEO最適化（Writer3）"
else
    echo "🔄 SEO・MEO記事: 歯科医院のSEO対策とMEO最適化（Writer3）- 制作中"
fi

# 締切チェック
echo ""
echo "⏰ 締切状況"
echo "================================"

CURRENT_TIME=$(date +%s)
DEADLINE_48H=$(date -d '+2 days' +%s 2>/dev/null || date -v+2d +%s 2>/dev/null || echo "0")
DEADLINE_72H=$(date -d '+3 days' +%s 2>/dev/null || date -v+3d +%s 2>/dev/null || echo "0")

echo "📅 Writer1 & Writer2 締切: 48時間以内"
echo "📅 Writer3 締切: 72時間以内"

# 遅延チェック（48時間以上の場合）
for writer in writer1 writer2; do
    if [ -f "$PROJECT_DIR/tmp/${writer}_writing.txt" ]; then
        TASK_START=$(stat -f "%Y" "$PROJECT_DIR/tmp/${writer}_writing.txt" 2>/dev/null || echo "0")
        ELAPSED=$(($CURRENT_TIME - $TASK_START))
        
        if [ $ELAPSED -gt 172800 ]; then  # 48時間 = 172800秒
            ELAPSED_HOURS=$(($ELAPSED / 3600))
            echo "🚨 遅延アラート: $writer のタスクが${ELAPSED_HOURS}時間経過"
        fi
    fi
done

# 品質指標
echo ""
echo "📊 品質指標"
echo "================================"

# 完成記事の品質チェック
if [ $TOTAL_COMPLETED -gt 0 ]; then
    echo "📝 完成記事の品質評価:"
    
    for article in $(find "$ARTICLES_DIR" -name "*.md" 2>/dev/null); do
        if [ -f "$article" ]; then
            WORD_COUNT=$(wc -w < "$article" 2>/dev/null || echo "0")
            FILENAME=$(basename "$article")
            echo "   📄 $FILENAME: $WORD_COUNT 文字"
        fi
    done
else
    echo "📝 完成記事なし - 品質評価待ち"
fi

# 次のアクション
echo ""
echo "🎯 次のアクション"
echo "================================"

if [ $TOTAL_COMPLETED -lt $WEEK_TARGET ]; then
    echo "📋 優先タスク:"
    echo "   1. 各ライターの進捗確認"
    echo "   2. ブロッカーの特定と解決"
    echo "   3. 必要に応じてサポート提供"
    echo "   4. 品質チェック体制の準備"
fi

if [ $REVIEW_QUEUE -gt 0 ]; then
    echo "   5. 品質チェックの実施"
fi

echo ""
echo "📞 連絡事項"
echo "================================"
echo "❓ 質問・サポート要請はすぐに報告してください"
echo "📈 進捗に遅れが生じた場合は即座に連絡"
echo "✅ 記事完成時は品質チェックリストと共に提出"

echo ""
echo "=== 進捗レポート完了 ==="