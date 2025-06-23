#!/bin/bash

# 開発パッケージインストールスクリプト
# Node.js開発環境用

echo "=== 開発パッケージインストールスクリプト ==="
echo "実行日時: $(date)"
echo ""

# 色付きログ用の関数
print_info() { echo -e "\033[34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[33m[WARNING]\033[0m $1"; }
print_error() { echo -e "\033[31m[ERROR]\033[0m $1"; }

# エラーハンドリング
set -e
trap 'print_error "パッケージインストール中にエラーが発生しました (line $LINENO)"' ERR

# 環境確認
print_info "環境を確認中..."
if ! command -v node &> /dev/null; then
    print_error "Node.jsが見つかりません"
    print_info "先に ./setup_nodejs.sh を実行してください"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    print_error "npmが見つかりません"
    print_info "先に ./setup_nodejs.sh を実行してください"
    exit 1
fi

NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
print_success "Node.js: $NODE_VERSION, npm: $NPM_VERSION"

# Node.jsバージョンチェック
NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
if [ "$NODE_MAJOR" -lt 18 ]; then
    print_error "Node.js v18以上が必要です (現在: $NODE_VERSION)"
    print_info "Node.jsをアップデートしてから再実行してください"
    exit 1
fi

echo ""

# インストールするパッケージの定義
declare -A PACKAGES=(
    # 基本的な開発ツール
    ["typescript"]="TypeScript コンパイラ"
    ["ts-node"]="TypeScript を直接実行"
    ["@types/node"]="Node.js の型定義"
    ["nodemon"]="ファイル変更監視とサーバー再起動"
    
    # コード品質・フォーマット
    ["eslint"]="JavaScript/TypeScript リンター"
    ["prettier"]="コードフォーマッター"
    ["@typescript-eslint/parser"]="TypeScript用ESLintパーサー"
    ["@typescript-eslint/eslint-plugin"]="TypeScript用ESLintプラグイン"
    
    # パッケージ管理
    ["yarn"]="代替パッケージマネージャー"
    ["npm-check-updates"]="依存関係の更新チェック"
    
    # 開発サーバー・ツール
    ["concurrently"]="複数コマンドの並列実行"
    ["cross-env"]="クロスプラットフォーム環境変数設定"
    
    # AI開発ツール
    ["@anthropic-ai/claude-code"]="Anthropic Claude Code ツール"
)

# オプショナルパッケージ（エラーが発生してもスキップ）
declare -A OPTIONAL_PACKAGES=(
    ["pnpm"]="高速パッケージマネージャー"
    ["rimraf"]="クロスプラットフォームのrmコマンド"
    ["dotenv-cli"]="環境変数ファイルの読み込み"
)

# メインパッケージのインストール
print_info "基本開発パッケージをインストール中..."
echo ""

failed_packages=()

for package in "${!PACKAGES[@]}"; do
    description="${PACKAGES[$package]}"
    print_info "インストール中: $package ($description)"
    
    if npm install -g "$package"; then
        print_success "$package のインストールが完了しました"
    else
        print_error "$package のインストールに失敗しました"
        failed_packages+=("$package")
    fi
    echo ""
done

# オプショナルパッケージのインストール
print_info "オプショナルパッケージをインストール中..."
echo ""

for package in "${!OPTIONAL_PACKAGES[@]}"; do
    description="${OPTIONAL_PACKAGES[$package]}"
    print_info "インストール中: $package ($description) - オプショナル"
    
    if npm install -g "$package" 2>/dev/null; then
        print_success "$package のインストールが完了しました"
    else
        print_warning "$package のインストールをスキップしました"
    fi
    echo ""
done

# TypeScript設定ファイルの作成（プロジェクトディレクトリの場合）
if [ "$(basename "$PWD")" != "$(basename "$HOME")" ] && [ ! -f "tsconfig.json" ]; then
    print_info "TypeScript設定ファイルを作成中..."
    cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "removeComments": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noImplicitThis": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "exactOptionalPropertyTypes": true
  },
  "include": [
    "src/**/*"
  ],
  "exclude": [
    "node_modules",
    "dist",
    "**/*.test.ts",
    "**/*.spec.ts"
  ]
}
EOF
    print_success "tsconfig.json を作成しました"
fi

# ESLint設定ファイルの作成
if [ "$(basename "$PWD")" != "$(basename "$HOME")" ] && [ ! -f ".eslintrc.js" ]; then
    print_info "ESLint設定ファイルを作成中..."
    cat > .eslintrc.js << 'EOF'
module.exports = {
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint'],
  extends: [
    'eslint:recommended',
    '@typescript-eslint/recommended',
  ],
  rules: {
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-inferrable-types': 'off',
    '@typescript-eslint/no-non-null-assertion': 'warn',
    'prefer-const': 'error',
    'no-var': 'error',
  },
  env: {
    node: true,
    es6: true,
  },
};
EOF
    print_success ".eslintrc.js を作成しました"
