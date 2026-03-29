# Chapter 3 — The Shell

## What the Shell Actually Is

When you open Terminal and type a command, something has to:
1. Read what you typed
2. Figure out what you mean
3. Find the right program
4. Run it
5. Show you the result

That something is the **shell**. It's just a program — a text-based interface that sits between you and the operating system.

On macOS you're probably using `zsh`. On Linux, usually `bash`. They're almost identical for everything in this chapter.

```bash
echo $SHELL   # which shell are you running?
# /bin/zsh
```

---

## How the Shell Finds Commands

When you type `ls`, where does the shell look?

```bash
which ls      # /bin/ls
which ruby    # /usr/local/bin/ruby
which python3 # /usr/bin/python3
```

The shell searches through directories listed in your `PATH` variable, in order, until it finds a match:

```bash
echo $PATH
# /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
```

This is a colon-separated list of directories. The shell checks each one, left to right.

**Why this matters:** if you install a new version of something, it needs to be in a directory that comes *before* the old version in `$PATH`.

---

## Variables

The shell has variables. They store text.

```bash
name="Yosia"          # set a variable (no spaces around =!)
echo $name            # => Yosia
echo "Hello, $name!"  # => Hello, Yosia!
echo 'Hello, $name!'  # => Hello, $name! (single quotes = no expansion)
```

**Single quotes** = everything literal, no substitution.
**Double quotes** = substitution happens, but spaces are preserved.

### Built-in variables

```bash
echo $HOME    # your home directory: /Users/yosia
echo $USER    # your username: yosia
echo $PATH    # command search path
echo $PWD     # current directory (same as pwd)
echo $SHELL   # which shell: /bin/zsh
echo $?       # exit code of last command (0 = success)
echo $$       # PID (process ID) of the current shell
```

### Setting variables permanently

```bash
# In ~/.zshrc (for zsh) or ~/.bashrc (for bash):
export MY_VAR="hello"
export PATH="$HOME/bin:$PATH"   # add ~/bin to the front of PATH
```

After editing `~/.zshrc`, run `source ~/.zshrc` to reload it.

---

## Redirection — Sending Output Somewhere

Every program has three streams:
- **stdin** (0) — input (usually your keyboard)
- **stdout** (1) — normal output (usually your screen)
- **stderr** (2) — error output (also your screen, but separate)

### Redirect stdout to a file

```bash
echo "hello" > output.txt     # write (overwrites if exists)
echo "world" >> output.txt    # append (adds to end)
ls -l >> log.txt              # append ls output to log
```

### Redirect stdin from a file

```bash
wc -l < notes.txt    # feed notes.txt as input to wc
```

### Redirect stderr

```bash
command 2>errors.txt          # send errors to file
command 2>/dev/null           # throw away errors
command >output.txt 2>&1      # send both stdout and stderr to file
command &>output.txt          # same thing, shorthand in bash/zsh
```

`2>&1` means "send file descriptor 2 (stderr) to the same place as file descriptor 1 (stdout)".

### The real power: pipes

```bash
command1 | command2
```

The `|` (pipe) connects the stdout of command1 directly to the stdin of command2. No files involved. Data flows in real time.

```bash
ls -l | less              # browse ls output one page at a time
cat notes.txt | grep TODO # find TODO lines in notes
ps aux | grep ruby        # find ruby processes
```

We'll go deep on pipes in Chapter 4.

---

## Quoting and Escaping

The shell interprets special characters. Sometimes you need to turn that off:

```bash
echo $HOME              # => /Users/yosia  (variable expanded)
echo "$HOME"            # => /Users/yosia  (same)
echo '$HOME'            # => $HOME         (literal)
echo \$HOME             # => $HOME         (backslash escapes one char)
```

Special characters that need quoting or escaping:
```
$   &   |   ;   (   )   <   >   `   \   "   '   !   #   *   ?   [ ]
```

```bash
echo "Hello (world)"     # parens are fine in double quotes
echo "She said \"hi\""   # escape quotes inside quotes
```

### Filename patterns (globbing)

The shell expands `*`, `?`, `[...]` before running the command:

```bash
ls *.rb         # all files ending in .rb
ls chapter-?.md # chapter-1.md, chapter-2.md, etc.
ls [abc]*       # files starting with a, b, or c
rm temp*.log    # delete all temp*.log files
```

This happens **in the shell** before the command sees it. So the command receives a list of actual filenames.

---

## Command Substitution

Run a command and use its output as part of another command:

```bash
echo "Today is $(date)"
# => Today is Fri Mar 28 14:00:00 CET 2026

files=$(ls *.rb)    # store result in variable
echo "Found: $files"

echo "Ruby is at $(which ruby)"
```

The `$(...)` syntax runs the inner command and substitutes its output.

---

## Semicolons and &&

Run multiple commands:

```bash
command1; command2         # run both, regardless of success
command1 && command2       # run command2 ONLY if command1 succeeded
command1 || command2       # run command2 ONLY if command1 FAILED
```

```bash
# Practical example:
mkdir new-project && cd new-project && git init
# Only creates and enters and inits if each step succeeds

# Safe delete:
rm file.txt || echo "File not found, skipping"
```

---

## The History

The shell remembers your past commands:

```bash
history           # show all past commands
history 20        # show last 20
!!                # run the last command again
!ls               # run the most recent command starting with "ls"
Ctrl+R            # search history interactively (type to search)
```

---

## Aliases — Your Own Commands

```bash
alias ll='ls -la'
alias gs='git status'
alias ..='cd ..'
alias ...='cd ../..'
```

Put these in `~/.zshrc` to make them permanent.

---

## The Prompt

Your prompt can show useful info. In `~/.zshrc`:

```bash
# Simple prompt showing user, machine, and current directory:
PS1="%n@%m %~ %% "

# Or use a theme (zsh has oh-my-zsh, bash has bash-it)
```

---

## Exercises

1. Add `~/bin` to your PATH permanently in `~/.zshrc`. Reload it. Verify with `echo $PATH`.
2. Run `ls /nonexistent 2>/dev/null` — what happens? Now without the redirect?
3. Save the output of `ls -la ~` to a file. Then count the lines with `wc -l`.
4. What's `$?` after a successful command? After a failed one?
5. Create aliases for your 3 most-used commands. Add them to `~/.zshrc`.
6. Use `Ctrl+R` to find and re-run a command from your history.
7. Try: `echo "Current dir has $(ls | wc -l) files"` — what does it print?

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| The shell | just a program that runs other programs |
| `$PATH` | where the shell looks for commands |
| Variables | `name="value"`, accessed as `$name` |
| `>` and `>>` | redirect output to file (overwrite/append) |
| `<` | redirect input from file |
| `2>` | redirect stderr |
| `\|` | pipe: connect stdout of one to stdin of next |
| Single vs double quotes | `'literal'` vs `"with $expansion"` |
| `*` glob | shell expands it to matching filenames |
| `$(command)` | run command, substitute output |
| `&&` | run next only if previous succeeded |

---

## The Big Idea from This Chapter

The shell is a **programmable glue**. It connects programs together using pipes and redirection, manages variables, and expands patterns. The shell does all this *before* your command even runs. Understanding that timing — what the shell processes vs. what the command receives — is key to writing commands that actually work.
