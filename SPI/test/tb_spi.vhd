
-- synthesis translate_off

library vunit_lib;
  context vunit_lib.vunit_context;

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

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait until END_OF_SIMULATION = true;
    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  spi_miso <= spi_mosi;

  p_m_axis : process
    procedure check_data( tdest : std_logic_vector(7 downto 0); tdata : std_logic_vector(7 downto 0); tlast : std_logic ) is
    begin
      wait until rising_edge(aclk) and m_axis_tvalid = '1';

      assert m_axis_tdest = tdest
        report "ERROR tdest : tdata(0x" & to_hstring(tdest) & ") : actual(0x" & to_hstring(m_axis_tdest) & ")"
        severity ERROR;

      assert m_axis_tdata = tdata
        report "ERROR : data : tdata(0x" & to_hstring(tdata) & ") : actual(0x" & to_hstring(m_axis_tdata) & ")"
        severity ERROR;

      assert m_axis_tlast = tlast
        report "ERROR : endofpacket : tdata(" & std_logic'image(tlast) & ") : actual(" & std_logic'image(m_axis_tlast) & ")"
        severity ERROR;
    end procedure;
  begin
    check_data( X"00", X"01", '0' );
    check_data( X"00", X"02", '0' );
    check_data( X"00", X"03", '0' );
    check_data( X"00", X"04", '0' );
    check_data( X"00", X"05", '1' );

    END_OF_SIMULATION <= true;

    wait;
  end process;

  m_axis_tready  <= '1';

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

    wait until rising_edge(aclk) and aresetn = '0';

    send_data( X"00", X"01", '0' );
    send_data( X"00", X"02", '0' );
    send_data( X"00", X"03", '0' );
    send_data( X"00", X"04", '0' );
    send_data( X"00", X"05", '1' );

    wait;
  end process;

end behav_tb_spi;

-- synthesis translate_on

