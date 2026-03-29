# Understanding Unix
### A modern course inspired by *The Unix Programming Environment* — Kernighan & Pike (1984)

Kernighan's book is a classic. But it was written in 1984 — some explanations assume you already think like a programmer from that era.

This course takes the same ideas and explains them the way a friend would: clearly, with real examples, and without assuming anything.

---

## Who this is for

- You use a Mac or Linux machine
- You've opened Terminal before but aren't sure what's really happening
- You want to *understand* Unix, not just memorize commands

## What you'll learn

By the end of this course you'll understand:
- Why Unix works the way it does (the philosophy)
- How the filesystem really works
- How the shell executes your commands
- How to chain tools together into powerful pipelines
- How to write shell scripts that actually do useful things
- What happens under the hood when you run a program

## How to use this course

1. Read each chapter's `README.md`
2. Type the examples yourself — don't copy-paste, **type them**
3. Do the exercises at the end
4. Break things. Fix them. That's how you learn.

**You need:** a Mac or Linux terminal. That's it.

---

## Chapters

| # | Chapter | What you'll understand |
|---|---------|----------------------|
| 1 | [Getting Started](chapters/01_getting_started/) | What Unix is, your first commands, getting around |
| 2 | [The File System](chapters/02_filesystem/) | Everything is a file. What that actually means. |
| 3 | [The Shell](chapters/03_shell/) | What happens when you press Enter |
| 4 | [Filters & Pipelines](chapters/04_filters/) | The Unix superpower: chaining tools |
| 5 | [Shell Programming](chapters/05_shell_programming/) | Writing scripts that automate your life |
| 6 | [Processes & I/O](chapters/06_processes/) | Running programs, background jobs, streams |
| 7 | [Under the Hood](chapters/07_under_the_hood/) | Fork, exec, pipes — what Unix does internally |
| 8 | [Building Things](chapters/08_tools/) | Make, compilation, putting it all together |

---

## The Unix Philosophy

Before you start, understand this. It's three sentences:

> **Write programs that do one thing and do it well.**
> **Write programs that work together.**
> **Write programs that handle text streams.**

That's it. Everything in Unix flows from this. A command like `ls` does one thing: list files. `grep` does one thing: find lines. But when you connect them with a pipe (`|`), suddenly you can do anything.

This course is about understanding *why* that works so beautifully.
