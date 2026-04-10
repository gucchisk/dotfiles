#!/bin/bash
#
# dotfiles テストスイート
# 各設定ファイルとスクリプトの整合性・動作を検証する
#

set -euo pipefail

# === テストフレームワーク ===

COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_CYAN='\033[0;36m'
COLOR_RESET='\033[0m'

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

pass() {
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  PASSED_TESTS=$((PASSED_TESTS + 1))
  echo -e "  ${COLOR_GREEN}PASS${COLOR_RESET} $1"
}

fail() {
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  FAILED_TESTS=$((FAILED_TESTS + 1))
  echo -e "  ${COLOR_RED}FAIL${COLOR_RESET} $1"
  if [ -n "${2:-}" ]; then
    echo -e "       ${COLOR_RED}=> $2${COLOR_RESET}"
  fi
}

skip() {
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
  echo -e "  ${COLOR_YELLOW}SKIP${COLOR_RESET} $1 ($2)"
}

section() {
  echo ""
  echo -e "${COLOR_CYAN}=== $1 ===${COLOR_RESET}"
}

assert_file_exists() {
  local filepath="$1"
  local label="${2:-$filepath が存在する}"
  if [ -e "$filepath" ]; then
    pass "$label"
  else
    fail "$label" "ファイルが見つかりません: $filepath"
  fi
}

assert_file_executable() {
  local filepath="$1"
  local label="${2:-$filepath が実行可能}"
  if [ -x "$filepath" ]; then
    pass "$label"
  else
    fail "$label" "実行権限がありません: $filepath"
  fi
}

assert_command_exists() {
  local cmd="$1"
  local label="${2:-コマンド $cmd が利用可能}"
  if command -v "$cmd" &>/dev/null; then
    pass "$label"
  else
    skip "$label" "$cmd が未インストール"
  fi
}

# === 1. symlink.sh のテスト ===

section "symlink.sh - 構造テスト"

assert_file_exists "$DOTFILES_DIR/symlink.sh" "symlink.sh が存在する"
assert_file_executable "$DOTFILES_DIR/symlink.sh" "symlink.sh が実行可能"

# シェバン行の確認
if head -1 "$DOTFILES_DIR/symlink.sh" | grep -q '^#!/bin/bash'; then
  pass "symlink.sh にシェバン行がある"
else
  fail "symlink.sh にシェバン行がある"
fi

section "symlink.sh - リンク対象ファイルの存在確認"

# 個別リンク対象のソースファイルが存在するか
INDIVIDUAL_TARGETS=(.emacs .emacs.d/elisp .emacs.d/conf .gitconfig .emacs.d/custom.el .claude/scripts)
for target in "${INDIVIDUAL_TARGETS[@]}"; do
  assert_file_exists "$DOTFILES_DIR/$target" "ソースファイル $target が存在する"
done

# ディレクトリリンク対象のディレクトリが存在するか
DIR_TARGETS=(.config/fish/functions .config/fish/conf.d .claude/skills)
for dir in "${DIR_TARGETS[@]}"; do
  if [ -d "$DOTFILES_DIR/$dir" ]; then
    pass "ディレクトリ $dir が存在する"
  else
    fail "ディレクトリ $dir が存在する" "ディレクトリが見つかりません"
  fi
done

section "symlink.sh - シンボリックリンクの確認（デプロイ済みの場合）"

# 個別ファイルのシンボリックリンク確認
for target in "${INDIVIDUAL_TARGETS[@]}"; do
  dest="$HOME/$target"
  if [ -L "$dest" ]; then
    # リンク先が正しいか確認
    link_target=$(readlink "$dest")
    expected="$DOTFILES_DIR/$target"
    if [ "$link_target" = "$expected" ]; then
      pass "$HOME/$target => dotfiles (リンク先が正しい)"
    else
      fail "$HOME/$target => dotfiles" "リンク先が不正: $link_target (期待: $expected)"
    fi
  elif [ -e "$dest" ]; then
    fail "$HOME/$target がシンボリックリンク" "通常のファイル/ディレクトリとして存在しています"
  else
    skip "$HOME/$target のリンク確認" "未デプロイ"
  fi
done

