#!/bin/bash

# 古いNode.js環境クリーンアップスクリプト
# Ubuntu 22.04用

echo "=== Node.js環境クリーンアップスクリプト ==="
echo "実行日時: $(date)"
echo ""

# 色付きログ用の関数
print_info() { echo -e "\033[34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[33m[WARNING]\033[0m $1"; }
print_error() { echo -e "\033[31m[ERROR]\033[0m $1"; }

# 確認プロンプト
print_warning "このスクリプトは以下の操作を実行します:"
echo "  - apt経由でインストールされたNode.js/npmの削除"
echo "  - 古いグローバルNode.jsファイルの削除"
echo "  - npm設定のリセット"
echo "  - キャッシュのクリア"
echo ""
print_warning "注意: NVMでインストールしたNode.jsは削除されません"
echo ""

read -p "続行しますか？ (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "クリーンアップを中止しました"
    exit 0
fi

echo ""

# バックアップディレクトリ作成
BACKUP_DIR="$HOME/nodejs_backup_$(date +%Y%m%d_%H%M%S)"
print_info "バックアップディレクトリを作成: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# 現在の状態をバックアップ
print_info "現在の設定をバックアップ中..."
if [ -f "$HOME/.npmrc" ]; then
    cp "$HOME/.npmrc" "$BACKUP_DIR/"
    print_success ".npmrcをバックアップしました"
fi

if command -v npm &> /dev/null; then
    npm list -g --depth=0 > "$BACKUP_DIR/global_packages.txt" 2>/dev/null
    print_success "グローバルパッケージリストをバックアップしました"
fi

# apt経由のNode.js/npm削除
print_info "apt経由のNode.js/npmを削除中..."
if dpkg -l | grep -q nodejs; then
    sudo apt remove -y nodejs npm
    sudo apt autoremove -y
    print_success "apt経由のNode.js/npmを削除しました"
else
    print_info "apt経由のNode.js/npmは見つかりませんでした"
fi

# 古いファイルの削除
print_info "古いNode.js関連ファイルを削除中..."

# グローバルのNode.jsファイル
GLOBAL_PATHS=(
    "/usr/local/bin/node"
    "/usr/local/bin/npm"
    "/usr/local/bin/npx"
    "/usr/local/lib/node_modules"
    "/usr/local/share/man/man1/node*"
    "/usr/local/include/node"
)

for path in "${GLOBAL_PATHS[@]}"; do
    if [ -e "$path" ] || [ -L "$path" ]; then
        print_info "削除中: $path"
        sudo rm -rf "$path"
    fi
done

# ユーザーレベルのファイル
USER_PATHS=(
    "$HOME/.npm"
    "$HOME/.node-gyp"
    "$HOME/.npmrc"
)

for path in "${USER_PATHS[@]}"; do
    if [ -e "$path" ]; then
        print_info "移動中: $path -> $BACKUP_DIR/"
        mv "$path" "$BACKUP_DIR/"
    fi
done

# which コマンドで確認
print_info "残存ファイルの確認中..."
if command -v node &> /dev/null; then
    print_warning "Node.jsがまだ検出されます: $(which node)"
    print_info "これは通常、NVMでインストールされたバージョンです"
else
    print_success "Node.jsは完全に削除されました"
fi

if command -v npm &> /dev/null; then
    print_warning "npmがまだ検出されます: $(which npm)"
    print_info "これは通常、NVMでインストールされたバージョンです"
else
    print_success "npmは完全に削除されました"
fi

# パッケージマネージャーのキャッシュクリア
print_info "パッケージマネージャーのキャッシュをクリア中..."
sudo apt update
sudo apt clean

print_success "クリーンアップが完了しました"

echo ""
print_info "バックアップ情報:"
echo "  バックアップディレクトリ: $BACKUP_DIR"
echo "  含まれるファイル:"
ls -la "$BACKUP_DIR" 2>/dev/null || echo "    (ファイルなし)"

echo ""
print_info "次のステップ:"
echo "  1. シェルを再起動してください: exec bash"
echo "  2. ./setup_nodejs.sh を実行してNode.js環境をセットアップしてください"

echo ""
print_warning "注意事項:"
echo "  - NVMがインストール済みの場合は影響を受けません"
echo "  - 削除されたファイルはバックアップディレクトリから復元できます"
echo "  - 問題が発生した場合は、バックアップから設定を復元してください"