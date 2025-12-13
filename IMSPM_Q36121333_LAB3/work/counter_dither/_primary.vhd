library verilog;
use verilog.vl_types.all;
entity counter_dither is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        d_n_input       : in     vl_logic_vector(6 downto 0);
        duty            : out    vl_logic
    );
end counter_dither;
