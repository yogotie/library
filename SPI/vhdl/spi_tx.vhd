
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_tx is
  generic(
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
    coe_clk_export          : out std_logic;

    asi_data_channel        : in  std_logic_vector(7 downto 0);
    asi_data_data           : in  std_logic_vector(7 downto 0);
    asi_data_startofpacket  : in  std_logic;
    asi_data_endofpacket    : in  std_logic;
    asi_data_valid          : in  std_logic;
    asi_data_ready          : out std_logic
  );
end spi_tx;

architecture spi_tx_a of spi_tx is

  constant max_count  : integer := clk_freq / spi_freq;

  type spi_state is (S_IDLE, S_SET_CSN, S_DATA, S_CLR_CSN, S_DONE);

  signal spi_s            : spi_state := S_IDLE;

  signal i_coe_clk_export : std_logic;

  signal i_cnt_done       : std_logic;
  signal i_counter        : unsigned(31 downto 0);
  signal i_bit_cnt        : integer range 0 to 7;
  signal i_word_done      : std_logic;

begin

  coe_clk_export_pol_0_g : if cpol = 0 generate
    coe_clk_export <= not i_coe_clk_export;
  end generate;

  coe_clk_export_pol_1_g : if cpol = 1 generate
    coe_clk_export <= i_coe_clk_export;
  end generate;

  asi_data_ready  <= '1' when spi_s = S_DATA and i_word_done = '1' and i_cnt_done = '1' else '0';  -- return that asi_data_ready signal when the transmission is done

  i_word_done     <= '1' when i_bit_cnt = 0 else '0';

  csn_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        coe_csn_export <= (others => '1');
      else
        if spi_s = S_SET_CSN then
          coe_csn_export( to_integer(unsigned(asi_data_channel)) ) <= '0';
        end if;

        if spi_s = S_CLR_CSN then
          coe_csn_export <= (others => '1');
        end if;
      end if;
    end if;
  end process;

  mosi_p : process(clk) is
  begin
    if rising_edge(clk) then
      case spi_s is
        when S_IDLE => coe_mosi_export <= '0';
        when others => coe_mosi_export <= asi_data_data(i_bit_cnt); -- send the data bits
      end case;
    end if;
  end process;

  clk_p : process(clk) is
  begin
    if rising_edge(clk) then
      if spi_s = S_DATA then
        if cpha = 1 then
          if i_counter = 0 then i_coe_clk_export <= '0'; elsif i_counter = max_count / 2 then i_coe_clk_export <= '1'; end if;
        else
          if i_counter = 0 then i_coe_clk_export <= '1'; elsif i_counter = max_count / 2 then i_coe_clk_export <= '0'; end if;
        end if;
      elsif spi_s = S_DONE then
        if cpha = 1 then
          if asi_data_valid = '1' and asi_data_startofpacket = '0' then i_coe_clk_export <= '0'; end if;
        else
          if asi_data_valid = '1' and asi_data_startofpacket = '0' then i_coe_clk_export <= '1'; end if;
        end if;
      else
        i_coe_clk_export <= '1';
      end if;
    end if;
  end process;

  -- flag when the bit time is complete
  i_cnt_done_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_cnt_done <= '0';
      else
        if i_counter = max_count - 2 then
          i_cnt_done <= '1';
        else
          i_cnt_done <= '0';
        end if;
      end if;
    end if;
  end process;
  
  -- counter for the length of each bit
  i_counter_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_counter <= (others => '0');
      else
        if i_cnt_done = '1' then
          i_counter <= (others => '0');
        else
          i_counter <= i_counter + 1;
        end if;
      end if;
    end if;
  end process;

  i_bit_cnt_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_bit_cnt <= 0;
      else
        if (spi_s /= S_DATA or (spi_s = S_DATA and i_word_done = '1')) and i_cnt_done = '1' then
          i_bit_cnt <= 7;
        elsif i_bit_cnt /= 0 and i_cnt_done = '1' then
          i_bit_cnt <= i_bit_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  spi_sm : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        spi_s <= S_IDLE;
      else
        case spi_s is
          when S_IDLE => 
            if asi_data_startofpacket = '1' and asi_data_valid = '1' and i_cnt_done = '1' then
              spi_s <= S_SET_CSN;
            elsif asi_data_valid = '1' and i_cnt_done = '1' then
              spi_s <= S_DATA;
            end if;

          when S_SET_CSN => 
            if i_cnt_done = '1' then
              spi_s <= S_DATA;
            end if;

          when S_DATA => 
            if i_word_done = '1' and i_cnt_done = '1' then
              if asi_data_endofpacket = '1' then
                spi_s <= S_CLR_CSN;
              else
                spi_s <= S_DONE;
              end if;
            end if;

          when S_CLR_CSN => 
            if i_cnt_done = '1' then
              spi_s <= S_DONE;
            end if;

          when S_DONE => 
            if asi_data_valid = '1' and asi_data_startofpacket = '0' then
              spi_s <= S_DATA;
            elsif asi_data_valid = '1' and asi_data_startofpacket = '1' then
              spi_s <= S_SET_CSN;
            else
              spi_s <= S_IDLE;
            end if;

        end case;
      end if;
    end if;
  end process;

