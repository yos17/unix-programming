# Chapter 6 — Processes & I/O

## What is a Process?

A **process** is a running program. When you type `ls`, Unix:
1. Creates a new process
2. Loads the `ls` program into it
3. Runs it
4. Destroys it when it's done

At any moment, dozens or hundreds of processes are running on your machine simultaneously.

```bash
ps aux           # show ALL running processes
ps aux | wc -l   # how many?
top              # live view, updates every second (q to quit)
htop             # nicer version (brew install htop)
```

---

## Every Process Has an ID

Each process gets a unique **PID** (Process ID):

```bash
echo $$          # PID of your current shell
sleep 10 &       # run sleep in background
echo $!          # PID of the last background process
ps aux | grep sleep
```

---

## Foreground vs Background

By default, commands run in the **foreground** — the shell waits for them to finish before giving you the prompt back.

```bash
sleep 10         # foreground: you wait 10 seconds
sleep 10 &       # background: shell returns immediately, prints [1] PID
```

### Managing background jobs

```bash
sleep 100 &         # start in background
sleep 200 &         # start another
jobs                # list background jobs
fg                  # bring last job to foreground
fg %1               # bring job #1 to foreground
bg %2               # send job #2 to background
kill %1             # kill job #1
```

### Ctrl shortcuts

```
Ctrl+C    — kill the current foreground process (sends SIGINT)
Ctrl+Z    — pause (suspend) it, sends it to background stopped
Ctrl+\    — kill with core dump (SIGQUIT)
```

After `Ctrl+Z`:
```bash
bg        # resume it in the background
fg        # resume it in the foreground
```

---

## Killing Processes

```bash
kill 1234           # send SIGTERM (polite: "please stop")
kill -9 1234        # send SIGKILL (force kill, can't be ignored)
kill -HUP 1234      # send SIGHUP (reload config, for servers)
killall ruby        # kill all processes named "ruby"
pkill -f "my script" # kill by matching command name pattern
```

Signals are messages sent to processes:

| Signal | Number | Meaning |
|--------|--------|---------|
| SIGTERM | 15 | Please terminate (default kill) |
| SIGKILL | 9 | Die NOW — cannot be caught |
| SIGINT | 2 | Interrupt (Ctrl+C) |
| SIGHUP | 1 | Hangup (reload config) |
| SIGSTOP | 19 | Pause the process |
| SIGCONT | 18 | Continue a paused process |

---

## Standard I/O — The Three Streams

Every process gets three open "files" when it starts:

| Stream | Number | Default |
|--------|--------|---------|
| stdin | 0 | keyboard |
| stdout | 1 | screen |
| stderr | 2 | screen (but separate!) |

This is why redirection works — you're just swapping what those file descriptors point to.

```bash
# stderr and stdout look the same on screen but are separate:
ls /real /fake 2>/dev/null     # suppress errors, show output
ls /real /fake 1>/dev/null     # suppress output, show errors
ls /real /fake &>/dev/null     # suppress everything

# Capture both in a variable:
output=$(ls /real /fake 2>&1)
```

### Why separate stderr?

So you can pipe stdout to the next command without polluting it with error messages:

```bash
find / -name "*.log" 2>/dev/null | head -20
# Without 2>/dev/null, "Permission denied" errors flood the output
```

---

## Pipes Under the Hood

When you write `cmd1 | cmd2`, Unix:
1. Creates a **pipe** — a small in-memory buffer with two ends (read/write)
2. Forks `cmd1`, connects its stdout to the write end
3. Forks `cmd2`, connects its stdin to the read end
4. Runs both simultaneously

They run **at the same time**. `cmd2` starts processing as soon as `cmd1` produces output. This is why pipes are fast even on huge files — data flows through without being fully stored anywhere.

```bash
# This works on a 100GB file efficiently:
cat huge.log | grep "error" | tail -10
# grep starts outputting before cat is done reading
```

---

## `wait`, `nohup`, and Long-Running Jobs

```bash
# Run a long job and wait for it:
long_process &
pid=$!
echo "Running as PID $pid..."
wait $pid
echo "Done! Exit code: $?"
```

### nohup — survive terminal close

```bash
nohup long_process.sh &
```

`nohup` (no hangup) makes the process ignore the SIGHUP signal that gets sent when you close your terminal. Output goes to `nohup.out`.

### disown

```bash
long_process &
disown    # detach it from the shell completely
```

---

## Environment Variables

Every process inherits a copy of its parent's **environment** — a set of name=value pairs.

```bash
env             # show all environment variables
printenv HOME   # show one variable
```

When you set `export VAR=value`, child processes inherit it. Without `export`, only the current shell sees it:

```bash
LOCAL="only here"
export SHARED="children can see this"

bash -c 'echo $LOCAL'   # => (empty)
bash -c 'echo $SHARED'  # => children can see this
```

This is why you put things in `.zshrc` with `export` — every new shell (child) inherits them.

---

## `exec` — Replace the Current Process

```bash
exec ls -la   # replace the shell with ls — shell is gone after this
```

`exec` doesn't fork a new process — it *replaces* the current one. After `exec`, your shell is gone. This is actually how the shell runs programs internally (fork → exec).

---

## Process Substitution

A clever feature — treat a command's output as a file:

```bash
diff <(ls dir1) <(ls dir2)     # diff the output of two commands
wc -l <(find . -name "*.rb")   # count files found
```

`<(command)` runs the command and provides its output as a temporary file-like thing.

---

## Exercises

