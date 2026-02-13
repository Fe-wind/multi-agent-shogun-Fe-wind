#!/bin/bash
# 🪚 multi-agent-daiku 作業開始スクリプト（毎日の起動用）
# Daily Startup Script for Multi-Agent Orchestration System
#
# 使用方法:
#   ./koubou_hajime.sh           # 全エージェント起動（通常）
#   ./koubou_hajime.sh -s        # セットアップのみ（エージェントCLI起動なし）
#   ./koubou_hajime.sh -h        # ヘルプ表示

set -e

# ディレクトリ変数の初期化
# TORYO_HOME: ツール本体の場所（スクリプト自身のディレクトリ）
# PROJECT_DIR: 作業対象プロジェクト（デフォルトは起動した場所）
TORYO_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(pwd)"
DASHBOARDS_DIR=""
PROJECT_ID=""
PROJECT_DASHBOARD_DIR=""
DASHBOARD_PATH=""
DASHBOARD_LINK_PATH="$TORYO_HOME/dashboard.md"

# エージェントCLI構成（デフォルト: 棟梁=Claude, 番頭/大工衆=Codex）
AGENT_PROVIDER_TORYO="claude"
AGENT_PROVIDER_BANTO="codex"
AGENT_PROVIDER_DAIKUSHU="codex"
AGENT_WAIT_SECONDS=15

# 言語設定を読み取り（デフォルト: ja）
LANG_SETTING="ja"
if [ -f "$TORYO_HOME/config/settings.yaml" ]; then
    LANG_SETTING=$(grep "^language:" "$TORYO_HOME/config/settings.yaml" 2>/dev/null | awk '{print $2}' || echo "ja")
fi

resolve_project_id() {
    local config_file="$TORYO_HOME/config/projects.yaml"
    local resolved_id=""

    if [ -f "$config_file" ]; then
        resolved_id=$(awk -v target="$PROJECT_DIR" '
            function clean(v) {
                gsub(/^[ \t"\047]+|[ \t"\047]+$/, "", v)
                return v
            }

            /^[[:space:]]*-[[:space:]]id:[[:space:]]*/ {
                line = $0
                sub(/^[[:space:]]*-[[:space:]]id:[[:space:]]*/, "", line)
                current_id = clean(line)
                next
            }

            /^[[:space:]]*id:[[:space:]]*/ {
                line = $0
                sub(/^[[:space:]]*id:[[:space:]]*/, "", line)
                current_id = clean(line)
                next
            }

            /^[[:space:]]*path:[[:space:]]*/ {
                line = $0
                sub(/^[[:space:]]*path:[[:space:]]*/, "", line)
                path_value = clean(line)
                if (path_value == target && current_id != "") {
                    print current_id
                    exit
                }
            }
        ' "$config_file")
    fi

    if [ -z "$resolved_id" ]; then
        resolved_id="$(basename "$PROJECT_DIR")"
    fi

    PROJECT_ID=$(echo "$resolved_id" | sed -E 's/[^A-Za-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g')
    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID="project"
    fi
}

ensure_project_registered() {
    local config_file="$TORYO_HOME/config/projects.yaml"
    local project_name
    local escaped_name
    local escaped_path
    local base_id
    local candidate_id
    local suffix=2

    project_name="$(basename "$PROJECT_DIR")"
    escaped_name=$(printf "%s" "$project_name" | sed 's/"/\\"/g')
    escaped_path=$(printf "%s" "$PROJECT_DIR" | sed 's/"/\\"/g')

    if [ ! -f "$config_file" ]; then
        cat > "$config_file" << 'EOF'
projects:
EOF
    fi

    if ! grep -q '^projects:' "$config_file"; then
        local tmp_file
        tmp_file=$(mktemp)
        {
            echo "projects:"
            cat "$config_file"
        } > "$tmp_file"
        mv "$tmp_file" "$config_file"
    fi

    if awk -v target="$PROJECT_DIR" '
        function clean(v) {
            gsub(/^[ \t"\047]+|[ \t"\047]+$/, "", v)
            return v
        }

        /^[[:space:]]*path:[[:space:]]*/ {
            line = $0
            sub(/^[[:space:]]*path:[[:space:]]*/, "", line)
            path_value = clean(line)
            if (path_value == target) {
                found = 1
                exit
            }
        }

        END { if (found == 1) exit 0; exit 1 }
    ' "$config_file"; then
        return
    fi

    base_id="$PROJECT_ID"
    candidate_id="$base_id"

    while awk -v target="$candidate_id" '
        function clean(v) {
            gsub(/^[ \t"\047]+|[ \t"\047]+$/, "", v)
            return v
        }

        /^[[:space:]]*-[[:space:]]id:[[:space:]]*/ {
            line = $0
            sub(/^[[:space:]]*-[[:space:]]id:[[:space:]]*/, "", line)
            if (clean(line) == target) {
                found = 1
                exit
            }
        }

        /^[[:space:]]*id:[[:space:]]*/ {
            line = $0
            sub(/^[[:space:]]*id:[[:space:]]*/, "", line)
            if (clean(line) == target) {
                found = 1
                exit
            }
        }

        END { if (found == 1) exit 0; exit 1 }
    ' "$config_file"; do
        candidate_id="${base_id}-${suffix}"
        suffix=$((suffix + 1))
    done

    PROJECT_ID="$candidate_id"

    cat >> "$config_file" << EOF

  - id: $PROJECT_ID
    name: "$escaped_name"
    path: "$escaped_path"
    priority: medium
    status: active
EOF

    log_info "📌 projects.yaml に自動登録: id=$PROJECT_ID"
}

# 色付きログ関数（江戸職人口調）
log_info() {
    echo -e "\033[1;33m【報】\033[0m $1"
}

log_success() {
    echo -e "\033[1;32m【成】\033[0m $1"
}

log_work() {
    echo -e "\033[1;31m【工】\033[0m $1"
}

escape_single_quotes() {
    printf "%s" "$1" | sed "s/'/'\\\\''/g"
}

prompt_provider_for_role() {
    local role_name="$1"
    local default_provider="$2"
    local choice=""

    while true; do
        echo ""
        echo "    $role_name のCLIを選択せよ (default: $default_provider)"
        echo "      1) claude"
        echo "      2) codex"
        read -r -p "      > " choice

        case "$choice" in
            "")
                REPLY_PROVIDER="$default_provider"
                return
                ;;
            1|claude|CLAUDE|Claude)
                REPLY_PROVIDER="claude"
                return
                ;;
            2|codex|CODEX|Codex)
                REPLY_PROVIDER="codex"
                return
                ;;
            *)
                echo "      入力エラー: 1 または 2 を入力せよ"
                ;;
        esac
    done
}

