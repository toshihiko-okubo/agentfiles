# agentfiles

chezmoiを使用してAIエージェント（Claude Code, Codex等）のスキル・設定ファイルを管理するリポジトリ。

## Requirements

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin
```

## Setup

```sh
chezmoi init --source /path/to/agentfiles
chezmoi apply
```

## Usage

### スキルの追加（ディレクトリ単位）

`.chezmoidata/manifest.toml` に `[[skills]]` エントリを追加。`~/.codex/skills/` or `~/.claude/skills/` に配置される。

```toml
[repos.openai-skills]
owner = "openai"
name = "skills"

[[skills]]
name = "vercel-deploy"
repo = "openai-skills"
ref = "main"
path = "skills/.curated/vercel-deploy"
targets = ["codex", "claude"]
refreshPeriod = "168h"
```

### エージェントの追加

`[[agents]]` エントリを追加。`path` の形式で取得方式が自動判定される:

- `.md` で終わる → 単一ファイル取得（`~/.claude/agents/{dir}/{name}.md`）
- `.md` で終わらない → ディレクトリまるごと取得（`~/.claude/agents/{name}/`）

```toml
[repos.agency-agents]
owner = "msitarzewski"
name = "agency-agents"

# ディレクトリまるごと（engineeringカテゴリの全エージェント）
[[agents]]
name = "engineering"
repo = "agency-agents"
ref = "main"
path = "engineering"
targets = ["claude"]
refreshPeriod = "168h"

# 単一ファイル
[[agents]]
name = "engineering-backend-architect"
repo = "agency-agents"
ref = "main"
path = "engineering/engineering-backend-architect.md"
targets = ["claude"]
refreshPeriod = "168h"
```

### ローカルスキル・エージェント・hookの追加

リポジトリ内の `dot_claude/` / `dot_codex/` に直接ファイルを配置:

```
dot_claude/
  skills/{name}/SKILL.md     → ~/.claude/skills/{name}/SKILL.md
  agents/{name}.md            → ~/.claude/agents/{name}.md
  hooks/{script}              → ~/.claude/hooks/{script}
dot_codex/
  skills/{name}/SKILL.md     → ~/.codex/skills/{name}/SKILL.md
```

既存ファイルの取り込み:

```sh
chezmoi add ~/.claude/hooks/my-hook.sh
chezmoi add ~/.claude/skills/my-skill
```

### 適用・更新・削除

```sh
# 適用
chezmoi apply

# 外部リソースのバージョン更新（ref変更後）
chezmoi apply --refresh-externals

# 削除（エントリ or ファイルを削除後）
chezmoi apply
```

## マニフェスト フィールド

### `[[skills]]` — ディレクトリ単位

| フィールド | 説明 | 例 |
|-----------|------|-----|
| `name` | スキル名（インストール先ディレクトリ名） | `"vercel-deploy"` |
| `repo` | `[repos.*]` のキー名 | `"openai-skills"` |
| `ref` | git tag / branch / commit SHA | `"v1.0.0"`, `"main"` |
| `path` | リポジトリ内のスキルディレクトリパス | `"skills/.curated/vercel-deploy"` |
| `targets` | インストール先 | `["codex"]`, `["claude"]`, `["codex","claude"]` |
| `refreshPeriod` | 再取得間隔（任意） | `"168h"` |

### `[[agents]]` — 単一ファイル

| フィールド | 説明 | 例 |
|-----------|------|-----|
| `name` | ファイル名（拡張子なし） | `"engineering-backend-architect"` |
| `repo` | `[repos.*]` のキー名 | `"agency-agents"` |
| `ref` | git tag / branch / commit SHA | `"main"` |
| `path` | リポジトリ内の.mdファイルパス | `"engineering/engineering-backend-architect.md"` |
| `targets` | インストール先 | `["claude"]` |
| `refreshPeriod` | 再取得間隔（任意） | `"168h"` |
