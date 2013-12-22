SRCS=	ulpi_link.sv ulpi_if.sv ulpi_link_if.sv
TBS=	ulpi_tb.sv

SRCS+=	spi_slave.sv
TBS+=	spi_tb.sv

SYNPLIFYPRJ=	ulpi_gateway_syn.prj

MODELSIMDIR?=	/opt/altera/13.1/modelsim_ase/linux
ICECUBEDIR?=	/opt/lscc/iCEcube2.2013.03

define synplify_get_impl
$(shell awk '$$1 == "impl" && $$2 == "-active" { print $$3 }' ${SYNPLIFYPRJ})
endef

define SYNPLIFY ?=
LD_LIBRARY_PATH=${ICECUBEDIR}/sbt_backend/bin/linux/opt/synpwrap \
SYNPLIFY_PATH=${ICECUBEDIR}/synpbase \
${ICECUBEDIR}/sbt_backend/bin/linux/opt/synpwrap/synpwrap -prj ${SYNPLIFYPRJ};
cat $(call synplify_get_impl)/synlog/report/*.txt
endef

all: simulate

work:
	${MODELSIMDIR}/vlib work

lint: ${SRCS:.sv=-lint}

%-lint: %.sv
	verilator -Dsynthesis --lint-only -Wall $^

compile: compile-modelsim compile-synplify

compile-modelsim.stamp: work ${SRCS} ${TBS}
	${MODELSIMDIR}/vlog -lint ${SRCS} ${TBS}
	touch $@

compile-synplify:
	${SYNPLIFY}

simulate: $(patsubst %.sv,%.vcd,${TBS})

%.vcd: compile-modelsim.stamp
	${MODELSIMDIR}/vsim -c -do 'run 1000ns;quit' ${@:.vcd=}
