
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
  generic(
    clk_freq                  : integer := 100000000;
    baud_rate                 : integer := 115200
  );
  port(
    clk                       : in  std_logic;
    reset                     : in  std_logic;
    
    ------------------------
    -- uart Interface
    ------------------------
    coe_rx_export             : in  std_logic;
    coe_tx_export             : out std_logic;
    
    ------------------------
    -- FPGA Fabric Interface
    ------------------------
    aso_rxData_data           : out std_logic_vector(7 downto 0);
    aso_rxData_startofpacket  : out std_logic;
    aso_rxData_endofpacket    : out std_logic;
    aso_rxData_valid          : out std_logic;
    aso_rxData_ready          : in  std_logic;
    
    asi_txData_data           : in  std_logic_vector(7 downto 0);
    asi_txData_startofpacket  : in  std_logic;
    asi_txData_endofpacket    : in  std_logic;
    asi_txData_valid          : in  std_logic;
    asi_txData_ready          : out std_logic
  );
end uart;

architecture uart_a of uart is
begin

  uart_rx_i : entity work.uart_rx
    generic map(
      clk_freq                => clk_freq,
      baud_rate               => baud_rate
    )
    port map(
      clk                     => clk,
      reset                   => reset,
      
      ------------------------
      -- uart_rx Interface
      ------------------------
      coe_rx_export           => coe_rx_export,
      
      ------------------------
      -- FPGA Fabric Receive Interface
      ------------------------
      aso_data_data           => aso_rxData_data,
      aso_data_startofpacket  => aso_rxData_startofpacket,
      aso_data_endofpacket    => aso_rxData_endofpacket,
      aso_data_valid          => aso_rxData_valid,
      aso_data_ready          => aso_rxData_ready
    );

  uart_tx_i : entity work.uart_tx
    generic map(
      clk_freq                => clk_freq,
      baud_rate               => baud_rate
    )
    port map(
      clk                     => clk,
      reset                   => reset,
      
      ------------------------
      -- uart_tx Interface
      ------------------------
      coe_tx_export           => coe_tx_export,
      
      ------------------------
      -- FPGA Fabric Transmit Interface
      ------------------------
      asi_data_data           => asi_txData_data,
      asi_data_startofpacket  => asi_txData_startofpacket,
      asi_data_endofpacket    => asi_txData_endofpacket,
      asi_data_valid          => asi_txData_valid,
      asi_data_ready          => asi_txData_ready
    );
  
end uart_a;

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_ut is
  generic(
    clk_freq                    : integer := 100000000;
    baud_rate                   : integer := 115200
  );
end uart_ut;

architecture uart_ut_a of uart_ut is
  
  signal clk_period               : time := real(real(1) / real(clk_freq)) * 1 sec;
  
  signal clk                      : std_logic := '0';
  signal reset                    : std_logic;
  signal coe_rx_export            : std_logic;
  signal coe_tx_export            : std_logic;
  signal aso_rxData_data          : std_logic_vector(7 downto 0);
  signal aso_rxData_startofpacket : std_logic;
  signal aso_rxData_endofpacket   : std_logic;
  signal aso_rxData_valid         : std_logic;
  signal aso_rxData_ready         : std_logic;
  signal asi_txData_data          : std_logic_vector(7 downto 0);
  signal asi_txData_startofpacket : std_logic;
  signal asi_txData_endofpacket   : std_logic;
  signal asi_txData_valid         : std_logic;
  signal asi_txData_ready         : std_logic;
  
begin
  
  UUT : entity work.uart
    generic map(
      clk_freq                  => clk_freq,
      baud_rate                 => baud_rate
    )
    port map(
      clk                       => clk,
      reset                     => reset,
      coe_rx_export             => coe_rx_export,
      coe_tx_export             => coe_tx_export,
      aso_rxData_data           => aso_rxData_data,
      aso_rxData_startofpacket  => aso_rxData_startofpacket,
      aso_rxData_endofpacket    => aso_rxData_endofpacket,
      aso_rxData_valid          => aso_rxData_valid,
      aso_rxData_ready          => aso_rxData_ready,
      asi_txData_data           => asi_txData_data,
      asi_txData_startofpacket  => asi_txData_startofpacket,
      asi_txData_endofpacket    => asi_txData_endofpacket,
      asi_txData_valid          => asi_txData_valid,
      asi_txData_ready          => asi_txData_ready
    );
  
  clk   <= not clk after clk_period / 2;
  reset <= '1', '0' after 100 ns;
  
  coe_rx_export <= coe_tx_export;

  aso_rxData_p : process
    procedure check_data( expected : std_logic_vector(7 downto 0) ) is
    begin
      wait until rising_edge(clk) and aso_rxData_valid = '1';
      assert aso_rxData_data = expected
        report "ERROR expected(0x" & to_hstring(expected) & ") : actual(0x" & to_hstring(aso_rxData_data) & ")"
        severity ERROR;
    end procedure;
  begin
    check_data( X"12" );
    check_data( X"34" );

    report "END OF SIMULATION" severity FAILURE;

  end process;

  aso_rxData_ready <= '1';
  
  asi_txData_p : process
    procedure send_data( value : std_logic_vector(7 downto 0) ) is
    begin
      asi_txData_data   <= value;
      asi_txData_valid  <= '1';
      wait until rising_edge(clk) and asi_txData_ready = '1';
      asi_txData_valid  <= '0';
      wait until rising_edge(clk);
    end procedure;
  begin
    asi_txData_data         <= (others => '0');
    asi_txData_startofpacket  <= '1';
    asi_txData_endofpacket    <= '1';
    asi_txData_valid        <= '0';
    
    wait for 1 us;
    send_data( X"12" );
    send_data( X"34" );
    wait;
  end process;
  
end uart_ut_a;

-- synthesis translate_on
