
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity uart_avalon is
  generic(
    clk_freq            : integer := 100000000;
    baud_rate           : integer := 115200
  );
  port(
    clk                 : in  std_logic;
    reset               : in  std_logic;
    
    --------------------
    -- Interrupt Request
    --------------------
    ins_irq0_irq        : out std_logic;
    
    ------------------------
    -- FPGA Fabric Interface
    ------------------------
    avs_s0_address      : in  std_logic_vector(7 downto 0);
    avs_s0_read         : in  std_logic;
    avs_s0_readdata     : out std_logic_vector(31 downto 0);
    avs_s0_write        : in  std_logic;
    avs_s0_writedata    : in  std_logic_vector(31 downto 0);
    avs_s0_waitrequest  : out std_logic;
    
    ------------------------
    -- uart_avalon Interface
    ------------------------
    coe_rx_export       : in  std_logic;
    coe_tx_export       : out std_logic
  );
end uart_avalon;

architecture uart_avalon_a of uart_avalon is
  
  type reg_state is (S_IDLE, S_READ, S_WRITE, S_DONE);
  
  signal reg_s              : reg_state := S_IDLE;
  
  signal i_int_ena          : std_logic_vector(1 downto 0);
  signal i_int              : std_logic_vector(1 downto 0);
  
  signal i_rxData_data      : std_logic_vector(7 downto 0);
  signal i_rxData_valid     : std_logic;

  signal i_txData_ready     : std_logic;
  
  signal i_aso_rxData_data  : std_logic_vector(7 downto 0);
  signal i_aso_rxData_valid : std_logic;
  signal i_aso_rxData_ready : std_logic;
  
  signal i_asi_txData_data  : std_logic_vector(7 downto 0);
  signal i_asi_txData_valid : std_logic;
  signal i_asi_txData_ready : std_logic;
  
