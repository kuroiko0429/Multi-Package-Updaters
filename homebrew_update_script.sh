#!/bin/bash

# Homebrew パッケージアップデートチェッカー
# アップデートが利用可能な場合、自動的にupdate & upgradeを実行

set -e  # エラー時にスクリプトを終了

# 色付きの出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Homebrewがインストールされているかチェック
check_homebrew() {
    if ! command -v brew &> /dev/null; then
        log_error "Homebrewがインストールされていません。"
        log_info "Homebrewをインストールしてください: https://brew.sh/"
        exit 1
    fi
}

# 現在のHomebrewの状態を表示
show_current_status() {
    log_info "現在のHomebrew状態を確認中..."
    echo ""
    brew --version
    echo ""
    log_info "インストール済みパッケージ数: $(brew list --formula | wc -l | tr -d ' ')"
    log_info "インストール済みCask数: $(brew list --cask | wc -l | tr -d ' ')"
    echo ""
}

# アップデート可能なパッケージをチェック
check_outdated() {
    log_info "アップデート可能なパッケージを確認中..."
    
    # まずリポジトリ情報を更新（静かに実行）
    brew update --quiet
    
    # アップデート可能なformula（パッケージ）をチェック
    OUTDATED_FORMULAS=$(brew outdated --formula 2>/dev/null | wc -l | tr -d ' ')
    
    # アップデート可能なcask（アプリケーション）をチェック
    OUTDATED_CASKS=$(brew outdated --cask 2>/dev/null | wc -l | tr -d ' ')
    
    TOTAL_OUTDATED=$((OUTDATED_FORMULAS + OUTDATED_CASKS))
    
    if [ $TOTAL_OUTDATED -eq 0 ]; then
        log_success "すべてのパッケージは最新です！"
        return 1
    else
        log_warning "アップデート可能: Formula $OUTDATED_FORMULAS 個, Cask $OUTDATED_CASKS 個"
        echo ""
        
        if [ $OUTDATED_FORMULAS -gt 0 ]; then
            log_info "アップデート可能なFormula:"
            brew outdated --formula
            echo ""
        fi
        
        if [ $OUTDATED_CASKS -gt 0 ]; then
            log_info "アップデート可能なCask:"
            brew outdated --cask
            echo ""
        fi
        
        return 0
    fi
}

# アップデートを実行
perform_update() {
    log_info "アップデートを開始します..."
    echo ""
    
    # タイムスタンプを記録
    START_TIME=$(date)
    
    log_info "brew update && brew upgrade を実行中..."
    
    if brew update && brew upgrade; then
        echo ""
        log_success "アップデートが正常に完了しました！"
        
        # 完了時刻を表示
        END_TIME=$(date)
        echo ""
        log_info "開始時刻: $START_TIME"
        log_info "完了時刻: $END_TIME"
        
        # クリーンアップを提案
        echo ""
        log_info "不要なファイルをクリーンアップするには以下を実行してください:"
        echo "brew cleanup"
        
    else
        log_error "アップデート中にエラーが発生しました。"
        exit 1
    fi
}

# メイン処理
main() {
    echo "========================================"
    echo "     Homebrew Update Checker"
    echo "========================================"
    echo ""
    
    # Homebrewの存在チェック
    check_homebrew
    
    # 現在の状態表示
    show_current_status
    
    # アップデートチェック
    if check_outdated; then
        # アップデートが必要な場合
        echo ""
        read -p "アップデートを実行しますか？ (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            perform_update
        else
            log_info "アップデートをキャンセルしました。"
        fi
    fi
    
    echo ""
    log_info "スクリプト完了。"
}

# スクリプト実行
main "$@"