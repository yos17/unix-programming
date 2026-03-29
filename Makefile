CHAPTERS = 01_getting_started 02_filesystem 03_shell \
           04_filters 05_shell_programming 06_processes \
           07_under_the_hood 08_tools

SCRIPTS = $(wildcard scripts/*.sh)

.PHONY: all check-scripts word-count clean help

all: check-scripts
	@echo "All checks passed!"

check-scripts:
	@echo "Checking shell scripts..."
	@for script in $(SCRIPTS); do \
		bash -n $$script && echo "  OK: $$script" || exit 1; \
	done

word-count:
	@echo "Chapter word counts:"
	@for ch in $(CHAPTERS); do \
		count=$$(wc -w < chapters/$$ch/README.md); \
		printf "  %-30s %s words\n" "$$ch" "$$count"; \
	done
	@echo ""
	@total=$$(cat chapters/*/README.md | wc -w); \
		echo "  Total: $$total words"

clean:
	rm -f *.log *.tmp

help:
	@echo "Available targets:"
	@echo "  make               - check all scripts"
	@echo "  make word-count    - count words per chapter"
	@echo "  make clean         - remove temp files"
	@echo "  make help          - show this help"