1. Start `sleep 1000` in the background. Find its PID. Kill it with `kill`. Verify it's gone with `ps`.
2. Run a command, pause it with Ctrl+Z, check `jobs`, then resume it with `fg`.
3. What's the difference between `kill -9` and `kill` (no flag)? When would you use each?
4. Write a script that runs 3 tasks in parallel and waits for all to finish:
   ```bash
   sleep 3 &; sleep 2 &; sleep 1 &; wait; echo "all done"
   ```
5. Use `nohup` to run a script that appends the date to a file every second. Close your terminal. Reopen it. Is it still running?

---

## Solutions

### Exercise 1 — Start sleep 1000, find PID, kill it, verify

```bash
#!/bin/bash
# Start sleep in background
sleep 1000 &
SLEEP_PID=$!

echo "Started sleep with PID: $SLEEP_PID"

# Verify it's running
echo "Checking it's running:"
ps aux | grep "sleep 1000" | grep -v grep

# Kill it
echo "Killing PID $SLEEP_PID..."
kill $SLEEP_PID

# Wait a moment and verify it's gone
sleep 1
echo "Verifying it's gone:"
if ps -p $SLEEP_PID > /dev/null 2>&1; then
  echo "Process still running!"
else
  echo "Process $SLEEP_PID is gone ✓"
fi
```

```bash
# Manual steps:
# $ sleep 1000 &
# [1] 45123
# $ ps aux | grep sleep
# yosia  45123  0.0  0.0  sleep 1000
# $ kill 45123
# [1]  + 45123 terminated  sleep 1000
# $ ps aux | grep sleep | grep -v grep
# (no output — it's gone)
```

### Exercise 2 — Run a command, pause with Ctrl+Z, check jobs, resume

```bash
# In your terminal (interactive — can't script Ctrl+Z):

# 1. Start a long-running command
sleep 60

# 2. Press Ctrl+Z — you see:
# ^Z
# [1]  + 12345 suspended  sleep 60

# 3. Check jobs
jobs
# [1]  + suspended  sleep 60

# 4. Resume in background
bg
# [1]  + 12345 continued  sleep 60

# 5. Or bring back to foreground
fg
# (now waiting for sleep 60 to finish — Ctrl+C to kill it)
```

### Exercise 3 — Difference between kill -9 and kill

```bash
# SIGTERM (default kill) — polite request to terminate
kill 1234
# kill -15 1234 (same thing)
# - Process receives SIGTERM signal
# - Process can catch the signal and do cleanup (close files, save state)
# - Process can even ignore it
# - Use this FIRST — let the process clean up

# SIGKILL — forced, immediate termination
kill -9 1234
# - Kernel immediately terminates the process
# - Process CANNOT catch, block, or ignore SIGKILL
# - No cleanup happens — open files, temp files may be left around
# - Use this ONLY when SIGTERM doesn't work after waiting a few seconds

# Best practice:
kill 1234
sleep 5
# if still running:
kill -9 1234
```

**Rule of thumb:**
- `kill` (SIGTERM) first: give the process a chance to clean up
- `kill -9` (SIGKILL) only if the process doesn't respond after a few seconds

### Exercise 4 — Script running 3 tasks in parallel, waiting for all

```bash
#!/bin/bash
# parallel_tasks.sh — run multiple tasks simultaneously and wait for all

echo "Starting 3 tasks in parallel at $(date '+%H:%M:%S')"

# Start all tasks in background, capture their PIDs
sleep 3 &
pid1=$!
echo "Task 1 started (PID $pid1, will take 3s)"

sleep 2 &
pid2=$!
echo "Task 2 started (PID $pid2, will take 2s)"

sleep 1 &
pid3=$!
echo "Task 3 started (PID $pid3, will take 1s)"

echo "Waiting for all tasks..."

# Wait for each specifically, check exit codes
wait $pid1; echo "Task 1 done (exit: $?)"
wait $pid2; echo "Task 2 done (exit: $?)"
wait $pid3; echo "Task 3 done (exit: $?)"

echo "All done at $(date '+%H:%M:%S') — took ~3 seconds total (not 6!)"
```

```bash
# Shorter version from the exercise:
sleep 3 & sleep 2 & sleep 1 & wait; echo "all done"
# All three sleeps run simultaneously — total time is ~3 seconds
```

### Exercise 5 — Use nohup to keep a script running after terminal close

```bash
#!/bin/bash
# date_logger.sh — append date to a file every second
# Run with: nohup ./date_logger.sh &

LOGFILE="$HOME/date_log.txt"

while true; do
  date >> "$LOGFILE"
  sleep 1
done
```

```bash
# Make it executable and run with nohup
chmod +x date_logger.sh
nohup ./date_logger.sh &
# Output: [1] 45678
#         nohup: appending output to 'nohup.out'

# Close your terminal. Reopen it. Check:
ps aux | grep date_logger   # still running!
tail -f ~/date_log.txt      # watch the dates accumulating

# To stop it:
pkill -f date_logger.sh
```

`nohup` makes the process ignore the SIGHUP signal that the terminal sends to all its child processes when it closes. Output from the script (stdout/stderr) is redirected to `nohup.out` automatically.

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| Process | a running instance of a program |
| PID | unique ID for each process |
| `&` | run in background |
| `jobs`, `fg`, `bg` | manage background jobs |
| `kill` | send signals to processes |
| stdin/stdout/stderr | the three standard streams (0, 1, 2) |
| `2>/dev/null` | discard stderr |
| Pipes | two processes running simultaneously, connected |
| `nohup` | survive terminal close |
| `exec` | replace current process |
| `export` | share variables with child processes |

---

## The Big Idea from This Chapter

Unix multitasking is built on one simple mechanism: **fork and exec**. The shell forks a copy of itself, the copy execs the new program, and the original shell waits. Pipes work because both sides of the pipe run simultaneously. Once you understand this, the behavior of background jobs, signals, and I/O redirection all make sense.
