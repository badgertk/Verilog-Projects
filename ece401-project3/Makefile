#ECE 201/401 Project Unified Makefile

#By default, Verilator will treat warnings as errors. To change this behavior, 
#uncomment the following line:
#VERILATOR_ALLOW_WARNINGS=1

#By default, verilator will not generate traces (vcd files). To change this 
#behavior, uncomment the following line:
#SUPPORT_VCD=1

#When completing projects 3 and 4, if you want to enable the superscalar 
#features in sim_main, uncomment the following line:
#ENABLE_SUPERSCALAR=1

VERILATOR_VER=3.864
VERILATOR_REL_PATH=./
VERILATOR_DIR=${VERILATOR_REL_PATH}verilator-${VERILATOR_VER}
VERLIATOR_TAR=verilator-${VERILATOR_VER}.tar.bz2
VERILATOR_TAR_PATH=${VERILATOR_REL_PATH}${VERLIATOR_TAR}
VERILATOR_TAR_URL=http://www.ece.rochester.edu/~irichter/${VERLIATOR_TAR}
SIM_FILES=sim_main/sim_main.cpp sim_main/sm_heap.cpp sim_main/sm_memory.cpp sim_main/sm_syscalls.cpp sim_main/sm_txtload.cpp sim_main/sm_elfload.cpp sim_main/elf/elf_reader.cpp sim_main/sm_regfile.cpp
VERILOG_FILES=$(wildcard verilog/*.v)
VERILATOR_BIN=${VERILATOR_DIR}/bin/verilator
UNAME:=$(shell uname)
SM_FLAGS=-O3
VFLAGS+=--autoflush -O4 -Wall #-Wno-fatal
ifeq ($(VERILATOR_ALLOW_WARNINGS),1)
VFLAGS+=-Wno-fatal
endif
ifeq ($(SUPPORT_VCD),1)
VFLAGS+=--trace
SM_FLAGS+=-DSUPPORT_VCD
endif

all: VMIPS

.PHONY : all

PROJECT?=4


ifneq ($(PROJECT), 1)
VFLAGS+=-DUSE_ICACHE -DUSE_DCACHE
endif
ENABLE_SUPERSCALAR?=0
ENABLE_OOO?=0

ifeq ($(PROJECT), 2)
ENABLE_SUPERSCALAR=1
else ifeq ($(PROJECT), 3)
SM_FLAGS+=-DDEBUG_CACHE
else ifeq ($(PROJECT), 4)
ENABLE_OOO=1
endif

ifeq ($(ENABLE_SUPERSCALAR),1)
VFLAGS+=-DSUPERSCALAR
SM_FLAGS+=-DDOUBLE_FETCH
endif

ifeq ($(ENABLE_OOO),1)
VFLAGS+=-DOUT_OF_ORDER
SM_FLAGS+=-DOOO
endif


VMIPS : obj_dir/VMIPS
	cp obj_dir/VMIPS ./

obj_dir/VMIPS : obj_dir/VMIPS.mk ${SIM_FILES} ${VERILOG_FILES}
	$(MAKE) -C obj_dir -f VMIPS.mk VMIPS

obj_dir/VMIPS.mk : ${VERILATOR_BIN} ${SIM_FILES} ${VERILOG_FILES}
	VERILATOR_ROOT=$(shell pwd)/${VERILATOR_DIR} ${VERILATOR_BIN} ${VFLAGS} -CFLAGS "${SM_FLAGS}" -cc verilog/MIPS.v -I./verilog/ --exe ${SIM_FILES}

${VERILATOR_BIN} : ${VERILATOR_DIR}/Makefile
	$(MAKE) -C ${VERILATOR_DIR}/src ${MAKEFLAGS} ../verilator_bin

${VERILATOR_DIR}/Makefile : ${VERILATOR_DIR}/configure
	cd ${VERILATOR_DIR} && ./configure

${VERILATOR_DIR}/configure : ${VERILATOR_TAR_PATH}
	tar -xjf ${VERILATOR_TAR_PATH} -C ${VERILATOR_REL_PATH}
	touch ${VERILATOR_DIR}/configure

${VERILATOR_TAR_PATH} : 
	wget ${VERILATOR_TAR_URL} -O ${VERILATOR_TAR_PATH}

.INTERMEDIATE : ece401-tests.tar.xz ${VERILATOR_TAR_PATH}

tests : ece401-tests.tar.xz
	@echo
	@echo Extracting Test Applications...
	xzcat ece401-tests.tar.xz|tar x
	@echo
	@echo Test applications extracted to tests/
	@echo

ece401-tests.tar.xz :
	@echo
	@echo Downloading Test Applications...
	wget http://www.ece.rochester.edu/~irichter/ece401-tests.tar.xz -O ece401-tests.tar.xz
	@echo
	@echo Test Applications downloaded
	@echo

clean :
	rm -rf obj_dir VMIPS