begin
  
  -- post an interrupt when an event occurs
  ins_irq0_irq        <= or_reduce( i_int_ena and i_int );
  
  -- the transaction is complete when in the DONE state
  avs_s0_waitrequest  <= '0' when reg_s = S_DONE else '1';

  -- set to '1' always because receieve data cannot be throttled
  i_aso_rxData_ready  <= '1';
  
  reg_rd_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        avs_s0_readdata <= (others => '0');
        i_rxData_data   <= (others => '0');
        i_rxData_valid  <= '0';
      else
        -- receieve data is ready when q_valid
        if i_aso_rxData_valid = '1' then
          i_rxData_data   <= i_aso_rxData_data;
          i_rxData_valid  <= '1';
        end if;
        
        if reg_s = S_READ then
          case avs_s0_address is
            when X"00" => -- return the rx and tx status
              avs_s0_readdata  <= X"0000000" & "00" & i_rxData_valid & i_txData_ready;
              
            when X"01" => 
              avs_s0_readdata <= X"0000000" & "00" & i_int_ena;
              
            when X"02" => 
              avs_s0_readdata <= X"0000000" & "00" & i_int;
              
            when X"03" => -- clear receieve data ready flag when reading UART data
              i_rxData_valid  <= '0';
              avs_s0_readdata <= X"000000" & i_rxData_data;
              
            when others  => -- set invalid data to something obvious
              avs_s0_readdata  <= X"DEADC0DE";
              
          end case;
        end if;
      end if;
    end if;
  end process;
  
  reg_wr_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_int_ena           <= (others => '0');
        i_int               <= (others => '0');
        i_asi_txData_data   <= (others => '0');
        i_asi_txData_valid  <= '0';
        i_txData_ready      <= '1';
      else
        if i_asi_txData_ready = '1' and i_int_ena(0) = '1' then
          i_int(0)            <= '1';
        end if;
        
        if i_aso_rxData_valid = '1' and i_int_ena(1) = '1' then
          i_int(1)            <= '1';
        end if;
        
        if i_asi_txData_ready = '1' then
          i_asi_txData_valid  <= '0';  -- clear the transmit data valid flag
          i_txData_ready      <= '1';  -- set the transmit data ready flag
        end if;
        
        if reg_s = S_WRITE then
          case avs_s0_address is
            when X"01" =>  -- set the interrupt enable
              i_int_ena           <= avs_s0_writedata(i_int_ena'range);
              
            when X"02" =>  -- clear interrupt on write of '1'
              i_int               <= i_int and (not avs_s0_writedata(i_int'range));
              
            when X"03" =>
              i_asi_txData_data   <= avs_s0_writedata(i_asi_txData_data'range); -- set the data to send
              i_asi_txData_valid  <= '1';                                       -- set the transmit data valid flag
              i_txData_ready      <= '0';                                       -- clear the transmit data ready flag
              
            when others  =>
              
          end case;
        end if;
      end if;
    end if;
  end process;
  
  reg_sm : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        reg_s <= S_IDLE;
      else
        case reg_s is
          when S_IDLE => 
            if avs_s0_read = '1' then     -- go to the read state on reads
              reg_s <= S_READ;
            elsif avs_s0_write = '1' then -- go to the write state on writes
              reg_s <= S_WRITE;
            end if;
            
          when S_READ => 
            reg_s <= S_DONE;
            
          when S_WRITE => 
            reg_s <= S_DONE;
            
          when S_DONE => 
            reg_s <= S_IDLE;
            
        end case;
      end if;
    end if;
  end process;
  
  uart_i : entity work.uart
    generic map (
      clk_freq                  => clk_freq,
      baud_rate                 => baud_rate
    )
    port map (
      clk                       => clk,
      reset                     => reset,
      
      ------------------------
      -- uart Interface
      ------------------------
      coe_rx_export             => coe_rx_export,
      coe_tx_export             => coe_tx_export,
      
      ------------------------
      -- FPGA Fabric Interface
      ------------------------
      aso_rxData_data           => i_aso_rxData_data,
      aso_rxData_startofpacket  => open,
      aso_rxData_endofpacket    => open,
      aso_rxData_valid          => i_aso_rxData_valid,
      aso_rxData_ready          => i_aso_rxData_ready,

      asi_txData_data           => i_asi_txData_data,
      asi_txData_startofpacket  => '1',
      asi_txData_endofpacket    => '1',
      asi_txData_valid          => i_asi_txData_valid,
      asi_txData_ready          => i_asi_txData_ready
    );

end uart_avalon_a;

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_avalon_ut is
  generic(
    clk_freq  : integer := 100000000;
    baud_rate : integer := 115200
  );
end uart_avalon_ut;

architecture uart_avalon_ut_a of uart_avalon_ut is
  
  signal clk_period         : time := real(real(1) / real(clk_freq)) * 1 sec;
  
  signal clk                : std_logic := '0';
  signal reset              : std_logic;
  signal ins_irq0_irq       : std_logic;
  signal avs_s0_address     : std_logic_vector(7 downto 0);
  signal avs_s0_read        : std_logic;
  signal avs_s0_readdata    : std_logic_vector(31 downto 0);
  signal avs_s0_write       : std_logic;
  signal avs_s0_writedata   : std_logic_vector(31 downto 0);
  signal avs_s0_waitrequest : std_logic;
  signal coe_rx_export      : std_logic;
  signal coe_tx_export      : std_logic;
  
  procedure wait_clks( n : integer ) is
  begin
    for i in 1 to n loop
      wait until rising_edge(clk);
    end loop;
  end procedure wait_clks;
  
begin
  
  UUT : entity work.uart_avalon
    generic map(
      clk_freq            => clk_freq,
      baud_rate           => baud_rate
    )
    port map(
      clk                 => clk,
      reset               => reset,
      ins_irq0_irq        => ins_irq0_irq,
      avs_s0_address      => avs_s0_address,
      avs_s0_read         => avs_s0_read,
      avs_s0_readdata     => avs_s0_readdata,
      avs_s0_write        => avs_s0_write,
      avs_s0_writedata    => avs_s0_writedata,
      avs_s0_waitrequest  => avs_s0_waitrequest,
      coe_rx_export       => coe_rx_export,
      coe_tx_export       => coe_tx_export
    );
  
  clk   <= not clk after clk_period / 2;
  reset <= '1', '0' after 100 ns;
  
  coe_rx_export <= coe_tx_export;
  
  avs_p : process
    -- procedure to perform a read transfer
    procedure rd( a : std_logic_vector(7 downto 0); expected : std_logic_vector(31 downto 0) ) is
    begin
      -- setup the read transfer
      avs_s0_read       <= '1';
      avs_s0_address    <= a(avs_s0_address'range);
      
      -- wait until the transfer is done
      wait until rising_edge(clk) and avs_s0_waitrequest = '0';

      assert avs_s0_readdata = expected
        report "ERROR expected(0x" & to_hstring(expected) & ") : actual(0x" & to_hstring(avs_s0_readdata) & ")"
        severity ERROR;

      -- clear the read
      avs_s0_read       <= '0';
    end procedure rd;
    
    -- procedure to perform a write transfer
    procedure wr( a : std_logic_vector(7 downto 0); d : std_logic_vector(31 downto 0) ) is
    begin
      -- setup the write transfer
      avs_s0_write      <= '1';
      avs_s0_address    <= a(avs_s0_address'range);
      avs_s0_writedata  <= d;
      
      -- wait until the transfer is done
      wait until rising_edge(clk) and avs_s0_waitrequest = '0';
      
      -- clear the write
      avs_s0_write      <= '0';
    end procedure wr;
  begin
    -- initialize the slave interface signals
    avs_s0_write      <= '0';
    avs_s0_read       <= '0';
    avs_s0_address    <= (others => '0');
    avs_s0_writedata  <= (others => '0');
    
    -- wait until rest is done
    wait until rising_edge(clk) and reset = '0';
    
    wr( X"01", X"0000_0003" );  -- enable tx and rx interrupts
    wr( X"03", X"0000_0001" );  -- write data to transmit
    
    wait until rising_edge(clk) and ins_irq0_irq = '1';
    rd( X"00", X"0000_0001" );  -- read status
    rd( X"02", X"0000_0001" );  -- read interrupt value
    rd( X"03", X"0000_0000" );  -- read data
    wr( X"02", X"0000_0003" );  -- clear interrupt
    rd( X"02", X"0000_0000" );  -- read interrupt value
    
    wait until rising_edge(clk) and ins_irq0_irq = '1';
    rd( X"00", X"0000_0003" );  -- read status
    rd( X"02", X"0000_0002" );  -- read interrupt value
    rd( X"03", X"0000_0001" );  -- read data
    wr( X"02", X"0000_0003" );  -- clear interrupt
    rd( X"02", X"0000_0000" );  -- read interrupt value
    rd( X"00", X"0000_0001" );  -- read status

    report "END OF SIMULATION" severity FAILURE;

  end process;
  
end uart_avalon_ut_a;

-- synthesis translate_on
