---
name: hook-guideline
description: フック（hooks）の新規作成・修正時に自動参照される構築ガイドライン。フックの設計・ヒアリング・レビューに使用。ユーザーが「フックを作成」「hookを追加」「自動化したい」と言った時や、settings.jsonのhooksセクションを変更する時に使用。
user-invocable: false
allowed-tools: Read, Glob, Grep, Edit, Write
---

# Hook Building Guide

フック（hooks）の新規作成・修正時に必ず参照するガイドライン。
公式ドキュメント: https://code.claude.com/docs/en/hooks-guide

## Instructions

### フック作成時の必須フロー

1. **ヒアリング**: ユーザーからフック作成依頼を受けたら、以下を確認する
   - 何を自動化したいか（目的）
   - どのタイミングで実行するか（イベントタイプ）
   - フィルタ条件（matcher）が必要か
   - フックのタイプ（command / prompt / agent / http）
   - 配置先（グローバル `~/.claude/settings.json` / プロジェクト `.claude/settings.json` / ローカル `.claude/settings.local.json`）
   - ブロッキング動作が必要か（許可/拒否の判定）

2. **設計**: ヒアリング結果に基づきフック設定を設計する。詳細は以下のリファレンスを参照。

3. **レビュー**: 作成したフックが以下を満たすか検証する
   - 正しいイベントタイプとmatcherの組み合わせ
   - JSONの構文が正しいこと（末尾カンマ・コメント不可）
   - スクリプトファイルが必要な場合は実行権限（`chmod +x`）
   - Stop hookの場合は無限ループ防止（`stop_hook_active` チェック）

### フック修正時

既存の settings.json のフック設定を読み込み、変更点を確認した上で修正する。

## リファレンス

### イベントタイプ一覧

| イベント | 発火タイミング | matcher対象 |
|---------|--------------|------------|
| `SessionStart` | セッション開始・再開時 | 開始方法: `startup`, `resume`, `clear`, `compact` |
| `UserPromptSubmit` | プロンプト送信時（処理前） | matcher非対応 |
| `PreToolUse` | ツール実行前（ブロック可能） | ツール名: `Bash`, `Edit\|Write`, `mcp__.*` |
| `PermissionRequest` | 許可ダイアログ表示時 | ツール名 |
| `PostToolUse` | ツール実行成功後 | ツール名 |
| `PostToolUseFailure` | ツール実行失敗後 | ツール名 |
| `Notification` | 通知送信時 | 通知タイプ: `permission_prompt`, `idle_prompt` |
| `SubagentStart` | サブエージェント起動時 | エージェントタイプ |
| `SubagentStop` | サブエージェント完了時 | エージェントタイプ |
| `Stop` | Claude応答完了時 | matcher非対応 |
| `StopFailure` | APIエラーでターン終了時 | エラータイプ: `rate_limit`, `server_error` |
| `TeammateIdle` | チームメイトがアイドル状態になる時 | matcher非対応 |
| `TaskCompleted` | タスク完了マーク時 | matcher非対応 |
| `InstructionsLoaded` | CLAUDE.md/rules読み込み時 | 読み込み理由 |
| `ConfigChange` | 設定ファイル変更時 | 設定ソース: `user_settings`, `project_settings`, `skills` |
| `WorktreeCreate` | worktree作成時 | matcher非対応 |
| `WorktreeRemove` | worktree削除時 | matcher非対応 |
| `PreCompact` | コンテキスト圧縮前 | トリガー: `manual`, `auto` |
| `PostCompact` | コンテキスト圧縮後 | トリガー: `manual`, `auto` |
| `Elicitation` | MCPサーバーがユーザー入力要求時 | MCPサーバー名 |
| `ElicitationResult` | MCPエリシテーション応答後 | MCPサーバー名 |
| `SessionEnd` | セッション終了時 | 終了理由: `clear`, `resume`, `logout` |

### フックタイプ

| タイプ | 説明 | 用途 |
|-------|------|------|
| `command` | シェルコマンドを実行 | ファイル操作、外部ツール呼び出し、ログ記録 |
| `prompt` | LLMに判断を委譲（単発） | 条件判断が必要だがツール実行不要な場合 |
| `agent` | サブエージェントで検証（複数ターン） | ファイル読み取りやテスト実行が必要な検証 |
| `http` | HTTPエンドポイントにPOST | 外部サービス連携、監査ログ |

### 設定フォーマット

```json
{
  "hooks": {
    "<イベントタイプ>": [
      {
        "matcher": "<正規表現パターン（省略可）>",
        "hooks": [
          {
            "type": "command",
            "command": "<実行するコマンド>",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

### 終了コードとフック出力

| 終了コード | 動作 |
|-----------|------|
| `0` | アクション続行。stdout の内容がコンテキストに追加される（一部イベント） |
| `2` | アクションをブロック。stderr の内容が Claude へのフィードバックになる |
| その他 | アクション続行。stderr はログに記録（verbose モードで確認可能） |

### 構造化JSON出力

終了コード `0` で JSON を stdout に出力すると、より詳細な制御が可能:

**PreToolUse の例（ツール実行を拒否）:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "grep の代わりに rg を使用してください"
  }
}
```

**PermissionRequest の例（自動承認）:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow"
    }
  }
}
```

### 環境変数

フックのコマンド内で使用可能な環境変数:
- `$CLAUDE_PROJECT_DIR`: プロジェクトのルートディレクトリ
- stdin にはイベント固有の JSON データが渡される（`jq` でパース）

### 配置先スコープ

| 配置先 | スコープ | 共有 |
|-------|--------|------|
| `~/.claude/settings.json` | 全プロジェクト | 不可（ローカル） |
| `.claude/settings.json` | 単一プロジェクト | 可（リポジトリにコミット） |
| `.claude/settings.local.json` | 単一プロジェクト | 不可（gitignore） |

### よくあるパターン

#### 通知（Notification）
```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code' 'Claude Code needs your attention'"
          }
        ]
      }
    ]
  }
}
```

#### コード自動フォーマット（PostToolUse）
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write"
          }
        ]
      }
    ]
  }
}
```

#### 保護ファイルへの編集ブロック（PreToolUse）
```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
PROTECTED_PATTERNS=(".env" "package-lock.json" ".git/")
for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH matches protected pattern '$pattern'" >&2
    exit 2
  fi
done
exit 0
```

#### コンテキスト圧縮後のリマインダー（SessionStart）
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'リマインダー: npm ではなく bun を使用。コミット前に bun test を実行。'"
          }
        ]
      }
    ]
  }
}
```

#### Stop hookの無限ループ防止
```bash
#!/bin/bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0  # Claude の停止を許可
fi
# ... フックのロジック
```

### 注意事項

- フックスクリプトは実行権限が必要（`chmod +x`）
- `jq` がJSON パースに必要（`apt-get install jq` または `brew install jq`）
- `PostToolUse` フックはツール実行後のため、アクションの取り消しは不可
- `PermissionRequest` フックは非インタラクティブモード（`-p`）では発火しない
- `Stop` フックはユーザー中断時には発火しない
- シェルプロファイル（`~/.zshrc`）の `echo` 文がJSON出力を壊す場合がある → `[[ $- == *i* ]]` で対策
- デフォルトタイムアウトは10分（`timeout` フィールドで変更可能）
- matcher は大文字小文字を区別する
- 設定ファイルの `/hooks` メニューで確認可能
