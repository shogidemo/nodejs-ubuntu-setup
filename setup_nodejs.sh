#!/bin/bash

# Node.js環境セットアップスクリプト
# Ubuntu 22.04 + NVM + Node.js 22 LTS

echo "=== Node.js環境セットアップスクリプト ==="
echo "実行日時: $(date)"
echo ""

# 色付きログ用の関数
print_info() { echo -e "\033[34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[33m[WARNING]\033[0m $1"; }
print_error() { echo -e "\033[31m[ERROR]\033[0m $1"; }

# エラーハンドリング
set -e
trap 'print_error "スクリプトの実行中にエラーが発生しました (line $LINENO)"' ERR

# 設定変数
NODE_VERSION="22"  # 最新LTSバージョン
NVM_VERSION="v0.39.0"

print_info "セットアップ設定:"
echo "  - NVM バージョン: $NVM_VERSION"
echo "  - Node.js バージョン: $NODE_VERSION (最新LTS)"
echo "  - インストール先: $HOME/.nvm"
echo ""

# 依存パッケージのインストール
print_info "依存パッケージをインストール中..."
sudo apt update
sudo apt install -y curl wget build-essential

# NVMがすでにインストールされているかチェック
if [ -f "$HOME/.nvm/nvm.sh" ]; then
    print_info "NVMはすでにインストールされています"
    source "$HOME/.nvm/nvm.sh"
    source "$HOME/.nvm/bash_completion"
    
    # NVMのバージョン確認
    if command -v nvm &> /dev/null; then
        CURRENT_NVM_VERSION=$(nvm --version)
        print_success "NVM バージョン: $CURRENT_NVM_VERSION"
    fi
else
    # NVMのインストール
    print_info "NVMをインストール中..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
    
    # NVMスクリプトを読み込み
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    print_success "NVMのインストールが完了しました"
fi

# シェル設定ファイルの更新
print_info "シェル設定を更新中..."
SHELL_CONFIG=""
if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if [ -n "$SHELL_CONFIG" ]; then
    # NVM設定が既に存在するかチェック
    if ! grep -q "NVM_DIR" "$SHELL_CONFIG"; then
        echo '' >> "$SHELL_CONFIG"
        echo '# NVM設定' >> "$SHELL_CONFIG"
        echo 'export NVM_DIR="$HOME/.nvm"' >> "$SHELL_CONFIG"
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$SHELL_CONFIG"
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$SHELL_CONFIG"
        print_success "シェル設定ファイルを更新しました: $SHELL_CONFIG"
    else
        print_info "シェル設定ファイルは既に更新済みです"
    fi
fi

# NVMの動作確認
if ! command -v nvm &> /dev/null; then
    print_error "NVMの読み込みに失敗しました"
    print_info "手動でシェルを再起動してから再実行してください: exec bash"
    exit 1
fi

# Node.js 22 LTSのインストール
print_info "Node.js $NODE_VERSION LTSをインストール中..."
nvm install "$NODE_VERSION"
nvm use "$NODE_VERSION"
nvm alias default "$NODE_VERSION"

print_success "Node.js $NODE_VERSION LTSのインストールが完了しました"

# バージョン確認
NODE_ACTUAL_VERSION=$(node --version)
NPM_ACTUAL_VERSION=$(npm --version)

print_success "インストール完了!"
echo "  Node.js: $NODE_ACTUAL_VERSION"
echo "  npm: $NPM_ACTUAL_VERSION"

# npmの設定最適化
print_info "npmの設定を最適化中..."

# グローバルパッケージディレクトリの設定
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"

# パフォーマンス設定
npm config set fund false  # 支援メッセージを無効化
npm config set audit-level moderate  # 監査レベルを設定
npm config set maxsockets 5  # 同時接続数を制限

print_success "npm設定の最適化が完了しました"

# PATH設定の確認と更新
print_info "PATH設定を確認中..."
if [[ ":$PATH:" != *":$HOME/.npm-global/bin:"* ]]; then
    if [ -n "$SHELL_CONFIG" ]; then
        echo '' >> "$SHELL_CONFIG"
        echo '# npm global packages' >> "$SHELL_CONFIG"
        echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$SHELL_CONFIG"
        print_success "PATH設定を追加しました"
    fi
fi

# 現在のセッションでPATHを更新
export PATH="$HOME/.npm-global/bin:$PATH"

# npmの最新化
print_info "npmを最新バージョンに更新中..."
npm install -g npm@latest

# .nvmrcファイルの作成（プロジェクト用）
print_info "プロジェクト用設定ファイルを作成中..."
if [ ! -f ".nvmrc" ]; then
    echo "$NODE_VERSION" > .nvmrc
    print_success ".nvmrcファイルを作成しました (Node.js $NODE_VERSION)"
fi

# package.jsonテンプレートの作成
if [ ! -f "package.json" ] && [ "$(basename "$PWD")" != "$HOME" ]; then
    print_info "開発用package.jsonテンプレートを作成中..."
    cat > package.json << EOF
{
  "name": "$(basename "$PWD")",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "engines": {
    "node": ">=$NODE_VERSION.0.0",
    "npm": ">=10.0.0"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
EOF
    print_success "package.jsonテンプレートを作成しました"
fi

# 最終確認
print_info "セットアップの最終確認中..."
echo "  Node.js バージョン: $(node --version)"
echo "  npm バージョン: $(npm --version)"
echo "  npm prefix: $(npm config get prefix)"
echo "  利用可能なNode.jsバージョン:"
nvm list

echo ""
print_success "=== Node.js環境のセットアップが完了しました! ==="

echo ""
print_info "次のステップ:"
echo "  1. 新しいターミナルを開くか、以下を実行してください:"
echo "     source ~/.bashrc  (または source ~/.zshrc)"
echo ""
echo "  2. 開発パッケージをインストールしてください:"
echo "     ./install_packages.sh"
echo ""
echo "  3. プロジェクトでNode.jsバージョンを切り替える場合:"
echo "     nvm use  (プロジェクトディレクトリで実行)"

print_info "便利なNVMコマンド:"
echo "  nvm list          - インストール済みバージョンの表示"
echo "  nvm install 20    - Node.js 20をインストール"
echo "  nvm use 20        - Node.js 20に切り替え"
echo "  nvm alias default 20  - デフォルトバージョンを20に設定"