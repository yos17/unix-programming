# Chapter 8 — Building Things: make, compilation, and putting it all together

## The Problem make Solves

Imagine you have a project with 20 source files. You change one file. Do you need to rebuild all 20? No — only the files that depend on the changed file.

`make` is a tool that figures out the minimum work needed to update your project. It's been doing this since 1976.

---

## How make Works

You write a `Makefile` that describes:
- **Targets**: what to build
- **Dependencies**: what each target depends on
- **Recipes**: the commands to build each target

```makefile
target: dependency1 dependency2
	command to build target
```

⚠️ The indentation **must** be a TAB, not spaces. This is `make`'s most notorious quirk.

---

## A Simple Makefile

```makefile
# Makefile

# Build the program
hello: main.c utils.c
	gcc -o hello main.c utils.c

# Build just the object files
main.o: main.c
	gcc -c main.c

utils.o: utils.c
	gcc -c utils.c

# Clean up built files
clean:
	rm -f hello *.o

# Run the program
run: hello
	./hello
```

```bash
make           # builds the first target (hello)
make clean     # runs the clean target
make run       # builds hello if needed, then runs it
```

`make` checks timestamps: if `hello` is newer than `main.c` and `utils.c`, it skips the build. Smart.

---

## Make for Non-C Projects

`make` works for any project, not just C. Lots of Ruby/Python/JS projects use it:

```makefile
# Makefile for a shell scripting course

.PHONY: test install lint clean

install:
	brew install shellcheck

test:
	shellcheck scripts/*.sh
	ruby spec/software_tools_spec.rb

lint:
	shellcheck --severity=warning scripts/*.sh

clean:
	rm -f *.log tmp/*

docs:
	markdown README.md > docs/index.html
```

`.PHONY` tells make these targets don't produce files — they're just command names.

---

## Variables in Makefiles

```makefile
CC = gcc
CFLAGS = -Wall -O2
SRC = main.c utils.c helper.c
OBJ = $(SRC:.c=.o)    # replaces .c with .o
TARGET = myapp

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJ)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJ)
```

Special variables:
- `$@` — the target name
- `$<` — the first dependency
- `$^` — all dependencies
- `$(VAR:.old=.new)` — text substitution

---

## A Practical Makefile for Scripts

```makefile
# Makefile for our unix-programming course

CHAPTERS = 01_getting_started 02_filesystem 03_shell \
           04_filters 05_shell_programming 06_processes \
           07_under_the_hood 08_tools

SCRIPTS = $(wildcard scripts/*.sh)

.PHONY: all test check-scripts word-count clean help

all: check-scripts
	@echo "All checks passed!"

# Run shellcheck on all scripts
check-scripts: $(SCRIPTS)
	@echo "Checking shell scripts..."
	@for script in $(SCRIPTS); do \
		echo "  Checking $$script..."; \
		bash -n $$script || exit 1; \
	done
	@echo "All scripts OK"

# Word count for the course
word-count:
	@echo "Chapter word counts:"
	@for ch in $(CHAPTERS); do \
		count=$$(wc -w < chapters/$$ch/README.md); \
		echo "  $$ch: $$count words"; \
	done

# Test a specific script
test-%:
	bash -n scripts/$*.sh && echo "OK: $*.sh"

clean:
	rm -f *.log *.tmp

help:
	@echo "Available targets:"
	@echo "  make              - check all scripts"
	@echo "  make word-count   - count words in each chapter"
	@echo "  make clean        - remove temp files"
```

---

## How Programs Get Built (Brief)

Even if you never write C, understanding the build pipeline helps you understand how software works.

### The four stages of C compilation:

```
source.c → [preprocessor] → source_expanded.c
         → [compiler]     → source.s (assembly)
         → [assembler]    → source.o (machine code, unlinked)
         → [linker]       → myprogram (executable)
```

```bash
gcc -E source.c    # stop after preprocessor
gcc -S source.c    # stop after compiler (produces .s)
gcc -c source.c    # stop after assembler (produces .o)
gcc source.c       # all the way to executable
```

Interpreted languages (Ruby, Python) skip this — the interpreter reads source directly. But they still use compiled C libraries under the hood.

---

## Environment and Configuration

Putting it all together: how do programs find their configuration?

### Precedence (most to least important):
1. Command-line arguments (`--port 8080`)
2. Environment variables (`PORT=8080`)
3. Config files (`~/.myapp.conf`, `/etc/myapp.conf`)
4. Compiled-in defaults

```bash
# Different ways to configure the same thing:
ruby server.rb --port 8080
PORT=8080 ruby server.rb
echo "port=8080" >> ~/.serverconf && ruby server.rb
```

This layered approach is the Unix way — flexible, composable, scriptable.

---

## The Full Picture: A Day in the Life of a Command

Let's trace `grep "error" /var/log/system.log | sort | uniq -c | head -5` from start to finish:

```
1. You press Enter
2. Shell reads the line, tokenizes it into commands and operators
3. Shell parses the pipeline: 4 commands connected by 3 pipes

4. Shell creates 3 pipes (kernel buffers):
   pipe1: grep → sort
   pipe2: sort → uniq
   pipe3: uniq → head

5. Shell forks 4 child processes
   Each child:
   - Connects its stdin/stdout to the right pipe ends
   - Calls exec() to become grep/sort/uniq/head

6. grep opens /var/log/system.log (a system call: open)
   grep reads it line by line (system call: read)
   For each matching line, writes to stdout → pipe1 (system call: write)

7. sort reads from pipe1 (stdin)
   Buffers all lines in memory (because sort needs all input before sorting)
   When grep closes pipe1, sort sorts and writes to pipe2

8. uniq reads from pipe2
   Counts consecutive duplicates, writes to pipe3

9. head reads from pipe3
   After 5 lines, closes pipe3
   This causes SIGPIPE to propagate back up the pipeline
   Each upstream process exits

10. Shell calls wait() for all 4 children
11. All return exit code 0
12. Shell shows prompt
```

From your Enter key to the result on screen — all of that, in milliseconds.

---

## Exercises

1. Write a `Makefile` for the ruby-software-tools course: targets for `test`, `clean`, `word-count`
2. Add a `help` target that prints available targets
3. Use `make -n` (dry-run) on any Makefile to see what it would do without doing it
4. Trace `ls | wc -l` step by step: what system calls happen? (Use `strace` on Linux or `dtruss` on macOS)
5. Write a `Makefile` that generates a PDF from a markdown file using `pandoc`

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| `make` | build only what needs rebuilding |
| Makefile rule | `target: deps; recipe` |
| `.PHONY` | targets that aren't real files |
| `$@`, `$<`, `$^` | special make variables |
| Compilation stages | preprocess → compile → assemble → link |
| Config precedence | args > env vars > config files > defaults |

---

## The Big Idea from This Chapter — and the Course

Kernighan wrote this book to pass on a way of thinking, not just a set of commands.

Unix is built from small, sharp tools that do one thing and connect cleanly. The filesystem is a universal interface. The shell is programmable glue. Processes communicate through streams. Everything composes.

When you sit at a terminal now, you're not typing into a black box. You know what the shell does with your input, how processes are created and connected, how the filesystem organizes everything, and how signals and streams flow through the system.

That's what Kernighan wanted you to understand. You've got it.

---

## What's Next

Now that you understand Unix:
- **Learn a system language**: Go or Rust — you'll understand why they work the way they do
- **Learn networking**: sockets are just file descriptors
- **Learn containers**: Docker is just namespaced processes and filesystems
- **Go deeper**: read *Advanced Programming in the Unix Environment* (Stevens)

The foundation you built here scales infinitely.
