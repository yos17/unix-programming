# Chapter 8 — Building Things

## The Last Piece: Putting It All Together

In the previous chapters you learned:
- How to navigate and use Unix (Ch1-2)
- How the shell works (Ch3)
- How to chain tools with pipes (Ch4)
- How to write shell scripts (Ch5)
- How processes and I/O really work (Ch6-7)

This chapter is about **building software** on Unix — compiling programs, managing dependencies, and automating the build process.

---

## Compiling a Program

The simplest C program:

```c
/* hello.c */
#include <stdio.h>

int main() {
    printf("Hello, World!\n");
    return 0;
}
```

Compile and run:
```bash
gcc hello.c -o hello    # compile
./hello                 # run
```

What just happened?
1. `gcc` reads `hello.c` (source code — human readable)
2. **Preprocesses** it (expands `#include`, `#define`)
3. **Compiles** it to assembly
4. **Assembles** it to machine code (object file `hello.o`)
5. **Links** it with libraries (like stdio) to produce `./hello`

You can see each step:
```bash
gcc -E hello.c          # stop after preprocessing
gcc -S hello.c          # stop after compilation (produces hello.s assembly)
gcc -c hello.c          # stop after assembling (produces hello.o object file)
gcc hello.o -o hello    # link to produce executable
```

---

## Make — Automating Builds

When a project has many files, recompiling everything from scratch every time is slow. `make` solves this by tracking **dependencies** and only rebuilding what changed.

A `Makefile`:

```makefile
# Format: target: dependencies
#             command (must be indented with TAB, not spaces!)

# Final program depends on object files
hello: main.o util.o
	gcc main.o util.o -o hello

# Each object file depends on its source
main.o: main.c main.h
	gcc -c main.c

util.o: util.c util.h
	gcc -c util.c

# Cleanup (not a real file, so mark as PHONY)
.PHONY: clean
clean:
	rm -f *.o hello
```

```bash
make          # build (only recompiles changed files)
make clean    # delete compiled files
make hello    # build a specific target
```

How `make` decides what to rebuild:
- Compares timestamps of target vs dependencies
- If dependency is newer than target → rebuild target
- If target doesn't exist → build it

This is the core of every build system (Gradle, webpack, rake, cargo) — they all do the same dependency tracking, just with different syntax.

---

## A Minimal Makefile for Any Project

```makefile
.PHONY: all test clean install

all: build

build:
	@echo "Building..."
	# your build command here

test:
	@echo "Running tests..."
	# your test command here

clean:
	@echo "Cleaning..."
	# rm -f built files

install:
	@echo "Installing..."
	# cp files to /usr/local/bin etc.
```

The `@` before a command suppresses echoing the command itself.

---

## Environment and Configuration

How programs find their configuration:

```bash
# 1. Command-line arguments (highest priority)
myapp --config /etc/myapp.conf

# 2. Environment variables
export DATABASE_URL="postgres://localhost/mydb"
myapp

# 3. Config files (checked in order)
~/.myapp/config     # user-specific
/etc/myapp.conf     # system-wide

# 4. Compiled-in defaults (lowest priority)
```

Good Unix programs follow this priority. The `12-factor app` methodology is just this idea applied to web apps.

---

## The `PATH` — How Commands Are Found

```bash
echo $PATH
# /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

which ruby        # which ruby is being used?
type -a python    # show ALL versions of python in PATH
```

Add your own tools to `~/bin`:
```bash
mkdir -p ~/bin
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Now any executable you put in `~/bin` becomes a command.

---

## `cron` — Scheduled Jobs

`cron` runs commands automatically on a schedule:

```bash
crontab -e    # edit your cron schedule
crontab -l    # list current cron jobs
```

Cron format: `minute hour day-of-month month day-of-week command`

```
# Run at 9am every day
0 9 * * * /Users/yosia/bin/morning-report.sh

# Every 15 minutes
*/15 * * * * /Users/yosia/bin/check-email.sh

# Every Monday at 8am
0 8 * * 1 /Users/yosia/bin/weekly-summary.sh

