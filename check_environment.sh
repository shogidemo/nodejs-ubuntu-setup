#!/bin/bash

# 環境確認スクリプト
# Ubuntu 22.04 Node.js環境チェック

echo "=== Node.js環境確認スクリプト ==="
echo "実行日時: $(date)"
echo "ユーザー: $(whoami)"
echo "OS: $(lsb_release -d | cut -f2)"
echo ""

# 色付きログ用の関数
print_info() { echo -e "\033[34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[33m[WARNING]\033[0m $1"; }
print_error() { echo -e "\033[31m[ERROR]\033[0m $1"; }

# Node.js確認
print_info "Node.jsの状況を確認中..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_success "Node.js インストール済み: $NODE_VERSION"
    
    # バージョンが22未満かチェック
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
    if [ "$NODE_MAJOR" -lt 22 ]; then
        print_warning "Node.js v$NODE_MAJOR は古いバージョンです（推奨: v22以上）"
        echo "  推奨アクション: Node.jsをアップデートしてください"
    else
        print_success "Node.js バージョンは要件を満たしています"
    fi
    
    echo "  インストール場所: $(which node)"
else
    print_warning "Node.js が見つかりません"
fi

echo ""

# npm確認
print_info "npmの状況を確認中..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    print_success "npm インストール済み: v$NPM_VERSION"
    echo "  インストール場所: $(which npm)"
    echo "  グローバルディレクトリ: $(npm config get prefix)"
    
    # 権限問題をチェック
    PREFIX=$(npm config get prefix)
    if [[ "$PREFIX" == "/usr/local" ]] || [[ "$PREFIX" == "/usr" ]]; then
        print_warning "グローバルディレクトリが管理者権限を要求する場所です"
        echo "  推奨アクション: npm設定を変更するか、NVMの使用を検討してください"
    fi
else
    print_warning "npm が見つかりません"
fi

echo ""

# NVM確認
print_info "NVMの状況を確認中..."
if command -v nvm &> /dev/null; then
    NVM_VERSION=$(nvm --version)
    print_success "NVM インストール済み: v$NVM_VERSION"
    echo "  利用可能なNode.jsバージョン:"
    nvm list
elif [ -f "$HOME/.nvm/nvm.sh" ]; then
    print_warning "NVMはインストール済みですが、パスが設定されていません"
    echo "  修正方法: source ~/.nvm/nvm.sh を実行するか、シェルを再起動してください"
else
    print_warning "NVM が見つかりません"
    echo "  推奨アクション: NVMをインストールして複数バージョンを管理することを推奨します"
fi

echo ""

# yarn確認
print_info "yarnの状況を確認中..."
if command -v yarn &> /dev/null; then
    YARN_VERSION=$(yarn --version)
    print_success "yarn インストール済み: v$YARN_VERSION"
else
    print_info "yarn は見つかりません（オプショナル）"
fi

echo ""

# グローバルパッケージ確認
print_info "グローバルパッケージの確認中..."
if command -v npm &> /dev/null; then
    echo "  インストール済みグローバルパッケージ:"
    npm list -g --depth=0 2>/dev/null | grep -E "(nodemon|typescript|ts-node|@anthropic-ai/claude-code)" || echo "    主要な開発パッケージは見つかりません"
fi

echo ""

# ディスク容量確認
print_info "ディスク容量の確認中..."
DISK_USAGE=$(df -h $HOME | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    print_warning "ディスク使用量が高いです ($DISK_USAGE%)"
else
    print_success "ディスク容量は充分です (使用量: $DISK_USAGE%)"
fi

echo ""
echo "=== 確認完了 ==="

# 推奨アクション
echo ""
print_info "推奨アクション:"

if ! command -v node &> /dev/null; then
    echo "  1. Node.jsをインストールしてください"
elif [ "$NODE_MAJOR" -lt 22 ]; then
    echo "  1. Node.jsをv22以上にアップデートしてください"
fi

if ! command -v nvm &> /dev/null && [ ! -f "$HOME/.nvm/nvm.sh" ]; then
    echo "  2. NVMをインストールして複数バージョンを管理してください"
fi

if [[ "$PREFIX" == "/usr/local" ]] || [[ "$PREFIX" == "/usr" ]]; then
    echo "  3. npm設定を変更して権限問題を回避してください"
fi

echo ""
echo "次のステップ: ./setup_nodejs.sh を実行してNode.js環境をセットアップしてください"