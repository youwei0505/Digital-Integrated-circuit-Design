library verilog;
use verilog.vl_types.all;
entity FA is
    port(
        s               : out    vl_logic;
        c_out           : out    vl_logic;
        x               : in     vl_logic;
        y               : in     vl_logic;
        c_in            : in     vl_logic
    );
end FA;
