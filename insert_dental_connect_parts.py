import os
import re

# 挿入パーツ
INSERT_PART = """---
### リスクゼロで矯正の新患を増やしませんか？

株式会社デンタルコネクトでは、患者様が来院した時だけ費用が発生する"完全成果報酬型"のポータルサイト「矯正歯科ガイド」を運営しています。

無駄な費用を払わずに新患を増やしたい方は、下のURLから紹介資料をダウンロードしてみてください！

https://www.dental-connect.net/download_kyosei-guide 
---"""

def insert_parts_in_article(file_path):
    """記事に指定されたパーツを挿入"""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
        
        lines = content.split('\n')
        
        # 最初のH2の手前を探す
        first_h2_index = -1
        for i, line in enumerate(lines):
            if line.strip().startswith('## ') and not line.strip().startswith('### '):
                first_h2_index = i
                break
        
        # 挿入位置を決定
        if first_h2_index != -1:
            # 最初のH2の手前に挿入
            insert_index = first_h2_index
        else:
            # H2が見つからない場合は、最初の段落の後に挿入
            insert_index = 1
        
        # 挿入パーツを分割
        insert_lines = INSERT_PART.split('\n')
        
        # 最初のH2の手前に挿入
        lines = lines[:insert_index] + insert_lines + lines[insert_index:]
        
        # 記事の最後に挿入
        lines.extend([''] + insert_lines)
        
        # ファイルに書き戻し
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write('\n'.join(lines))
        
        return True
    except Exception as e:
        print(f"❌ エラー ({os.path.basename(file_path)}): {e}")
        return False

def process_all_articles(directory_path):
    """ディレクトリ内の全記事を処理"""
    if not os.path.exists(directory_path):
        print(f"❌ ディレクトリが見つかりません: {directory_path}")
        return
    
    md_files = [f for f in os.listdir(directory_path) if f.endswith('.md')]
    print(f"📁 処理対象記事数: {len(md_files)}")
    
    success_count = 0
    for filename in md_files:
        file_path = os.path.join(directory_path, filename)
        print(f"📝 処理中: {filename}")
        
        if insert_parts_in_article(file_path):
            success_count += 1
            print(f"✅ 完了: {filename}")
        else:
            print(f"❌ 失敗: {filename}")
    
    print(f"\n🎉 処理完了: {success_count}/{len(md_files)} 記事を更新しました")

if __name__ == "__main__":
    directory = "./articles/20250726_note_dental-connect-b2b-strategy"
    process_all_articles(directory) 