# At midnight on the 1st of every month
0 0 1 * * /Users/yosia/bin/monthly-backup.sh
```

`*` means "every". `*/15` means "every 15".

---

## Logging — Tracking What Happened

Good Unix tools log what they do:

```bash
#!/bin/bash
LOGFILE="$HOME/logs/myapp.log"
mkdir -p "$(dirname $LOGFILE)"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

log "Script started"
log "Processing files..."
# ... do work ...
log "Script finished"
```

`tee` sends output to both the screen AND a file simultaneously.

Watch a log file live:
```bash
tail -f ~/logs/myapp.log
```

---

## Debugging Scripts

```bash
#!/bin/bash
set -e          # exit immediately if any command fails
set -u          # treat undefined variables as errors
set -x          # print each command before running it (debug mode)
set -o pipefail # catch failures in pipes too

# Or combine:
set -euxo pipefail
```

`set -x` is incredibly useful — it shows you exactly what the shell is doing:
```bash
bash -x my-script.sh    # run with debug output
```

---

## `trap` — Cleanup on Exit

```bash
#!/bin/bash

TMPFILE=$(mktemp)   # create a temporary file

# Clean up temp file when script exits (for any reason)
trap 'rm -f "$TMPFILE"' EXIT
trap 'echo "Interrupted!"; exit 1' INT TERM

echo "Working..." > "$TMPFILE"
# ... do stuff ...
cat "$TMPFILE"
# TMPFILE is automatically deleted when script exits
```

`trap` catches signals and runs cleanup code. `EXIT` fires whenever the script ends, even on error.

---

## Building a Complete Tool

Let's build `log-summary` — a tool that summarizes a log file:

```bash
#!/bin/bash
# log-summary — summarize a log file
# Usage: log-summary [logfile]
#        cat logfile | log-summary

set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: log-summary [logfile]"
  echo "Summarize a log file: count errors, warnings, info messages"
  exit 0
fi

input="${1:-/dev/stdin}"

echo "=== Log Summary ==="
echo "Errors:   $(grep -c -i 'error'   "$input" 2>/dev/null || echo 0)"
echo "Warnings: $(grep -c -i 'warning' "$input" 2>/dev/null || echo 0)"
echo "Info:     $(grep -c -i 'info'    "$input" 2>/dev/null || echo 0)"
echo ""
echo "=== Last 5 Errors ==="
grep -i 'error' "$input" | tail -5 || echo "(none)"
echo ""
echo "=== Time Range ==="
echo "First: $(head -1 "$input")"
echo "Last:  $(tail -1 "$input")"
```

This is a complete, well-behaved Unix tool:
- Has `--help`
- Reads from file or stdin
- Clear output format
- Handles errors gracefully

---

## Final Project — Your Own Shell Script Toolkit

Build a personal `~/bin` with at least 5 tools you'll actually use:

Suggestions:
- `today` — show today's date, weather, and your todo list
- `mkproject` — create a new project directory with standard structure
- `cleanup` — remove old temp files, empty trash, etc.
- `gitlog` — pretty git log with colors
- `serve` — start a local HTTP server in the current directory

---

## Exercises

1. Write a `Makefile` with targets: `all`, `test`, `clean`. Add a fake test.
2. Set up a cron job that appends the date to a file every minute. Watch it with `tail -f`.
3. Add `set -euxo pipefail` to one of your scripts from Ch5. Does it catch any hidden bugs?
4. Write a `log-watch.sh` that monitors a log file and sends an alert (echo to screen) when "ERROR" appears.
5. Build your `~/bin` with 3 useful personal scripts.

---

## Solutions

### Exercise 1 — Makefile with all, test, clean targets

```makefile
# Makefile — example project build system

.PHONY: all test clean

all: build

build:
	@echo "Building project..."
	@mkdir -p bin
	@echo '#!/bin/bash' > bin/hello
	@echo 'echo "Hello from the build!"' >> bin/hello
	@chmod +x bin/hello
	@echo "Build complete: bin/hello"

