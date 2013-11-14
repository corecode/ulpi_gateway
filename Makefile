SRCS=	ulpi_link.sv ulpi_if.sv ulpi_link_if.sv
TBS=	ulpi_tb.sv
SYNPLIFYPRJ=	ulpi_gateway_syn.prj

MODELSIMDIR?=	/opt/altera/13.1/modelsim_ase/linux
ICECUBEDIR?=	/opt/lscc/iCEcube2.2013.03

SYNPLIFY?=	LD_LIBRARY_PATH=${ICECUBEDIR}/sbt_backend/bin/linux/opt/synpwrap SYNPLIFY_PATH=${ICECUBEDIR}/synpbase ${ICECUBEDIR}/sbt_backend/bin/linux/opt/synpwrap/synpwrap -prj ${SYNPLIFYPRJ}

all: simulate

work:
	${MODELSIMDIR}/vlib work

compile: compile-modelsim compile-synplify

compile-modelsim: work ${SRCS} ${TBS}
	${MODELSIMDIR}/vlog -lint ${SRCS} ${TBS}

compile-synplify:
	${SYNPLIFY}

simulate: $(patsubst %.sv,%.vcd,${TBS})

%.vcd: compile-modelsim
	${MODELSIMDIR}/vsim -c -do 'run 1000ns;quit' ${@:.vcd=}