select_agent_runtime_profile() {
    local profile=""

    if [ "$SETUP_ONLY" = true ]; then
        return
    fi

    if [ ! -t 0 ]; then
        log_info "🧭 非対話環境のため既定構成を使用: 棟梁=claude / 番頭=codex / 大工衆=codex"
        return
    fi

    echo "  ┌──────────────────────────────────────────────────────────┐"
    echo "  │  🧠 エージェントCLI構成を選択                            │"
    echo "  └──────────────────────────────────────────────────────────┘"
    echo "    1) 推奨: 棟梁=claude / 番頭=codex / 大工衆=codex"
    echo "    2) 全員 claude"
    echo "    3) 全員 codex"
    echo "    4) カスタム（棟梁/番頭/大工衆を個別選択）"

    while true; do
        read -r -p "    選択 [1-4] (default: 1): " profile
        case "$profile" in
            ""|1)
                AGENT_PROVIDER_TORYO="claude"
                AGENT_PROVIDER_BANTO="codex"
                AGENT_PROVIDER_DAIKUSHU="codex"
                break
                ;;
            2)
                AGENT_PROVIDER_TORYO="claude"
                AGENT_PROVIDER_BANTO="claude"
                AGENT_PROVIDER_DAIKUSHU="claude"
                break
                ;;
            3)
                AGENT_PROVIDER_TORYO="codex"
                AGENT_PROVIDER_BANTO="codex"
                AGENT_PROVIDER_DAIKUSHU="codex"
                break
                ;;
            4)
                prompt_provider_for_role "棟梁 (Toryo)" "$AGENT_PROVIDER_TORYO"
                AGENT_PROVIDER_TORYO="$REPLY_PROVIDER"
                prompt_provider_for_role "番頭 (Banto)" "$AGENT_PROVIDER_BANTO"
                AGENT_PROVIDER_BANTO="$REPLY_PROVIDER"
                prompt_provider_for_role "大工衆 (Daikushu)" "$AGENT_PROVIDER_DAIKUSHU"
                AGENT_PROVIDER_DAIKUSHU="$REPLY_PROVIDER"
                break
                ;;
            *)
                echo "    入力エラー: 1-4 を入力せよ"
                ;;
        esac
    done

    log_success "🛠️ CLI構成: 棟梁=$AGENT_PROVIDER_TORYO / 番頭=$AGENT_PROVIDER_BANTO / 大工衆=$AGENT_PROVIDER_DAIKUSHU"
    echo ""
}