end spi_tx_a;

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_tx_ut is
  generic (
    clk_freq                : integer := 100000000;
    spi_freq                : integer := 3200000;
    cpol                    : integer := 1;
    cpha                    : integer := 1;
    csn_width               : integer := 1
  );
end spi_tx_ut;

architecture spi_tx_ut_a of spi_tx_ut is

  signal clk                     : std_logic := '0';
  signal reset                   : std_logic;

  signal coe_csn_export          : std_logic_vector(csn_width - 1 downto 0);
  signal coe_mosi_export         : std_logic;
  signal coe_clk_export          : std_logic;

  signal asi_data_channel        : std_logic_vector(7 downto 0);
  signal asi_data_data           : std_logic_vector(7 downto 0);
  signal asi_data_startofpacket  : std_logic;
  signal asi_data_endofpacket    : std_logic;
  signal asi_data_valid          : std_logic;
  signal asi_data_ready          : std_logic;

begin
  
  UUT : entity work.spi_tx
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
      coe_clk_export          => coe_clk_export,

      asi_data_channel        => asi_data_channel,
      asi_data_data           => asi_data_data,
      asi_data_startofpacket  => asi_data_startofpacket,
      asi_data_endofpacket    => asi_data_endofpacket,
      asi_data_valid          => asi_data_valid,
      asi_data_ready          => asi_data_ready
    );

  clk <= not clk after 5 ns;
  reset <= '1', '0' after 100 ns;

  coe_mosi_export_p : process
    procedure check_data( csn : std_logic_vector(coe_csn_export'range); data : std_logic_vector(7 downto 0) ) is
      variable actual : std_logic_vector(data'range) := (others => '0');
    begin
      wait until coe_csn_export /= (coe_csn_export'range => 'X') and coe_clk_export /= 'X';

      for i in 7 downto 0 loop
        if (cpol = 0 and cpha = 0) or (cpol = 1 and cpha = 1) then
          wait until rising_edge( coe_clk_export );
        else
          wait until falling_edge( coe_clk_export );
        end if;

        if i = 7 then
          assert coe_csn_export = csn
            report "ERROR : CSN : expected(0x" & to_hstring(csn) & ") : actual(0x" & to_hstring(coe_csn_export) & ")"
            severity ERROR;
        end if;

        actual(i) := coe_mosi_export;
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

    report "END OF SIMULATION" severity FAILURE;

  end process;

  asi_data_p : process
    procedure send_data( channel : std_logic_vector(7 downto 0); sop : std_logic; eop : std_logic; value : std_logic_vector(7 downto 0) ) is
    begin
      asi_data_channel        <= channel;
      asi_data_data           <= value;
      asi_data_startofpacket  <= sop;
      asi_data_endofpacket    <= eop;
      asi_data_valid          <= '1';
      wait until rising_edge(clk) and asi_data_ready = '1';
      asi_data_channel        <= (others => '0');
      asi_data_data           <= (others => '0');
      asi_data_startofpacket  <= '0';
      asi_data_endofpacket    <= '0';
      asi_data_valid          <= '0';
    end procedure;
  begin
    asi_data_data           <= (others => '0');
    asi_data_startofpacket  <= '0';
    asi_data_endofpacket    <= '0';
    asi_data_valid          <= '0';

    wait until rising_edge(clk) and reset = '0';

    send_data( X"00", '1', '0', X"01" );
    send_data( X"00", '0', '0', X"02" );
    send_data( X"00", '0', '0', X"03" );
    send_data( X"00", '0', '0', X"04" );
    send_data( X"00", '0', '1', X"05" );

    wait;
  end process;

end spi_tx_ut_a;

-- synthesis translate_on
