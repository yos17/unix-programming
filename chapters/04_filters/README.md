# Chapter 4 — Filters & Pipelines

## The Unix Superpower

This is the chapter where Unix starts to feel like magic.

A **filter** is a program that:
- Reads text from stdin
- Transforms it somehow
- Writes the result to stdout

The Unix toolkit has dozens of small filters. Each does one thing. But when you connect them with pipes, you can answer almost any question about text data — without writing a single program.

---

## grep — Find Lines Matching a Pattern

`grep` = **g**lobally search for a **r**egular **e**xpression and **p**rint

```bash
grep "error" logfile.txt          # lines containing "error"
grep -i "error" logfile.txt       # case-insensitive
grep -n "error" logfile.txt       # show line numbers
grep -v "error" logfile.txt       # lines NOT containing "error"
grep -r "TODO" ~/Projects/        # search recursively through dirs
grep -l "TODO" *.rb               # just list filenames, not lines
grep -c "error" logfile.txt       # count matching lines
grep "^def " *.rb                 # lines starting with "def "
grep "\.rb$" file.txt             # lines ending with ".rb"
```

### Patterns (regular expressions)

```
.       any single character
*       zero or more of the previous
^       start of line
$       end of line
[abc]   any of a, b, c
[a-z]   any lowercase letter
[^abc]  anything except a, b, c
\b      word boundary
```

```bash
grep "^$" file.txt          # blank lines
grep "^[0-9]" file.txt      # lines starting with a digit
grep -E "cat|dog" file.txt  # lines with "cat" OR "dog" (-E for extended regex)
```

---

## sort — Sort Lines

```bash
sort names.txt              # alphabetical
sort -r names.txt           # reverse
sort -n numbers.txt         # numeric sort (not alphabetical!)
sort -u names.txt           # sort + remove duplicates
sort -k 2 data.txt          # sort by 2nd field (whitespace-separated)
sort -t: -k 3 -n /etc/passwd  # sort by 3rd field, colon-delimited, numeric
```

Why `-n` matters:
```bash
printf "10\n3\n25\n1\n" | sort      # wrong: 1, 10, 25, 3 (alphabetical)
printf "10\n3\n25\n1\n" | sort -n   # right: 1, 3, 10, 25
```

---

## uniq — Remove Duplicate Lines

```bash
sort names.txt | uniq         # remove adjacent duplicates (sort first!)
sort names.txt | uniq -c      # count occurrences
sort names.txt | uniq -d      # show only lines that appear more than once
sort names.txt | uniq -u      # show only lines that appear exactly once
```

`uniq` only removes **adjacent** duplicates — that's why you almost always `sort` first.

---

## wc — Count Things

```bash
wc file.txt           # lines, words, characters
wc -l file.txt        # lines only
wc -w file.txt        # words only
wc -c file.txt        # characters (bytes)
ls *.rb | wc -l       # how many .rb files?
```

---

## cut — Extract Columns

```bash
cut -d: -f1 /etc/passwd          # 1st field, colon-delimited
cut -d, -f1,3 data.csv           # fields 1 and 3 from CSV
cut -c1-10 file.txt              # first 10 characters of each line
cut -c10- file.txt               # from character 10 to end
```

---

## paste — Combine Columns

```bash
paste file1.txt file2.txt        # merge files side by side (tab-separated)
paste -d, file1.txt file2.txt    # comma-separated
```

---

## tr — Translate Characters

```bash
echo "hello" | tr 'a-z' 'A-Z'   # lowercase to uppercase
echo "hello" | tr -d 'aeiou'    # delete vowels
echo "hello" | tr -s ' '        # squeeze multiple spaces to one
cat file.txt | tr '\n' ' '       # replace newlines with spaces
```

---

## sed — Stream Editor

`sed` applies editing operations to each line as it streams through:

```bash
sed 's/old/new/' file.txt        # replace first "old" with "new" on each line
sed 's/old/new/g' file.txt       # replace ALL occurrences (g = global)
sed 's/old/new/gi' file.txt      # global + case-insensitive
sed '/^#/d' file.txt             # delete lines starting with #
sed -n '/error/p' file.txt       # print only lines matching "error"
sed '1,5d' file.txt              # delete lines 1 through 5
sed 's/  */ /g' file.txt         # squeeze multiple spaces to one
```

