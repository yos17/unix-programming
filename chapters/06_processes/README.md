# Chapter 6 — Processes & I/O

## What is a Process?

A **process** is a running program. When you type `ls` and press Enter, the shell creates a new process, runs `ls` inside it, waits for it to finish, then shows you the next prompt.

Every process has:
- A **PID** (process ID) — a unique number
- A **parent** — the process that created it (your shell)
- An **owner** — which user it runs as
- **Three streams**: stdin, stdout, stderr
- An **exit code** — returned when it finishes (0 = success)

---

## Viewing Processes

```bash
ps             # processes in your current terminal
ps aux         # ALL processes on the system
ps aux | grep ruby    # find ruby processes
```

Understanding `ps aux` output:
```
USER  PID  %CPU  %MEM  VSZ  RSS  TTY  STAT  START  TIME  COMMAND
yosia 1234  0.0   0.1  123M  4M  s001  S+   14:00  0:00  ruby server.rb
```

- `PID` — process ID
- `%CPU`, `%MEM` — resource usage
- `STAT` — status: `S` = sleeping, `R` = running, `Z` = zombie
- `COMMAND` — what's running

```bash
top         # live, updating view of processes (press q to quit)
htop        # prettier version (install with brew install htop)
```

---

## Running in the Background

Normally a command runs in the **foreground** — it holds your terminal until it's done.

```bash
sleep 10    # blocks for 10 seconds, you can't type
```

Add `&` to run in the **background**:

```bash
sleep 10 &
# [1] 5678
# [1] = job number, 5678 = PID
```

Now your prompt returns immediately. The sleep continues in the background.

```bash
jobs        # list background jobs
fg          # bring last background job to foreground
fg %1       # bring job #1 to foreground
bg %1       # send stopped job to background
```

### Stopping and killing

```bash
Ctrl+C      # send SIGINT — interrupt (usually stops the program)
Ctrl+Z      # send SIGTSTP — pause (suspend) the program
Ctrl+\      # send SIGQUIT — quit with core dump

kill 5678          # send SIGTERM to PID 5678 (polite stop)
kill -9 5678       # send SIGKILL — force kill (no cleanup)
kill -HUP 5678     # send SIGHUP — hangup (often means "reload config")
killall ruby       # kill all processes named "ruby"
```

**SIGTERM vs SIGKILL:**
- SIGTERM (15): politely asks the process to stop. It can catch this signal and clean up first.
- SIGKILL (9): immediately terminates. The process has no chance to clean up. Use as last resort.

---

## Signals

Signals are messages the OS sends to processes. Some important ones:

| Signal | Number | Meaning |
|--------|--------|---------|
| SIGTERM | 15 | Please terminate (can be caught) |
| SIGKILL | 9 | Terminate NOW (cannot be caught) |
| SIGINT | 2 | Interrupt (Ctrl+C) |
| SIGTSTP | 20 | Pause (Ctrl+Z) |
| SIGHUP | 1 | Hangup (reload config for servers) |
| SIGUSR1 | 10 | User-defined (app-specific meaning) |

---

## stdin, stdout, stderr — Revisited

Every process gets three file descriptors automatically:

```
0 = stdin  — where it reads from
1 = stdout — where it writes normal output
2 = stderr — where it writes errors
```

These are just files. When you run a command in the terminal:
- stdin is connected to your keyboard
- stdout and stderr are connected to your screen

When you use `|`, the shell connects stdout of one process to stdin of the next. That's all a pipe is.

```bash
ls | grep ".rb"
```
What happens:
1. Shell creates two processes: `ls` and `grep`
2. Shell connects `ls`'s stdout to `grep`'s stdin
3. Both run at the same time
4. `ls` writes filenames → `grep` reads and filters → screen

### /dev/stdin and /dev/stdout

These device files let you redirect explicitly:

```bash
echo "hello" > /dev/stdout    # same as just echoing to screen
cat /dev/stdin                # reads from keyboard until Ctrl+D
```

### Here-strings and Here-documents

Sometimes you want to give a command a string as stdin without a file:

```bash
# Here-string: feed a single string as stdin
grep "hello" <<< "hello world"

# Here-document: multi-line stdin
cat << EOF
This is line 1
This is line 2
Today is $(date)
EOF
```

The `EOF` can be any word — it marks the end of the input.

---

## nohup — Keep Running After Logout

Normally, when you close your terminal, all your processes die (they receive SIGHUP).

```bash
nohup long-running-script.sh &
```

`nohup` makes the process ignore SIGHUP. Output goes to `nohup.out` by default.

---

## wait — Wait for Background Jobs

```bash
#!/bin/bash
# Run three things in parallel, wait for all

process_chunk.sh part1 &
process_chunk.sh part2 &
process_chunk.sh part3 &

wait    # wait for all background jobs to finish
echo "All done!"
```

---

## Pipe Internals — How it Really Works

When the shell runs `ls | grep ruby`, this is what actually happens:

1. Shell calls `pipe()` — creates a pipe (a buffer in memory)
2. Shell calls `fork()` — creates a copy of itself (child process)
3. Child process closes its stdin, connects it to the pipe's read end
4. Shell calls `fork()` again for the second command
5. Second process closes its stdout, connects it to the pipe's write end
6. Both processes call `exec()` to replace themselves with `ls` and `grep`
7. `ls` writes to stdout → goes into the pipe buffer → `grep` reads from stdin

You never see this. The shell does it all automatically when you type `|`. But understanding it explains why:
- Pipes are fast (in-memory, no disk)
- Pipes handle data as streams (one line at a time, not all at once)
- Processes in a pipeline run concurrently

---

## Exercises

1. Run `sleep 60 &` then immediately check `jobs` and `ps`. Find the PID. Kill it with `kill`.
2. Start a long command, pause it with Ctrl+Z, check `jobs`, resume with `fg`.
3. Run two processes in parallel with `&`, then `wait` for both. Time it vs running sequentially.
4. Start a process with `nohup`, close and reopen terminal, check if it's still running with `ps aux`.
5. Explain what happens, step by step, when you run: `cat file.txt | sort | uniq -c | sort -rn`

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| Process | a running program with PID, owner, streams |
| `ps aux` | see all processes |
| `&` | run in background |
| `jobs`, `fg`, `bg` | manage background jobs |
| `Ctrl+C` | interrupt, `Ctrl+Z` = pause |
| `kill` | send signals to processes |
| SIGTERM vs SIGKILL | polite stop vs forced stop |
| stdin/stdout/stderr | file descriptors 0, 1, 2 |
| `<<< "string"` | here-string: stdin from a string |
| `<< EOF` | here-document: multi-line stdin |
| `nohup` | survive terminal close |
| `wait` | wait for all background jobs |

---

## The Big Idea from This Chapter

Processes are the living, breathing units of Unix. They're created by forking, they communicate through streams, and they die with exit codes. The pipe is the genius mechanism that connects them — not by writing to files, but by connecting streams directly in memory. This is why Unix pipelines are so fast and so composable.
