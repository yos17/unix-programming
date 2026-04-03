# Chapter 7 — Under the Hood

## What Actually Happens When You Type a Command?

Let's trace exactly what happens when you type `ls -la` and press Enter.

```
You type:  ls -la
           ↓
Shell reads it → parses it → finds /bin/ls → forks → execs → waits → prompt
```

Let's break down every step.

---

## Step 1: The Shell Reads and Parses

The shell reads your input character by character. It:
1. Splits it into **tokens**: `ls`, `-la`
2. Expands variables (`$HOME` → `/Users/yosia`)
3. Expands globs (`*.rb` → `a.rb b.rb c.rb`)
4. Handles quotes and escaping
5. Builds an **argument list**: `["ls", "-la"]`

All of this happens *before* any program runs. The command never sees `$HOME` — it sees the expanded value.

---

## Step 2: Fork

The shell calls `fork()`.

`fork()` is a Unix system call that **duplicates the current process**. After fork:
- There are now two identical processes
- The **parent** (shell) gets the child's PID
- The **child** (new process) gets 0

```
     Shell (PID 100)
          |
       fork()
          |
    ┌─────┴────────┐
    │              │
Shell (100)    Child (101)
gets PID 101   gets 0
waits...       executes ls
```

This is a weird but genius design. Instead of building complex machinery to create a new process from scratch, Unix just copies the existing one.

---

## Step 3: Exec

The child process calls `exec("ls", ["-la"])`.

`exec()` **replaces** the child's memory with a new program — it loads `/bin/ls` into the child's address space and starts running it from the beginning.

After exec:
- The process still has PID 101
- But it's now running `ls`, not the shell
- All the shell's code/data is gone
- The file descriptors (stdin, stdout, stderr) are inherited ← this is crucial

The child inherits the parent's file descriptors. This is how redirection works:
- Before exec, the shell can replace `fd 1` (stdout) with a file
- The child doesn't know — it just writes to fd 1 as usual
- But that fd 1 now points to the file

---

## Step 4: Wait

The parent shell calls `wait()`, which suspends the shell until the child finishes.

When `ls` finishes, it calls `exit(code)`. The kernel:
1. Sends SIGCHLD to the parent
2. Records the exit code
3. Cleans up the child process

`wait()` in the parent returns with the exit code. The shell stores it in `$?`. The prompt appears.

---

## How Pipes Work Internally

When you type `ls | grep txt`, here's what really happens:

1. Shell creates a **pipe** — two file descriptors: `pipe_read` and `pipe_write`
2. Shell forks child 1 (`ls`):
   - Replaces its stdout (fd 1) with `pipe_write`
   - Closes `pipe_read`
   - Execs `ls`
3. Shell forks child 2 (`grep`):
   - Replaces its stdin (fd 0) with `pipe_read`
   - Closes `pipe_write`
   - Execs `grep txt`
