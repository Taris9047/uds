CC=gcc

vm_check: vm_check.c
	$(CC) -Os -ggdb3 -o $@ ./vm_check.c

all: vm_check

clean:
	rm -rf ./vm_check