ensure_selected_cli_available() {
    local provider
    declare -A checked

    for provider in "$AGENT_PROVIDER_TORYO" "$AGENT_PROVIDER_BANTO" "$AGENT_PROVIDER_DAIKUSHU"; do
        if [ -z "${checked[$provider]+x}" ]; then
            if ! command -v "$provider" >/dev/null 2>&1; then
                echo "エラー: '$provider' が見つかりません。PATHを確認してください。"
                exit 1
            fi
            checked[$provider]=1
        fi
    done
}

build_agent_launch_command() {
    local role="$1"
    local provider="$2"
    local prompt_text="$3"
    local escaped_prompt=""
    local role_prefix=""

    if [ "$provider" = "claude" ]; then
        escaped_prompt=$(escape_single_quotes "$prompt_text")
        if [ "$role" = "toryo" ]; then
            echo "MAX_THINKING_TOKENS=0 claude --model opus --dangerously-skip-permissions --append-system-prompt '$escaped_prompt'"
        else
            echo "claude --dangerously-skip-permissions --append-system-prompt '$escaped_prompt'"
        fi
        return
    fi

    if [ "$provider" = "codex" ]; then
        case "$role" in
            toryo) role_prefix="棟梁として行動せよ。" ;;
            banto) role_prefix="番頭として行動せよ。" ;;
            daikushu) role_prefix="大工衆として行動せよ。" ;;
            *) role_prefix="与えられた役割に従って行動せよ。" ;;
        esac
        escaped_prompt=$(escape_single_quotes "$role_prefix $prompt_text")
        echo "codex --dangerously-bypass-approvals-and-sandbox '$escaped_prompt'"
        return
    fi

    echo "エラー: 未対応の provider '$provider'" >&2
    exit 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# オプション解析
# ═══════════════════════════════════════════════════════════════════════════════
SETUP_ONLY=false
OPEN_TERMINAL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--setup-only)
            SETUP_ONLY=true
            shift
            ;;
        -t|--terminal)
            OPEN_TERMINAL=true
            shift
            ;;
        -p|--project)
            PROJECT_DIR="$(cd "$2" 2>/dev/null && pwd)" || { echo "エラー: ディレクトリ '$2' が見つかりません"; exit 1; }
            shift 2
            ;;
        -h|--help)
            echo ""
            echo "🪚 multi-agent-daiku 作業開始スクリプト（ランチャー）"
            echo ""
            echo "使用方法: koubou_hajime.sh [オプション]"
            echo ""
            echo "オプション:"
            echo "  -s, --setup-only   tmuxセッションのセットアップのみ（エージェントCLI起動なし）"
            echo "  -t, --terminal     Windows Terminal で新しいタブを開く"
            echo "  -p, --project DIR  作業対象プロジェクトディレクトリを指定（デフォルト: カレントディレクトリ）"
            echo "  -h, --help         このヘルプを表示"
            echo ""
            echo "例:"
            echo "  cd /home/user/my-app && ~/tools/multi-agent-daiku-Fe-wind/koubou_hajime.sh"
            echo "  ~/tools/multi-agent-daiku-Fe-wind/koubou_hajime.sh -p /home/user/my-app"
            echo "  ./koubou_hajime.sh -s   # セットアップのみ（手動でエージェントCLI起動）"
            echo "  ./koubou_hajime.sh -t   # 全エージェント起動 + ターミナルタブ展開"
            echo ""
            echo "ディレクトリ:"
            echo "  TORYO_HOME  ツール本体の場所（スクリプトのディレクトリ）"
            echo "  PROJECT_DIR  作業対象プロジェクト（-p で指定、またはカレントディレクトリ）"
            echo ""
            echo "エイリアス:"
            echo "  css   → tmux attach-session -t toryo"
            echo "  csm   → tmux attach-session -t multiagent"
            echo ""
            exit 0
            ;;
        *)
            echo "不明なオプション: $1"
            echo "./koubou_hajime.sh -h でヘルプを表示"
            exit 1
            ;;
    esac
