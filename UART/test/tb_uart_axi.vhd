
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

  procedure wait_clks( n : integer ) is
  begin
    for i in 1 to n loop
      wait until rising_edge(aclk);
    end loop;
  end procedure wait_clks;

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

  -- p_s_axi : process
  --   -- procedure to perform a read transfer
  --   procedure rd( a : std_logic_vector(7 downto 0); expected : std_logic_vector(31 downto 0) ) is
  --     variable v_data : std_logic_vector( s_axi_rdata'range ) := (others => '0');
  --   begin
  --     -- setup the read transfer
  --     s_axi_araddr      <= a(s_axi_araddr'range);
  --     s_axi_arvalid     <= '1';
  --     s_axi_rready      <= '1';

  --     -- wait until the transfer is done
  --     loop
  --       wait until rising_edge(aclk) and (s_axi_arready = '1' or s_axi_rvalid = '1');

  --       if s_axi_arready = '1' then
  --         s_axi_arvalid <= '0';
  --       end if;

  --       if s_axi_rready = '1' and s_axi_rvalid = '1' then
  --         v_data := s_axi_rdata;
  --         s_axi_rready <= '0';
  --       end if;

  --       if s_axi_arvalid = '0' and s_axi_rready = '0' then
  --         exit;
  --       end if;
  --     end loop;

  --     assert v_data = expected
  --       report "ERROR expected(0x" & to_hstring(expected) & ") : actual(0x" & to_hstring(v_data) & ")"
  --       severity ERROR;

  --   end procedure rd;

  --   -- procedure to perform a write transfer
  --   procedure wr( a : std_logic_vector(7 downto 0); d : std_logic_vector(31 downto 0) ) is
  --   begin
  --     s_axi_awaddr  <= a( s_axi_awaddr'range );
  --     s_axi_awvalid <= '1';
  --     s_axi_wdata   <= d;
  --     s_axi_wstrb   <= X"F";
  --     s_axi_wvalid  <= '1';
  --     s_axi_bready  <= '1';

  --     -- wait until the transfer is done
  --     loop
  --       wait until rising_edge(aclk) and (s_axi_awready = '1' or s_axi_wready = '1' or s_axi_bvalid = '1');

  --       if s_axi_awready = '1' then
  --         s_axi_awvalid <= '0';
  --       end if;

  --       if s_axi_wready = '1' then
  --         s_axi_wvalid <= '0';
  --       end if;

  --       if s_axi_bvalid = '1' then
  --         s_axi_bready <= '0';
  --       end if;

  --       if s_axi_awvalid = '0' and s_axi_wvalid = '0' and s_axi_bready = '0' then
  --         exit;
  --       end if;
  --     end loop;

  --   end procedure wr;
  -- begin
  --   -- initialize the slave interface signals
  --   s_axi_araddr  <= (others => '0');
  --   s_axi_arvalid <= '0';
  --   s_axi_rdata   <= (others => '0');
  --   s_axi_rvalid  <= '0';
  --   s_axi_awaddr  <= (others => '0');
  --   s_axi_awvalid <= '0';
  --   s_axi_wdata   <= (others => '0');
  --   s_axi_wstrb   <= (others => '0');
  --   s_axi_wvalid  <= '0';
  --   s_axi_bready  <= '0';

  --   -- wait until rest is done
  --   wait until rising_edge(aclk) and aresetn = '0';

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

  --   report "END OF SIMULATION" severity FAILURE;

  -- end process;

end uart_avalon_ut_a;

-- synthesis translate_on
