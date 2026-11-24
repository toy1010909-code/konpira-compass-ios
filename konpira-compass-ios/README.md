# 金比羅コンパス（iOS）

安井金比羅宮の方向を指すコンパスアプリ。GitHub Actionsで署名なしIPAをビルドし、Sideloadlyで入れる。

## 1. GitHubでビルド
1. 新しいリポジトリ（例: konpira-compass-ios）を作る
2. このフォルダの中身をすべてリポジトリ直下に置く
   - `.github/workflows/build.yml`（隠しフォルダなので、GitHubの Add file > Create new file でパスに `.github/workflows/build.yml` と入力して作るのが確実）
   - `project.yml`
   - `KonpiraCompass/` の3つの .swift ファイル
3. mainブランチにコミットすると、Actionsタブで「Build IPA」が自動で動く（手動なら Run workflow）
4. 完了後、そのrunのページ下部 Artifacts から `KonpiraCompass-ipa` をダウンロードして展開 → `KonpiraCompass.ipa`

## 2. Sideloadlyで入れる
1. iPhoneをPC/Macにつなぎ、Sideloadlyを開く
2. IPAをドラッグし、Apple IDを入力して Start
3. iPhoneの設定 > 一般 > VPNとデバイス管理 で自分のApple IDを「信頼」
4. 初回起動で位置情報を「アプリの使用中は許可」にする

無料Apple IDの署名は7日で切れる。切れたらSideloadlyで再度入れる。