done

resolve_project_id
ensure_project_registered
DASHBOARDS_DIR="$TORYO_HOME/dashboards"
PROJECT_DASHBOARD_DIR="$DASHBOARDS_DIR/$PROJECT_ID"
DASHBOARD_PATH="$PROJECT_DASHBOARD_DIR/dashboard.md"

# ═══════════════════════════════════════════════════════════════════════════════
# 作業開始バナー表示（CC0ライセンスASCIIアート使用）
# ───────────────────────────────────────────────────────────────────────────────
# 【著作権・ライセンス表示】
# 工房バナーは本リポジトリ内の独自ASCIIアートを使用
# "all files and scripts in this repo are released CC0 / kopimi!"
# ═══════════════════════════════════════════════════════════════════════════════
show_workshop_banner() {
    clear

    # タイトルバナー（色付き）
    echo ""
    echo -e "\033[1;31m╔══════════════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;31m║\033[0m \033[1;33m███████╗██╗  ██╗██╗   ██╗████████╗███████╗██╗   ██╗     ██╗██╗███╗   ██╗\033[0m \033[1;31m║\033[0m"
    echo -e "\033[1;31m║\033[0m \033[1;33m██╔════╝██║  ██║██║   ██║╚══██╔══╝██╔════╝██║   ██║     ██║██║████╗  ██║\033[0m \033[1;31m║\033[0m"
    echo -e "\033[1;31m║\033[0m \033[1;33m███████╗███████║██║   ██║   ██║   ███████╗██║   ██║     ██║██║██╔██╗ ██║\033[0m \033[1;31m║\033[0m"
    echo -e "\033[1;31m║\033[0m \033[1;33m╚════██║██╔══██║██║   ██║   ██║   ╚════██║██║   ██║██   ██║██║██║╚██╗██║\033[0m \033[1;31m║\033[0m"
    echo -e "\033[1;31m║\033[0m \033[1;33m███████║██║  ██║╚██████╔╝   ██║   ███████║╚██████╔╝╚█████╔╝██║██║ ╚████║\033[0m \033[1;31m║\033[0m"
    echo -e "\033[1;31m║\033[0m \033[1;33m╚══════╝╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚══════╝ ╚═════╝  ╚════╝ ╚═╝╚═╝  ╚═══╝\033[0m \033[1;31m║\033[0m"
    echo -e "\033[1;31m╠══════════════════════════════════════════════════════════════════════════════════╣\033[0m"
    echo -e "\033[1;31m║\033[0m       \033[1;37m作業開始じゃーーー！！！\033[0m    \033[1;36m🪚\033[0m    \033[1;35m工房始動！\033[0m                          \033[1;31m║\033[0m"
    echo -e "\033[1;31m╚══════════════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo ""

    # ═══════════════════════════════════════════════════════════════════════════
    # 大工衆隊列（オリジナル）
    # ═══════════════════════════════════════════════════════════════════════════
    echo -e "\033[1;34m  ╔═════════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;34m  ║\033[0m                    \033[1;37m【 職 人 隊 列 ・ 八 名 配 備 】\033[0m                      \033[1;34m║\033[0m"
    echo -e "\033[1;34m  ╚═════════════════════════════════════════════════════════════════════════════╝\033[0m"

    cat << 'DAIKUSHU_EOF'

       /\      /\      /\      /\      /\      /\      /\      /\
      /||\    /||\    /||\    /||\    /||\    /||\    /||\    /||\
     /_||\   /_||\   /_||\   /_||\   /_||\   /_||\   /_||\   /_||\
       ||      ||      ||      ||      ||      ||      ||      ||
      /||\    /||\    /||\    /||\    /||\    /||\    /||\    /||\
      /  \    /  \    /  \    /  \    /  \    /  \    /  \    /  \
     [工1]   [工2]   [工3]   [工4]   [工5]   [工6]   [工7]   [工8]

DAIKUSHU_EOF

    echo -e "                    \033[1;36m「「「 はっ！！ 作業に取り掛かる！！ 」」」\033[0m"
    echo ""

    # ═══════════════════════════════════════════════════════════════════════════
    # システム情報
    # ═══════════════════════════════════════════════════════════════════════════
    echo -e "\033[1;33m  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\033[0m"
    echo -e "\033[1;33m  ┃\033[0m  \033[1;37m🪚 multi-agent-daiku\033[0m  〜 \033[1;36m大工マルチエージェント統率システム\033[0m 〜           \033[1;33m┃\033[0m"
    echo -e "\033[1;33m  ┃\033[0m                                                                           \033[1;33m┃\033[0m"
    echo -e "\033[1;33m  ┃\033[0m    \033[1;35m棟梁\033[0m: プロジェクト統括    \033[1;31m番頭\033[0m: タスク管理    \033[1;34m大工衆\033[0m: 実働部隊×8      \033[1;33m┃\033[0m"
    echo -e "\033[1;33m  ┃\033[0m                                                                           \033[1;33m┃\033[0m"
    echo -e "\033[1;33m  ┃\033[0m     📁 TORYO_HOME: \033[1;36m$TORYO_HOME\033[0m"
    echo -e "\033[1;33m  ┃\033[0m     📁 PROJECT_DIR: \033[1;36m$PROJECT_DIR\033[0m"
    echo -e "\033[1;33m  ┃\033[0m     🏷️ PROJECT_ID: \033[1;36m$PROJECT_ID\033[0m"
    echo -e "\033[1;33m  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\033[0m"
    echo ""
}

