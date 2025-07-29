import requests
import json

class NotionCleaner:
    def __init__(self):
        self.NOTION_TOKEN = "ntn_Z6342742995b7oyHRSNydcBJ0eB4d22Z6bjeESZeLcj9F6"
        self.DATABASE_ID = "22a17a0e93d380769f9de752467102ca"
        self.headers = {
            "Authorization": f"Bearer {self.NOTION_TOKEN}",
            "Content-Type": "application/json",
            "Notion-Version": "2022-06-28"
        }
        self.base_url = "https://api.notion.com/v1"

    def fetch_notion(self, endpoint: str, method: str, payload: dict = None) -> requests.Response:
        """Notionへのリクエストを実行する関数"""
        url = f"{self.base_url}{endpoint}"

        if method == "GET":
            response = requests.request(
                method=method,
                url=url,
                headers=self.headers,
                timeout=60
            )
        else:
            response = requests.request(
                method=method,
                url=url,
                headers=self.headers,
                data=json.dumps(payload),
                timeout=60
            )

        return response

    def get_database_pages(self):
        """データベース内の全ページを取得"""
        payload = {
            "page_size": 100
        }
        
        response = self.fetch_notion(f"/databases/{self.DATABASE_ID}/query", "POST", payload)
        
        if response.status_code == 200:
            return response.json().get("results", [])
        else:
            print(f"❌ データベース取得エラー: {response.status_code} - {response.text}")
            return []

    def delete_page(self, page_id):
        """ページを削除"""
        response = self.fetch_notion(f"/pages/{page_id}", "PATCH", {"archived": True})
        
        if response.status_code == 200:
            return True
        else:
            print(f"❌ ページ削除エラー: {response.status_code} - {response.text}")
            return False

    def delete_test_pages(self):
        """指定された3記事以外のテスト記事を削除"""
        print("🗑️ テスト記事の削除を開始...")
        
        # 残したい記事のタイトル
        keep_titles = [
            "【最新版】矯正歯科医院の集患方法15選！効果的な戦略と具体的な方法をご紹介",
            "歯科医院のホームページ制作 | おすすめ会社・選び方・失敗しない作り方を徹底解説",
            "矯正歯科の新患を増やす！今すぐ実践可能な戦略とは？"
        ]
        
        pages = self.get_database_pages()
        print(f"📁 見つかったページ数: {len(pages)}")
        
        if not pages:
            print("✅ 削除対象のページがありません")
            return
        
        success_count = 0
        for page in pages:
            page_id = page["id"]
            page_title = page.get("properties", {}).get("Title", {}).get("title", [])
            title = page_title[0].get("text", {}).get("content", "タイトルなし") if page_title else "タイトルなし"
            
            # 残したい記事かチェック
            if title in keep_titles:
                print(f"💾 保持: {title} (残したい記事)")
            else:
                print(f"🗑️ 削除中: {title}")
                
                if self.delete_page(page_id):
                    success_count += 1
                    print(f"✅ 削除完了: {title}")
                else:
                    print(f"❌ 削除失敗: {title}")
        
        print(f"\n🎉 削除完了: {success_count} 件のテスト記事を削除しました")

if __name__ == "__main__":
    cleaner = NotionCleaner()
    cleaner.delete_test_pages() 