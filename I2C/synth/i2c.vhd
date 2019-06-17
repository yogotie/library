
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c is
  generic (
    g_clock_freq_hz       : integer := 100000000;
    g_i2c_freq_hz         : integer := 100000
  );
  port (
    clk                   : in    std_logic;
    reset                 : in    std_logic;

    coe_sda_export        : inout std_logic;
    coe_scl_export        : inout std_logic;

    aso_rx_data           : out   std_logic_vector(7 downto 0);
    aso_rx_startofpacket  : out   std_logic;
    aso_rx_endofpacket    : out   std_logic;
    aso_rx_error          : out   std_logic;
    aso_rx_valid          : out   std_logic;
    aso_rx_ready          : in    std_logic;

    asi_tx_data           : in    std_logic_vector(7 downto 0);
    asi_tx_startofpacket  : in    std_logic;
    asi_tx_endofpacket    : in    std_logic;
    asi_tx_error          : in    std_logic;
    asi_tx_valid          : in    std_logic;
    asi_tx_ready          : out   std_logic
  );
end i2c;

architecture i2c_a of i2c is

  signal i_sda            : std_logic;
  signal i_scl            : std_logic;
  signal i_aso_bit_data   : std_logic_vector(1 downto 0);
  signal i_aso_bit_valid  : std_logic;
  signal i_aso_bit_ready  : std_logic;

  signal i_sda_t          : std_logic;
  signal i_scl_t          : std_logic;
  signal i_asi_bit_data   : std_logic_vector(1 downto 0);
  signal i_asi_bit_valid  : std_logic;
  signal i_asi_bit_ready  : std_logic;

begin

  u_sda_iobuf : entity work.i2c_iobuf port map ( clk => clk, o => i_sda, i => '0', oe => not i_sda_t, io => coe_sda_export );
  u_scl_iobuf : entity work.i2c_iobuf port map ( clk => clk, o => i_scl, i => '0', oe => not i_scl_t, io => coe_scl_export );

  u_i2c_bit_rx : entity work.i2c_bit_rx
    generic map (
      g_clock_freq_hz => g_clock_freq_hz,
      g_i2c_freq_hz   => g_i2c_freq_hz
    )
    port map (
      clk             => clk,
      reset           => reset,

      coe_sda_export  => i_sda,
      coe_scl_export  => i_scl,

      aso_bit_data    => i_aso_bit_data,
      aso_bit_valid   => i_aso_bit_valid,
      aso_bit_ready   => i_aso_bit_ready
    );

  u_i2c_bit_tx : entity work.i2c_bit_tx
    generic map (
      g_clock_freq_hz => g_clock_freq_hz,
      g_i2c_freq_hz   => g_i2c_freq_hz
    )
    port map (
      clk             => clk,
      reset           => reset,

      coe_sda_export  => i_sda_t,
      coe_scl_export  => i_scl_t,

      asi_bit_data    => i_asi_bit_data,
      asi_bit_valid   => i_asi_bit_valid,
      asi_bit_ready   => i_asi_bit_ready
    );

  u_i2c_byte_rx : entity work.i2c_byte_rx
    port map (
      clk                     => clk,
      reset                   => reset,

      asi_bit_data            => i_aso_bit_data,
      asi_bit_valid           => i_aso_bit_valid,
      asi_bit_ready           => i_aso_bit_ready,

      aso_byte_data           => aso_rx_data,
      aso_byte_startofpacket  => aso_rx_startofpacket,
      aso_byte_endofpacket    => aso_rx_endofpacket,
      aso_byte_error          => aso_rx_error,
      aso_byte_valid          => aso_rx_valid,
      aso_byte_ready          => aso_rx_ready
    );

  u_i2c_byte_tx : entity work.i2c_byte_tx
    port map (
      clk                     => clk,
      reset                   => reset,

      aso_bit_data            => i_asi_bit_data,
      aso_bit_valid           => i_asi_bit_valid,
      aso_bit_ready           => i_asi_bit_ready,

      asi_byte_data           => asi_tx_data,
      asi_byte_startofpacket  => asi_tx_startofpacket,
      asi_byte_endofpacket    => asi_tx_endofpacket,
      asi_byte_error          => asi_tx_error,
      asi_byte_valid          => asi_tx_valid,
      asi_byte_ready          => asi_tx_ready
    );

end i2c_a;

