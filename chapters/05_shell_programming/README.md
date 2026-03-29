# Chapter 5 — Shell Programming

## The Shell is a Programming Language

Everything you've typed so far — commands, pipes, variables — is already shell programming. A shell script is just those same things saved in a file so you can run them again.

Shell scripts are how Unix people automate their lives. Backup scripts, deployment scripts, data processing scripts — all shell.

---

## Your First Script

Create a file called `hello.sh`:

```bash
#!/bin/bash
echo "Hello, World!"
echo "Today is $(date)"
echo "You are $(whoami)"
```

The first line `#!/bin/bash` is called a **shebang**. It tells the OS which program should run this file. Always include it.

Make it executable and run it:

```bash
chmod +x hello.sh
./hello.sh
```

Why `./`? Because the shell only looks in `$PATH` for commands. `./` means "right here in this directory."

---

## Variables

```bash
#!/bin/bash

name="Yosia"
greeting="Hello"

echo "$greeting, $name!"
echo "Script name: $0"    # $0 = name of the script itself
echo "Arguments: $@"      # $@ = all arguments passed to the script
echo "Arg count: $#"      # $# = number of arguments
```

Run it: `./script.sh one two three`
```
Hello, Yosia!
Script name: ./script.sh
Arguments: one two three
Arg count: 3
```

### Positional parameters

```bash
#!/bin/bash
# greet.sh — say hello to someone
echo "Hello, $1! You are argument number one."
echo "Second arg: $2"
```

```bash
./greet.sh Yosia Ruby
# Hello, Yosia! You are argument number one.
# Second arg: Ruby
```

---

## Conditions: if/elif/else

```bash
#!/bin/bash

if [ "$1" = "hello" ]; then
  echo "You said hello!"
elif [ "$1" = "bye" ]; then
  echo "Goodbye!"
else
  echo "You said: $1"
fi
```

The `[ ]` is actually a command called `test`. It evaluates conditions and returns 0 (true) or 1 (false).

### Comparison operators

**String comparison:**
```bash
[ "$a" = "$b" ]    # equal
[ "$a" != "$b" ]   # not equal
[ -z "$a" ]        # $a is empty
[ -n "$a" ]        # $a is not empty
```

**Number comparison:**
```bash
[ $a -eq $b ]    # equal
[ $a -ne $b ]    # not equal
[ $a -lt $b ]    # less than
[ $a -gt $b ]    # greater than
[ $a -le $b ]    # less than or equal
[ $a -ge $b ]    # greater than or equal
```

**File tests:**
```bash
[ -f file.txt ]   # file exists and is a regular file
[ -d mydir ]      # directory exists
[ -e path ]       # path exists (file or directory)
[ -r file ]       # file is readable
[ -w file ]       # file is writable
[ -x file ]       # file is executable
[ -s file ]       # file exists and is not empty
```

```bash
#!/bin/bash
if [ -f "$1" ]; then
  echo "$1 is a file"
elif [ -d "$1" ]; then
  echo "$1 is a directory"
else
  echo "$1 doesn't exist"
fi
```

---

## Loops

### for loop

```bash
# Loop over a list
for name in Alice Bob Charlie; do
  echo "Hello, $name!"
done

# Loop over files
for file in *.txt; do
  echo "Processing: $file"
  wc -l "$file"
done

# Loop over arguments
for arg in "$@"; do
  echo "Got argument: $arg"
done

# C-style loop
for ((i=1; i<=5; i++)); do
  echo "Count: $i"
done
```

### while loop

```bash
# Count down
count=5
while [ $count -gt 0 ]; do
  echo "T-minus $count"
  count=$((count - 1))
done
echo "Blast off!"

# Read a file line by line
while IFS= read -r line; do
  echo "Line: $line"
done < input.txt

# Infinite loop (until broken)
while true; do
  echo "Still running... (Ctrl+C to stop)"
  sleep 1
done
```

---

## Functions

```bash
#!/bin/bash

# Define a function
greet() {
  local name="$1"           # local = only visible inside function
  echo "Hello, $name!"
}

# Call it
greet "Yosia"
greet "World"

# Function with return value
add() {
  echo $(( $1 + $2 ))      # echo the result
}

result=$(add 3 4)           # capture with $()
echo "3 + 4 = $result"
```

Functions can't `return` a value the way other languages do. They return an exit code (0-255). To pass back data, `echo` it and capture with `$()`.

