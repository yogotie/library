
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi is
  generic (
    clk_freq                : integer := 100000000;
    spi_freq                : integer := 3200000;
    cpol                    : integer := 1;
    cpha                    : integer := 1;
    csn_width               : integer := 1
  );
  port (
    clk                     : in  std_logic;
    reset                   : in  std_logic;

    coe_csn_export          : out std_logic_vector(csn_width - 1 downto 0);
    coe_mosi_export         : out std_logic;
    coe_miso_export         : in  std_logic;
    coe_clk_export          : out std_logic;

    aso_rx_channel          : out std_logic_vector(7 downto 0);
    aso_rx_data             : out std_logic_vector(7 downto 0);
    aso_rx_startofpacket    : out std_logic;
    aso_rx_endofpacket      : out std_logic;
    aso_rx_valid            : out std_logic;
    aso_rx_ready            : in  std_logic;

    asi_tx_channel          : in  std_logic_vector(7 downto 0);
    asi_tx_data             : in  std_logic_vector(7 downto 0);
    asi_tx_startofpacket    : in  std_logic;
    asi_tx_endofpacket      : in  std_logic;
    asi_tx_valid            : in  std_logic;
    asi_tx_ready            : out std_logic
  );
end spi;

architecture spi_a of spi is
  
  signal i_coe_csn_export   : std_logic_vector(csn_width - 1 downto 0);
  signal i_coe_mosi_export  : std_logic;
  signal i_coe_miso_export  : std_logic;
  signal i_coe_clk_export   : std_logic;

begin

  coe_csn_export    <= i_coe_csn_export;
  coe_mosi_export   <= i_coe_mosi_export;
  i_coe_miso_export <= coe_miso_export;
  coe_clk_export    <= i_coe_clk_export;

  u_spi_tx : entity work.spi_tx
    generic map (
      clk_freq                => clk_freq,
      spi_freq                => spi_freq,
      cpol                    => cpol,
      cpha                    => cpha,
      csn_width               => csn_width
    )
    port map (
      clk                     => clk,
      reset                   => reset,

      coe_csn_export          => i_coe_csn_export,
      coe_mosi_export         => i_coe_mosi_export,
      coe_clk_export          => i_coe_clk_export,

      asi_data_channel        => asi_tx_channel,
      asi_data_data           => asi_tx_data,
      asi_data_startofpacket  => asi_tx_startofpacket,
      asi_data_endofpacket    => asi_tx_endofpacket,
      asi_data_valid          => asi_tx_valid,
      asi_data_ready          => asi_tx_ready
    );

  u_spi_rx : entity work.spi_rx
    generic map (
      clk_freq                => clk_freq,
      spi_freq                => spi_freq,
      cpol                    => cpol,
      cpha                    => cpha,
      csn_width               => csn_width
    )
    port map (
      clk                     => clk,
      reset                   => reset,

      coe_csn_export          => i_coe_csn_export,
      coe_miso_export         => i_coe_miso_export,
      coe_clk_export          => i_coe_clk_export,

      aso_data_channel        => aso_rx_channel,
      aso_data_data           => aso_rx_data,
      aso_data_startofpacket  => aso_rx_startofpacket,
      aso_data_endofpacket    => aso_rx_endofpacket,
      aso_data_valid          => aso_rx_valid,
      aso_data_ready          => aso_rx_ready
    );

end spi_a;

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_ut is
  generic (
    clk_freq                : integer := 100000000;
    spi_freq                : integer := 3200000;
    cpol                    : integer := 1;
    cpha                    : integer := 1;
    csn_width               : integer := 1
  );
end spi_ut;

architecture spi_ut_a of spi_ut is
  
  signal spi_period             : time := real(real(1) / real(spi_freq)) * 1 sec;
  signal clk_period             : time := real(real(1) / real(clk_freq)) * 1 sec;
  
  signal clk                    : std_logic := '0';
  signal reset                  : std_logic;

  signal coe_csn_export         : std_logic_vector(csn_width - 1 downto 0);
  signal coe_mosi_export        : std_logic;
  signal coe_miso_export        : std_logic;
  signal coe_clk_export         : std_logic;

  signal aso_rx_channel         : std_logic_vector(7 downto 0);
  signal aso_rx_data            : std_logic_vector(7 downto 0);
  signal aso_rx_startofpacket   : std_logic;
  signal aso_rx_endofpacket     : std_logic;
  signal aso_rx_valid           : std_logic;
  signal aso_rx_ready           : std_logic;

  signal asi_tx_channel         : std_logic_vector(7 downto 0);
  signal asi_tx_data            : std_logic_vector(7 downto 0);
  signal asi_tx_startofpacket   : std_logic;
  signal asi_tx_endofpacket     : std_logic;
  signal asi_tx_valid           : std_logic;
  signal asi_tx_ready           : std_logic;
      
