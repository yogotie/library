
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;
  context vunit_lib.vc_context;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_spi is
  generic (
    runner_cfg  : string;
    clk_freq    : integer := 100000000;
    spi_freq    : integer := 3200000;
    cpol        : integer := 1;
    cpha        : integer := 1;
    csn_width   : integer := 1
  );
end tb_spi;

architecture behav_tb_spi of tb_spi is

  constant s_axis           : axi_stream_master_t := new_axi_stream_master( dest_length => 8, data_length => 8 );
  constant m_axis           : axi_stream_slave_t  := new_axi_stream_slave ( dest_length => 8, data_length => 8 );

  signal END_OF_SIMULATION  : boolean := false;

  signal spi_period         : time := real(real(1) / real(spi_freq)) * 1 sec;
  signal clk_period         : time := real(real(1) / real(clk_freq)) * 1 sec;

  signal aclk               : std_logic := '0';
  signal aresetn            : std_logic;

  signal spi_csn            : std_logic_vector(csn_width - 1 downto 0);
  signal spi_mosi           : std_logic;
  signal spi_miso           : std_logic;
  signal spi_clk            : std_logic;

  signal m_axis_tdest       : std_logic_vector(7 downto 0);
  signal m_axis_tdata       : std_logic_vector(7 downto 0);
  signal m_axis_tlast       : std_logic;
  signal m_axis_tvalid      : std_logic;
  signal m_axis_tready      : std_logic;

  signal s_axis_tdest       : std_logic_vector(7 downto 0);
  signal s_axis_tdata       : std_logic_vector(7 downto 0);
  signal s_axis_tlast       : std_logic;
  signal s_axis_tvalid      : std_logic;
  signal s_axis_tready      : std_logic;

begin

  UUT : entity work.spi
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

      spi_csn       => spi_csn,
      spi_mosi      => spi_mosi,
      spi_miso      => spi_miso,
      spi_clk       => spi_clk,

      m_axis_tdest  => m_axis_tdest,
      m_axis_tdata  => m_axis_tdata,
      m_axis_tlast  => m_axis_tlast,
      m_axis_tvalid => m_axis_tvalid,
      m_axis_tready => m_axis_tready,

      s_axis_tdest  => s_axis_tdest,
      s_axis_tdata  => s_axis_tdata,
      s_axis_tlast  => s_axis_tlast,
      s_axis_tvalid => s_axis_tvalid,
      s_axis_tready => s_axis_tready
    );

  aclk    <= not aclk after clk_period / 2;
  aresetn <= '0', '1' after 100 ns;

  test_runner_watchdog(runner, 10 ms);

  PROC_main : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait until END_OF_SIMULATION = true;
    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  spi_miso <= spi_mosi;

  PROC_m_axis : process
  begin
    check_axi_stream( net, m_axis, tdest => X"00", expected => X"01", tlast => '0' );
    check_axi_stream( net, m_axis, tdest => X"00", expected => X"02", tlast => '0' );
    check_axi_stream( net, m_axis, tdest => X"00", expected => X"03", tlast => '0' );
    check_axi_stream( net, m_axis, tdest => X"00", expected => X"04", tlast => '0' );
    check_axi_stream( net, m_axis, tdest => X"00", expected => X"05", tlast => '1' );

    END_OF_SIMULATION <= true;
    wait;
  end process;

  m_axis_tready  <= '1';

  PROC_s_axis : process
  begin
    wait until rising_edge(aclk) and aresetn = '0';

    push_axi_stream( net, s_axis, tdest => X"00", tdata => X"01", tlast => '0' );
    push_axi_stream( net, s_axis, tdest => X"00", tdata => X"02", tlast => '0' );
    push_axi_stream( net, s_axis, tdest => X"00", tdata => X"03", tlast => '0' );
    push_axi_stream( net, s_axis, tdest => X"00", tdata => X"04", tlast => '0' );
    push_axi_stream( net, s_axis, tdest => X"00", tdata => X"05", tlast => '1' );

    wait;
  end process;
  
  U_m_axis : entity vunit_lib.axi_stream_slave
    generic map(
      slave   => m_axis
    )
    port map(
      aclk     => aclk,
      areset_n => aresetn,
      tdest    => m_axis_tdest,
      tdata    => m_axis_tdata,
      tlast    => m_axis_tlast,
      tvalid   => m_axis_tvalid,
      tready   => m_axis_tready
    );

  U_s_axis : entity vunit_lib.axi_stream_master
    generic map(
      master  => s_axis
    )
    port map(
      aclk     => aclk,
      areset_n => aresetn,
      tdest    => s_axis_tdest,
      tdata    => s_axis_tdata,
      tlast    => s_axis_tlast,
      tvalid   => s_axis_tvalid,
      tready   => s_axis_tready
    );

end behav_tb_spi;

-- synthesis translate_on

