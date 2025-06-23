#!/bin/bash

# Node.js環境一括セットアップスクリプト
# Ubuntu 22.04用 - 完全自動インストール

echo "==========================================="
echo "   Node.js環境一括セットアップスクリプト"
echo "==========================================="
echo "実行日時: $(date)"
echo "ユーザー: $(whoami)"
echo "作業ディレクトリ: $(pwd)"
echo ""

# 色付きログ用の関数
print_info() { echo -e "\033[34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[33m[WARNING]\033[0m $1"; }
print_error() { echo -e "\033[31m[ERROR]\033[0m $1"; }
print_step() { echo -e "\033[35m[STEP]\033[0m $1"; }

# スクリプトファイルの存在確認
REQUIRED_SCRIPTS=(
    "check_environment.sh"
    "setup_nodejs.sh"
    "install_packages.sh"
)

OPTIONAL_SCRIPTS=(
    "cleanup_old_nodejs.sh"
)

print_info "必要なスクリプトファイルの確認中..."
missing_scripts=()

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -f "$script" ]; then
        missing_scripts+=("$script")
    else
        print_success "✓ $script"
    fi
done

if [ ${#missing_scripts[@]} -gt 0 ]; then
    print_error "以下のスクリプトファイルが見つかりません:"
    for script in "${missing_scripts[@]}"; do
        echo "  - $script"
    done
    echo ""
    print_info "全てのスクリプトファイルを同じディレクトリに配置してから再実行してください"
    exit 1
fi

echo ""

# 実行モードの選択
print_info "セットアップモードを選択してください:"
echo "  1. 新規インストール（推奨）"
echo "  2. クリーンインストール（既存環境をクリーンアップしてから）"
echo "  3. 環境確認のみ"
echo ""

while true; do
    read -p "選択してください (1-3): " -n 1 -r
    echo
    case $REPLY in
        1)
            SETUP_MODE="new"
            break
            ;;
        2)
            SETUP_MODE="clean"
            break
            ;;
        3)
            SETUP_MODE="check"
            break
            ;;
        *)
            print_warning "1、2、または3を入力してください"
            ;;
    esac
done

echo ""

# ログファイルの設定
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/nodejs_setup_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR"

print_info "ログファイル: $LOG_FILE"
echo ""

# ログ関数
log_and_print() {
    echo "$1" | tee -a "$LOG_FILE"
}

# ステップ1: 環境確認
print_step "ステップ1: 現在の環境を確認中..."
log_and_print "=== 環境確認開始 $(date) ==="

chmod +x check_environment.sh
./check_environment.sh 2>&1 | tee -a "$LOG_FILE"

if [ "$SETUP_MODE" = "check" ]; then
    print_success "環境確認が完了しました"
    print_info "詳細なログは $LOG_FILE をご確認ください"
    exit 0
fi

echo ""
read -p "続行しますか？ (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "セットアップを中止しました"
    exit 0
fi

# ステップ2: クリーンアップ（クリーンインストールの場合）
if [ "$SETUP_MODE" = "clean" ]; then
    print_step "ステップ2: 既存環境のクリーンアップ中..."
    log_and_print "=== クリーンアップ開始 $(date) ==="
    
    if [ -f "cleanup_old_nodejs.sh" ]; then
        chmod +x cleanup_old_nodejs.sh
        ./cleanup_old_nodejs.sh 2>&1 | tee -a "$LOG_FILE"
    else
        print_warning "cleanup_old_nodejs.sh が見つかりません。スキップします"
    fi
    
    echo ""
    print_info "シェルを再読み込み中..."
    exec bash -c "
        export LOG_FILE='$LOG_FILE'
        export SETUP_MODE='$SETUP_MODE'
        source '$0' --continue-after-cleanup
    "
fi

# ステップ3: Node.js環境のセットアップ
print_step "ステップ3: Node.js環境をセットアップ中..."
log_and_print "=== Node.js環境セットアップ開始 $(date) ==="

chmod +x setup_nodejs.sh
if ./setup_nodejs.sh 2>&1 | tee -a "$LOG_FILE"; then
    print_success "Node.js環境のセットアップが完了しました"