# ディレクトリ内ファイルのシンボリックリンク確認
for dir in "${DIR_TARGETS[@]}"; do
  if [ -d "$DOTFILES_DIR/$dir" ]; then
    for file in "$DOTFILES_DIR/$dir"/*; do
      [ -e "$file" ] || continue
      basename=$(basename "$file")
      dest="$HOME/$dir/$basename"
      if [ -L "$dest" ]; then
        link_target=$(readlink "$dest")
        expected="$DOTFILES_DIR/$dir/$basename"
        if [ "$link_target" = "$expected" ]; then
          pass "$HOME/$dir/$basename => dotfiles (リンク先が正しい)"
        else
          fail "$HOME/$dir/$basename => dotfiles" "リンク先不正: $link_target"
        fi
      elif [ -e "$dest" ]; then
        fail "$HOME/$dir/$basename がシンボリックリンク" "通常ファイルとして存在"
      else
        skip "$HOME/$dir/$basename のリンク確認" "未デプロイ"
      fi
    done
  fi
done

section "symlink.sh - 既存リンクの上書き防止テスト"

# symlink.sh は [ ! -L $dist ] で既にリンクの場合はスキップする仕様
# テスト: 既にシンボリックリンクがある場合に再実行しても安全か確認
TMPDIR_TEST=$(mktemp -d)
# shellcheck disable=SC2329
cleanup() { rm -rf "$TMPDIR_TEST"; }
trap cleanup EXIT

# テスト用のダミーファイルとリンクを作成
mkdir -p "$TMPDIR_TEST/src" "$TMPDIR_TEST/dest"
echo "original" > "$TMPDIR_TEST/src/testfile"
ln -s "$TMPDIR_TEST/src/testfile" "$TMPDIR_TEST/dest/testfile"

# 既にリンクがある場合、-L チェックが正しく動作するか
if [ -L "$TMPDIR_TEST/dest/testfile" ]; then
  pass "既存シンボリックリンクの検出が正しく動作する"
else
  fail "既存シンボリックリンクの検出"
fi

# 通常ファイルの場合は -L が false になるか
echo "regular" > "$TMPDIR_TEST/dest/regularfile"
if [ ! -L "$TMPDIR_TEST/dest/regularfile" ]; then
  pass "通常ファイルはシンボリックリンクとして検出されない"
else
  fail "通常ファイルの判定" "通常ファイルがリンクとして検出されました"
fi

# === 2. gen_claude_settings.sh のテスト ===

section "gen_claude_settings.sh - 構造テスト"

assert_file_exists "$DOTFILES_DIR/gen_claude_settings.sh" "gen_claude_settings.sh が存在する"
assert_file_executable "$DOTFILES_DIR/gen_claude_settings.sh" "gen_claude_settings.sh が実行可能"

# ベース設定ファイルの存在確認
assert_file_exists "$DOTFILES_DIR/.claude/settings.json.base" "settings.json.base が存在する"

# ベース設定ファイルが有効なJSONか確認
if command -v jq &>/dev/null; then
  if jq empty "$DOTFILES_DIR/.claude/settings.json.base" 2>/dev/null; then
    pass "settings.json.base が有効なJSON"
  else
    fail "settings.json.base が有効なJSON" "JSONパースエラー"
  fi
else
  skip "settings.json.base のJSON検証" "jq が未インストール"
fi

# gen_claude_settings.sh のタイポ検出テスト
# 注: cp先が setting.json (typo) になっている
if grep -q 'setting\.json' "$DOTFILES_DIR/gen_claude_settings.sh" && \
   ! grep -q 'settings\.json' <(grep 'cp.*setting' "$DOTFILES_DIR/gen_claude_settings.sh"); then
  fail "gen_claude_settings.sh のファイル名" "cp先が 'setting.json' (sが抜けている可能性: settings.json)"
else
  pass "gen_claude_settings.sh のファイル名に問題なし"
fi

# === 3. Fish関数のテスト ===

section "Fish関数 - ファイル存在確認"

FISH_FUNCTIONS_DIR="$DOTFILES_DIR/.config/fish/functions"
FISH_CONFD_DIR="$DOTFILES_DIR/.config/fish/conf.d"

assert_file_exists "$FISH_FUNCTIONS_DIR/mkcd.fish" "mkcd.fish が存在する"
assert_file_exists "$FISH_FUNCTIONS_DIR/set_openai_api_key.fish" "set_openai_api_key.fish が存在する"

section "Fish関数 - mkcd.fish 構文チェック"

# mkcd.fish が正しい fish 関数定義を持つか
if grep -q '^function mkcd' "$FISH_FUNCTIONS_DIR/mkcd.fish"; then
  pass "mkcd.fish に function 定義がある"
else
  fail "mkcd.fish に function 定義がある"
fi

if grep -q '^end' "$FISH_FUNCTIONS_DIR/mkcd.fish"; then
  pass "mkcd.fish に end 文がある"
else
  fail "mkcd.fish に end 文がある"
fi

# mkcd が mkdir と cd の両方を呼んでいるか
if grep -q 'mkdir' "$FISH_FUNCTIONS_DIR/mkcd.fish" && grep -q 'cd' "$FISH_FUNCTIONS_DIR/mkcd.fish"; then
  pass "mkcd.fish が mkdir と cd を呼び出している"
else
  fail "mkcd.fish が mkdir と cd を呼び出している"
fi

section "Fish関数 - set_openai_api_key.fish 構文チェック"

if grep -q '^function set_openai_api_key' "$FISH_FUNCTIONS_DIR/set_openai_api_key.fish"; then
  pass "set_openai_api_key.fish に function 定義がある"
else
  fail "set_openai_api_key.fish に function 定義がある"
fi

if grep -q 'OPENAI_API_KEY' "$FISH_FUNCTIONS_DIR/set_openai_api_key.fish"; then
  pass "set_openai_api_key.fish が OPENAI_API_KEY を設定している"
else
  fail "set_openai_api_key.fish が OPENAI_API_KEY を設定している"
fi

if grep -q 'set -x' "$FISH_FUNCTIONS_DIR/set_openai_api_key.fish"; then
  pass "set_openai_api_key.fish が環境変数をエクスポートしている (set -x)"
else
  fail "set_openai_api_key.fish が環境変数をエクスポートしている"
fi

section "Fish関数 - conf.d 構文チェック"

# conf.d 内の全 .fish ファイルの基本チェック
if [ -d "$FISH_CONFD_DIR" ]; then
  for fishfile in "$FISH_CONFD_DIR"/*.fish; do
    [ -e "$fishfile" ] || continue
    basename=$(basename "$fishfile")
    # fish -n でシンタックスチェック（fish がインストールされている場合）
    if command -v fish &>/dev/null; then
      if fish -n "$fishfile" 2>/dev/null; then
        pass "$basename の構文が正しい"
      else
        fail "$basename の構文が正しい" "fish構文エラー"
      fi
    else
      skip "$basename の構文チェック" "fish が未インストール"
    fi
  done
fi

# === 4. notify.sh / switch_tmux.sh のテスト ===

section "Claude Scripts - 構造テスト"

assert_file_exists "$DOTFILES_DIR/.claude/scripts/notify.sh" "notify.sh が存在する"
assert_file_executable "$DOTFILES_DIR/.claude/scripts/notify.sh" "notify.sh が実行可能"

assert_file_exists "$DOTFILES_DIR/.claude/scripts/switch_tmux.sh" "switch_tmux.sh が存在する"
assert_file_executable "$DOTFILES_DIR/.claude/scripts/switch_tmux.sh" "switch_tmux.sh が実行可能"

section "Claude Scripts - notify.sh 内容チェック"

# notify.sh が stdin から JSON を読み取るか
# shellcheck disable=SC2016
if grep -q 'INPUT=$(cat)' "$DOTFILES_DIR/.claude/scripts/notify.sh"; then
  pass "notify.sh が stdin からの入力を読み取る"
else
  fail "notify.sh が stdin からの入力を読み取る"
fi

# notify.sh が jq でメッセージを抽出するか
if grep -q 'jq -r' "$DOTFILES_DIR/.claude/scripts/notify.sh"; then
  pass "notify.sh が jq でメッセージを抽出する"
else
  fail "notify.sh が jq でメッセージを抽出する"
fi

# TMUX判定分岐があるか
# shellcheck disable=SC2016
if grep -q 'if \[ -n "\$TMUX" \]' "$DOTFILES_DIR/.claude/scripts/notify.sh"; then
  pass "notify.sh に TMUX 環境判定がある"
else
  fail "notify.sh に TMUX 環境判定がある"
fi

# terminal-notifier の呼び出しがあるか
if grep -q 'terminal-notifier' "$DOTFILES_DIR/.claude/scripts/notify.sh"; then
  pass "notify.sh が terminal-notifier を使用する"
else
  fail "notify.sh が terminal-notifier を使用する"
fi

# switch_tmux.sh への参照があるか
if grep -q 'switch_tmux.sh' "$DOTFILES_DIR/.claude/scripts/notify.sh"; then
  pass "notify.sh が switch_tmux.sh を参照している"
else
  fail "notify.sh が switch_tmux.sh を参照している"
fi

section "Claude Scripts - switch_tmux.sh 内容チェック"

# ターゲットファイルの読み込みがあるか
if grep -q '/tmp/claude_tmux_target' "$DOTFILES_DIR/.claude/scripts/switch_tmux.sh"; then
  pass "switch_tmux.sh が tmux ターゲットファイルを読み込む"
else
  fail "switch_tmux.sh が tmux ターゲットファイルを読み込む"
fi

# tmux select-window の呼び出しがあるか
if grep -q 'tmux select-window' "$DOTFILES_DIR/.claude/scripts/switch_tmux.sh"; then
  pass "switch_tmux.sh が tmux select-window を呼び出す"
else
  fail "switch_tmux.sh が tmux select-window を呼び出す"
fi

# iTerm2 / Terminal.app の分岐があるか
if grep -q 'iTerm2' "$DOTFILES_DIR/.claude/scripts/switch_tmux.sh" && \
   grep -q 'Terminal' "$DOTFILES_DIR/.claude/scripts/switch_tmux.sh"; then
  pass "switch_tmux.sh が iTerm2 と Terminal.app を分岐処理する"
else
  fail "switch_tmux.sh が iTerm2 と Terminal.app を分岐処理する"
fi

# === 5. Emacs設定の整合性テスト ===

section "Emacs設定 - エントリーポイント"

assert_file_exists "$DOTFILES_DIR/.emacs" ".emacs が存在する"

# .emacs から load されている設定ファイルが全て存在するか
LOADED_MODULES=$(grep '^\(load "' "$DOTFILES_DIR/.emacs" | sed 's/^(load "//;s/".*//' || true)
for module in $LOADED_MODULES; do
  if [ -f "$DOTFILES_DIR/.emacs.d/conf/${module}.el" ]; then
    pass ".emacs.d/conf/${module}.el が存在する (load \"$module\")"
  else
    fail ".emacs.d/conf/${module}.el が存在する" ".emacs で load されているが見つかりません"
  fi