# バナー表示実行
show_workshop_banner

echo -e "  \033[1;33m工房始動！段取りを開始いたす\033[0m (Setting up the worksite)"
echo ""

select_agent_runtime_profile
if [ "$SETUP_ONLY" = false ]; then
    ensure_selected_cli_available
fi

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 1: 既存セッションクリーンアップ
# ═══════════════════════════════════════════════════════════════════════════════
log_info "🧹 既存セッションを終了中..."
tmux kill-session -t multiagent 2>/dev/null && log_info "  └─ multiagentセッション、終了完了" || log_info "  └─ multiagentセッションは存在せず"
tmux kill-session -t toryo 2>/dev/null && log_info "  └─ toryoセッション、終了完了" || log_info "  └─ toryoセッションは存在せず"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 2: 報告ファイルリセット
# ═══════════════════════════════════════════════════════════════════════════════
log_info "📜 前回の作業記録を破棄中..."
for i in {1..8}; do
    cat > "$TORYO_HOME/queue/reports/daikushu${i}_report.yaml" << EOF
worker_id: daikushu${i}
task_id: null
timestamp: ""
status: idle
result: null
EOF
done

# キューファイルリセット
cat > "$TORYO_HOME/queue/toryo_to_banto.yaml" << 'EOF'
queue: []
EOF

cat > "$TORYO_HOME/queue/banto_to_toryo.yaml" << 'EOF'
notifications: []
EOF

cat > "$TORYO_HOME/queue/banto_to_daikushu.yaml" << 'EOF'
assignments:
  daikushu1:
    task_id: null
    description: null
    target_path: null
    status: idle
  daikushu2:
    task_id: null
    description: null
    target_path: null
    status: idle
  daikushu3:
    task_id: null
    description: null
    target_path: null
    status: idle
  daikushu4:
    task_id: null
    description: null
    target_path: null
    status: idle
  daikushu5:
    task_id: null
    description: null
    target_path: null
    status: idle
  daikushu6:
    task_id: null
    description: null
    target_path: null
    status: idle
  daikushu7:
    task_id: null
    description: null
    target_path: null
    status: idle
  daikushu8:
    task_id: null
    description: null
    target_path: null
    status: idle
EOF

log_success "✅ 初期化完了"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 3: ダッシュボード初期化
# ═══════════════════════════════════════════════════════════════════════════════
log_info "📊 工事進捗板を初期化中..."
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
mkdir -p "$PROJECT_DASHBOARD_DIR"

if [ "$LANG_SETTING" = "ja" ]; then
    # 日本語のみ
    cat > "$DASHBOARD_PATH" << EOF
# 📊 工事進捗報告
対象プロジェクト: ${PROJECT_ID}
プロジェクトパス: ${PROJECT_DIR}
最終更新: ${TIMESTAMP}

## 🚨 要対応 - 施主のご判断をお待ちしております
なし

## 🔄 進行中 - 只今、施工中でござる
なし

## ✅ 本日の施工実績
| 時刻 | 担当箇所 | 作業 | 結果 |
|------|------|------|------|

## 🎯 スキル化候補 - 承認待ち
なし

## 🛠️ 生成されたスキル
なし

## ⏸️ 待機中
なし