4. Shell closes both ends of pipe (it doesn't need them)
5. Shell waits for both children

```
ls stdout → pipe_write ══════ pipe_read → grep stdin
```

Both processes run simultaneously. When `ls` writes data, it goes into the pipe buffer. When `grep` reads, it gets that data. When `ls` finishes and closes `pipe_write`, `grep` sees EOF and finishes too.

---

## System Calls — The OS Interface

A **system call** is how a program asks the kernel to do something it can't do itself:
- Read/write files
- Create processes
- Allocate memory
- Send signals
- Open network connections

Key system calls you've seen indirectly:

| System call | What it does |
|-------------|-------------|
| `fork()` | duplicate the current process |
| `exec()` | replace process with a new program |
| `wait()` | wait for a child to finish |
| `open()` | open a file, get a file descriptor |
| `read()` | read bytes from a file descriptor |
| `write()` | write bytes to a file descriptor |
| `pipe()` | create a pipe, get two file descriptors |
| `dup2()` | copy a file descriptor (used for redirection) |
| `kill()` | send a signal to a process |
| `exit()` | terminate the current process |

You can watch system calls in real time with `strace` (Linux) or `dtruss` (macOS):

```bash
# Linux:
strace ls -la 2>&1 | head -30

# macOS (needs to disable SIP, or use dtrace):
sudo dtruss ls 2>&1 | head -30
```

You'll see every `open()`, `read()`, `write()`, `close()` call `ls` makes.

---

## File Descriptors

A **file descriptor** (fd) is just a small integer — an index into the process's table of open files.

```
Process file descriptor table:
  0 → stdin  (keyboard)
  1 → stdout (screen)
  2 → stderr (screen)
  3 → (a file you opened)
  4 → (another file)
  ...
```

When you open a file, you get back a number (3, 4, 5...). When you read/write, you use that number. When you close it, the slot is freed.

**Redirection is just dup2():**
```bash
command > file.txt
```
The shell does:
1. Opens `file.txt`, gets fd 3
2. `dup2(3, 1)` — makes fd 1 point to the same file as fd 3
3. Closes fd 3
4. Forks → execs `command`
5. `command` writes to fd 1, which now goes to `file.txt`

---

## The Kernel — What it Does

The **kernel** is the core of the OS. It:
- Manages all processes (scheduling, creating, killing)
- Manages memory (who gets what RAM)
- Manages the filesystem (files, directories, permissions)
- Manages devices (disks, keyboard, screen, network)
- Handles system calls (the interface between programs and hardware)

User programs (including the shell) run in **user space** and can't touch hardware directly. They ask the kernel via system calls.

```
Your program (user space)
    │
    │  system call (open, read, write, fork...)
    ▼
  Kernel (kernel space)
    │
    ▼
  Hardware (disk, network, CPU)
```

This separation is why a buggy program can't crash the whole system — the kernel enforces boundaries.

---

## The Shell is Just a Program

This is worth repeating: **the shell has no special powers**.

The shell (`/bin/zsh`, `/bin/bash`) is just a program like any other. It:
- Reads your input
- Parses it
- Calls `fork()` and `exec()` like any other program could

You could write your own shell. In fact, that's a famous programming exercise. Here's the core of a shell in pseudocode:

```
loop:
  print prompt
  read line
  parse into command + arguments
  if command == "cd": call chdir() directly (can't fork — why?)
  else:
    fork()
    if child:
      exec(command, arguments)
    if parent:
      wait()
```

Why can't `cd` be a separate program? Because `chdir()` changes the *current process*'s directory. If `cd` ran in a child process, only the child's directory would change. The parent shell would be unaffected. So `cd` must be a **builtin** — executed directly by the shell, not forked.

Same for `export`, `source`, `exit`, and other builtins.

---

## Exercises

1. Use `strace`/`dtruss` to watch `cat` read a file. How many system calls does it make?
2. Why is `cd` a shell builtin and not a standalone program? (Try to explain it in your own words.)
3. What happens to open file descriptors when you fork? Are they shared or copied?
4. Why does `grep` in a pipe know when `ls` is done? What signals/mechanisms are involved?
5. Write a prediction: if you do `ls 2>&1 1>/dev/null`, does stderr go to the file or the screen? Then test it. (Hint: order matters.)

---

## Solutions

### Exercise 1 — Watch cat read a file with strace/dtruss

```bash
# On Linux (strace):
strace cat /etc/hosts 2>&1 | head -40
# Look for: openat(), read(), write(), close() calls

# On macOS (dtruss — needs to run as root or SIP disabled):
sudo dtruss cat /etc/hosts 2>&1 | head -40

# Alternative on macOS without disabling SIP — use dtrace probes:
sudo dtrace -n 'syscall:::entry /execname == "cat"/ { printf("%s\n", probefunc); }' \
  -c "cat /etc/hosts" 2>/dev/null | sort | uniq -c | sort -rn | head -20

# What you'll see for 'cat file':
# open()/openat()  — opens the file, returns fd (e.g., 3)
# fstat()          — gets file info/size
# read()           — reads bytes from fd 3 (usually 4096 bytes at a time)
# write()          — writes to fd 1 (stdout)
# read()           — reads again (returns 0 bytes = EOF)
# close()          — closes the file descriptor
# exit_group()     — process exits

# Typical count: 10-30 system calls for a small file
```

### Exercise 2 — Why is cd a shell builtin?

`cd` must be a shell builtin because `chdir()` changes the **current working directory of the calling process**.

If `cd` were a separate executable:
```
Shell (PID 100, cwd=/home/yosia)
  └── forks child (PID 101, cwd=/home/yosia)
        └── exec(/bin/cd, ["cd", "Projects"])
              └── chdir("/home/yosia/Projects")
                    → changes PID 101's directory
                    → exits
Shell (PID 100) — still at cwd=/home/yosia! (unchanged)
```

The child process changes its own directory and exits. The parent shell never changes. That's why `cd` must run **inside** the shell process itself — as a builtin that calls `chdir()` directly without forking.

The same logic applies to: `export` (sets shell's own environment), `source`/`.` (runs script in current shell), `exit` (exits the shell itself), and `umask`.

### Exercise 3 — File descriptors after fork: shared or copied?

```bash
#!/bin/bash
# Demonstrate fd behavior across fork (using a shell script)

# Open a file and write to it from parent
exec 3> /tmp/test_fd.txt   # open fd 3 for writing

echo "parent writing line 1" >&3

# When shell runs a subcommand, it forks — child inherits fd 3
(echo "child writing line 2" >&3)

echo "parent writing line 3" >&3

exec 3>&-   # close fd 3
cat /tmp/test_fd.txt
# Shows all 3 lines — both parent and child write to the same file
```

**Answer:** File descriptors are **copied** (duplicated) on fork, not shared. Each process gets its own copy of the fd table, but both copies point to the **same underlying open file description** in the kernel (same file offset, same flags). So:
- Both parent and child can read/write the file independently
- Both see the same file position (they share the offset)
- Closing an fd in the child doesn't close it in the parent

### Exercise 4 — How does grep in a pipe know when ls is done?

```bash
ls | grep txt
```

The mechanism is **EOF on the pipe**:

1. Shell creates a pipe: `[write_end, read_end]`
2. `ls` gets `write_end` as its stdout; `grep` gets `read_end` as its stdin
3. Shell closes both ends in the parent (only the children hold them)
4. `ls` writes filenames to `write_end`
5. `grep` reads from `read_end`, processes each line
6. When `ls` finishes and exits, the kernel closes `write_end`
7. `grep`'s next `read()` on `read_end` returns **0 bytes** (EOF)
8. `grep` sees EOF, finishes, exits

**No signal is sent.** EOF is the mechanism — when all write ends of a pipe are closed, readers get EOF. This is why the shell closes its copies of the pipe fds in step 3 — otherwise `grep` would never see EOF (the shell's copy of `write_end` would still be open).

### Exercise 5 — Redirect ordering: ls 2>&1 1>/dev/null

```bash
# Prediction exercise:
ls /real_dir /fake_dir 2>&1 1>/dev/null
```

**Prediction:** stderr goes to the **screen**, stdout goes to `/dev/null`.

**Why:** Shell processes redirections **left to right**:
1. `2>&1` — make stderr (fd 2) point to the same place as stdout (fd 1) → currently the screen
2. `1>/dev/null` — make stdout (fd 1) point to `/dev/null`

After step 2, stdout is now `/dev/null`, but stderr was already set to "screen" in step 1. Changing stdout afterwards doesn't affect stderr.

**Test it:**
```bash
# Create a real directory
mkdir /tmp/real_dir

ls /tmp/real_dir /fake_dir 2>&1 1>/dev/null
# Output: ls: /fake_dir: No such file or directory
# (stderr shows on screen; stdout with real_dir contents is suppressed)

# To send BOTH to /dev/null:
ls /tmp/real_dir /fake_dir 1>/dev/null 2>&1   # note: reversed order!
# Or:
ls /tmp/real_dir /fake_dir &>/dev/null

rm -r /tmp/real_dir
```

The order of redirections is critical — right-to-left thinking doesn't work here. Each redirect is evaluated at the moment it's processed.

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| fork() | duplicates the current process |
| exec() | replaces current process with a new program |
| wait() | parent waits for child to finish |
| File descriptors | integers pointing to open files |
| Pipes | two fds connected; both processes run simultaneously |
| dup2() | how redirection is implemented |
| System calls | the only way to talk to the kernel |
| Kernel | manages everything; enforces boundaries |
| Shell builtins | `cd`, `export` must run inside the shell |

---

## The Big Idea from This Chapter

Three system calls — `fork`, `exec`, `wait` — are the foundation of everything Unix does. Every time you run a command, every time you use a pipe, every time you redirect output — it all comes back to these three. The elegance is that these primitives are so simple and composable that you can build any program execution model on top of them.
