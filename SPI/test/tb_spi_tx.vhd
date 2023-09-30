
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;
  context vunit_lib.vc_context;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_spi_tx is
  generic (
    runner_cfg  : string;
    clk_freq    : integer := 100000000;
    spi_freq    : integer := 3200000;
    cpol        : integer := 1;
    cpha        : integer := 1;
    csn_width   : integer := 1
  );
end tb_spi_tx;

architecture behav_tb_spi_tx of tb_spi_tx is

  constant s_axis           : axi_stream_master_t := new_axi_stream_master( data_length => 8, dest_length => 8 );
  
  signal END_OF_SIMULATION  : boolean := false;

  signal aclk               : std_logic := '0';
  signal aresetn            : std_logic;

  signal spi_csn            : std_logic_vector(csn_width - 1 downto 0);
  signal spi_mosi           : std_logic;
  signal spi_clk            : std_logic;

  signal s_axis_tdest       : std_logic_vector(7 downto 0);
  signal s_axis_tdata       : std_logic_vector(7 downto 0);
  signal s_axis_tlast       : std_logic;
  signal s_axis_tvalid      : std_logic;
  signal s_axis_tready      : std_logic;

begin

  UUT : entity work.spi_tx
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
      spi_clk       => spi_clk,

      s_axis_tdest  => s_axis_tdest,
      s_axis_tdata  => s_axis_tdata,
      s_axis_tlast  => s_axis_tlast,
      s_axis_tvalid => s_axis_tvalid,
      s_axis_tready => s_axis_tready
    );

  aclk    <= not aclk after 5 ns;
  aresetn <= '0', '1' after 100 ns;

  test_runner_watchdog(runner, 10 ms);

  PROC_main : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait until END_OF_SIMULATION = true;
    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  PROC_spi_csn : process
    procedure check_data( csn : std_logic_vector(spi_csn'range); data : std_logic_vector(7 downto 0) ) is
      variable actual : std_logic_vector(data'range) := (others => '0');
    begin
      wait until spi_csn /= (spi_csn'range => 'X') and spi_clk /= 'X';

      for i in 7 downto 0 loop
        if (cpol = 0 and cpha = 0) or (cpol = 1 and cpha = 1) then
          wait until rising_edge( spi_clk );
        else
          wait until falling_edge( spi_clk );
        end if;

        if i = 7 then
          assert spi_csn = csn
            report "ERROR : CSN : expected(0x" & to_hstring(csn) & ") : actual(0x" & to_hstring(spi_csn) & ")"
            severity ERROR;
        end if;

        actual(i) := spi_mosi;
      end loop;

      assert actual = data
        report "ERROR expected(0x" & to_hstring(data) & ") : actual(0x" & to_hstring(actual) & ")"
        severity ERROR;

      wait for 1 ps;

    end procedure;
  begin

    check_data( "0", X"01" );
    check_data( "0", X"02" );
    check_data( "0", X"03" );
    check_data( "0", X"04" );
    check_data( "0", X"05" );

    wait for 1 us;

    END_OF_SIMULATION <= true;
    wait;
  end process;

  PROC_s_axis : process
  begin
    wait until rising_edge(aclk) and aresetn = '1';

    push_axi_stream( net, s_axis, tdest => X"00", tdata => X"01", tlast => '0' );
    push_axi_stream( net, s_axis, tdest => X"00", tdata => X"02", tlast => '0' );
    push_axi_stream( net, s_axis, tdest => X"00", tdata => X"03", tlast => '0' );
    push_axi_stream( net, s_axis, tdest => X"00", tdata => X"04", tlast => '0' );
    push_axi_stream( net, s_axis, tdest => X"00", tdata => X"05", tlast => '1' );

    wait;
  end process;

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

end behav_tb_spi_tx;

-- synthesis translate_on