---

## Exit Codes

Every command returns an exit code when it finishes:
- `0` = success
- non-zero = failure (any number 1-255)

```bash
ls /exists
echo $?       # => 0 (success)

ls /doesnt-exist
echo $?       # => 1 (failure)
```

In scripts, you should check exit codes:

```bash
#!/bin/bash

if ! mkdir "$1"; then
  echo "Error: couldn't create directory $1" >&2
  exit 1
fi

echo "Created $1 successfully"
exit 0
```

`>&2` sends the error message to stderr (the right place for errors).

---

## A Real Script: Backup

```bash
#!/bin/bash
# backup.sh — backup a directory with a timestamp

if [ $# -ne 2 ]; then
  echo "Usage: $0 source destination" >&2
  exit 1
fi

source="$1"
dest="$2"
timestamp=$(date +%Y-%m-%d_%H-%M-%S)
backup_name="backup_${timestamp}"

if [ ! -d "$source" ]; then
  echo "Error: $source is not a directory" >&2
  exit 1
fi

mkdir -p "$dest"
cp -r "$source" "$dest/$backup_name"

if [ $? -eq 0 ]; then
  echo "✅ Backup created: $dest/$backup_name"
else
  echo "❌ Backup failed" >&2
  exit 1
fi
```

---

## A Real Script: Find Big Files

```bash
#!/bin/bash
# bigfiles.sh — find files larger than N megabytes

limit="${1:-100}"   # default to 100MB if no argument
dir="${2:-.}"       # default to current directory

echo "Files larger than ${limit}MB in $dir:"
echo ""

find "$dir" -type f -size "+${limit}M" | while read -r file; do
  size=$(du -sh "$file" | cut -f1)
  echo "$size  $file"
done | sort -rh
```

---

## Handling Input

```bash
#!/bin/bash
# Ask user for input
echo -n "Enter your name: "
read name
echo "Hello, $name!"

# Read with a prompt
read -p "Enter your age: " age
echo "You are $age years old"

# Silent input (for passwords)
read -s -p "Password: " password
echo ""
echo "Got it (not showing it!)"
```

---

## String Operations

```bash
str="Hello, World!"

echo ${#str}           # length: 13
echo ${str:0:5}        # substring: Hello
echo ${str/World/Ruby} # replace: Hello, Ruby!
echo ${str,,}          # lowercase: hello, world!
echo ${str^^}          # uppercase: HELLO, WORLD!

filename="report.pdf"
echo ${filename%.pdf}  # remove suffix: report
echo ${filename#re}    # remove prefix: port.pdf
```

---

## Arithmetic

```bash
a=10
b=3

echo $(( a + b ))   # 13
echo $(( a - b ))   # 7
echo $(( a * b ))   # 30
echo $(( a / b ))   # 3 (integer division!)
echo $(( a % b ))   # 1 (remainder)
echo $(( a ** b ))  # 1000 (power)

# Increment
((a++))
echo $a   # 11
```

---

## Exercises

1. Write `count.sh` that counts lines, words, and chars in a given file and prints a summary
2. Write `rename_ext.sh` that renames all files with one extension to another: `./rename_ext.sh txt md`
3. Write `monitor.sh` that every 5 seconds prints the current time and how many files are in the current directory
4. Write `safe_rm.sh` that moves files to `~/.trash/` instead of deleting them permanently
5. Write `greet.sh` that takes a name as argument, defaults to `$USER` if no argument given

---

## What You Learned

| Concept | Syntax |
|---------|--------|
| Shebang | `#!/bin/bash` |
| Variables | `name="value"`, `$name` |
| Arguments | `$1`, `$2`, `$@`, `$#` |
| Condition | `if [ test ]; then ... fi` |
| File test | `[ -f file ]`, `[ -d dir ]` |
| For loop | `for x in list; do ... done` |
| While loop | `while [ cond ]; do ... done` |
| Function | `name() { ... }`, `local var` |
| Exit code | `$?`, `exit 0`, `exit 1` |
| Arithmetic | `$(( a + b ))` |
| String ops | `${#str}`, `${str:0:5}` |

---

## The Big Idea from This Chapter

Shell scripts are the glue of Unix systems. Every time you find yourself doing the same sequence of commands more than once, that's a script waiting to be written. Start simple — even a 3-line script that saves you retyping the same thing is worth it. Scripts grow over time into powerful automation tools.
