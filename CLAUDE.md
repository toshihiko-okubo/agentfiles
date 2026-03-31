# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

chezmoiを使用してAIエージェント（Claude Code, Codex等）の構成ファイルを管理するリポジトリ。管理対象はskill、agent、MCP server設定、hooksなどのエージェント設定ファイル。

## アーキテクチャ

```
.chezmoidata/manifest.toml          # 外部リソースマニフェスト（編集対象）
.chezmoiexternal.toml.tmpl          # マニフェスト→external定義を自動生成
dot_claude/                          # ローカル管理ファイル → ~/.claude/
  skills/                            #   ローカルスキル
  agents/                            #   ローカルエージェント
  hooks/                             #   hookスクリプト
dot_codex/                           # ローカル管理ファイル → ~/.codex/
  skills/                            #   ローカルスキル
```

外部リソース（GitHub）:
- `[[skills]]`: archive取得 → `~/.codex/skills/` or `~/.claude/skills/`
- `[[agents]]`: file取得 → `~/.claude/agents/`
  - path が `.md` で終わる → 単一ファイル取得
  - path が `.md` で終わらない → ディレクトリまるごとarchive取得
- `[[plugins]]`: `chezmoi apply` 時に `claude plugin install` で自動インストール
  - `marketplace` 省略時は `claude-plugins-official`
  - 他のレジストリは `marketplace ="my-org/my-plugins"` で指定

ローカルリソース（このリポジトリ内）:
- `dot_claude/skills/{name}/` → `~/.claude/skills/{name}/`
- `dot_claude/agents/{name}.md` → `~/.claude/agents/{name}.md`
- `dot_claude/hooks/{script}` → `~/.claude/hooks/{script}`
- `dot_codex/skills/{name}/` → `~/.codex/skills/{name}/`

## 管理操作

```bash
# 初期化（初回のみ）
chezmoi init --source /path/to/agentfiles

# 外部リソース追加: manifest.toml にエントリ追加 → apply
# ローカルリソース追加: dot_claude/ or dot_codex/ にファイル配置 → apply
chezmoi apply

# 外部リソースのバージョン更新: manifest.toml の ref を変更
chezmoi apply --refresh-externals

# 既存ファイルをリポジトリに取り込む
chezmoi add ~/.claude/hooks/my-hook.sh

# dry-run で差分確認
chezmoi apply --dry-run -v
```

## chezmoi基本操作

```bash
chezmoi add <file>              # 実ファイル→リポジトリに追加
chezmoi diff                    # 差分確認
chezmoi apply                   # リポジトリ→実ファイルに適用
chezmoi execute-template < file.tmpl  # テンプレートのテスト
```

## ターゲットパス

- **Codex skills**: `~/.codex/skills/{name}/`
- **Claude skills**: `~/.claude/skills/{name}/`
- **Claude agents**: `~/.claude/agents/{name}.md`
- **Claude hooks**: `~/.claude/hooks/{script}` （settings.json から参照）

## chezmoi ディレクトリ規約

- `dot_` → `.`（ドットファイル）
- `private_` → パーミッション600
- `executable_` → 実行権限付与
- `.tmpl` → テンプレートとして処理
- `exact_` → ディレクトリ内の未管理ファイルを削除

## 注意事項

- APIキーやトークンなどの秘密情報はchezmoiテンプレート + シークレット管理で外部化すること
- プライベートリポジトリのスキル取得には `.chezmoiexternal.toml` の headers でトークン設定が必要