else
    print_error "Node.js環境のセットアップに失敗しました"
    print_info "詳細なログは $LOG_FILE をご確認ください"
    exit 1
fi

# 環境変数の再読み込み
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc" 2>/dev/null || true
fi

# NVMの読み込み
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

echo ""

# ステップ4: 開発パッケージのインストール
print_step "ステップ4: 開発パッケージをインストール中..."
log_and_print "=== 開発パッケージインストール開始 $(date) ==="

chmod +x install_packages.sh
if ./install_packages.sh 2>&1 | tee -a "$LOG_FILE"; then
    print_success "開発パッケージのインストールが完了しました"
else
    print_warning "開発パッケージのインストールで一部エラーが発生しました"
    print_info "詳細なログは $LOG_FILE をご確認ください"
fi

echo ""

# 最終確認
print_step "最終確認: インストール結果の検証中..."
log_and_print "=== 最終確認開始 $(date) ==="

echo ""
print_info "インストール結果:"

# Node.js確認
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_success "✓ Node.js: $NODE_VERSION"
    log_and_print "Node.js: $NODE_VERSION"
else
    print_error "✗ Node.js: インストールされていません"
    log_and_print "Node.js: 未インストール"
fi

# npm確認
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    print_success "✓ npm: v$NPM_VERSION"
    log_and_print "npm: v$NPM_VERSION"
else
    print_error "✗ npm: インストールされていません"
    log_and_print "npm: 未インストール"
fi

# NVM確認
if command -v nvm &> /dev/null; then
    NVM_VERSION=$(nvm --version)
    print_success "✓ NVM: v$NVM_VERSION"
    log_and_print "NVM: v$NVM_VERSION"
else
    print_warning "✗ NVM: コマンドが認識されません（要シェル再起動）"
    log_and_print "NVM: 要シェル再起動"
fi

# Claude Code確認
if command -v claude-code &> /dev/null; then
    CLAUDE_VERSION=$(claude-code --version 2>/dev/null || echo "バージョン取得失敗")
    print_success "✓ Claude Code: $CLAUDE_VERSION"
    log_and_print "Claude Code: $CLAUDE_VERSION"
else
    print_warning "✗ Claude Code: インストールされていません"
    log_and_print "Claude Code: 未インストール"
fi

# TypeScript確認
if command -v tsc &> /dev/null; then
    TS_VERSION=$(tsc --version)
    print_success "✓ TypeScript: $TS_VERSION"
    log_and_print "TypeScript: $TS_VERSION"
else
    print_warning "✗ TypeScript: インストールされていません"
    log_and_print "TypeScript: 未インストール"
fi

echo ""
log_and_print "=== セットアップ完了 $(date) ==="

# サマリー
print_success "==========================================="
print_success "   Node.js環境セットアップ完了！"
print_success "==========================================="

echo ""
print_info "次のステップ:"
echo "  1. 新しいターミナルを開くか、以下を実行:"
echo "     source ~/.bashrc"
echo ""
echo "  2. プロジェクトを開始:"
echo "     mkdir my-project && cd my-project"
echo "     npm init -y"
echo "     npm run dev"
echo ""
echo "  3. AI開発支援を使用:"
echo "     claude-code chat"

echo ""
print_info "設定ファイル:"
echo "  - Node.jsバージョン指定: .nvmrc"
echo "  - TypeScript設定: tsconfig.json"
echo "  - ESLint設定: .eslintrc.js"
echo "  - Prettier設定: .prettierrc"
echo "  - Git無視ファイル: .gitignore"

echo ""
print_info "便利なコマンド:"
echo "  nvm use           - プロジェクトのNode.jsバージョンを使用"
echo "  npm run dev       - 開発サーバーの起動"
echo "  npm run build     - プロダクションビルド"
echo "  npm run lint      - コード品質チェック"
echo "  npm run format    - コードフォーマット"

echo ""
print_info "ログファイル: $LOG_FILE"
print_info "トラブルシューティングや詳細情報については、ログファイルをご確認ください"

# 完了音（利用可能な場合）
command -v paplay &> /dev/null && paplay /usr/share/sounds/alsa/Front_Left.wav 2>/dev/null &
command -v beep &> /dev/null && beep 2>/dev/null &

print_success "セットアップが正常に完了しました！"