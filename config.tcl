set ::env(DESIGN_NAME) "top"
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]

set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "15.625"
set ::env(SDC_FILE) "$::env(DESIGN_DIR)/constraints.sdc"

# 保守一點，避免 placement/routing 卡住
set ::env(FP_CORE_UTIL) 35
set ::env(PL_TARGET_DENSITY) 0.45
