
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c is
  generic (
    g_clock_freq_hz  : integer := 100000000;
    g_i2c_freq_hz    : integer := 100000
  );
  port (
    aclk             : in    std_logic;
    aresetn          : in    std_logic;

    sda_inout        : inout std_logic;
    scl_inout        : inout std_logic;

    m_axis_rx_tuser  : out   std_logic_vector(2 downto 0);
    m_axis_rx_tdata  : out   std_logic_vector(7 downto 0);
    m_axis_rx_tvalid : out   std_logic;
    m_axis_rx_tready : in    std_logic;

    s_axis_tx_tuser  : in    std_logic_vector(2 downto 0);
    s_axis_tx_tdata  : in    std_logic_vector(7 downto 0);
    s_axis_tx_tvalid : in    std_logic;
    s_axis_tx_tready : out   std_logic
  );
end i2c;

architecture i2c_a of i2c is

  signal sig_sda               : std_logic;
  signal sig_scl               : std_logic;
  signal sig_m_axis_bit_tdata  : std_logic_vector(1 downto 0);
  signal sig_m_axis_bit_tvalid : std_logic;
  signal sig_m_axis_bit_tready : std_logic;

  signal sig_sda_t             : std_logic;
  signal sig_scl_t             : std_logic;
  signal sig_s_axis_bit_tdata  : std_logic_vector(1 downto 0);
  signal sig_s_axis_bit_tvalid : std_logic;
  signal sig_s_axis_bit_tready : std_logic;

begin

  u_sda_iobuf : entity work.i2c_iobuf port map ( aclk => aclk, o => sig_sda, i => '0', oe => not sig_sda_t, io => sda_inout );
  u_scl_iobuf : entity work.i2c_iobuf port map ( aclk => aclk, o => sig_scl, i => '0', oe => not sig_scl_t, io => scl_inout );

  u_i2c_bit_rx : entity work.i2c_bit_rx
    generic map (
      g_clock_freq_hz   => g_clock_freq_hz,
      g_i2c_freq_hz     => g_i2c_freq_hz
    )
    port map (
      aclk              => aclk,
      aresetn           => aresetn,

      sda_in            => sig_sda,
      scl_in            => sig_scl,

      m_axis_bit_tdata  => sig_m_axis_bit_tdata,
      m_axis_bit_tvalid => sig_m_axis_bit_tvalid,
      m_axis_bit_tready => sig_m_axis_bit_tready
    );

  u_i2c_bit_tx : entity work.i2c_bit_tx
    generic map (
      g_clock_freq_hz   => g_clock_freq_hz,
      g_i2c_freq_hz     => g_i2c_freq_hz
    )
    port map (
      aclk              => aclk,
      aresetn           => aresetn,

      sda_out           => sig_sda_t,
      scl_out           => sig_scl_t,

      s_axis_bit_tdata  => sig_s_axis_bit_tdata,
      s_axis_bit_tvalid => sig_s_axis_bit_tvalid,
      s_axis_bit_tready => sig_s_axis_bit_tready
    );

  u_i2c_byte_rx : entity work.i2c_byte_rx
    port map (
      aclk               => aclk,
      aresetn            => aresetn,

      s_axis_bit_tdata   => sig_m_axis_bit_tdata,
      s_axis_bit_tvalid  => sig_m_axis_bit_tvalid,
      s_axis_bit_tready  => sig_m_axis_bit_tready,

      m_axis_byte_tuser  => m_axis_rx_tuser,
      m_axis_byte_tdata  => m_axis_rx_tdata,
      m_axis_byte_tvalid => m_axis_rx_tvalid,
      m_axis_byte_tready => m_axis_rx_tready
    );

  u_i2c_byte_tx : entity work.i2c_byte_tx
    port map (
      aclk               => aclk,
      aresetn            => aresetn,

      m_axis_bit_tdata   => sig_s_axis_bit_tdata,
      m_axis_bit_tvalid  => sig_s_axis_bit_tvalid,
      m_axis_bit_tready  => sig_s_axis_bit_tready,

      s_axis_byte_tuser  => s_axis_tx_tuser,
      s_axis_byte_tdata  => s_axis_tx_tdata,
      s_axis_byte_tvalid => s_axis_tx_tvalid,
      s_axis_byte_tready => s_axis_tx_tready
    );

end i2c_a;

