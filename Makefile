SRCS=	ulpi.v
PROGS=	${SRCS:.v=_tb}

all: compile simulate

compile: ${PROGS}

simulate: $(patsubst %,simulate-%,${PROGS})

simulate-%: %
	./$^

%_tb: %.v
	iverilog -Wall -s $@ -o $@ $^

%.vcd: %
	./$^
