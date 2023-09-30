
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;
  context vunit_lib.vc_context;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_spi_rx is
  generic(
    runner_cfg  : string;
    clk_freq    : integer := 100000000;
    spi_freq    : integer := 3200000;
    cpol        : integer := 1;
    cpha        : integer := 1;
    csn_width   : integer := 2
  );
end tb_spi_rx;

architecture behav_tb_spi_rx of tb_spi_rx is

  constant m_axis           : axi_stream_slave_t  := new_axi_stream_slave ( data_length => 8, dest_length => 8 );

  signal END_OF_SIMULATION  : boolean := false;

  signal spi_period         : time := real(real(1) / real(spi_freq)) * 1 sec;
  signal clk_period         : time := real(real(1) / real(clk_freq)) * 1 sec;

  signal aclk               : std_logic := '0';
  signal aresetn            : std_logic;
  signal spi_csn            : std_logic_vector(csn_width - 1 downto 0);
  signal spi_miso           : std_logic;
  signal spi_clk            : std_logic;
  signal m_axis_tdest       : std_logic_vector(7 downto 0);
  signal m_axis_tdata       : std_logic_vector(7 downto 0);
  signal m_axis_tlast       : std_logic;
  signal m_axis_tvalid      : std_logic;
  signal m_axis_tready      : std_logic;

begin

  UUT : entity work.spi_rx
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
      spi_miso      => spi_miso,
      spi_clk       => spi_clk,

      m_axis_tdest  => m_axis_tdest,
      m_axis_tdata  => m_axis_tdata,
      m_axis_tlast  => m_axis_tlast,
      m_axis_tvalid => m_axis_tvalid,
      m_axis_tready => m_axis_tready
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

  PROC_spi_miso : process
    procedure send_data( csn : std_logic_vector(spi_csn'range); data : std_logic_vector(7 downto 0); bit_cnt : integer ) is
    begin
      if spi_csn /= csn then
        spi_csn <= csn;
        wait for spi_period;
      end if;

      for i in bit_cnt - 1 downto 0 loop
        spi_miso <= data(i);
        if (cpol = 1 and cpha = 1) or (cpol = 0 and cpha = 0) then
          spi_clk  <= '0'; wait for spi_period / 2; spi_clk  <= '1'; wait for spi_period / 2;
        else
          spi_clk  <= '1'; wait for spi_period / 2; spi_clk  <= '0'; wait for spi_period / 2;
        end if;
      end loop;

    if cpol = 1 then
      spi_clk  <= '1';
    else
      spi_clk  <= '0';
    end if;

    end procedure;
  begin
    spi_csn  <= (others => '1');
    spi_miso <= '0';

    if cpol = 1 then
      spi_clk  <= '1';
    else
      spi_clk  <= '0';
    end if;

    spi_csn <= "11";
    send_data( "10", X"01", 8 );
    spi_csn <= "11"; wait for 100 ns;
    send_data( "01", X"02", 8 );
    send_data( "01", X"03", 8 );
    spi_csn <= "11";

    wait;
  end process;

  PROC_m_axis_tdata : process
  begin
    check_axi_stream( net, m_axis, tdest => X"00", expected => X"01", tlast => '1' );
    check_axi_stream( net, m_axis, tdest => X"01", expected => X"02", tlast => '0' );
    check_axi_stream( net, m_axis, tdest => X"01", expected => X"03", tlast => '1' );

    END_OF_SIMULATION <= true;
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

end behav_tb_spi_rx;

-- synthesis translate_on