## ❓ 伺い事項
なし
EOF
else
    # 日本語 + 翻訳併記
    cat > "$DASHBOARD_PATH" << EOF
# 📊 工事進捗報告 (Construction Progress Report)
対象プロジェクト (Project): ${PROJECT_ID}
プロジェクトパス (Path): ${PROJECT_DIR}
最終更新 (Last Updated): ${TIMESTAMP}

## 🚨 要対応 - 施主のご判断をお待ちしております (Action Required - Awaiting Client Decision)
なし (None)

## 🔄 進行中 - 只今、施工中でござる (In Progress - Currently in Progress)
なし (None)

## ✅ 本日の施工実績 (Today's Achievements)
| 時刻 (Time) | 担当箇所 (Work Area) | 作業 (Task) | 結果 (Result) |
|------|------|------|------|

## 🎯 スキル化候補 - 承認待ち (Skill Candidates - Pending Approval)
なし (None)

## 🛠️ 生成されたスキル (Generated Skills)
なし (None)

## ⏸️ 待機中 (On Standby)
なし (None)

## ❓ 伺い事項 (Questions for Client)
なし (None)
EOF
fi

if ln -sfn "$DASHBOARD_PATH" "$DASHBOARD_LINK_PATH" 2>/dev/null; then
    log_info "  └─ ダッシュボードリンク更新: $DASHBOARD_LINK_PATH -> $DASHBOARD_PATH"
else
    cp "$DASHBOARD_PATH" "$DASHBOARD_LINK_PATH"
    log_info "  └─ dashboard.md を複製作成: $DASHBOARD_LINK_PATH (symlink未対応)"
fi

log_success "  └─ ダッシュボード初期化完了 (言語: $LANG_SETTING, project: $PROJECT_ID)"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 4: multiagentセッション作成（9ペイン：banto + daikushu1-8）
# ═══════════════════════════════════════════════════════════════════════════════
log_work "🪚 番頭・大工衆セッションを構築中（9名配備）..."

# 最初のペイン作成
tmux new-session -d -s multiagent -n "agents"

# 3x3グリッド作成（合計9ペイン）
# ※ detach中でも確実に multiagent セッションを操作できるように、すべて -t を指定する
# まず3列
tmux split-window -h -t "multiagent:0.0"
tmux split-window -h -t "multiagent:0.0"

# 各列を3行（左=0, 中=1, 右=2）
tmux split-window -v -t "multiagent:0.0"
tmux split-window -v -t "multiagent:0.3"

tmux split-window -v -t "multiagent:0.1"
tmux split-window -v -t "multiagent:0.5"

tmux split-window -v -t "multiagent:0.2"
tmux split-window -v -t "multiagent:0.7"

tmux select-layout -t "multiagent:0" tiled

# ペインタイトル設定（0: banto, 1-8: daikushu1-8）
PANE_TITLES=("banto" "daikushu1" "daikushu2" "daikushu3" "daikushu4" "daikushu5" "daikushu6" "daikushu7" "daikushu8")
PANE_COLORS=("1;31" "1;34" "1;34" "1;34" "1;34" "1;34" "1;34" "1;34" "1;34")  # banto: 赤, daikushu: 青

for i in {0..8}; do
    tmux select-pane -t "multiagent:0.$i" -T "${PANE_TITLES[$i]}"
    tmux send-keys -t "multiagent:0.$i" "cd \"$PROJECT_DIR\" && export TORYO_HOME=\"$TORYO_HOME\" && export PROJECT_DIR=\"$PROJECT_DIR\" && export PROJECT_ID=\"$PROJECT_ID\" && export DASHBOARD_PATH=\"$DASHBOARD_PATH\" && export PS1='(\[\033[${PANE_COLORS[$i]}m\]${PANE_TITLES[$i]}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ ' && clear" Enter
done

log_success "  └─ 番頭・大工衆セッション、構築完了"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 5: toryoセッション作成（1ペイン）
# ═══════════════════════════════════════════════════════════════════════════════
log_work "👑 棟梁セッションを構築中..."
tmux new-session -d -s toryo
tmux send-keys -t toryo "cd \"$PROJECT_DIR\" && export TORYO_HOME=\"$TORYO_HOME\" && export PROJECT_DIR=\"$PROJECT_DIR\" && export PROJECT_ID=\"$PROJECT_ID\" && export DASHBOARD_PATH=\"$DASHBOARD_PATH\" && export PS1='(\[\033[1;35m\]棟梁\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ ' && clear" Enter
tmux select-pane -t toryo:0.0 -P 'bg=#002b36'  # 棟梁の Solarized Dark

