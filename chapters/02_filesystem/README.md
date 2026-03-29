# Chapter 2 — The File System

## The Most Important Idea in Unix: Everything is a File

This sounds weird at first. But it's the key to understanding everything.

In Unix:
- A text document? A file.
- A directory? A file (that contains other files).
- Your keyboard? A file (`/dev/stdin`).
- Your screen? A file (`/dev/stdout`).
- A network connection? A file.
- A running process? Kind of a file (in `/proc` on Linux).

Why does this matter? Because once everything is a file, the same tools work on everything. `cat` reads a text file. But it also reads from your keyboard. The same command. The same tool. This is the genius of Unix.

---

## The Directory Tree

The Unix filesystem is a single tree, starting at `/` (called "root"):

```
/
├── bin/        — essential commands (ls, cat, cp...)
├── etc/        — configuration files
├── home/       — user home directories (Linux)
│   └── yosia/
├── Users/      — user home directories (macOS)
│   └── yosia/
├── tmp/        — temporary files (wiped on restart)
├── usr/        — user programs and libraries
│   ├── bin/    — more commands (grep, find, ruby...)
│   └── local/  — things you installed yourself
├── var/        — variable data (logs, databases)
│   └── log/    — log files
└── dev/        — devices (your keyboard, screen, disk)
```

There's no `C:\` or `D:\` like Windows. Everything hangs off one `/`. Even other disks get "mounted" somewhere in this tree.

### Paths

A **path** is the address of a file:

**Absolute path** — starts from `/`, works from anywhere:
```
/Users/yosia/Projects/my-app/README.md
```

**Relative path** — relative to where you currently are:
```
Projects/my-app/README.md    # if you're in /Users/yosia
../other-project/             # go up one, then into other-project
./script.sh                   # ./ means "right here"
```

---

## Permissions — Who Can Do What

Every file has permissions. Run `ls -l` and you see:

```
-rw-r--r--  1 yosia  staff  1234 Mar 28 14:00 notes.txt
drwxr-xr-x  3 yosia  staff    96 Mar 28 12:00 Projects
```

The first 10 characters are the permission string. Let's decode it:

```
- rw- r-- r--
│ │   │   │
│ │   │   └── others: read only
│ │   └────── group: read only
│ └────────── owner (you): read + write
└──────────── type: - = file, d = directory, l = symlink
```

Three permission bits for each of three groups:
- `r` = read (can see the contents)
- `w` = write (can change it)
- `x` = execute (can run it as a program)

For directories, `x` means "can enter this directory" (cd into it).

### Changing permissions

```bash
chmod +x script.sh    # add execute permission
chmod -w notes.txt    # remove write permission (make read-only)
chmod 755 script.sh   # set exact permissions with numbers
```

The number system (octal):
```
7 = rwx (4+2+1)
6 = rw- (4+2)
5 = r-x (4+1)
4 = r-- (4)
0 = --- (nothing)
```

So `755` means: owner=rwx, group=r-x, others=r-x.
A typical script: `755`. A private file: `600` (owner read/write only).

### Who owns a file?

```bash
ls -l notes.txt
# -rw-r--r--  1 yosia  staff  1234 ...
```

`yosia` = owner. `staff` = group.

```bash
chown yosia:staff notes.txt   # change owner and group
sudo chown root notes.txt     # need sudo to change to root
```

---

## The Special Files in `/dev`

```bash
ls /dev
```

You'll see hundreds of entries. Important ones:

| File | What it is |
|------|-----------|
| `/dev/stdin` | your keyboard input |
| `/dev/stdout` | your screen output |
| `/dev/stderr` | error output (also screen, but separate) |
| `/dev/null` | a black hole — anything written here disappears |
| `/dev/random` | generates random bytes |
| `/dev/disk0` | your main hard drive |

The black hole is genuinely useful:
```bash
command 2>/dev/null   # throw away error messages
command >/dev/null    # throw away all output (run silently)
```

---

## Hard Links and Symbolic Links

### Hard link

```bash
ln original.txt hardlink.txt
```

A hard link is another name for the **same file**. Both names point to the same data on disk. If you delete `original.txt`, the data still exists via `hardlink.txt`.

```bash
ls -li original.txt hardlink.txt
# 123456 -rw-r--r--  2 yosia staff 100 ... original.txt
# 123456 -rw-r--r--  2 yosia staff 100 ... hardlink.txt
```

Notice: same inode number (123456), and the link count is `2`.

### Symbolic link (symlink)

```bash
ln -s /Users/yosia/Projects projects
```

A symlink is a shortcut — a pointer to another path. If the original is deleted, the symlink breaks (becomes a "dangling symlink").

```bash
ls -l projects
# lrwxr-xr-x  1 yosia staff  20 ... projects -> /Users/yosia/Projects
```

The `l` at the start and the `->` tell you it's a symlink.

---

## Inodes — The Real File System

Here's what's actually happening under the hood:

Every file has an **inode** (index node) — a small data structure that stores:
- File size
- Owner, group
- Permissions
- Timestamps (created, modified, accessed)
- Pointers to where the actual data is on disk

The filename is NOT stored in the inode. Filenames live in **directories**, which are just files that map names to inode numbers.

```bash
ls -i          # show inode numbers
stat notes.txt # show full inode info
```

This is why:
- Hard links work: two names → same inode
- Renaming is instant: just change the directory entry, don't move data
- `rm` doesn't erase data immediately: it just removes the directory entry and decrements the link count; data is erased when count reaches 0

---

## Finding Files

```bash
find . -name "*.rb"              # find all .rb files from here down
find . -name "*.log" -type f     # only files, not directories
find /tmp -mtime +7              # files modified more than 7 days ago
find . -size +1M                 # files larger than 1 megabyte
find . -name "*.tmp" -delete     # find and delete
```

`find` is powerful but its syntax is quirky. It walks the whole directory tree.

---

## Disk Usage

```bash
df -h          # how much space on each disk/partition
du -sh *       # size of each item in current directory
du -sh ~       # total size of your home directory
```

`-h` = human readable (shows KB, MB, GB instead of raw bytes).

---

## Exercises

1. What is the inode number of `/etc/hosts`? Use `ls -i`.
2. Create a file, make a hard link to it, edit the original — does the hard link show the change?
3. Create a symlink to your Desktop. Navigate via the symlink. What does `pwd` show?
4. Find all `.log` files on your system under `/var/log`. How many are there?
5. What permissions does `/etc/hosts` have? Who can write to it?
6. Use `du -sh *` in your home directory — what's taking the most space?

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| Everything is a file | keyboard, screen, devices — all accessed like files |
| The tree | one root `/`, everything hangs off it |
| Paths | absolute (`/Users/yosia/...`) vs relative (`../other`) |
| Permissions | `rwx` for owner, group, others |
| `/dev/null` | the black hole — discard unwanted output |
| Hard links | two names, one file |
| Symlinks | a pointer/shortcut to another path |
| Inodes | the real metadata behind every file |

---

## The Big Idea from This Chapter

The filesystem isn't just storage. It's a **universal interface**. Because everything is a file, you can use the same handful of tools (`cat`, `cp`, `ls`, `rm`) on text documents, configuration, devices, and more. This uniformity is what makes Unix so powerful and learnable.
