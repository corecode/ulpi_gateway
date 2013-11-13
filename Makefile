SRCS=	ulpi_link.sv ulpi_if.sv ulpi_link_if.sv
TBS=	ulpi_tb.sv

MODELSIMDIR?=	/opt/altera/13.1/modelsim_ase/linux

all: simulate

work:
	${MODELSIMDIR}/vlib work

compile: work ${SRCS} ${TBS}
	${MODELSIMDIR}/vlog -lint ${SRCS} ${TBS}

simulate: $(patsubst %.sv,%.vcd,${TBS})

%.vcd: compile
	${MODELSIMDIR}/vsim -c -do 'run 1000ns;quit' ${@:.vcd=}
