# Chapter 1 — Getting Started

## What is Unix, really?

Unix is not just an operating system. It's a *way of thinking* about computing.

In the 1970s, Ken Thompson and Dennis Ritchie at Bell Labs built something unusual: an OS where:
- Every tool does one small thing
- Tools talk to each other through text
- Everything — files, devices, network connections — looks like a file
- The shell is just another program, not magic

That last one surprises people. The shell — the thing you type commands into — is just a normal program. It reads your input, figures out what you mean, and runs other programs. That's it.

macOS is Unix under the hood. When you open Terminal, you're using the real Unix that Kernighan wrote about.

---

## Your First Session

Open Terminal. You'll see something like:
```
yosia@MacBook ~ %
```

This is called the **prompt**. It's telling you:
- `yosia` — who you are
- `MacBook` — which machine you're on
- `~` — where you are (`~` means your home directory)
- `%` — "I'm ready, type something" (bash uses `$`)

### Who am I?

```bash
whoami
```
Output: `yosia` (or whatever your username is)

### What time is it?

```bash
date
```
Output: `Fri Mar 28 14:00:00 CET 2026`

### Where am I?

```bash
pwd
```
`pwd` = **p**rint **w**orking **d**irectory. It prints the full path of where you currently are.

Output: `/Users/yosia`

---

## Moving Around

The filesystem is a tree of directories (folders). You navigate it like moving through a building.

### See what's here

```bash
ls
```
Lists files and directories in your current location.

```bash
ls -l
```
The `-l` flag means "long format" — shows more details:
```
-rw-r--r--  1 yosia  staff  4096 Mar 28 14:00 notes.txt
drwxr-xr-x  5 yosia  staff   160 Mar 28 12:00 Projects
```

