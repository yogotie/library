
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;

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

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait until END_OF_SIMULATION = true;
    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  p_spi_csn : process
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

  p_s_axis : process
    procedure send_data( tdest : std_logic_vector(7 downto 0); tdata : std_logic_vector(7 downto 0); tlast : std_logic ) is
    begin
      s_axis_tdest  <= tdest;
      s_axis_tdata  <= tdata;
      s_axis_tlast  <= tlast;
      s_axis_tvalid <= '1';
      wait until rising_edge(aclk) and s_axis_tready = '1';
      s_axis_tdest  <= (others => '0');
      s_axis_tdata  <= (others => '0');
      s_axis_tlast  <= '0';
      s_axis_tvalid <= '0';
    end procedure;
  begin
    s_axis_tdata  <= (others => '0');
    s_axis_tlast  <= '0';
    s_axis_tvalid <= '0';

    wait until rising_edge(aclk) and aresetn = '1';

    send_data( X"00", X"01", '0' );
    send_data( X"00", X"02", '0' );
    send_data( X"00", X"03", '0' );
    send_data( X"00", X"04", '0' );
    send_data( X"00", X"05", '1' );

    wait;
  end process;

end behav_tb_spi_tx;

-- synthesis translate_on
