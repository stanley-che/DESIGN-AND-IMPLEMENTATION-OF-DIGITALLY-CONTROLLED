library verilog;
use verilog.vl_types.all;
entity top_controller is
    port(
        clk             : in     vl_logic;
        clk_count       : in     vl_logic;
        rst             : in     vl_logic;
        err_in          : in     vl_logic_vector(3 downto 0);
        pwm_out         : out    vl_logic
    );
end top_controller;
