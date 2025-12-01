# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリの概要

このリポジトリは、macOS環境全体で設定ファイルを管理するための個人用dotfilesリポジトリです。シンボリックリンクを使用して、この一元化された場所からホームディレクトリに設定をデプロイします。
Emacs, fish shell, Gitの設定が主なものです。

## アーキテクチャ

### デプロイシステム

`symlink.sh`を使用して、このリポジトリからホームディレクトリへのシンボリックリンクを作成します。スクリプトは以下を行います：
- 個別ファイルのリンク：`.emacs`, `.emacs.d/elisp`, `.emacs.d/conf`, `.gitconfig`, `.emacs.d/custom.el`
- `.config/fish/functions/`および`.config/fish/conf.d/`内の全ファイルを再帰的にリンク

ファイルを修正する際は、実際の設定ファイルを編集しています（コピーではありません）。

### Emacs設定の構造

Emacs設定はモジュラーアーキテクチャに従っています：

**メインエントリーポイント：** `.emacs`
- パッケージ管理の初期化（MELPA、GNU ELPA、Org）
- テーマとグローバル設定の読み込み
- `.emacs.d/conf/`から個別の言語/ツール設定を読み込み

**設定モジュール：** `.emacs.d/conf/`
- 各`.el`ファイルは特定の言語またはツールを設定
- `.emacs`から`(load "filename")`で読み込まれる
- 例：`go.el`, `typescript.el`, `github-copilot.el`, `lsp-conf.el`

**カスタムelispパッケージ：** `.emacs.d/elisp/`
- パッケージマネージャー経由でないサードパーティまたはカスタムelispファイルを含む
- 例：`gyp.el`, `wat-mode.el`, `company-tern.el`

**ユーザーカスタマイズ：** `.emacs.d/custom.el`
- Emacsのcustomizeシステムにより自動生成
- `.emacs`をクリーンに保つため、別途読み込まれる

### Fish Shell設定

**環境マネージャー：** `.config/fish/conf.d/`
- 各`.fish`ファイルは特定の環境マネージャーまたはツールを初期化
- fish shell起動時に自動読み込み
- 例：`anyenv.fish`, `rbenv.fish`, `pyenv.fish`, `direnv.fish`

**カスタム関数：** `.config/fish/functions/`
- ユーザー定義のfish関数
- 例：`mkcd.fish`, `set_openai_api_key.fish`

## 言語固有の設定

### Go開発
- LSPモード経由で`gopls`を使用（`go install golang.org/x/tools/gopls@latest`が必要）
- タブ幅：4スペース（実際はタブ、`indent-tabs-mode t`）
- 保存時に`lsp-format-buffer`と`lsp-organize-imports`で自動フォーマット
- `~/go/bin`をexec-pathに追加
- `lsp-conf.el`でキーバインド定義：M-.（定義）、M-/（参照）

### TypeScript/JavaScript
- TypeScriptは`typescript-ts-mode`でTideモードを使用
- インデントサイズ：2スペース
- 保存前に自動フォーマット
- FlycheckとCompany-modeが有効

### Python
- `py.el`に設定

### C++
- `cpp.el`に設定

### その他の言語
- PHP: `php-conf.el`
- Swift: `swift.el`
- Vue: `vue.el`
- Markdown: `md.el`

## AI/生産性ツール

### Copilot統合
- `prog-mode-hook`経由で全プログラミングモードで有効
- Tabキーで補完を受け入れ
- Copilot Chatのキーバインド：
  - `C-c c c`: チャット表示
  - `C-c c a`: 現在のバッファを追加
  - `C-c c s`: 選択範囲でカスタムプロンプト
  - `C-c c r`: チャットリセット

### gptel（AI統合）
- GitHub Copilotバックエンドを使用するように設定
- デフォルトモデル：`claude-3.7-sonnet`
- markdown-modeで`C-c C-c`によりAIに送信

### Multiple Cursors
- `C-;`: 次の同じシンボルをマーク
- `C-M-;`: 次の同じものをスキップ
- `C-l`: 前の同じシンボルをマーク
- `C-c C-;`: 全ての同じシンボルをマーク
- `C-c m l`: 行を編集

## よく使うコマンド

### Dotfilesのデプロイ
```bash
# このリポジトリからホームディレクトリへのシンボリックリンクを作成
./symlink.sh
```

### Emacsパッケージ管理
パッケージはMELPA/GNU ELPAからpackage.el経由でインストールされます。新しいパッケージをインストールするには、適切なconfファイルに追加し、package-initializeが実行されることを確認してください。

### 設定の変更

**新しい言語設定の追加：**
1. `.emacs.d/conf/`に新しい`.el`ファイルを作成（例：`newlang.el`）
2. `.emacs`の適切なセクションに`(load "newlang")`を追加
3. Emacs起動時にファイルが自動的に読み込まれます

**新しいfish環境の追加：**
1. `.config/fish/conf.d/`に新しい`.fish`ファイルを作成
2. 次回の`symlink.sh`実行時にシンボリックリンクが自動作成されます
3. Fishが起動時に自動読み込みします

**キーバインドの競合：**
一部のモードはグローバルキーバインドを上書きする可能性があります。競合するバインドを確認して無効化してください（例：`go.el`では`lsp-mode-map`が`C-;`を無効化してmultiple-cursorsとの競合を回避しています）。