fi

# Prettier設定ファイルの作成
if [ "$(basename "$PWD")" != "$(basename "$HOME")" ] && [ ! -f ".prettierrc" ]; then
    print_info "Prettier設定ファイルを作成中..."
    cat > .prettierrc << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false,
  "quoteProps": "as-needed",
  "bracketSpacing": true,
  "arrowParens": "avoid",
  "endOfLine": "lf"
}
EOF
    print_success ".prettierrc を作成しました"
fi

# .gitignore の作成
if [ "$(basename "$PWD")" != "$(basename "$HOME")" ] && [ ! -f ".gitignore" ]; then
    print_info ".gitignore ファイルを作成中..."
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# Build outputs
dist/
build/
*.tsbuildinfo

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# nyc test coverage
.nyc_output

# Grunt intermediate storage
.grunt

# Bower dependency directory
bower_components

# node-waf configuration
.lock-wscript

# Compiled binary addons
build/Release

# Dependency directories
node_modules/
jspm_packages/

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env
.env.test
.env.production
.env.local

# parcel-bundler cache
.cache
.parcel-cache

# Next.js build output
.next

# Nuxt.js build / generate output
.nuxt
dist

# Gatsby files
.cache/
public

# Storybook build outputs
.out
.storybook-out

# Temporary folders
tmp/
temp/

# Logs
logs
*.log

# Editor directories and files
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?

# macOS
.DS_Store

# Windows
Thumbs.db
ehthumbs.db
Desktop.ini
EOF
    print_success ".gitignore を作成しました"
fi

# package.jsonのスクリプトセクションを更新
if [ -f "package.json" ] && command -v jq &> /dev/null; then
    print_info "package.json のスクリプトセクションを更新中..."
    
    # jqを使用してスクリプトセクションを更新
    tmp_file=$(mktemp)
    jq '.scripts = {
        "start": "node dist/index.js",
        "dev": "nodemon --exec ts-node src/index.ts",
        "build": "tsc",
        "build:watch": "tsc --watch",
        "clean": "rimraf dist",
        "lint": "eslint src/**/*.ts",
        "lint:fix": "eslint src/**/*.ts --fix",
        "format": "prettier --write src/**/*.ts",
        "type-check": "tsc --noEmit",
        "test": "echo \"Error: no test specified\" && exit 1"
    }' package.json > "$tmp_file" && mv "$tmp_file" package.json
    
    print_success "package.json のスクリプトを更新しました"
elif [ -f "package.json" ]; then
    print_warning "jqがインストールされていないため、package.jsonの自動更新をスキップしました"
fi

# インストール結果の確認
echo ""
print_info "インストール済みパッケージの確認中..."
npm list -g --depth=0 | grep -E "(typescript|nodemon|eslint|prettier|claude-code)" || true

# Claude Codeの動作確認
echo ""
if command -v claude-code &> /dev/null; then
    print_success "Claude Code の動作確認:"
    claude-code --version
    echo ""
    print_info "Claude Code の使用方法:"
    echo "  claude-code --help     - ヘルプの表示"
    echo "  claude-code init       - プロジェクトの初期化"
    echo "  claude-code chat       - 対話モードの開始"
else
    print_warning "Claude Code のインストールに失敗しました"
    print_info "手動でインストールしてください: npm install -g @anthropic-ai/claude-code"
fi

# 失敗したパッケージの報告
if [ ${#failed_packages[@]} -gt 0 ]; then
    echo ""
    print_warning "以下のパッケージのインストールに失敗しました:"
    for package in "${failed_packages[@]}"; do
        echo "  - $package"
    done
    echo ""
    print_info "これらのパッケージは後で手動でインストールできます:"
    echo "  npm install -g package_name"
fi

echo ""
print_success "=== 開発パッケージのインストールが完了しました! ==="

echo ""
print_info "インストールされた主要ツール:"
echo "  ✓ TypeScript - 型安全なJavaScript"
echo "  ✓ ts-node - TypeScript直接実行"
echo "  ✓ nodemon - ファイル変更監視"
echo "  ✓ ESLint - コード品質チェック"
echo "  ✓ Prettier - コードフォーマット"
echo "  ✓ Claude Code - AI開発支援"

echo ""
print_info "プロジェクト開始の手順:"
echo "  1. プロジェクトディレクトリを作成: mkdir my-project && cd my-project"
echo "  2. 依存関係をインストール: npm install"
echo "  3. 開発を開始: npm run dev"

echo ""
print_info "便利なコマンド:"
echo "  npm run dev        - 開発サーバーの起動"
echo "  npm run build      - TypeScriptのコンパイル"
echo "  npm run lint       - コードチェック"
echo "  npm run format     - コードフォーマット"
echo "  claude-code chat   - AI開発支援の開始"