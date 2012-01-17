
CC = /usr/bin/cc

OPTS = -g3 -O

CFLAGS = -c $(OPTS)

.PHONY: all install clean

all: markov

install: markov
	if [ "$(FAMPATH)" = "" ]; then \
	echo; \
	echo "!!! WARNING !!! Don't know where to install to; FAMPATH not set."; \
	echo;exit 2; \
	else \
	echo; \
	cp markov $(FAMPATH)/bin; \
	echo "Installation successfully completed."; \
	fi; \
	echo;

markov: markov.o
	$(CC) markov.o -o $@ -lm

markov.o: markov.c markov.h
	$(CC) $(CFLAGS) markov.c markov.h

clean:
	rm -f markov.o markov
