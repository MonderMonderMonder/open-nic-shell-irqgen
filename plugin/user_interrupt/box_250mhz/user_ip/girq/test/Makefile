# Makefile

# defaults
SIM ?= questa
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../hdl/girq_axil_wrapper.v 
VERILOG_SOURCES += $(PWD)/../hdl/gen_irq.v 
VERILOG_SOURCES += $(PWD)/../../../../../../src/utility/axi_lite_register.sv

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = girq_axil_wrapper

# MODULE is the basename of the Python test file
MODULE ?= girq_axil_wrapper_test

GUI=1
WAVES=1

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

SIM_ARGS += -gui