done

section "Emacs設定 - 設定モジュールの構文チェック"

# Emacs が利用可能な場合、各設定ファイルの構文チェック
if command -v emacs &>/dev/null; then
  for elfile in "$DOTFILES_DIR/.emacs.d/conf"/*.el; do
    [ -e "$elfile" ] || continue
    basename=$(basename "$elfile")
    # 基本的な括弧の対応チェック（Emacs Lisp の軽量チェック）
    open_parens=$(tr -cd '(' < "$elfile" | wc -c | tr -d ' ')
    close_parens=$(tr -cd ')' < "$elfile" | wc -c | tr -d ' ')
    if [ "$open_parens" -eq "$close_parens" ]; then
      pass "$basename の括弧が対応している ($open_parens 組)"
    else
      fail "$basename の括弧が対応している" "開き括弧: $open_parens, 閉じ括弧: $close_parens"
    fi
  done
else
  skip "Emacs設定の構文チェック" "emacs が未インストール"
fi

section "Emacs設定 - custom.el"

assert_file_exists "$DOTFILES_DIR/.emacs.d/custom.el" "custom.el が存在する"

# .emacs で custom-file が設定されているか
if grep -q 'custom-file' "$DOTFILES_DIR/.emacs"; then
  pass ".emacs で custom-file が設定されている"
else
  fail ".emacs で custom-file が設定されている"
fi

# === 6. Git設定のテスト ===

section "Git設定"

assert_file_exists "$DOTFILES_DIR/.gitconfig" ".gitconfig が存在する"

# 基本的なエイリアスが定義されているか
for alias in st br ci co; do
  if grep -q "^\s*$alias\s*=" "$DOTFILES_DIR/.gitconfig"; then
    pass "git alias '$alias' が定義されている"
  else
    fail "git alias '$alias' が定義されている"
  fi
done

# include path が設定されているか
if grep -q 'path = ~/.gituser' "$DOTFILES_DIR/.gitconfig"; then
  pass ".gitconfig が ~/.gituser をインクルードしている"
else
  fail ".gitconfig が ~/.gituser をインクルードしている"
fi

# === 7. 必要な外部コマンドの確認 ===

section "外部依存コマンドの確認"

assert_command_exists "jq" "jq が利用可能 (gen_claude_settings.sh, notify.sh で使用)"
assert_command_exists "fish" "fish が利用可能 (シェル設定)"
assert_command_exists "emacs" "emacs が利用可能 (エディタ設定)"
assert_command_exists "git" "git が利用可能 (バージョン管理)"
assert_command_exists "terminal-notifier" "terminal-notifier が利用可能 (通知)"
assert_command_exists "tmux" "tmux が利用可能 (ターミナル多重化)"

# === テスト結果サマリー ===

echo ""
echo -e "${COLOR_CYAN}==========================================${COLOR_RESET}"
echo -e "${COLOR_CYAN}  テスト結果サマリー${COLOR_RESET}"
echo -e "${COLOR_CYAN}==========================================${COLOR_RESET}"
echo -e "  合計:   $TOTAL_TESTS"
echo -e "  ${COLOR_GREEN}成功:   $PASSED_TESTS${COLOR_RESET}"
echo -e "  ${COLOR_RED}失敗:   $FAILED_TESTS${COLOR_RESET}"
echo -e "  ${COLOR_YELLOW}スキップ: $SKIPPED_TESTS${COLOR_RESET}"
echo -e "${COLOR_CYAN}==========================================${COLOR_RESET}"

if [ "$FAILED_TESTS" -gt 0 ]; then
  echo -e "${COLOR_RED}テストに失敗があります${COLOR_RESET}"
  exit 1
else
  echo -e "${COLOR_GREEN}全テスト成功${COLOR_RESET}"
  exit 0
fi
