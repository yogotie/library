
-- synthesis translate_off
library vunit_lib;
  context vunit_lib.vunit_context;
  context vunit_lib.vc_context;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_uart_axi is
  generic(
    runner_cfg  : string;
    g_clk_freq  : integer := 100000000;
    g_baud_rate : integer := 115200
  );
end tb_uart_axi;

architecture uart_avalon_ut_a of tb_uart_axi is

  constant s_axi        : bus_master_t := new_bus(data_length => 32, address_length => 8);

  signal c_clk_period   : time := real(real(1) / real(g_clk_freq)) * 1 sec;

  signal aclk           : std_logic := '0';
  signal aresetn        : std_logic;
  signal irq            : std_logic;
  signal s_axi_araddr   : std_logic_vector( 7 downto 0);
  signal s_axi_arvalid  : std_logic;
  signal s_axi_arready  : std_logic;
  signal s_axi_rdata    : std_logic_vector(31 downto 0);
  signal s_axi_rvalid   : std_logic;
  signal s_axi_rready   : std_logic;
  signal s_axi_awaddr   : std_logic_vector( 7 downto 0);
  signal s_axi_awvalid  : std_logic;
  signal s_axi_awready  : std_logic;
  signal s_axi_wdata    : std_logic_vector(31 downto 0);
  signal s_axi_wstrb    : std_logic_vector( 3 downto 0);
  signal s_axi_wvalid   : std_logic;
  signal s_axi_wready   : std_logic;
  signal s_axi_bresp    : std_logic_vector( 1 downto 0);
  signal s_axi_bvalid   : std_logic;
  signal s_axi_bready   : std_logic;

begin

  UUT : entity work.uart_axi
    generic map(
      g_clk_freq    => g_clk_freq,
      g_baud_rate   => g_baud_rate
    )
    port map(
      aclk          => aclk,
      aresetn       => aresetn,
      irq           => irq,
      s_axi_araddr  => s_axi_araddr,
      s_axi_arvalid => s_axi_arvalid,
      s_axi_arready => s_axi_arready,
      s_axi_rdata   => s_axi_rdata,
      s_axi_rvalid  => s_axi_rvalid,
      s_axi_rready  => s_axi_rready,
      s_axi_awaddr  => s_axi_awaddr,
      s_axi_awvalid => s_axi_awvalid,
      s_axi_awready => s_axi_awready,
      s_axi_wdata   => s_axi_wdata,
      s_axi_wstrb   => s_axi_wstrb,
      s_axi_wvalid  => s_axi_wvalid,
      s_axi_wready  => s_axi_wready,
      s_axi_bresp   => s_axi_bresp,
      s_axi_bvalid  => s_axi_bvalid,
      s_axi_bready  => s_axi_bready
    );

  aclk   <= not aclk after c_clk_period / 2;
  aresetn <= '0', '1' after 100 ns;

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    write_bus( net, s_axi, X"00", X"00000000" );
    wait_until_idle( net, s_axi );

  --   wr( X"01", X"0000_0003" );  -- enable tx and rx interrupts
  --   wr( X"03", X"0000_0001" );  -- write data to transmit

  --   wait until rising_edge(aclk) and irq = '1';
  --   rd( X"00", X"0000_0001" );  -- read status
  --   rd( X"02", X"0000_0001" );  -- read interrupt value
  --   rd( X"03", X"0000_0000" );  -- read data
  --   wr( X"02", X"0000_0003" );  -- clear interrupt
  --   rd( X"02", X"0000_0000" );  -- read interrupt value

  --   wait until rising_edge(aclk) and irq = '1';
  --   rd( X"00", X"0000_0003" );  -- read status
  --   rd( X"02", X"0000_0002" );  -- read interrupt value
  --   rd( X"03", X"0000_0001" );  -- read data
  --   wr( X"02", X"0000_0003" );  -- clear interrupt
  --   rd( X"02", X"0000_0000" );  -- read interrupt value
  --   rd( X"00", X"0000_0001" );  -- read status

    test_runner_cleanup(runner);
  end process;

  test_runner_watchdog(runner, 1 ms);

  axi_lite_master_inst: entity vunit_lib.axi_lite_master
    generic map (
      bus_handle => s_axi
    )
    port map (
      aclk    => aclk,
      arready => s_axi_arready,
      arvalid => s_axi_arvalid,
      araddr  => s_axi_araddr,
      rready  => s_axi_rready,
      rvalid  => s_axi_rvalid,
      rdata   => s_axi_rdata,
      rresp   => (others => '0'),
      awready => s_axi_awready,
      awvalid => s_axi_awvalid,
      awaddr  => s_axi_awaddr,
      wready  => s_axi_wready,
      wvalid  => s_axi_wvalid,
      wdata   => s_axi_wdata,
      wstrb   => s_axi_wstrb,
      bvalid  => s_axi_bvalid,
      bready  => s_axi_bready,
      bresp   => s_axi_bresp
    );

end uart_avalon_ut_a;

-- synthesis translate_on
