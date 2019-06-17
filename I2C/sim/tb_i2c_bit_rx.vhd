
-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.i2c_pkg.all;

entity i2c_bit_rx_ut is
  generic (
    g_clock_freq_hz : integer := 100000000;
    g_i2c_freq_hz   : integer := 100000
  );
end i2c_bit_rx_ut;

architecture i2c_bit_rx_ut_a of i2c_bit_rx_ut is

  constant c_period       : time := integer( 1.0e9/real(g_i2c_freq_hz) ) * 1 ns;

  signal clk              : std_logic := '0';
  signal reset            : std_logic;

  signal coe_sda_export   : std_logic;
  signal coe_scl_export   : std_logic;

  signal aso_bit_data     : std_logic_vector(1 downto 0);
  signal aso_bit_valid    : std_logic;
  signal aso_bit_ready    : std_logic;

begin

  UUT : entity work.i2c_bit_rx
    generic map (
      g_clock_freq_hz => g_clock_freq_hz,
      g_i2c_freq_hz   => g_i2c_freq_hz
    )
    port map (
      clk             => clk,
      reset           => reset,

      coe_sda_export  => coe_sda_export,
      coe_scl_export  => coe_scl_export,

      aso_bit_data    => aso_bit_data,
      aso_bit_valid   => aso_bit_valid,
      aso_bit_ready   => aso_bit_ready
    );

  clk   <= not clk after 5 ns;
  reset <= '1', '0' after 100 ns;

  i2c_bit_p : process
    procedure send_bit( value : std_logic_vector(1 downto 0) ) is
    begin
      case value is
        when C_BIT_0 =>
          coe_sda_export  <= '0';
          coe_scl_export  <= '0';
          wait for c_period / 4;
          coe_scl_export  <= 'H';
          wait for c_period / 2;
          coe_scl_export  <= '0';
          wait for c_period / 4;

        when C_BIT_1 =>
          coe_sda_export  <= 'H';
          coe_scl_export  <= '0';
          wait for c_period / 4;
          coe_scl_export  <= 'H';
          wait for c_period / 2;
          coe_scl_export  <= '0';
          wait for c_period / 4;

        when C_START =>
          coe_sda_export  <= 'H';
          coe_scl_export  <= 'H';
          wait for c_period / 2;
          coe_sda_export  <= '0';
          wait for c_period / 4;
          coe_scl_export  <= '0';
          wait for c_period / 4;

        when C_STOP =>
          coe_sda_export  <= '0';
          coe_scl_export  <= '0';
          wait for c_period / 4;
          coe_scl_export  <= 'H';
          wait for c_period / 4;
          coe_sda_export  <= 'H';
          wait for c_period / 2;

        when others =>
      end case;
    end procedure;
  begin
    coe_sda_export <= 'H';
    coe_scl_export <= 'H';

    wait for 1 us;

    send_bit( C_START );
    send_bit( C_BIT_0 );
    send_bit( C_BIT_1 );
    send_bit( C_STOP );

    wait;
  end process;

  aso_bit_p : process
    procedure check_bit( expected : std_logic_vector(1 downto 0) ) is
    begin
      aso_bit_ready <= '1';
      wait until rising_edge(clk) and aso_bit_valid = '1';

      assert aso_bit_data = expected
        report "ERROR expected(0x" & to_hstring(expected) & ") : actual(0x" & to_hstring(aso_bit_data) & ")"
        severity ERROR;

      aso_bit_ready <= '0';
      wait until rising_edge(clk);

    end procedure;
  begin

    check_bit( C_START );
    check_bit( C_BIT_0 );
    check_bit( C_BIT_1 );
    check_bit( C_STOP );

    report "END OF SIMULATION" severity FAILURE;

    wait;
  end process;

end i2c_bit_rx_ut_a;

-- synthesis translate_on

