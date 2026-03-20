---
name: commit
description: 現在のプロジェクトの差分からコミットコメントを考えてください。コミットコメントはconventional commitsを参考にしてください。そのコメントでコミットしてください。コミット前に確認をお願いします
---

# Commit

現在のプロジェクトのgit diffを分析し、Conventional Commitsに従ったコミットメッセージを生成してコミットする。

## ワークフロー

1. `git diff` と `git diff --cached` で変更内容を確認する
2. 変更内容を分析し、Conventional Commitsの形式でコミットのタイトルを作成する（タイトル以外のコメントは必要ありません）
3. コミットタイトルをユーザーに提示して確認を取る
4. 承認後、コミットを実行する

## Conventional Commits 形式

```
<type>[optional scope]: <description>

[optional body]
```

### type の種類

- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメントのみの変更
- `style`: コードの意味に影響しない変更（空白、フォーマット等）
- `refactor`: バグ修正でも機能追加でもないコード変更
- `perf`: パフォーマンス改善
- `test`: テストの追加・修正
- `chore`: ビルドプロセスやツールの変更
- `ci`: CI/CD関連の変更

### ルール

- body は不要です。Conventional Commits の title（`<type>[optional scope]: <description>`）のみを作成してください。
- title は英語で記述する
- 破壊的変更がある場合は type に `!` を付与する
