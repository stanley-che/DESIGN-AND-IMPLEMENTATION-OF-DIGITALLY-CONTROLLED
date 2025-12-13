library verilog;
use verilog.vl_types.all;
entity top_dither is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        dither_in       : in     vl_logic_vector(9 downto 0);
        duty            : out    vl_logic
    );
end top_dither;
