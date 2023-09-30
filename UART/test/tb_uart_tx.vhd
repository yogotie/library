
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;
  context vunit_lib.vc_context;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_uart_tx is
  generic(
    runner_cfg  : string;
    g_clk_freq  : integer := 100000000;
    g_baud_rate : integer := 115200
  );
end tb_uart_tx;

architecture behav_tb_uart_tx of tb_uart_tx is
  
  constant s_axis           : axi_stream_master_t := new_axi_stream_master( data_length => 8 );

  signal END_OF_SIMULATION  : boolean := false;

  signal C_BAUD_PERIOD      : time := real(real(1) / real(g_baud_rate)) * 1 sec;
  signal C_CLK_PERIOD       : time := real(real(1) / real(g_clk_freq)) * 1 sec;
  
  signal aclk               : std_logic := '0';
  signal aresetn            : std_logic;
  signal tx                 : std_logic;
  signal s_axis_tdata       : std_logic_vector(7 downto 0);
  signal s_axis_tlast       : std_logic;
  signal s_axis_tvalid      : std_logic;
  signal s_axis_tready      : std_logic;
  
begin
  
  UUT : entity work.uart_tx
    generic map(
      g_clk_freq      => g_clk_freq,
      g_baud_rate     => g_baud_rate
    )
    port map(
      aclk          => aclk,
      aresetn       => aresetn,
      tx            => tx,
      s_axis_tdata  => s_axis_tdata,
      s_axis_tlast  => s_axis_tlast,
      s_axis_tvalid => s_axis_tvalid,
      s_axis_tready => s_axis_tready
    );
  
  aclk    <= not aclk after C_CLK_PERIOD / 2;
  aresetn <= '0', '1' after 100 ns;

  test_runner_watchdog(runner, 10 ms);

  PROC_main : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait until END_OF_SIMULATION = true;
    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  PROC_tx : process
    procedure check_data( expected : std_logic_vector(7 downto 0) ) is
      variable actual : std_logic_vector(7 downto 0);
    begin
      wait until falling_edge(tx);
      wait for C_BAUD_PERIOD / 2;
      for i in 0 to 7 loop
        wait for C_BAUD_PERIOD;
        actual(i) := tx;
      end loop;

      assert actual = expected
        report "ERROR expected(0x" & to_hstring(expected) & ") : actual(0x" & to_hstring(actual) & ")"
        severity ERROR;

    end procedure;
  begin

    check_data( X"12" );
    check_data( X"34" );

    END_OF_SIMULATION <= true;
    wait;
  end process;
  
  s_axis_tlast    <= '1';

  PROC_s_axis : process
  begin
    wait for 1 us;
    push_axi_stream( net, s_axis, tdata => X"12", tlast => '1' );
    push_axi_stream( net, s_axis, tdata => X"34", tlast => '1' );

    wait;
  end process;

  U_s_axis : entity vunit_lib.axi_stream_master
    generic map(
      master  => s_axis
    )
    port map(
      aclk     => aclk,
      areset_n => aresetn,
      tdata    => s_axis_tdata,
      tlast    => s_axis_tlast,
      tvalid   => s_axis_tvalid,
      tready   => s_axis_tready
    );
  
end architecture behav_tb_uart_tx;

-- synthesis translate_on
