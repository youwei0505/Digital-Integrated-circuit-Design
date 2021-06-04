library verilog;
use verilog.vl_types.all;
entity MFE is
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        busy            : out    vl_logic;
        ready           : in     vl_logic;
        iaddr           : out    vl_logic_vector(13 downto 0);
        idata           : in     vl_logic_vector(7 downto 0);
        data_rd         : in     vl_logic_vector(7 downto 0);
        data_wr         : out    vl_logic_vector(7 downto 0);
        addr            : out    vl_logic_vector(13 downto 0);
        wen             : out    vl_logic
    );
end MFE;
