
-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.i2c_pkg.all;

entity tb_i2c is
  generic (
    g_clock_freq_hz           : integer := 100000000;
    g_i2c_freq_hz             : integer := 100000
  );
end tb_i2c;

architecture tb_i2c_a of tb_i2c is

  constant c_period           : time := integer( 1.0e9/real(g_i2c_freq_hz) ) * 1 ns;

  signal END_OF_SIMULATION    : boolean := false;

  signal clk                  : std_logic := '0';
  signal reset                : std_logic;
  signal coe_sda_export       : std_logic := 'H';
  signal coe_scl_export       : std_logic := 'H';
  signal aso_rx_data          : std_logic_vector(7 downto 0);
  signal aso_rx_startofpacket : std_logic;
  signal aso_rx_endofpacket   : std_logic;
  signal aso_rx_error         : std_logic;
  signal aso_rx_valid         : std_logic;
  signal aso_rx_ready         : std_logic;
  signal asi_tx_data          : std_logic_vector(7 downto 0);
  signal asi_tx_startofpacket : std_logic;
  signal asi_tx_endofpacket   : std_logic;
  signal asi_tx_error         : std_logic;
  signal asi_tx_valid         : std_logic;
  signal asi_tx_ready         : std_logic;

begin

  UUT : entity work.i2c
    generic map (
      g_clock_freq_hz       => g_clock_freq_hz,
      g_i2c_freq_hz         => g_i2c_freq_hz
    )
    port map (
      clk                   => clk,
      reset                 => reset,

      coe_sda_export        => coe_sda_export,
      coe_scl_export        => coe_scl_export,

      aso_rx_data           => aso_rx_data,
      aso_rx_startofpacket  => aso_rx_startofpacket,
      aso_rx_endofpacket    => aso_rx_endofpacket,
      aso_rx_error          => aso_rx_error,
      aso_rx_valid          => aso_rx_valid,
      aso_rx_ready          => aso_rx_ready,

      asi_tx_data           => asi_tx_data,
      asi_tx_startofpacket  => asi_tx_startofpacket,
      asi_tx_endofpacket    => asi_tx_endofpacket,
      asi_tx_error          => asi_tx_error,
      asi_tx_valid          => asi_tx_valid,
      asi_tx_ready          => asi_tx_ready
    );

  PR_clk : process
  begin
    if END_OF_SIMULATION then
      clk <= not clk;
      wait for 5 ns;
    end if;

    report "END OF SIMULATION" severity note;

    wait;
  end process;

  reset <= '1', '0' after 100 ns;

  aso_rx_p : process
    procedure check_byte( sop : std_logic; eop : std_logic; err : std_logic; value : std_logic_vector(7 downto 0) ) is
    begin
      aso_rx_ready  <= '1';
      wait until rising_edge(clk) and aso_rx_valid = '1';
      aso_rx_ready  <= '0';

      assert aso_rx_startofpacket = sop
        report "ERROR : startofpacket : expected(" & std_logic'image(sop) & ") : actual(" & std_logic'image(aso_rx_startofpacket) & ")"
        severity ERROR;

      assert aso_rx_endofpacket = eop
        report "ERROR : endofpacket : expected(" & std_logic'image(eop) & ") : actual(" & std_logic'image(aso_rx_endofpacket) & ")"
        severity ERROR;

      assert aso_rx_error = err
        report "ERROR : error : expected(" & std_logic'image(err) & ") : actual(" & std_logic'image(aso_rx_error) & ")"
        severity ERROR;

      assert aso_rx_data(value'range) = value
        report "ERROR : data : expected(0x" & to_hstring(value) & ") : actual(0x" & to_hstring(aso_rx_data(value'range)) & ")"
        severity ERROR;

    end procedure;
  begin
    aso_rx_ready  <= '0';

    wait until rising_edge(clk) and reset = '0';

    check_byte( '1', '0', '1', X"01" );
    check_byte( '0', '0', '1', X"02" );
    check_byte( '0', '1', '0', X"03" );

    wait for 1 us;

    END_OF_SIMULATION <= true;

    wait;
  end process;

  asi_tx_byte_p : process
    procedure send_byte( sop : std_logic; eop : std_logic; err : std_logic; value : std_logic_vector(7 downto 0) ) is
    begin
      asi_tx_data           <= value;
      asi_tx_startofpacket  <= sop;
      asi_tx_endofpacket    <= eop;
      asi_tx_error          <= err;
      asi_tx_valid          <= '1';
      wait until rising_edge(clk) and asi_tx_ready = '1';
      asi_tx_data           <= (others => '0');
      asi_tx_startofpacket  <= '0';
      asi_tx_endofpacket    <= '0';
      asi_tx_error          <= '0';
      asi_tx_valid          <= '0';
    end procedure;
  begin
    asi_tx_data           <= (others => '0');
    asi_tx_startofpacket  <= '0';
    asi_tx_endofpacket    <= '0';
    asi_tx_error          <= '0';
    asi_tx_valid          <= '0';

    wait until rising_edge(clk) and reset = '0';

    send_byte( '1', '0', '1', X"01" );
    send_byte( '0', '0', '1', X"02" );
    send_byte( '0', '1', '0', X"03" );

    wait;
  end process;

end tb_i2c_a;

-- synthesis translate_on