log_success "  └─ 棟梁セッション、構築完了"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 6: エージェントCLI起動（--setup-only でスキップ）
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$SETUP_ONLY" = false ]; then
    log_work "👑 全員にエージェントCLIを起動中..."

    # エージェントに注入するパス情報プロンプト
    TORYO_PROMPT="TORYO_HOME=$TORYO_HOME に toryo システムファイル(queue/,config/,instructions/,status/)がある。PROJECT_DIR=$PROJECT_DIR が作業対象プロジェクト。PROJECT_ID=$PROJECT_ID。ダッシュボード実体は DASHBOARD_PATH=$DASHBOARD_PATH。dashboard.md は \$DASHBOARD_PATH へのリンクとして扱え。更新時は必ず \$DASHBOARD_PATH を使え。"
    TORYO_LAUNCH_CMD=$(build_agent_launch_command "toryo" "$AGENT_PROVIDER_TORYO" "$TORYO_PROMPT")
    BANTO_LAUNCH_CMD=$(build_agent_launch_command "banto" "$AGENT_PROVIDER_BANTO" "$TORYO_PROMPT")
    DAIKUSHU_LAUNCH_CMD=$(build_agent_launch_command "daikushu" "$AGENT_PROVIDER_DAIKUSHU" "$TORYO_PROMPT")

    # 棟梁
    tmux send-keys -t toryo "$TORYO_LAUNCH_CMD"
    tmux send-keys -t toryo Enter
    log_info "  └─ 棟梁、召喚完了 (CLI: $AGENT_PROVIDER_TORYO)"

    # 少し待機（安定のため）
    sleep 1

    # 番頭
    tmux send-keys -t "multiagent:0.0" "$BANTO_LAUNCH_CMD"
    tmux send-keys -t "multiagent:0.0" Enter
    log_info "  └─ 番頭、召喚完了 (CLI: $AGENT_PROVIDER_BANTO)"

    # 大工衆（1-8）
    for i in {1..8}; do
        tmux send-keys -t "multiagent:0.$i" "$DAIKUSHU_LAUNCH_CMD"
        tmux send-keys -t "multiagent:0.$i" Enter
    done
    log_info "  └─ 大工衆隊、召喚完了 (CLI: $AGENT_PROVIDER_DAIKUSHU)"

    log_success "✅ 全員エージェントCLI起動完了"
    echo ""

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 6.5: 各エージェントに指示書を読み込ませる
    # ═══════════════════════════════════════════════════════════════════════════
    log_work "📜 各エージェントに指示書を読み込ませ中..."
    echo ""

    # ═══════════════════════════════════════════════════════════════════════════
    # 工房アナウンス
    # ═══════════════════════════════════════════════════════════════════════════
    echo ""
    echo -e "                              \033[1;35m「 木組みの段取り、抜かりなく参る！ 」\033[0m"
    echo ""

    echo "  エージェントCLIの起動を待機中（${AGENT_WAIT_SECONDS}秒）..."
    sleep "$AGENT_WAIT_SECONDS"

    # 棟梁に指示書を読み込ませる
    log_info "  └─ 棟梁に指示書を伝達中..."
    tmux send-keys -t toryo "$TORYO_HOME/instructions/toryo.md を読んで役割を理解せよ。"
    sleep 0.5
    tmux send-keys -t toryo Enter

    # 番頭に指示書を読み込ませる
    sleep 2
    log_info "  └─ 番頭に指示書を伝達中..."
    tmux send-keys -t "multiagent:0.0" "$TORYO_HOME/instructions/banto.md を読んで役割を理解せよ。"
    sleep 0.5
    tmux send-keys -t "multiagent:0.0" Enter

    # 大工衆に指示書を読み込ませる（1-8）
    sleep 2
    log_info "  └─ 大工衆に指示書を伝達中..."
    for i in {1..8}; do
        tmux send-keys -t "multiagent:0.$i" "$TORYO_HOME/instructions/daikushu.md を読んで役割を理解せよ。汝は大工衆${i}号である。"
        sleep 0.3
        tmux send-keys -t "multiagent:0.$i" Enter
        sleep 0.5
    done

    log_success "✅ 全員に指示書伝達完了"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 7: 環境確認・完了メッセージ
