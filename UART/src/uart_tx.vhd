
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity uart_tx is
  generic(
    g_clk_freq    : integer := 100000000;
    g_baud_rate   : integer := 115200
  );
  port(
    aclk          : in  std_logic;
    aresetn       : in  std_logic;

    tx            : out std_logic;

    s_axis_tdata  : in  std_logic_vector(7 downto 0);
    s_axis_tlast  : in  std_logic;
    s_axis_tvalid : in  std_logic;
    s_axis_tready : out std_logic
  );
end uart_tx;

architecture rtl_uart_tx of uart_tx is

  constant C_MAX_COUNT  : integer := g_clk_freq / g_baud_rate;

  type T_tx_state is (S_IDLE, S_START, S_DATA, S_DONE);

  signal sig_tx_s       : T_tx_state := S_IDLE;

  signal sig_cnt_done   : std_logic;                    -- flags when a bit is done
  signal sig_counter    : unsigned(15 downto 0);        -- counts the bit time
  signal sig_bit_cnt    : unsigned(2 downto 0);         -- counts the number of bits transmitted
  signal sig_data       : std_logic_vector(7 downto 0); -- shift register for transmitting data

begin

  s_axis_tready <= '1' when sig_tx_s = S_DONE else '0';  -- return that s_axis_tready signal when the transmission is done

  PROC_tx : process(aclk) is
  begin
    if rising_edge(aclk) then
      case sig_tx_s is
        when S_START  => tx <= '0';       -- send that start bit
        when S_DATA   => tx <= sig_data(0); -- send the data bits
        when others   => tx <= '1';       -- send the stop bit
      end case;
    end if;
  end process;

  -- flag when the bit time is complete
  PROC_sig_cnd_done : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_cnt_done <= '0';
      else
        if sig_counter = C_MAX_COUNT - 2 then
          sig_cnt_done <= '1';
        else
          sig_cnt_done <= '0';
        end if;
      end if;
    end if;
  end process;

  -- counter for the length of each bit
  PROC_sig_counter : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_counter <= (others => '0');
      else
        if sig_cnt_done = '1' then
          sig_counter <= (others => '0');
        else
          sig_counter <= sig_counter + 1;
        end if;
      end if;
    end if;
  end process;

  -- count the bits transmitted
  PROC_sig_bit_cnt : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_bit_cnt <= (others => '0');
      else
        if sig_tx_s /= S_DATA then  -- aresetn the count when not in the data state
          sig_bit_cnt <= (others => '0');
        elsif sig_cnt_done = '1' then
          sig_bit_cnt <= sig_bit_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  -- shift data out
  PROC_sig_data : process(aclk) is
  begin
    if rising_edge(aclk) then
      if sig_tx_s = S_IDLE then -- get the data to send when in the idle state
        sig_data <= s_axis_tdata(sig_data'range);
      elsif sig_cnt_done = '1' and sig_tx_s = S_DATA then  -- move to the next bit at the end of a bit in the data state
        sig_data <= sig_data(0) & sig_data(sig_data'left downto 1);
      end if;
    end if;
  end process;

  PROC_sig_tx_s : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_tx_s <= S_IDLE;
      else
        case sig_tx_s is
          when S_IDLE => -- only being at the end of a bit time
            if s_axis_tvalid = '1' and sig_cnt_done = '1' then
              sig_tx_s <= S_START;
            end if;

          when S_START => -- move to data at the end of the start bit
            if sig_cnt_done = '1' then
              sig_tx_s <= S_DATA;
            end if;

          when S_DATA =>
            if sig_cnt_done = '1' and sig_bit_cnt = 7 then
              sig_tx_s <= S_DONE;
            end if;

          when S_DONE =>
            sig_tx_s <= S_IDLE;

        end case;
      end if;
    end if;
  end process;

end architecture rtl_uart_tx;