In-place editing (modify the file directly):
```bash
sed -i '' 's/foo/bar/g' file.txt    # macOS
sed -i 's/foo/bar/g' file.txt       # Linux
```

---

## awk — The Swiss Army Knife

`awk` is a small programming language for processing structured text:

```bash
awk '{print $1}' file.txt          # print first field
awk '{print $NF}' file.txt         # print last field ($NF = number of fields)
awk -F: '{print $1, $3}' /etc/passwd  # colon-delimited, print fields 1 and 3
awk '{sum += $1} END {print sum}' numbers.txt   # sum a column of numbers
awk 'NR > 5' file.txt              # print from line 6 onwards (NR = line number)
awk '/error/ {print NR, $0}' log   # print line number + line for matches
awk '{print NR": "$0}' file.txt    # number every line
```

`awk` sees each line as fields separated by whitespace (or a delimiter you specify with `-F`).

---

## The Pipeline: Putting It All Together

This is where the magic happens. Real examples:

### Word frequency counter
```bash
cat essay.txt | tr -s ' \t\n' '\n' | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -20
```
What each step does:
1. `tr -s ' \t\n' '\n'` — put each word on its own line
2. `tr 'A-Z' 'a-z'` — lowercase everything
3. `sort` — group identical words
4. `uniq -c` — count occurrences
5. `sort -rn` — sort by count, highest first
6. `head -20` — show top 20

### Find all TODO comments in your code
```bash
grep -rn "TODO\|FIXME\|HACK" ~/Projects/ | grep -v ".git" | sort
```

### Find the 10 largest files in a directory
```bash
du -sh * | sort -rh | head -10
```

### Count lines of code by file type
```bash
find . -name "*.rb" | xargs wc -l | sort -rn | head -20
```

### Find which processes are using the most memory
```bash
ps aux | sort -k4 -rn | head -10
```

### Extract all email addresses from a file
```bash
grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' file.txt | sort -u
```

### Show git log as a simple list
```bash
git log --oneline | head -20
```

### Find duplicate files by size
```bash
find . -type f | xargs ls -l | awk '{print $5, $9}' | sort | uniq -d -w 10
```

---

## xargs — Turn Lines into Arguments

Sometimes you have a list of things (one per line) and want to run a command on each:

```bash
find . -name "*.log" | xargs rm              # delete all found files
find . -name "*.rb" | xargs grep "TODO"      # grep in all found files
cat hosts.txt | xargs ping -c 1             # ping each host
```

`xargs` takes stdin, splits it into arguments, and passes them to a command.

---

## Exercises

Build these pipelines yourself:

1. Count how many unique words are in this chapter's README (ignore case)
2. Find the 5 most common words in `/usr/share/dict/words` that start with "un"
3. List all running processes, sorted by memory usage (use `ps aux`)
4. Find all `.rb` files in `~/Projects`, count total lines of code
5. Extract all unique IP addresses from `/var/log/system.log` (or any log)
6. Find lines in `/etc/hosts` that aren't blank and don't start with `#`
7. Use `awk` to sum the second column of this data:
   ```
   Alice 85
   Bob 92
   Charlie 78
   ```

---

## What You Learned

| Tool | What it does |
|------|-------------|
| `grep` | find lines matching a pattern |
| `sort` | sort lines (alpha, numeric, by field) |
| `uniq` | remove/count duplicate adjacent lines |
| `wc` | count lines, words, characters |
| `cut` | extract specific fields/columns |
| `tr` | translate or delete characters |
| `sed` | find and replace, delete lines |
| `awk` | process structured text, compute |
| `xargs` | turn lines into command arguments |
| `\|` | the pipe: connect everything together |

---

## The Big Idea from This Chapter

You don't need to write a program for most data tasks. The Unix toolkit is a set of composable building blocks. A pipeline is a program you write on one line. This is what Kernighan meant by "write programs that work together."

The programmer who knows these tools can answer questions in seconds that would take others hours to write code for.