# ═══════════════════════════════════════════════════════════════════════════════
log_info "🔍 セッション構成を確認中..."
echo ""
echo "  ┌──────────────────────────────────────────────────────────┐"
echo "  │  📺 Tmuxセッション一覧                                   │"
echo "  └──────────────────────────────────────────────────────────┘"
tmux list-sessions | sed 's/^/     /'
echo ""
echo "  ┌──────────────────────────────────────────────────────────┐"
echo "  │  📋 ペイン配置図 (Formation)                             │"
echo "  └──────────────────────────────────────────────────────────┘"
echo ""
echo "     【toryoセッション】棟梁の工房"
echo "     ┌─────────────────────────────┐"
echo "     │  Pane 0: 棟梁 (TORYO)      │  ← 工程統括・プロジェクト統括"
echo "     └─────────────────────────────┘"
echo ""
echo "     【multiagentセッション】番頭・大工衆（3x3 = 9ペイン）"
echo "     ┌─────────┬─────────┬─────────┐"
echo "     │  banto   │daikushu3│daikushu6│"
echo "     │  (番頭) │ (大工衆3) │ (大工衆6) │"
echo "     ├─────────┼─────────┼─────────┤"
echo "     │daikushu1│daikushu4│daikushu7│"
echo "     │ (大工衆1) │ (大工衆4) │ (大工衆7) │"
echo "     ├─────────┼─────────┼─────────┤"
echo "     │daikushu2│daikushu5│daikushu8│"
echo "     │ (大工衆2) │ (大工衆5) │ (大工衆8) │"
echo "     └─────────┴─────────┴─────────┘"
echo ""

echo ""
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║  🪚 作業開始準備完了！工房始動！                              ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo ""

if [ "$SETUP_ONLY" = true ]; then
    echo "  ⚠️  セットアップのみモード: エージェントCLIは未起動です"
    echo ""
    echo "  手動でエージェントCLIを起動するには:"
    echo "  ┌──────────────────────────────────────────────────────────┐"
    echo "  │  # 棟梁（Claudeの例 / 2ステップ）                         │"
    echo "  │  tmux send-keys -t toryo 'claude --dangerously-skip-permissions' │"
    echo "  │  tmux send-keys -t toryo Enter                          │"
    echo "  │                                                          │"
    echo "  │  # 番頭（Codexの例 / 2ステップ）                          │"
    echo "  │  tmux send-keys -t multiagent:0.0 'codex --dangerously-bypass-approvals-and-sandbox \"起動\"' │"
    echo "  │  tmux send-keys -t multiagent:0.0 Enter                  │"
    echo "  │                                                          │"
    echo "  │  # 大工衆は multiagent:0.1〜0.8 に同様に送る               │"
    echo "  └──────────────────────────────────────────────────────────┘"
    echo ""
fi

echo "  次のステップ:"
echo "  ┌──────────────────────────────────────────────────────────┐"
echo "  │  棟梁の工房にアタッチして命令を開始:                      │"
echo "  │     tmux attach-session -t toryo   (または: css)        │"
echo "  │                                                          │"
echo "  │  番頭・大工衆セッションを確認する:                          │"
echo "  │     tmux attach-session -t multiagent   (または: csm)    │"
echo "  │                                                          │"
echo "  │  tmux内から切替える場合:                                  │"
echo "  │     tmux switch-client -t toryo / multiagent           │"
echo "  │                                                          │"
echo "  │  ※ 各エージェントは指示書を読み込み済み。                 │"
echo "  │    すぐに命令を開始できます。                             │"
echo "  └──────────────────────────────────────────────────────────┘"
echo ""
echo "  ════════════════════════════════════════════════════════════"
echo "   木組みの段取り、よろしく頼む！ (Workshop is ready for work.)"
echo "  ════════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 8: Windows Terminal でタブを開く（-t オプション時のみ）
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$OPEN_TERMINAL" = true ]; then
    log_info "📺 Windows Terminal でタブを展開中..."

    # Windows Terminal が利用可能か確認
    if command -v wt.exe &> /dev/null; then
        wt.exe -w 0 new-tab wsl.exe -e bash -c "tmux attach-session -t toryo" \; new-tab wsl.exe -e bash -c "tmux attach-session -t multiagent"
        log_success "  └─ ターミナルタブ展開完了"
    else
        log_info "  └─ wt.exe が見つかりません。手動でアタッチしてください。"
    fi
    echo ""
fi
