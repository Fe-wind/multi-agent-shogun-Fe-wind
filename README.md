# multi-agent-daiku

<div align="center">

**Multi-Agent Orchestration System for Claude Code**

*One command. Eight AI agents working in parallel.*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blueviolet)](https://claude.ai)
[![tmux](https://img.shields.io/badge/tmux-required-green)](https://github.com/tmux/tmux)

[English](README.md) | [Japanese / 日本語](README_ja.md)

</div>

---

## What is this?

**multi-agent-daiku** is a system that runs multiple Claude Code instances simultaneously, organized like a master-carpenter workshop hierarchy.

**Why use this?**
- Give one command, get 8 AI workers executing in parallel
- No waiting - you can keep giving commands while tasks run in background
- AI remembers your preferences across sessions (Memory MCP)
- Real-time progress tracking via dashboard

```
        You (Client)
             │
             ▼ Give orders
      ┌─────────────┐
      │   TORYO    │  ← Receives your command, delegates immediately
      └──────┬──────┘
             │ YAML files + tmux
      ┌──────▼──────┐
      │    BANTO     │  ← Distributes tasks to workers
      └──────┬──────┘
             │
    ┌─┬─┬─┬─┴─┬─┬─┬─┐
    │1│2│3│4│5│6│7│8│  ← 8 workers execute in parallel
    └─┴─┴─┴─┴─┴─┴─┴─┘
        DAIKUSHU
```

---

## 🚀 Quick Start

### 🪟 Windows Users (Most Common)

<table>
<tr>
<td width="60">

**Step 1**

</td>
<td>

📥 **Download this repository**

[Download ZIP](https://github.com/yohey-w/multi-agent-daiku/archive/refs/heads/main.zip) and extract to `C:\tools\multi-agent-daiku`

*Or use git:* `git clone https://github.com/yohey-w/multi-agent-daiku.git C:\tools\multi-agent-daiku`

</td>
</tr>
<tr>
<td>

**Step 2**

</td>
<td>

🖱️ **Double-click `koubou_install.bat`**

That's it! The installer handles everything automatically.

</td>
</tr>
<tr>
<td>

**Step 3**

</td>
<td>

✅ **Done!** 10 AI agents are now running.

</td>
</tr>
</table>

#### 📅 Daily Startup (After First Install)

Open **Ubuntu terminal** (WSL), navigate to your project directory, and run:

```bash
# Navigate to your project directory, then launch
cd /mnt/c/Users/you/my-project
/mnt/c/tools/multi-agent-daiku/koubou_hajime.sh

# Or specify the project directory with -p
/mnt/c/tools/multi-agent-daiku/koubou_hajime.sh -p /mnt/c/Users/you/my-project
```

---

<details>
<summary>🐧 <b>Linux / Mac Users</b> (Click to expand)</summary>

### First-Time Setup

```bash
# 1. Clone the repository
git clone https://github.com/yohey-w/multi-agent-daiku.git ~/multi-agent-daiku
cd ~/multi-agent-daiku

# 2. Make scripts executable
chmod +x *.sh

# 3. Run first-time setup
./koubou_junbi.sh
```

### Daily Startup

```bash
# Navigate to your project directory, then launch
cd ~/my-project
~/multi-agent-daiku/koubou_hajime.sh

# Or specify the project directory with -p
~/multi-agent-daiku/koubou_hajime.sh -p ~/my-project
```

</details>

---

<details>
<summary>❓ <b>What is WSL2? Why do I need it?</b> (Click to expand)</summary>

### About WSL2

**WSL2 (Windows Subsystem for Linux)** lets you run Linux inside Windows. This system uses `tmux` (a Linux tool) to manage multiple AI agents, so WSL2 is required on Windows.

### Don't have WSL2 yet?

No problem! When you run `koubou_install.bat`, it will:
1. Check if WSL2 is installed
2. If not, show you exactly how to install it
3. Guide you through the entire process

**Quick install command** (run in PowerShell as Administrator):
```powershell
wsl --install
```

Then restart your computer and run `koubou_install.bat` again.

</details>

---

<details>
<summary>📋 <b>Script Reference</b> (Click to expand)</summary>

| Script | Purpose | When to Run |
|--------|---------|-------------|
| `koubou_install.bat` | Windows: First-time setup (runs koubou_junbi.sh via WSL) | First time only |
| `koubou_junbi.sh` | Installs tmux, Node.js, Claude Code CLI | First time only |
| `koubou_hajime.sh` | Creates tmux sessions + starts Claude Code + loads instructions | Every day |

### What `koubou_install.bat` does automatically:
- ✅ Checks if WSL2 is installed
- ✅ Opens Ubuntu and runs `koubou_junbi.sh`
- ✅ Installs tmux, Node.js, and Claude Code CLI
- ✅ Creates necessary directories

### What `koubou_hajime.sh` does:
- ✅ Creates tmux sessions (toryo + multiagent)
- ✅ Launches Claude Code on all 10 agents
- ✅ Automatically loads instruction files for each agent
- ✅ Resets queue files for a fresh start
- ✅ Sets all panes' working directory to the target project (launcher mode)

**After running, all agents are ready to receive commands immediately!**

</details>

---

<details>
<summary>🔧 <b>Prerequisites (for manual setup)</b> (Click to expand)</summary>

If you prefer to install dependencies manually:

| Requirement | How to install | Notes |
|-------------|----------------|-------|
| WSL2 + Ubuntu | `wsl --install` in PowerShell | Windows only |
| tmux | `sudo apt install tmux` | Terminal multiplexer |
| Node.js v20+ | `nvm install 20` | Required for Claude Code CLI |
| Claude Code CLI | `npm install -g @anthropic-ai/claude-code` | Anthropic's official CLI |

</details>

---

### ✅ What Happens After Setup

After running either option, **10 AI agents** will start automatically:

| Agent | Role | Quantity |
|-------|------|----------|
| 🪚 Toryo | Master carpenter - receives your orders | 1 |
| 📋 Banto | Foreman - distributes tasks | 1 |
| 🔨 Daikushu | Craft workers - execute tasks in parallel | 8 |

You'll see tmux sessions created:
- `toryo` - Connect here to give commands
- `multiagent` - Workers running in background

---

## 🚀 Launcher Mode (Use with Any Project)

multi-agent-daiku can be installed in a fixed location and **launched from any project directory**.

### How It Works

| Variable | Meaning | Auto-set |
|----------|---------|----------|
| `TORYO_HOME` | Tool installation directory | Resolved from script location |
| `PROJECT_DIR` | Target project directory | Current directory, or specified with `-p` |
| `PROJECT_ID` | Resolved project identifier | From `config/projects.yaml` path match, else `basename(PROJECT_DIR)` |
| `DASHBOARD_PATH` | Active dashboard file | `$TORYO_HOME/dashboards/{project_id}/dashboard.md` |

- All tmux panes' working directory is set to `PROJECT_DIR`
- System files (queue/, config/, etc.) are referenced from `TORYO_HOME`
- Dashboard is initialized per project at `dashboards/{project_id}/dashboard.md`
- `TORYO_HOME/dashboard.md` is provided as a shortcut to the active project dashboard
- If `PROJECT_DIR` is not in `config/projects.yaml`, it is auto-registered at launch
- When `TORYO_HOME == PROJECT_DIR`, it runs in single-directory mode

### How to Launch

```bash
# Method 1: Navigate to your project, then launch
cd ~/my-app
~/tools/multi-agent-daiku-Fe-wind/koubou_hajime.sh

# Method 2: Specify with -p flag (from anywhere)
~/tools/multi-agent-daiku-Fe-wind/koubou_hajime.sh -p ~/my-app

# Set up an alias for convenience (~/.bashrc)
alias toryo='~/tools/multi-agent-daiku-Fe-wind/koubou_hajime.sh'
# → cd ~/my-app && toryo
```

### Agent CLI Selection (After Launch Start)

When startup begins (before agents are spawned), an interactive menu appears:

- `1` Recommended: Toryo=`claude`, Banto=`codex`, Daikushu=`codex`
- `2` All `claude`
- `3` All `codex`
- `4` Custom per role (Toryo/Banto/Daikushu)

In non-interactive shells, it automatically falls back to option `1`.

### After Launch

```
TORYO_HOME (~/tools/multi-agent-daiku-Fe-wind/)     PROJECT_DIR (~/my-app/)
├── queue/          ← System communication    ├── src/          ← Daikushu work here
├── config/         ← Settings                ├── package.json
├── instructions/   ← Agent instructions      └── ...
├── dashboards/
│   └── my-app/dashboard.md  ← Project dashboard
├── dashboard.md    ← Shortcut to active project dashboard
└── ...
```

---

## 📖 Basic Usage

### Step 1: Connect to Toryo

After running `koubou_hajime.sh`, all agents automatically load their instructions and are ready to work.

Open a new terminal and connect to the Toryo:

```bash
tmux attach-session -t toryo
```

### Step 2: Give Your First Order

The Toryo is already initialized! Just give your command:

```
Investigate the top 5 JavaScript frameworks and create a comparison table.
```

The Toryo will:
1. Write the task to a YAML file
2. Notify the Banto (manager)
3. Return control to you immediately (you don't have to wait!)

Meanwhile, the Banto distributes the work to Daikushu workers who execute in parallel.

### Step 3: Check Progress

Open the project dashboard in your editor to see real-time status:

```bash
cat "$TORYO_HOME/dashboards/$PROJECT_ID/dashboard.md"
# Shortcut path (points to active project)
cat "$TORYO_HOME/dashboard.md"
```

```markdown
## In Progress
| Worker | Task | Status |
|--------|------|--------|
| Daikushu 1 | React research | Running |
| Daikushu 2 | Vue research | Running |
| Daikushu 3 | Angular research | Done |
```

---

## ✨ Key Features

### ⚡ 1. Parallel Execution

One command can spawn up to 8 parallel tasks:

```
You: "Research 5 MCP servers"
→ 5 Daikushu start researching simultaneously
→ Results ready in minutes, not hours
```

### 🔄 2. Non-Blocking Workflow

The Toryo delegates immediately and returns control to you:

```
You: Give order → Toryo: Delegates → You: Can give next order immediately
                                           ↓
                         Workers: Execute in background
                                           ↓
                         Banto updates dashboard
                                           ↓
                         Banto notifies Toryo on completion
                                           ↓
                         Dashboard: Shows results / Toryo can relay status
```

You never have to wait for long tasks to complete.

### 🧠 3. Memory Across Sessions (Memory MCP)

The AI remembers your preferences:

```
Session 1: You say "I prefer simple solutions"
           → Saved to Memory MCP

Session 2: AI reads memory at startup
           → Won't suggest over-engineered solutions
```

### 📡 4. Event-Driven (No Polling)

Agents communicate via YAML files and wake each other with tmux send-keys.
**No API calls are wasted on polling loops.**

### 📸 5. Screenshot Support

VSCode's Claude Code extension lets you paste screenshots to explain issues. This CLI system brings the same capability:

```
# Configure your screenshot folder in config/settings.yaml
screenshot:
  path: "/mnt/c/Users/YourName/Pictures/Screenshots"

# Then just tell the Toryo:
You: "Check the latest screenshot"
You: "Look at the last 2 screenshots"
→ AI reads and analyzes your screenshots instantly
```

**💡 Windows Tip:** Press `Win + Shift + S` to take a screenshot. Configure the save location to match your `settings.yaml` path for seamless integration.

Perfect for:
- Explaining UI bugs visually
- Showing error messages
- Comparing before/after states

### 🧠 Model Configuration

| Agent | Model | Thinking | Reason |
|-------|-------|----------|--------|
| Toryo | Opus | Disabled | Delegation & dashboard updates don't need deep reasoning |
| Banto | Default | Enabled | Task distribution requires careful judgment |
| Daikushu | Default | Enabled | Actual implementation needs full capabilities |

The Toryo uses `MAX_THINKING_TOKENS=0` to disable extended thinking, reducing latency and cost while maintaining Opus-level judgment for high-level decisions.

### 📁 Context Management

The system uses a three-layer context structure for efficient knowledge sharing:

| Layer | Location | Purpose |
|-------|----------|---------|
| Memory MCP | `memory/daiku_memory.jsonl` | Persistent memory across sessions (preferences, decisions) |
| Global | `memory/global_context.md` | System-wide settings, user preferences |
| Project | `context/{project}.md` | Project-specific knowledge and state |

This design allows:
- Any Daikushu to pick up work on any project
- Consistent context across agent switches
- Clear separation of concerns
- Knowledge persistence across sessions

### Universal Context Template

All projects use the same 7-section template:

| Section | Purpose |
|---------|---------|
| What | Brief description of the project |
| Why | Goals and success criteria |
| Who | Stakeholders and responsibilities |
| Constraints | Deadlines, budget, limitations |
| Current State | Progress, next actions, blockers |
| Decisions | Decision log with rationale |
| Notes | Free-form notes and insights |

This standardized structure ensures:
- Quick onboarding for any agent
- Consistent information across all projects
- Easy handoffs between Daikushu workers

### 🛠️ Skills

Skills are not included in this repository by default.
As you use the system, skill candidates will appear in `dashboard.md`.
Review and approve them to grow your personal skill library.

#### Codex `AGENTS.md` Examples (`$multi-agent-daiku`)

Use `AGENTS.md` as the single instruction file for Codex in your project.

**1. Repository-wide default**

```markdown
# AGENTS.md
Use $multi-agent-daiku for all work that touches toryo orchestration files
(`koubou_hajime.sh`, `instructions/*.md`, `queue/*.yaml`, `config/*.yaml`, `dashboard.md`).

Keep the protocol:
- User -> Toryo -> Banto -> Daikushu
- YAML for payloads, `tmux send-keys` for wake-up only
```

**2. Task-specific trigger**

```markdown
# AGENTS.md
When the request is about setup, launch, or troubleshooting of this system,
explicitly invoke $multi-agent-daiku before editing files.
```

**3. Subdirectory override**

```markdown
# frontend/AGENTS.md
Inherit root AGENTS.md.
For frontend-only changes, keep root rules.
If dashboard/queue/instructions behavior is affected,
invoke $multi-agent-daiku explicitly.
```

**4. Fallback when skill is unavailable**

```markdown
# AGENTS.md
Primary path: use $multi-agent-daiku.
If unavailable, read `README.md` and `instructions/{toryo,banto,daikushu}.md` first,
then follow the same hierarchy and YAML queue protocol manually.
```

---

## 🏛️ Design Philosophy

### Why Hierarchical Structure?

The Toryo → Banto → Daikushu hierarchy exists for:

1. **Immediate Response**: Toryo delegates instantly and returns control to you
2. **Parallel Execution**: Banto distributes to multiple Daikushu simultaneously
3. **Separation of Concerns**: Toryo decides "what", Banto decides "who"

### Why YAML + send-keys?

- **YAML files**: Structured communication that survives agent restarts
- **send-keys**: Event-driven wakeups (no polling = no wasted API calls)
- **No direct calls**: Agents can't interrupt each other or your input

### Why Only Banto Updates Dashboard?

- **Single responsibility**: One writer = no conflicts
- **Information hub**: Banto receives all reports, knows the full picture
- **Consistency**: All updates go through one quality gate

### How Skills Work

Skills (`.claude/commands/`) are **not committed to this repository** by design.

**Why?**
- Each user's workflow is different
- Skills should grow organically based on your needs
- No one-size-fits-all solution

**How to create new skills:**
1. Daikushu report "skill candidates" when they notice repeatable patterns
2. Candidates appear in `dashboard.md` under "Skill Candidates"
3. You review and approve (or reject)
4. Approved skills are created by Banto

This keeps skills **user-driven** — only what you find useful gets added.

---

## 🔌 MCP Setup Guide

MCP (Model Context Protocol) servers extend Claude's capabilities. Here's how to set them up:

### What is MCP?

MCP servers give Claude access to external tools:
- **Notion MCP** → Read/write Notion pages
- **GitHub MCP** → Create PRs, manage issues
- **Memory MCP** → Remember things across sessions

### Installing MCP Servers

Run these commands to add MCP servers:

```bash
# 1. Notion - Connect to your Notion workspace
claude mcp add notion -e NOTION_TOKEN=your_token_here -- npx -y @notionhq/notion-mcp-server

# 2. Playwright - Browser automation
claude mcp add playwright -- npx @playwright/mcp@latest
# Note: Run `npx playwright install chromium` first

# 3. GitHub - Repository operations
claude mcp add github -e GITHUB_PERSONAL_ACCESS_TOKEN=your_pat_here -- npx -y @modelcontextprotocol/server-github

# 4. Sequential Thinking - Step-by-step reasoning for complex problems
claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking

# 5. Memory - Long-term memory across sessions (Recommended!)
claude mcp add memory -e MEMORY_FILE_PATH="$PWD/memory/daiku_memory.jsonl" -- npx -y @modelcontextprotocol/server-memory
```

### Verify Installation

```bash
claude mcp list
```

You should see all servers with "Connected" status.

---

## 🌍 Real-World Use Cases

### Example 1: Research Task

```
You: "Research the top 5 AI coding assistants and compare them"

What happens:
1. Toryo delegates to Banto
2. Banto assigns:
   - Daikushu 1: Research GitHub Copilot
   - Daikushu 2: Research Cursor
   - Daikushu 3: Research Claude Code
   - Daikushu 4: Research Codeium
   - Daikushu 5: Research Amazon CodeWhisperer
3. All 5 research simultaneously
4. Results compiled in dashboard.md
```

### Example 2: PoC Preparation

```
You: "Prepare a PoC for the project in this Notion page: [URL]"

What happens:
1. Banto fetches Notion content via MCP
2. Daikushu 2: Lists items to clarify
3. Daikushu 3: Researches technical feasibility
4. Daikushu 4: Creates PoC plan document
5. All results in dashboard.md, ready for your meeting
```

---

## ⚙️ Configuration

### Language Setting

Edit `config/settings.yaml`:

```yaml
language: ja   # Japanese only
language: en   # Japanese + English translation
```

---

## 🛠️ Advanced Usage

<details>
<summary><b>Script Architecture</b> (Click to expand)</summary>

```
┌─────────────────────────────────────────────────────────────────────┐
│                      FIRST-TIME SETUP (Run Once)                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  koubou_install.bat (Windows)                                              │
│      │                                                              │
│      └──▶ koubou_junbi.sh (via WSL)                                  │
│                │                                                    │
│                ├── Check/Install tmux                               │
│                ├── Check/Install Node.js v20+ (via nvm)             │
│                └── Check/Install Claude Code CLI                    │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                      DAILY STARTUP (Run Every Day)                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  koubou_hajime.sh                                             │
│      │                                                              │
│      ├──▶ Create tmux sessions                                      │
│      │         • "toryo" session (1 pane)                          │
│      │         • "multiagent" session (9 panes, 3x3 grid)           │
│      │                                                              │
│      ├──▶ Reset queue files and dashboard                           │
│      │                                                              │
│      └──▶ Launch Claude Code on all agents                          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

</details>

<details>
<summary><b>koubou_hajime.sh Options</b> (Click to expand)</summary>

```bash
# Default: Launch with current directory as the target project
cd ~/my-project && ~/tools/multi-agent-daiku-Fe-wind/koubou_hajime.sh

# Specify project directory with -p
~/tools/multi-agent-daiku-Fe-wind/koubou_hajime.sh -p ~/my-project

# Session setup only (without launching Claude Code)
./koubou_hajime.sh -s
./koubou_hajime.sh --setup-only

# Full startup + open Windows Terminal tabs
./koubou_hajime.sh -t
./koubou_hajime.sh --terminal

# Show help
./koubou_hajime.sh -h
./koubou_hajime.sh --help
```

**Directory Variables:**

| Variable | Meaning | Example |
|----------|---------|---------|
| `TORYO_HOME` | Tool installation directory | `~/tools/multi-agent-daiku-Fe-wind` |
| `PROJECT_DIR` | Target project directory | `/home/user/my-app` |
| `PROJECT_ID` | Resolved project identifier | `my-app` |
| `DASHBOARD_PATH` | Active dashboard path | `~/tools/multi-agent-daiku-Fe-wind/dashboards/my-app/dashboard.md` |

System files (queue/, config/, instructions/, etc.) live in `TORYO_HOME`, while actual coding work happens in `PROJECT_DIR`.

</details>

<details>
<summary><b>Common Workflows</b> (Click to expand)</summary>

**Normal Daily Usage:**
```bash
cd ~/my-project
~/tools/multi-agent-daiku-Fe-wind/koubou_hajime.sh  # Start everything
tmux attach-session -t toryo                       # Connect to give commands
```

**Debug Mode (manual control):**
```bash
~/tools/multi-agent-daiku-Fe-wind/koubou_hajime.sh -s  # Create sessions only

# Manually start Claude Code on specific agents
tmux send-keys -t toryo:0 'claude --dangerously-skip-permissions' Enter
tmux send-keys -t multiagent:0.0 'claude --dangerously-skip-permissions' Enter
```

**Restart After Crash:**
```bash
# Kill existing sessions
tmux kill-session -t toryo
tmux kill-session -t multiagent

# Start fresh
cd ~/my-project
~/tools/multi-agent-daiku-Fe-wind/koubou_hajime.sh
```

</details>

---

## 📁 File Structure

<details>
<summary><b>Click to expand file structure</b></summary>

```
multi-agent-daiku/
│
│  ┌─────────────────── SETUP SCRIPTS ───────────────────┐
├── koubou_install.bat               # Windows: First-time setup
├── koubou_junbi.sh            # Ubuntu/Mac: First-time setup
├── koubou_hajime.sh    # Daily startup (auto-loads instructions)
│  └────────────────────────────────────────────────────┘
│
├── instructions/             # Agent instruction files
│   ├── toryo.md             # Commander instructions
│   ├── banto.md               # Manager instructions
│   └── daikushu.md           # Worker instructions
│
├── config/
│   └── settings.yaml         # Language and other settings
│
├── queue/                    # Communication files
│   ├── toryo_to_banto.yaml   # Commands from Toryo to Banto
│   ├── banto_to_toryo.yaml   # Completion notifications from Banto to Toryo
│   ├── tasks/                # Individual worker task files
│   └── reports/              # Worker reports
│
├── memory/                   # Memory MCP storage
├── dashboards/               # Project dashboards
│   └── {project_id}/
│       └── dashboard.md
├── dashboard.md              # Shortcut to active project dashboard
└── CLAUDE.md                 # Project context for Claude
```

</details>

---

## 🔧 Troubleshooting

<details>
<summary><b>MCP tools not working?</b></summary>

MCP tools are "deferred" and need to be loaded first:

```
# Wrong - tool not loaded
mcp__memory__read_graph()  ← Error!

# Correct - load first
ToolSearch("select:mcp__memory__read_graph")
mcp__memory__read_graph()  ← Works!
```

</details>

<details>
<summary><b>Agents asking for permissions?</b></summary>

Make sure to start with `--dangerously-skip-permissions`:

```bash
claude --dangerously-skip-permissions --system-prompt "..."
```

</details>

<details>
<summary><b>Workers stuck?</b></summary>

Check the worker's pane:
```bash
tmux attach-session -t multiagent
# Use Ctrl+B then number to switch panes
```

</details>

<details>
<summary><b>tmux says "sessions should be nested with care"?</b></summary>

Cause:
1. Command typo like `tmux attach-session -t toryotmux attach-session -t toryo`
2. Running `attach-session` from inside an existing tmux session

Use this inside tmux:
```bash
tmux ls
tmux switch-client -t toryo
tmux switch-client -t multiagent
```

Use this only from a normal shell (outside tmux):
```bash
tmux attach-session -t toryo
```

Force attach from inside tmux (not recommended):
```bash
TMUX= tmux attach-session -t toryo
```

</details>

---

## 📚 tmux Quick Reference

| Command | Description |
|---------|-------------|
| `tmux attach-session -t toryo` | Connect to Toryo (outside tmux) |
| `tmux attach-session -t multiagent` | Connect to workers (outside tmux) |
| `tmux switch-client -t toryo` | Switch to Toryo (inside tmux) |
| `tmux switch-client -t multiagent` | Switch to workers (inside tmux) |
| `Ctrl+B` then `0-8` | Switch between panes |
| `Ctrl+B` then `d` | Detach (leave running) |
| `tmux kill-session -t toryo` | Stop Toryo session |
| `tmux kill-session -t multiagent` | Stop worker sessions |

---

## 🙏 Credits

Based on [Claude-Code-Communication](https://github.com/Akira-Papa/Claude-Code-Communication) by Akira-Papa.

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

<div align="center">

**Run your AI workshop. Build faster.**

</div>
