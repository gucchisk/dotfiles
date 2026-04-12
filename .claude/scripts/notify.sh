#!/bin/bash

# 入力からメッセージを取得
INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "入力待ち"')

# 現在のtmux情報を取得
if [ -n "$TMUX" ]; then
  TMUX_SESSION=$(tmux display-message -p '#S')
  TMUX_WINDOW=$(tmux display-message -p '#I')
  TMUX_WINDOW_NAME=$(tmux display-message -p '#W')

  # tmux情報をセッション+ウィンドウごとに一意なファイルに保存（switch_tmux.shが読み込む）
  CURRENT_DIR=$(basename "$PWD")
  TARGET_FILE="/tmp/claude_tmux_target_${TMUX_SESSION}_${TMUX_WINDOW}"

  # このtmuxセッションに接続しているクライアントのTTYを取得（iTerm2とのマッチングに使用）
  TMUX_CLIENT_TTY=$(tmux list-clients -t "${TMUX_SESSION}:" -F '#{client_tty}' 2>/dev/null | head -1)

  cat > "$TARGET_FILE" << EOF
TMUX_TARGET_SESSION="${TMUX_SESSION}"
TMUX_TARGET_WINDOW="${TMUX_WINDOW}"
TMUX_TARGET_WINDOW_NAME="${TMUX_WINDOW_NAME}"
TMUX_TARGET_DIR="${CURRENT_DIR}"
TMUX_CLIENT_TTY="${TMUX_CLIENT_TTY}"
EOF

  # iTerm2とTerminal.appの判定
  if pgrep -x "iTerm2" > /dev/null; then
    BUNDLE_ID="com.googlecode.iterm2"
  else
    BUNDLE_ID="com.apple.Terminal"
  fi

  EXEC_CMD=$(printf '%q %q' "$HOME/.claude/scripts/switch_tmux.sh" "$TARGET_FILE")
  # terminal-notifierで通知を表示
  # 通知クリック時にswitch_tmux.shを実行（対象ファイルパスを引数で渡す）
  terminal-notifier \
    -title "Claude Code" \
    -message "$MESSAGE" \
    -sound "Glass" \
    -activate "$BUNDLE_ID" \
    -execute "$EXEC_CMD"
else
  # tmux外の場合は通常の通知のみ
  BUNDLE_ID="com.googlecode.iterm2"
  if pgrep -x "Terminal" > /dev/null; then
    BUNDLE_ID="com.apple.Terminal"
  fi
  terminal-notifier \
    -title "Claude Code" \
    -message "$MESSAGE" \
    -sound "Glass" \
    -activate "$BUNDLE_ID"
fi

# tmux内でもメッセージを表示
if [ -n "$TMUX" ]; then
  tmux display-message "⚠️  Claude Code: $MESSAGE"
fi
