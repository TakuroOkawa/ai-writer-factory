#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
単一記事でマークダウン変換をテストするスクリプト
"""

import os
from pathlib import Path
from notion_upload_script import NotionUploader

def test_single_article():
    """単一記事のテスト"""
    uploader = NotionUploader()
    
    # テスト用の記事ファイル
    test_file = "./articles/20250725_dental-connect-b2b-strategy/waiting-time-reduction.md"
    
    if not os.path.exists(test_file):
        print(f"❌ テストファイルが見つかりません: {test_file}")
        return
    
    print(f"📝 テスト記事: {test_file}")
    
    try:
        # 記事をアップロード
        page_id = uploader.upload_article(test_file)
        
        if page_id:
            print(f"✅ テスト成功: {page_id}")
        else:
            print("❌ テスト失敗")
            
    except Exception as e:
        print(f"❌ テスト失敗: {e}")

if __name__ == "__main__":
    test_single_article() 