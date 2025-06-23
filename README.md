# Node.js環境セットアップツール

Ubuntu 22.04でNode.js開発環境を簡単にセットアップするためのスクリプト集です。

## 🚀 クイックスタート

### GitHubから一括ダウンロード

```bash
# リポジトリをクローン
git clone https://github.com/shogidemo/nodejs-ubuntu-setup.git
cd nodejs-ubuntu-setup

# 一括セットアップを実行
chmod +x install_all.sh
./install_all.sh
```

### 個別ファイルのダウンロード

```bash
# 作業ディレクトリを作成
mkdir nodejs-setup && cd nodejs-setup

# 各ファイルを個別にダウンロード
wget https://raw.githubusercontent.com/shogidemo/nodejs-ubuntu-setup/main/install_all.sh
wget https://raw.githubusercontent.com/shogidemo/nodejs-ubuntu-setup/main/check_environment.sh
wget https://raw.githubusercontent.com/shogidemo/nodejs-ubuntu-setup/main/cleanup_old_nodejs.sh
wget https://raw.githubusercontent.com/shogidemo/nodejs-ubuntu-setup/main/setup_nodejs.sh
wget https://raw.githubusercontent.com/shogidemo/nodejs-ubuntu-setup/main/install_packages.sh

# 実行権限を付与
chmod +x *.sh

# 一括セットアップを実行
./install_all.sh
```

## 📦 インストールされるもの

### Node.js環境
- **NVM** (Node Version Manager) - 複数バージョン管理
- **Node.js 22 LTS** - 最新の長期サポート版
- **npm** - パッケージマネージャー（最新版）

### 開発ツール
- **TypeScript** - 型安全なJavaScript
- **ts-node** - TypeScript直接実行
- **nodemon** - ファイル変更監視とサーバー再起動
- **ESLint** - コード品質チェック
- **Prettier** - コードフォーマッター
- **yarn** - 代替パッケージマネージャー

### AI開発支援
- **@anthropic-ai/claude-code** - Claude Code ツール

## 🛠️ 各スクリプトの説明

- `install_all.sh` - 一括実行スクリプト（推奨）
- `check_environment.sh` - 環境確認スクリプト
- `cleanup_old_nodejs.sh` - 古い環境のクリーンアップ
- `setup_nodejs.sh` - Node.js環境セットアップ
- `install_packages.sh` - 開発パッケージインストール

## ✅ 特徴

- **Node.js 22 LTS** 対応（2025年最新版）
- **エラーハンドリング** - 各ステップでエラーチェック
- **バックアップ機能** - 既存設定の自動保存
- **ログ記録** - 詳細な実行ログ
- **色付き出力** - 視認性の良いメッセージ
- **権限安全** - sudoを最小限に抑制

## 🎯 解決する問題

- Node.jsバージョンが古い（v12など）
- npm の権限エラー
- @anthropic-ai/claude-code のインストール失敗
- 開発環境の統一

## 📝 ライセンス

MIT License

---

**穀物輸入管理システム開発での推奨設定**

- Node.js 22 LTS（最新の安定版）
- TypeScript（型安全性）
- ESLint + Prettier（コード品質）
- NVM（複数プロジェクト対応）
