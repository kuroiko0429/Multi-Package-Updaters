#!/data/data/com.termux/files/usr/bin/bash

# Termux pkgパッケージアップデートチェッカー
# アップデートが利用可能な場合、自動的にupdate & upgradeを実行

set -e  # エラー時にスクリプトを終了

# 色付きの出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ログ出力関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_note() {
    echo -e "${CYAN}[NOTE]${NC} $1"
}

# Termux環境とpkgがインストールされているかチェック
check_termux_environment() {
    if [[ ! "$PREFIX" == *"com.termux"* ]]; then
        log_warning "Termux環境ではない可能性があります。"
    fi
    
    if ! command -v pkg &> /dev/null; then
        log_error "pkgコマンドが見つかりません。"
        log_info "Termux環境で実行してください。"
        exit 1
    fi
}

# 現在のpkgの状態を表示
show_current_status() {
    log_info "現在のTermux pkg状態を確認中..."
    echo ""
    
    # Termuxバージョン情報
    if command -v termux-info &> /dev/null; then
        log_note "Termux環境情報:"
        termux-info | head -3
        echo ""
    fi
    
    # インストール済みパッケージ数を取得
    INSTALLED_COUNT=$(pkg list-installed 2>/dev/null | grep -c "^" || echo "0")
    log_info "インストール済みパッケージ数: $INSTALLED_COUNT"
    
    # ディスク使用量を表示
    if command -v du &> /dev/null; then
        PACKAGE_SIZE=$(du -sh $PREFIX 2>/dev/null | cut -f1 || echo "不明")
        log_info "パッケージディスク使用量: $PACKAGE_SIZE"
    fi
    
    echo ""
}

# アップデート可能なパッケージをチェック
check_outdated() {
    log_info "アップデート可能なパッケージを確認中..."
    echo ""
    
    # まずリポジトリ情報を更新
    log_info "パッケージリストを更新中..."
    if ! pkg update -y &> /dev/null; then
        log_error "パッケージリストの更新に失敗しました。"
        return 1
    fi
    
    # アップデート可能なパッケージを取得
    UPGRADABLE_OUTPUT=$(pkg list-upgradable 2>/dev/null || echo "")
    
    if [ -z "$UPGRADABLE_OUTPUT" ]; then
        log_success "すべてのパッケージは最新です！"
        return 1
    else
        # アップデート可能パッケージ数をカウント
        UPGRADABLE_COUNT=$(echo "$UPGRADABLE_OUTPUT" | grep -c "^" || echo "0")
        
        if [ "$UPGRADABLE_COUNT" -eq 0 ]; then
            log_success "すべてのパッケージは最新です！"
            return 1
        else
            log_warning "アップデート可能なパッケージ: $UPGRADABLE_COUNT 個"
            echo ""
            log_info "アップデート可能なパッケージ一覧:"
            echo "$UPGRADABLE_OUTPUT" | head -20  # 最大20個まで表示
            
            if [ "$UPGRADABLE_COUNT" -gt 20 ]; then
                echo "... および他 $((UPGRADABLE_COUNT - 20)) 個"
            fi
            
            echo ""
            return 0
        fi
    fi
}

# アップデートを実行
perform_update() {
    log_info "アップデートを開始します..."
    echo ""
    
    # タイムスタンプを記録
    START_TIME=$(date)
    
    log_info "pkg update && pkg upgrade を実行中..."
    echo ""
    
    # 実際のアップデート実行
    if pkg update && pkg upgrade -y; then
        echo ""
        log_success "アップデートが正常に完了しました！"
        
        # 完了時刻を表示
        END_TIME=$(date)
        echo ""
        log_info "開始時刻: $START_TIME"
        log_info "完了時刻: $END_TIME"
        
        # クリーンアップを提案
        echo ""
        log_note "不要なファイルをクリーンアップするには以下を実行してください:"
        echo "pkg autoclean"
        echo "pkg clean"
        
        # 容量確認
        if command -v du &> /dev/null; then
            NEW_SIZE=$(du -sh $PREFIX 2>/dev/null | cut -f1 || echo "不明")
            log_info "アップデート後のディスク使用量: $NEW_SIZE"
        fi
        
    else
        log_error "アップデート中にエラーが発生しました。"
        echo ""
        log_note "トラブルシューティング:"
        echo "1. インターネット接続を確認してください"
        echo "2. ストレージ容量を確認してください"
        echo "3. 'pkg update' を単独で実行してみてください"
        exit 1
    fi
}

# ヘルプメッセージ
show_help() {
    echo "使用方法: $0 [オプション]"
    echo ""
    echo "オプション:"
    echo "  -h, --help     このヘルプメッセージを表示"
    echo "  -f, --force    確認なしでアップデートを実行"
    echo "  -c, --check    チェックのみ実行（アップデートしない）"
    echo "  -q, --quiet    詳細出力を抑制"
    echo ""
}

# コマンドライン引数の処理
FORCE_UPDATE=false
CHECK_ONLY=false
QUIET_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--force)
            FORCE_UPDATE=true
            shift
            ;;
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        *)
            log_error "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
done

# メイン処理
main() {
    if [ "$QUIET_MODE" = false ]; then
        echo "========================================"
        echo "     Termux pkg Update Checker"
        echo "========================================"
        echo ""
    fi
    
    # Termux環境の確認
    check_termux_environment
    
    # 現在の状態表示（Quietモードでない場合）
    if [ "$QUIET_MODE" = false ]; then
        show_current_status
    fi
    
    # アップデートチェック
    if check_outdated; then
        # アップデートが必要な場合
        
        if [ "$CHECK_ONLY" = true ]; then
            log_info "チェックのみモードです。アップデートは実行しません。"
            exit 0
        fi
        
        if [ "$FORCE_UPDATE" = true ]; then
            log_info "強制アップデートモードでアップデートを実行します..."
            perform_update
        else
            echo ""
            read -p "アップデートを実行しますか？ (y/N): " -n 1 -r
            echo ""
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                perform_update
            else
                log_info "アップデートをキャンセルしました。"
                log_note "後でアップデートするには: pkg update && pkg upgrade"
            fi
        fi
    fi
    
    if [ "$QUIET_MODE" = false ]; then
        echo ""
        log_info "スクリプト完了。"
    fi
}

# 割り込み処理
trap 'log_error "スクリプトが中断されました。"; exit 130' INT

# スクリプト実行
main "$@"