begin

  UUT : entity work.spi
    generic map (
      clk_freq                => clk_freq,
      spi_freq                => spi_freq,
      cpol                    => cpol,
      cpha                    => cpha,
      csn_width               => csn_width
    )
    port map (
      clk                     => clk,
      reset                   => reset,

      coe_csn_export          => coe_csn_export,
      coe_mosi_export         => coe_mosi_export,
      coe_miso_export         => coe_miso_export,
      coe_clk_export          => coe_clk_export,

      aso_rx_channel          => aso_rx_channel,
      aso_rx_data             => aso_rx_data,
      aso_rx_startofpacket    => aso_rx_startofpacket,
      aso_rx_endofpacket      => aso_rx_endofpacket,
      aso_rx_valid            => aso_rx_valid,
      aso_rx_ready            => aso_rx_ready,

      asi_tx_channel          => asi_tx_channel,
      asi_tx_data             => asi_tx_data,
      asi_tx_startofpacket    => asi_tx_startofpacket,
      asi_tx_endofpacket      => asi_tx_endofpacket,
      asi_tx_valid            => asi_tx_valid,
      asi_tx_ready            => asi_tx_ready
    );
  
  clk   <= not clk after clk_period / 2;
  reset <= '1', '0' after 100 ns;

  coe_miso_export <= coe_mosi_export;

  aso_rx_p : process
    procedure check_data( sop : std_logic; eop : std_logic; channel : std_logic_vector(7 downto 0); expected : std_logic_vector(7 downto 0) ) is
    begin
      wait until rising_edge(clk) and aso_rx_valid = '1';

      assert aso_rx_channel = channel
        report "ERROR channel : expected(0x" & to_hstring(channel) & ") : actual(0x" & to_hstring(aso_rx_channel) & ")"
        severity ERROR;

      assert aso_rx_startofpacket = sop
        report "ERROR : startofpacket : expected(" & std_logic'image(sop) & ") : actual(" & std_logic'image(aso_rx_startofpacket) & ")"
        severity ERROR;

      assert aso_rx_endofpacket = eop
        report "ERROR : endofpacket : expected(" & std_logic'image(eop) & ") : actual(" & std_logic'image(aso_rx_endofpacket) & ")"
        severity ERROR;

      assert aso_rx_data = expected
        report "ERROR : data : expected(0x" & to_hstring(expected) & ") : actual(0x" & to_hstring(aso_rx_data) & ")"
        severity ERROR;
    end procedure;
  begin
    check_data( '1', '0', X"00", X"01" );
    check_data( '0', '0', X"00", X"02" );
    check_data( '0', '0', X"00", X"03" );
    check_data( '0', '0', X"00", X"04" );
    check_data( '0', '1', X"00", X"05" );

    report "END OF SIMULATION" severity FAILURE;

  end process;

  aso_rx_ready  <= '1';

  asi_data_p : process
    procedure send_data( channel : std_logic_vector(7 downto 0); sop : std_logic; eop : std_logic; value : std_logic_vector(7 downto 0) ) is
    begin
      asi_tx_channel        <= channel;
      asi_tx_data           <= value;
      asi_tx_startofpacket  <= sop;
      asi_tx_endofpacket    <= eop;
      asi_tx_valid          <= '1';
      wait until rising_edge(clk) and asi_tx_ready = '1';
      asi_tx_channel        <= (others => '0');
      asi_tx_data           <= (others => '0');
      asi_tx_startofpacket  <= '0';
      asi_tx_endofpacket    <= '0';
      asi_tx_valid          <= '0';
    end procedure;
  begin
    asi_tx_data           <= (others => '0');
    asi_tx_startofpacket  <= '0';
    asi_tx_endofpacket    <= '0';
    asi_tx_valid          <= '0';

    wait until rising_edge(clk) and reset = '0';

    send_data( X"00", '1', '0', X"01" );
    send_data( X"00", '0', '0', X"02" );
    send_data( X"00", '0', '0', X"03" );
    send_data( X"00", '0', '0', X"04" );
    send_data( X"00", '0', '1', X"05" );

    wait;
  end process;

end spi_ut_a;

-- synthesis translate_on