test:
	@echo "Running tests..."
	@# Test that the binary exists
	@[ -x bin/hello ] && echo "✓ bin/hello exists and is executable" || echo "✗ bin/hello missing"
	@# Test that it outputs the expected string
	@bin/hello | grep -q "Hello" && echo "✓ output contains 'Hello'" || echo "✗ output check failed"
	@echo "Tests passed."

clean:
	@echo "Cleaning up..."
	@rm -rf bin/
	@echo "Clean complete."
```

```bash
# $ make
# Building project...
# Build complete: bin/hello

# $ make test
# Running tests...
# ✓ bin/hello exists and is executable
# ✓ output contains 'Hello'
# Tests passed.

# $ make clean
# Cleaning up...
# Clean complete.
```

### Exercise 2 — Cron job that appends date every minute

```bash
# Edit your crontab
crontab -e

# Add this line (runs every minute):
* * * * * date >> /tmp/date_log.txt

# Save and exit. Verify it was added:
crontab -l

# Watch it accumulate:
tail -f /tmp/date_log.txt
# Fri Apr  3 14:32:00 CET 2026
# Fri Apr  3 14:33:00 CET 2026
# Fri Apr  3 14:34:00 CET 2026
# ...

# To remove the cron job when done:
crontab -e   # delete the line
# Or:
crontab -r   # WARNING: removes ALL cron jobs
```

### Exercise 3 — Add set -euxo pipefail to a Ch5 script

```bash
#!/bin/bash
# monitor.sh from Chapter 5 — now with strict mode
set -euo pipefail

# -e  exit immediately if any command fails
# -u  treat unset variables as errors
# -x  print each command before running (debug output)
# -o pipefail  catch failures inside pipes too

echo "Monitoring $(pwd) every 5 seconds. Press Ctrl+C to stop."
echo ""

while true; do
  file_count=$(ls | wc -l | tr -d ' ')
  echo "[$(date '+%H:%M:%S')] Files in current directory: $file_count"
  sleep 5
done

# With -x, you'll see output like:
# + pwd
# + echo 'Monitoring /Users/yosia/Projects...'
# + ls
# + wc -l
# + tr -d ' '
# + file_count=12
# ...

# Bugs -euxo pipefail catches:
# - Without -u: $typo_var would silently be empty; now it's an error
# - Without -e: failing commands are ignored; now the script stops
# - Without pipefail: grep -q "x" file | wc -l — if grep fails (no match),
#   the pipeline still "succeeds" without pipefail
```

### Exercise 4 — log-watch.sh: monitor a log file and alert on ERROR

```bash
#!/bin/bash
# log-watch.sh — monitor a log file and alert when ERROR appears
# Usage: ./log-watch.sh [logfile]

set -euo pipefail

LOGFILE="${1:-/tmp/test.log}"

if [ ! -f "$LOGFILE" ]; then
  echo "Log file not found: $LOGFILE" >&2
  echo "Creating it for demo purposes..."
  touch "$LOGFILE"
fi

echo "Watching $LOGFILE for ERROR messages... (Ctrl+C to stop)"
echo ""

# tail -F follows file even if it's rotated (re-created)
tail -F "$LOGFILE" | while IFS= read -r line; do
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

  # Check if the line contains ERROR (case-insensitive)
  if echo "$line" | grep -qi "error"; then
    echo "🚨 ALERT [$timestamp]: $line"
  else
    echo "   INFO  [$timestamp]: $line"
  fi
done
```

```bash
# Test it:
# Terminal 1:
# $ ./log-watch.sh /tmp/test.log

# Terminal 2 (generate test log entries):
# $ echo "INFO: server started" >> /tmp/test.log
# $ echo "INFO: request received" >> /tmp/test.log
# $ echo "ERROR: database connection failed" >> /tmp/test.log
# $ echo "INFO: retrying..." >> /tmp/test.log