Reading this:
- First character: `-` = file, `d` = directory
- Next 9 characters: permissions (we'll learn this in Ch2)
- Number: how many links
- `yosia`: who owns it
- `staff`: which group
- `4096`: size in bytes
- Date: when last modified
- Name

```bash
ls -la
```
`-a` shows **hidden files** (files starting with `.`). You'll see `.zshrc`, `.gitconfig`, etc. These are config files apps store in your home directory.

### Go somewhere

```bash
cd Projects
```
`cd` = **c**hange **d**irectory. Now `pwd` shows `/Users/yosia/Projects`.

```bash
cd ..
```
`..` means "one level up" (parent directory). Goes back to `/Users/yosia`.

```bash
cd ~
```
`~` always means your home directory. No matter where you are, `cd ~` brings you home.

```bash
cd /
```
Goes to the **root** — the very top of the filesystem. `ls` here shows: `bin`, `etc`, `usr`, `var`, `tmp`...

```bash
cd -
```
Goes back to where you just were. Like the "back" button.

---

## Looking at Files

### Print a file's contents

```bash
cat README.md
```
`cat` = con**cat**enate. It reads files and prints them to the screen. Originally designed to join files together, but mostly used to read one file.

### Read a long file one page at a time

```bash
less README.md
```
`less` lets you scroll through a file:
- `Space` — next page
- `b` — previous page
- `/word` — search for "word"
- `q` — quit

> Why is it called `less`? Because there was a tool called `more` (show more of the file). Someone made a better version and called it `less` — as in "less is more".

### Just the first few lines

```bash
head README.md
```
Shows first 10 lines. `head -n 5 README.md` shows first 5.

### Just the last few lines

```bash
tail README.md
```
Shows last 10 lines. Useful for log files:
```bash
tail -f /var/log/system.log
```
`-f` means "follow" — keeps watching and shows new lines as they appear.

---

## Creating Things

### Create a directory

```bash
mkdir my-project
mkdir -p deep/nested/directory
```
`-p` creates parent directories if they don't exist.

### Create a file

```bash
touch hello.txt
```
`touch` creates an empty file (or updates the timestamp if it exists).

```bash
echo "hello world" > hello.txt
```
`echo` prints text. `>` redirects output into a file. Together: write "hello world" into `hello.txt`. (We'll learn all about `>` in Ch3.)

### Copy a file

```bash
cp hello.txt hello-copy.txt
cp -r Projects Projects-backup
```
`-r` = recursive, needed for directories.

### Move or rename

```bash
mv hello.txt goodbye.txt
mv goodbye.txt ~/Desktop/
```
`mv` does both moving AND renaming.

### Delete

```bash
rm hello-copy.txt
rm -r old-project/
```
⚠️ **Warning:** There is no Trash in the terminal. `rm` is permanent. There's no undo. Be careful.

---

## Getting Help

Unix has built-in manuals for every command:

```bash
man ls
man grep
man man
```

`man` = **man**ual. Press `q` to quit.

The manual is dense. A friendlier approach:

```bash
ls --help
grep --help
```

Or just search what you need online — that's what everyone does.

---

## The `echo` command

`echo` just prints what you give it:

```bash
echo hello
echo "hello world"
echo "My home is $HOME"
```

`$HOME` is a **variable** — the shell replaces it with the actual value before running the command. More on variables in Ch3.

---

## Exercises

Try these yourself. Don't look at answers first.

1. What's in your home directory? List it with details.
2. How many files are in `/usr/bin`? (hint: `ls /usr/bin | wc -l`)
3. Find the biggest file in your home directory with `ls -lS ~` — what's `-S` doing?
4. Create a directory called `unix-practice`, go into it, create 3 files, list them, go back up, and delete the whole directory with `rm -r unix-practice`
5. Read the first 5 lines of `/etc/hosts` — what's in there?
6. Run `date` and save the output to a file called `timestamp.txt`. Then read it with `cat`.

---

## What You Learned

| Command | What it does |
|---------|-------------|
| `whoami` | print your username |
| `date` | print current date/time |
| `pwd` | print current directory |
| `ls`, `ls -l`, `ls -la` | list files |
| `cd dir`, `cd ..`, `cd ~` | change directory |
| `cat file` | print file contents |
| `less file` | read file page by page |
| `head`, `tail` | first/last N lines |
| `mkdir`, `touch` | create directory/file |
| `cp`, `mv`, `rm` | copy, move, delete |
| `echo` | print text |
| `man command` | read the manual |

---

## Solutions

### Exercise 1 — List home directory with details

```bash
# $ ls -la ~
ls -la ~
# Shows all files (including hidden dotfiles) with permissions, owner, size, date
# Look for files starting with . — those are hidden config files like .zshrc, .gitconfig
```

### Exercise 2 — Count files in /usr/bin

```bash
# $ ls /usr/bin | wc -l
ls /usr/bin | wc -l
# ls outputs one name per line when piped; wc -l counts those lines
# Typical result: 1000+ commands
```

### Exercise 3 — Find the biggest file in home directory

```bash
# $ ls -lS ~
ls -lS ~
# -S sorts by file size, largest first
# -l shows size in bytes in the 5th column
# The first entry after "total" is the biggest file
```

What `-S` does: sorts the listing by file size in descending order (biggest first).

### Exercise 4 — Create, populate, and delete a practice directory

```bash
#!/bin/bash
# Create directory and enter it
mkdir unix-practice
cd unix-practice

# Create 3 files
touch file1.txt file2.txt file3.txt

# List them
ls -l

# Go back up
cd ..

# Delete the whole directory
rm -r unix-practice

# Verify it's gone
ls -d unix-practice 2>/dev/null || echo "unix-practice is gone"
```

### Exercise 5 — Read first 5 lines of /etc/hosts

```bash
# $ head -n 5 /etc/hosts
head -n 5 /etc/hosts
```

What's in `/etc/hosts`: A static hostname-to-IP mapping file. The OS checks here before DNS.
Common entries:
- `127.0.0.1 localhost` — loopback address
- `::1 localhost` — IPv6 loopback
- `127.0.0.1 myapp.local` — entries developers add for local development

### Exercise 6 — Save date output to a file and read it back

```bash
# Save the current date/time to a file
date > timestamp.txt

# Read it back
cat timestamp.txt

# Or do both in sequence
date > timestamp.txt && cat timestamp.txt
```

---

## The Big Idea from This Chapter

Unix commands are **small, simple, and composable**.

`ls` just lists. `cat` just reads. `echo` just prints. None of them do much on their own. But in Chapter 4, you'll see what happens when you connect them — and that's when it gets interesting.
