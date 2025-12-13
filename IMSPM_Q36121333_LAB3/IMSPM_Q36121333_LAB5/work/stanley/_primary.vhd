library verilog;
use verilog.vl_types.all;
entity stanley is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        err_in          : in     vl_logic_vector(3 downto 0);
        d_comp          : out    vl_logic_vector(8 downto 0)
    );
end stanley;