# Terminal 1 will show:
#    INFO  [2026-04-03 14:32:01]: INFO: server started
#    INFO  [2026-04-03 14:32:03]: INFO: request received
# 🚨 ALERT [2026-04-03 14:32:05]: ERROR: database connection failed
#    INFO  [2026-04-03 14:32:07]: INFO: retrying...
```

### Exercise 5 — Build ~/bin with 3 useful personal scripts

```bash
# Set up ~/bin
mkdir -p ~/bin
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Script 1: `~/bin/today` — show date, day, and simple reminder**

```bash
#!/bin/bash
# today — quick daily summary

echo "📅 $(date '+%A, %B %d %Y')"
echo "⏰ $(date '+%H:%M %Z')"
echo ""
echo "📂 Current directory: $(pwd)"
echo "💻 Disk usage home:   $(du -sh ~ 2>/dev/null | cut -f1)"
echo ""
if [ -f ~/todo.txt ]; then
  echo "📋 Todo:"
  cat ~/todo.txt
fi
```

**Script 2: `~/bin/mkproject` — create a new project with standard structure**

```bash
#!/bin/bash
# mkproject — create a new project directory with standard structure
# Usage: mkproject <project-name>

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <project-name>" >&2
  exit 1
fi

name="$1"
dir="$HOME/Projects/$name"

if [ -d "$dir" ]; then
  echo "Error: $dir already exists" >&2
  exit 1
fi

mkdir -p "$dir"/{src,test,docs}
cat > "$dir/README.md" << EOF
# $name

## Description

TODO: describe this project

## Usage

\`\`\`bash
# how to run it
\`\`\`
EOF

cat > "$dir/.gitignore" << 'EOF'
*.log
*.tmp
.DS_Store
EOF

cd "$dir"
git init -q
git add .
git commit -q -m "Initial project structure"

echo "✅ Created project: $dir"
echo "   cd $dir"
```

**Script 3: `~/bin/serve` — start a local HTTP server in current directory**

```bash
#!/bin/bash
# serve — start a local HTTP server in the current directory
# Usage: serve [port]

PORT="${1:-8000}"

echo "🌐 Serving $(pwd) at http://localhost:$PORT"
echo "   Press Ctrl+C to stop"
echo ""

# Try different available web servers
if command -v python3 &>/dev/null; then
  python3 -m http.server "$PORT"
elif command -v ruby &>/dev/null; then
  ruby -run -e httpd . -p "$PORT"
elif command -v npx &>/dev/null; then
  npx serve -l "$PORT" .
else
  echo "Error: No web server found (need python3, ruby, or node)" >&2
  exit 1
fi
```

```bash
# Make all scripts executable
chmod +x ~/bin/today ~/bin/mkproject ~/bin/serve

# Use them:
# $ today
# $ mkproject my-new-app
# $ serve 3000
```

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| Compilation | source → object files → linked executable |
| `make` | builds only what changed based on timestamps |
| `PATH` | where the shell looks for commands |
| `cron` | schedule commands automatically |
| `set -euxo pipefail` | make scripts fail safely |
| `trap` | cleanup code on exit or signal |
| `tee` | write to file and stdout simultaneously |
| `--help` | every good tool has this |

---

## The Big Idea from This Chapter

Unix tools are small, composable, and automatable. A good Unix programmer builds a personal toolkit of scripts over years — each one solving a real problem, each one usable as a building block in pipelines. The best code is code you write once and use forever.

---

## You're Done

You've covered everything Kernighan and Pike covered — but without the 1984 assumptions.

Here's what you now understand:
- ✅ The Unix philosophy (small tools, pipes, text)
- ✅ The filesystem (everything is a file, permissions, inodes)
- ✅ The shell (variables, redirection, PATH, quoting)
- ✅ Filters and pipelines (grep, sort, awk, sed — combined)
- ✅ Shell programming (scripts, functions, loops, conditions)
- ✅ Processes (fork/exec, signals, background jobs)
- ✅ Under the hood (system calls, file descriptors, how pipes work)
- ✅ Building things (make, cron, logging, debugging)

The next step: **use it**. Open a terminal and solve real problems with these tools. Every time you find yourself doing something repetitive, write a script. Every time you need to find something in data, build a pipeline. That's how you get good at Unix.
