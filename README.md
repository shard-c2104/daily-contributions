# 🟢 GitHub Contribution Painter (Educational Prototype)

<p align="center">
  <img src="assets/banner.jpg" alt="Contribution Painter Banner" width="100%">
</p>

> [!CAUTION]
> **Educational Purposes Only**
> This project was built strictly as an experiment to test out shell scripting, Git history manipulation, and command-line automation. It is **not recommended for actual use**. Use with extreme caution — GitHub's automated abuse detection systems may suspend or ban your account if they identify an unnatural volume of commits generated in a short period of time.

A single-command shell script to generate backdated GitHub commits and visualize patterns on a GitHub contribution graph.

---

## ⚡ Installation & Quick Start

> **Note:** Running these commands will modify your GitHub contribution history. Proceed with caution.

```bash
# 1. Install globally with one command (requires sudo if not run as root)
sudo curl -sSL https://raw.githubusercontent.com/shard-c6/daily-contributions/main/contribute.sh -o /usr/local/bin/contribute && sudo chmod +x /usr/local/bin/contribute

# 2. Generate 5 commits on a specific date
contribute 2026-01-15 5

# Generate 3 commits/day for an entire month
contribute 2026-08-01 2026-08-31 3
```
*(The first time you run it, it will securely set up a hidden dummy repository at `~/.daily-contributions` and ask for your remote GitHub repo URL.)*

---

## 📖 Usage

### Mode 1 — Single Date

```bash
contribute <DATE> <COUNT>
```

| Argument | Description              | Example        |
|----------|--------------------------|----------------|
| `DATE`   | Target date (YYYY-MM-DD) | `2026-01-15`   |
| `COUNT`  | Number of commits        | `5`            |

**Example:**

```bash
contribute 2026-03-14 7
# → 7 commits on March 14, 2026
```

### Mode 2 — Date Range

```bash
contribute <START_DATE> <END_DATE> [COUNT_PER_DAY]
```

| Argument        | Description                     | Example        |
|-----------------|---------------------------------|----------------|
| `START_DATE`    | First date (YYYY-MM-DD)         | `2026-01-01`   |
| `END_DATE`      | Last date (YYYY-MM-DD)          | `2026-01-31`   |
| `COUNT_PER_DAY` | Commits per day (default: `1`)  | `3`            |

**Example:**

```bash
contribute 2026-06-01 2026-06-30 2
# → 2 commits/day × 30 days = 60 total commits for June
```

---

## 🔧 Options

| Flag                 | Description                                    |
|----------------------|------------------------------------------------|
| `-y, --yes`          | Skip the confirmation prompt                   |
| `--week`             | Generate commits for 7 days starting from DATE |
| `--undo <DATE>`      | Undo commits generated on a specific date      |
| `--nuke`             | Delete ALL generated commits and start fresh   |
| `-h, --help`         | Show usage help                                |

**Examples:**

```bash
contribute -y 2026-07-04 10          # Skip confirmation
contribute 2026-01-15 --week random  # Random 1-50 commits for a week
contribute --undo 2026-01-15         # Undo commits for a date
contribute --nuke                    # Wipe all contributions
```

---

## 🛡️ Safety & Reverting

Every run shows a **confirmation prompt** before committing.

- Type `y` → commits are created and pushed
- Press Enter or type anything else → **aborted**, nothing happens

If you accidentally generate unwanted commits, you can use the `--undo <DATE>` or `--nuke` commands to purge the history from your local machine and force-push the clean history to GitHub.

---

## 🧠 How It Works (Technical Details)

This script was designed to test the limits of Git date manipulation and bash scripting.
1. Creates **empty commits** (`--allow-empty`) without tracking actual file changes.
2. Manipulates `GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE` environment variables to forge backdated timestamps.
3. **Randomizes the timestamp** within 8 AM – 10 PM for each commit to simulate human activity.
4. **Auto-pushes** to `origin/main` — propagating the manipulated history to the GitHub profile graph.

All actions are logged to `~/.daily-contributions/contributions.log` to support history parsing and the `--undo` feature.

---

## ⚠️ Disclaimer & Warning

This script manipulates your GitHub contribution graph by creating artificial commit history.
**It is intended strictly for educational purposes and testing shell scripts/Git commands.**

- **Account Risk**: Generating thousands of commits or manipulating the graph unnaturally can trigger GitHub's abuse detection mechanisms, potentially leading to account suspension or bans.
- **Responsibility**: The author is not responsible for any actions taken against your account for using this tool. Use entirely at your own risk.

---

## 📜 License

MIT
