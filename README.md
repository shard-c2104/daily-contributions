# 🟢 GitHub Contribution Painter

A single-command tool to generate backdated GitHub commits — paint your contribution graph however you want.

> **Note:** Commits are pushed to a **private repo** so they show on your profile graph without cluttering any real project.

---

## ⚡ Quick Start

```bash
# Clone the repo
git clone git@github.com:shard-c6/daily-contributions.git
cd daily-contributions

# Make the script executable (first time only)
chmod +x contribute.sh

# Generate 5 commits on a specific date
./contribute.sh 2026-01-15 5

# Generate 3 commits/day for an entire month
./contribute.sh 2026-08-01 2026-08-31 3
```

---

## 📖 Usage

### Mode 1 — Single Date

```bash
./contribute.sh <DATE> <COUNT>
```

| Argument | Description              | Example        |
|----------|--------------------------|----------------|
| `DATE`   | Target date (YYYY-MM-DD) | `2026-01-15`   |
| `COUNT`  | Number of commits        | `5`            |

**Example:**

```bash
./contribute.sh 2026-03-14 7
# → 7 commits on March 14, 2026
```

### Mode 2 — Date Range

```bash
./contribute.sh <START_DATE> <END_DATE> [COUNT_PER_DAY]
```

| Argument        | Description                     | Example        |
|-----------------|---------------------------------|----------------|
| `START_DATE`    | First date (YYYY-MM-DD)         | `2026-01-01`   |
| `END_DATE`      | Last date (YYYY-MM-DD)          | `2026-01-31`   |
| `COUNT_PER_DAY` | Commits per day (default: `1`)  | `3`            |

**Example:**

```bash
./contribute.sh 2026-06-01 2026-06-30 2
# → 2 commits/day × 30 days = 60 total commits for June
```

---

## 🔧 Options

| Flag         | Description                 |
|--------------|-----------------------------|
| `-y, --yes`  | Skip the confirmation prompt |
| `-h, --help` | Show usage help              |

**Example — skip confirmation:**

```bash
./contribute.sh -y 2026-07-04 10
```

---

## 🛡️ Safety

Every run shows a **confirmation prompt** before committing:

```
🟢 Generating 5 commits on 2026-01-15
─────────────────────────────────────────────

  ⚠  This action is irreversible — commits cannot be undone.
  Proceed? [y/N]: _
```

- Type `y` → commits are created and pushed
- Press Enter or type anything else → **aborted**, nothing happens

---

## 🧠 How It Works

1. Creates **empty commits** (`--allow-empty`) — no files are modified
2. Sets `GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE` to the target date
3. **Randomizes the timestamp** within 8 AM – 10 PM for each commit so it looks natural
4. **Auto-pushes** to `origin/main` — contributions appear on your GitHub graph within minutes

All commits are logged to `contributions.log` for your reference.

---

## 📁 Project Structure

```
daily-contributions/
├── contribute.sh       # Main script — the only thing you need to run
├── contributions.log   # Auto-generated log of all commits made
├── .gitignore
└── README.md
```

---

## 💡 Tips

- **Fill gaps in your graph:** Target specific dates you missed
- **Paint patterns:** Use varying commit counts across dates to create visual patterns
- **Bulk fill:** Use date ranges to cover entire months or years quickly
- **Automate:** Use `-y` flag in cron jobs or scripts to skip prompts

---

## ⚠️ Disclaimer

This tool is for **personal use** on your own GitHub profile. The commits are empty and go to a private repo — they don't affect any real projects. Use responsibly.

---

## 📜 License

MIT — do whatever you want with it.
