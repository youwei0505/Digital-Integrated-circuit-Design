library verilog;
use verilog.vl_types.all;
entity RCA is
    port(
        s               : out    vl_logic_vector(3 downto 0);
        c_out           : out    vl_logic;
        x               : in     vl_logic_vector(3 downto 0);
        y               : in     vl_logic_vector(3 downto 0);
        c_in            : in     vl_logic
    );
end RCA;
