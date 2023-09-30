
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity spi is
  generic (
    clk_freq      : integer := 100000000;
    spi_freq      : integer := 3200000;
    cpol          : integer := 1;
    cpha          : integer := 1;
    csn_width     : integer := 1
  );
  port (
    aclk          : in  std_logic;
    aresetn       : in  std_logic;

    spi_csn       : out std_logic_vector(csn_width - 1 downto 0);
    spi_mosi      : out std_logic;
    spi_miso      : in  std_logic;
    spi_clk       : out std_logic;

    m_axis_tdest  : out std_logic_vector(7 downto 0);
    m_axis_tdata  : out std_logic_vector(7 downto 0);
    m_axis_tlast  : out std_logic;
    m_axis_tvalid : out std_logic;
    m_axis_tready : in  std_logic;

    s_axis_tdest  : in  std_logic_vector(7 downto 0);
    s_axis_tdata  : in  std_logic_vector(7 downto 0);
    s_axis_tlast  : in  std_logic;
    s_axis_tvalid : in  std_logic;
    s_axis_tready : out std_logic
  );
end spi;

architecture struct_spi of spi is

  signal sig_spi_csn   : std_logic_vector(csn_width - 1 downto 0);
  signal sig_spi_mosi  : std_logic;
  signal sig_spi_miso  : std_logic;
  signal sig_spi_clk   : std_logic;

begin

  spi_csn       <= sig_spi_csn;
  spi_mosi      <= sig_spi_mosi;
  sig_spi_miso  <= spi_miso;
  spi_clk       <= sig_spi_clk;

  U_spi_tx : entity work.spi_tx
    generic map (
      clk_freq      => clk_freq,
      spi_freq      => spi_freq,
      cpol          => cpol,
      cpha          => cpha,
      csn_width     => csn_width
    )
    port map (
      aclk          => aclk,
      aresetn       => aresetn,

      spi_csn       => sig_spi_csn,
      spi_mosi      => sig_spi_mosi,
      spi_clk       => sig_spi_clk,

      s_axis_tdest  => s_axis_tdest,
      s_axis_tdata  => s_axis_tdata,
      s_axis_tlast  => s_axis_tlast,
      s_axis_tvalid => s_axis_tvalid,
      s_axis_tready => s_axis_tready
    );

  U_spi_rx : entity work.spi_rx
    generic map (
      clk_freq      => clk_freq,
      spi_freq      => spi_freq,
      cpol          => cpol,
      cpha          => cpha,
      csn_width     => csn_width
    )
    port map (
      aclk          => aclk,
      aresetn       => aresetn,

      spi_csn       => sig_spi_csn,
      spi_miso      => sig_spi_miso,
      spi_clk       => sig_spi_clk,

      m_axis_tdest  => m_axis_tdest,
      m_axis_tdata  => m_axis_tdata,
      m_axis_tlast  => m_axis_tlast,
      m_axis_tvalid => m_axis_tvalid,
      m_axis_tready => m_axis_tready
    );

end struct_spi;

