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

### agency-agents の追加

`[[agency_agents]]` エントリを追加。upstream の `scripts/install.sh` / `scripts/convert.sh` を使ってインストールされる。

- Claude Code: upstream の Markdown agent を `~/.claude/agents/` に配置
- Codex: upstream の `convert.sh --tool codex` で TOML に変換し、`~/.codex/agents/` に配置
- その他repoのagentは `[[agents]]` で従来通り `.chezmoiexternal.toml.tmpl` から直接取得

```toml
[repos.agency-agents]
owner = "msitarzewski"
name = "agency-agents"

# 単一ファイル
[[agency_agents]]
name = "engineering-backend-architect"
ref = "main"
path = "engineering/engineering-backend-architect.md"
targets = ["codex", "claude"]
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
  agents/{name}.toml          → ~/.codex/agents/{name}.toml
  hooks/{script}              → ~/.codex/hooks/{script}
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

### `[[agency_agents]]` — agency-agents

| フィールド | 説明 | 例 |
|-----------|------|-----|
| `name` | 管理名 | `"engineering-backend-architect"` |
| `ref` | git tag / branch / commit SHA | `"main"` |
| `path` | agency-agents内の.mdファイルパス | `"engineering/engineering-backend-architect.md"` |
| `targets` | インストール先 | `["codex"]`, `["claude"]`, `["codex","claude"]` |
| `refreshPeriod` | 再取得間隔（任意） | `"168h"` |

`refreshPeriod` は直接取得には使われない。`chezmoi apply` 時に `run_install-agency-agents.sh.tmpl` が cached clone を更新し、選択された agent を upstream installer 経由で再インストールする。

### `[[agents]]` — その他repoのagent

| フィールド | 説明 | 例 |
|-----------|------|-----|
| `name` | ファイル名（拡張子なし） | `"custom-agent"` |
| `repo` | `[repos.*]` のキー名 | `"my-agents"` |
| `ref` | git tag / branch / commit SHA | `"main"` |
| `path` | リポジトリ内の.mdファイルパスまたはディレクトリ | `"agents/custom-agent.md"` |
| `targets` | インストール先 | `["codex"]`, `["claude"]`, `["codex","claude"]` |
| `refreshPeriod` | 再取得間隔（任意） | `"168h"` |
