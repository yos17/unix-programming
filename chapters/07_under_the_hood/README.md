# Chapter 7 — Under the Hood

## What Actually Happens When You Type a Command

You've been using `ls`, `grep`, and pipes. Now let's open the hood and see the engine.

When you press Enter after typing a command, a precise sequence of events happens. Understanding this sequence is understanding Unix.

---

## The Three System Calls: fork, exec, wait

Almost everything in Unix processes comes down to three system calls:

### fork() — Make a Copy

`fork()` creates an exact copy of the current process. The copy is called the **child**. The original is the **parent**.

```
Parent process
      |
   fork()
     / \
Parent  Child
(keeps  (exact copy,
running) runs independently)
```

After fork, both processes are running the same code. How do they know which is which?

- fork() returns the **child's PID** to the parent
- fork() returns **0** to the child

```
if (fork() == 0):
    # I am the child
else:
    # I am the parent
```

### exec() — Become a Different Program

`exec()` replaces the current process with a new program. It doesn't create a new process — it *transforms* the current one. The PID stays the same, but the code, data, and stack are replaced.

```
shell process (PID 1234)
        |
     exec("ls")
        |
ls process (still PID 1234, but now running ls code)
```

### wait() — Wait for a Child

The parent calls `wait()` to pause until a child process finishes. This is how the shell knows when your command is done before showing the next prompt.

---

## Putting It Together: Running a Command

When you type `ls` and press Enter, here's exactly what happens:

```
1. Shell reads your input: "ls"

2. Shell calls fork()
   ├── Parent (shell): stores child's PID, calls wait()
   └── Child (new process):
       a. Looks up "ls" in $PATH → finds /bin/ls
       b. Calls exec("/bin/ls")
       c. Process is now running ls
       d. ls lists files, writes to stdout
       e. ls finishes, exits with code 0

3. Parent (shell) receives exit code from wait()
4. Shell shows prompt again
```

That's it. Every command you run goes through this cycle.

---

## How Pipes Work Internally

When you run `ls | grep .rb`, the shell does:

```
1. Create a pipe: two file descriptors
   - pipe_read  (fd 3)
   - pipe_write (fd 4)

2. Fork child #1 (for ls):
   - Close stdout (fd 1)
   - Replace stdout with pipe_write (fd 4)
   - exec("ls")
   → ls writes to stdout → goes into pipe

3. Fork child #2 (for grep):
   - Close stdin (fd 0)
   - Replace stdin with pipe_read (fd 3)
   - exec("grep", ".rb")
   → grep reads from stdin ← comes from pipe

4. Both run concurrently
5. When ls finishes, it closes the pipe write end
6. grep sees EOF on stdin, finishes too
7. Shell waits for both, shows prompt
```

The pipe is a kernel buffer — data flows through memory, not disk. This is why pipelines are fast.

---

## File Descriptors

Every process has a table of **file descriptors** — small integers that represent open files/pipes/connections.

```
FD 0 → stdin  (keyboard)
FD 1 → stdout (screen)
FD 2 → stderr (screen)
FD 3 → (next open file)
FD 4 → (etc.)
```

When you open a file in a program, you get the next available number. When you close it, that number becomes available again.

**Redirection** (`>`, `<`, `2>`) works by changing which file descriptors point to before exec:

```bash
ls > output.txt
```
Shell does:
1. Open `output.txt` → gets fd 3
2. Close fd 1 (stdout)
3. Duplicate fd 3 as fd 1 (`dup2(3, 1)`)
4. Fork + exec ls
5. ls writes to fd 1 → goes to output.txt

ls doesn't know or care. It just writes to "stdout". The shell arranged it.

---

## The /proc Filesystem (Linux)

On Linux, you can inspect running processes through `/proc`:

```bash
ls /proc              # one directory per PID
ls /proc/$$           # your current shell's info
cat /proc/$$/status   # process info
cat /proc/$$/maps     # memory layout
ls /proc/$$/fd        # open file descriptors
cat /proc/$$/cmdline  # command that was run
```

On macOS, use `lsof` instead:
```bash
lsof -p $$            # open files for current shell
lsof -i :8080         # what's using port 8080
```

---

## Environment Variables

Every process inherits a copy of environment variables from its parent:

```bash
export MY_VAR="hello"
ruby -e 'puts ENV["MY_VAR"]'   # => hello
```

`export` marks a variable to be inherited by child processes. Without `export`, it's only visible in the current shell.

```bash
MY_VAR="hello" ruby -e 'puts ENV["MY_VAR"]'   # set just for this command
```

This is why `.env` files exist — they set environment variables that your app inherits.

---

## The Kernel vs. User Space

Unix has two modes:

**User space**: where your programs run. Limited access to hardware.

**Kernel space**: the OS itself. Full access to everything.

When your program needs to do something real (read a file, create a process, open a network connection), it makes a **system call** — a request to the kernel.

```
Your program: "Please read 100 bytes from this file"
         ↓ system call (read)
Kernel: reads from disk, copies bytes to your process memory
         ↓ returns
Your program: here are your bytes
```

System calls are the API of Unix. Everything else is built on top of them.

Common system calls:
- `open`, `read`, `write`, `close` — file I/O
- `fork`, `exec`, `wait`, `exit` — process management
- `pipe`, `socket` — communication
- `stat`, `mkdir`, `unlink` — filesystem

---

## Zombie and Orphan Processes

**Zombie process**: a process that has finished but whose parent hasn't called `wait()` yet. It exists only to hold the exit code. Good parents call `wait()`.

```bash
ps aux | grep "Z"   # look for zombie processes (STAT = Z)
```

**Orphan process**: a process whose parent died before it. The kernel gives it a new parent: PID 1 (init/launchd). Orphans are adopted.

---

## Exercises

1. Run `sleep 30 &` and quickly do `ls -l /proc/$!` (Linux) or `lsof -p $!` (macOS). What do you see?
2. What is the PID of your shell? What is its parent PID? Trace the parent chain up.
3. Run `strace ls` (Linux) or `dtruss ls` (macOS) — this shows every system call ls makes. What do you see?
4. Create a pipe manually in bash: `exec 3<>/tmp/mypipe` — what happens?
5. What's the difference between `MY_VAR=hello command` vs `export MY_VAR=hello`?

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| `fork()` | copy a process |
| `exec()` | replace process with a new program |
| `wait()` | parent waits for child |
| File descriptors | integers (0,1,2 = stdin/out/err) |
| How pipes work | kernel buffer, fd duplication |
| How redirection works | changing fd targets before exec |
| `/proc` | live view of process internals (Linux) |
| `lsof` | list open files (macOS) |
| Zombie | finished process, parent hasn't waited |
| Orphan | process whose parent died (adopted by PID 1) |
| System call | request from user space to kernel |

---

## The Big Idea from This Chapter

Unix's elegance comes from its simplicity. Three system calls — fork, exec, wait — are the foundation of everything. Every command you run, every pipeline, every background job, every shell script, all of it is just clever orchestration of these three primitives. Once you understand that, the whole system makes sense.
