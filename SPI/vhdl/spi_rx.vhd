
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity spi_rx is
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

    coe_csn_export          : in  std_logic_vector(csn_width - 1 downto 0);
    coe_miso_export         : in  std_logic;
    coe_clk_export          : in  std_logic;

    aso_data_channel        : out std_logic_vector(7 downto 0);
    aso_data_data           : out std_logic_vector(7 downto 0);
    aso_data_startofpacket  : out std_logic;
    aso_data_endofpacket    : out std_logic;
    aso_data_valid          : out std_logic;
    aso_data_ready          : in  std_logic
  );
end spi_rx;

architecture spi_rx_a of spi_rx is

  constant max_count              : integer := (clk_freq / spi_freq) * 2;

  type spi_state is (S_IDLE, S_START, S_DATA, S_VALID_WAIT, S_STOP, S_VALID);
  
  signal spi_s                    : spi_state := S_IDLE;

  signal i_aso_data_channel       : std_logic_vector(7 downto 0);
  signal i_aso_data_data          : std_logic_vector(7 downto 0);
  signal i_aso_data_startofpacket : std_logic;
  signal i_aso_data_endofpacket   : std_logic;
  signal i_aso_data_valid         : std_logic;

  signal i_csn                    : std_logic_vector(csn_width - 1 downto 0);
  signal i_miso                   : std_logic;
  signal i_clk                    : std_logic_vector(1 downto 0);

  signal i_bit_valid              : std_logic;
  signal i_bit_cnt                : integer range 0 to 7;
  signal i_bit_time               : unsigned(31 downto 0);
  signal i_bit_timeout            : std_logic;

  signal i_channel                : std_logic_vector(7 downto 0);
  signal i_channel_valid          : std_logic_vector(1 downto 0);
  signal i_data                   : std_logic_vector(7 downto 0);
  signal i_startofpacket          : std_logic;
  signal i_endofpacket            : std_logic;
  signal i_valid                  : std_logic;

begin
  
  aso_data_channel        <= i_aso_data_channel;
  aso_data_data           <= i_aso_data_data;
  aso_data_startofpacket  <= i_aso_data_startofpacket;
  aso_data_endofpacket    <= i_aso_data_endofpacket;
  aso_data_valid          <= i_aso_data_valid;

  i_bit_valid             <= '1' when i_channel_valid(i_channel_valid'left) = '1' and (
                                        (i_clk = "01" and ((cpol = 0 and cpha = 0) or (cpol = 1 and cpha = 1))) or 
                                        (i_clk = "10" and ((cpol = 0 and cpha = 1) or (cpol = 1 and cpha = 0)))
                                      ) else '0';

  i_bit_timeout           <= i_bit_time(i_bit_time'left);

  i_csn_p  : process(clk) is begin if rising_edge(clk) then i_csn  <= coe_csn_export;  end if; end process;
  i_miso_p : process(clk) is begin if rising_edge(clk) then i_miso <= coe_miso_export; end if; end process;
  i_clk_p  : process(clk) is begin if rising_edge(clk) then i_clk  <= i_clk(i_clk'left - 1 downto 0) & coe_clk_export; end if; end process;

  aso_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_aso_data_channel        <= (others => '0');
        i_aso_data_data           <= (others => '0');
        i_aso_data_startofpacket  <= '0';
        i_aso_data_endofpacket    <= '0';
        i_aso_data_valid          <= '0';
      else
        if i_aso_data_valid = '0' and spi_s = S_VALID then
          i_aso_data_channel        <= i_channel;
          i_aso_data_data           <= i_data;
          i_aso_data_startofpacket  <= i_startofpacket;
          i_aso_data_endofpacket    <= i_endofpacket;
          i_aso_data_valid          <= '1';
        elsif i_aso_data_valid = '1' and aso_data_ready = '1' then
          i_aso_data_valid          <= '0';
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
        if i_channel_valid = "10" or i_channel_valid = "00" then
          i_bit_cnt <= 0;
        elsif i_bit_valid = '1' and i_bit_cnt /= 7 then
          i_bit_cnt <= i_bit_cnt + 1;
        elsif i_bit_valid = '1' then
          i_bit_cnt <= 0;
        end if;
      end if;
    end if;
  end process;

  i_bit_time_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_bit_time <= (others => '1');
      else
        if i_bit_valid = '1' or (i_bit_timeout = '0' and i_channel_valid = "10") then
          i_bit_time <= '0' & to_unsigned( max_count - 1, i_bit_time'length - 1 );
        elsif i_bit_time(i_bit_time'left) = '0' then
          i_bit_time <= i_bit_time - 1;
        end if;
      end if;
    end if;
  end process;

  i_channel_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_channel       <= (others => '0');
        i_channel_valid <= (others => '0');
      else
        for i in i_csn'range loop
          if i_csn(i) = '0' then
            i_channel       <= std_logic_vector( to_unsigned(i, i_channel'length) );
          end if;
        end loop;

        i_channel_valid <= i_channel_valid(i_channel_valid'left - 1 downto 0) & (not and_reduce( i_csn ));
      end if;
    end if;
  end process;

  i_data_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_data <= (others => '0');
      else
        if i_bit_valid = '1' then
          i_data( 7 - i_bit_cnt ) <= i_miso;
        end if;
      end if;
    end if;
  end process;

  i_packet_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_startofpacket <= '0';
        i_endofpacket   <= '0';
      else
        if spi_s = S_IDLE then
          i_startofpacket <= '0';
          i_endofpacket   <= '0';
        end if;
        
        if spi_s = S_START then
          i_startofpacket <= '1';
        end if;

        if spi_s = S_STOP then
          i_endofpacket   <= '1';
        end if;
      end if;
    end if;
  end process;

  i_valid_p : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        i_valid <= '0';
      else
        if (i_bit_cnt = 7 and i_bit_valid = '1') or i_channel_valid = "10" or i_bit_timeout = '1' then
          i_valid <= '1';
        else
          i_valid <= '0';
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
            if i_channel_valid = "01" or i_bit_timeout = '1' then
              spi_s <= S_START;
            elsif i_bit_valid = '1' then
              spi_s <= S_DATA;
            end if;

          when S_START => 
            if i_bit_timeout = '0' then
              spi_s <= S_DATA;
            end if;

          when S_DATA => 
            if i_bit_cnt = 7 and i_bit_valid = '1' then
              spi_s <= S_VALID_WAIT;
            elsif i_channel_valid = "10" or i_bit_timeout = '1' then
              spi_s <= S_STOP;
            end if;

          when S_VALID_WAIT => 
            if i_bit_valid = '1' then
              spi_s <= S_VALID;
            elsif i_channel_valid = "10" or i_bit_timeout = '1' then
              spi_s <= S_STOP;
            end if;

          when S_STOP => 
            spi_s <= S_VALID;

          when S_VALID => 
            spi_s <= S_IDLE;

        end case;
      end if;
    end if;
  end process;

end spi_rx_a;

-- synthesis translate_off

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_rx_ut is
  generic(
    clk_freq                : integer := 100000000;
    spi_freq                : integer := 3200000;
    cpol                    : integer := 1;
    cpha                    : integer := 1;
    csn_width               : integer := 2
  );
end spi_rx_ut;

architecture spi_rx_ut_a of spi_rx_ut is
  
  signal spi_period             : time := real(real(1) / real(spi_freq)) * 1 sec;
  signal clk_period             : time := real(real(1) / real(clk_freq)) * 1 sec;
  
  signal clk                    : std_logic := '0';
  signal reset                  : std_logic;
  signal coe_csn_export         : std_logic_vector(csn_width - 1 downto 0);
  signal coe_miso_export        : std_logic;
  signal coe_clk_export         : std_logic;
  signal aso_data_channel       : std_logic_vector(7 downto 0);
  signal aso_data_data          : std_logic_vector(7 downto 0);
  signal aso_data_startofpacket : std_logic;
  signal aso_data_endofpacket   : std_logic;
  signal aso_data_valid         : std_logic;
  signal aso_data_ready         : std_logic;

begin
  
  UUT : entity work.spi_rx
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
      coe_miso_export         => coe_miso_export,
      coe_clk_export          => coe_clk_export,

      aso_data_channel        => aso_data_channel,
      aso_data_data           => aso_data_data,
      aso_data_startofpacket  => aso_data_startofpacket,
      aso_data_endofpacket    => aso_data_endofpacket,
      aso_data_valid          => aso_data_valid,
      aso_data_ready          => aso_data_ready
    );
  
  clk   <= not clk after clk_period / 2;
  reset <= '1', '0' after 100 ns;

  coe_miso_export_p : process
    procedure send_data( csn : std_logic_vector(coe_csn_export'range); data : std_logic_vector(7 downto 0); bit_cnt : integer ) is
    begin
      if coe_csn_export /= csn then
        coe_csn_export <= csn;
        wait for spi_period;
      end if;

      for i in bit_cnt - 1 downto 0 loop
        coe_miso_export <= data(i);
        if (cpol = 1 and cpha = 1) or (cpol = 0 and cpha = 0) then
          coe_clk_export  <= '0'; wait for spi_period / 2; coe_clk_export  <= '1'; wait for spi_period / 2;
        else
          coe_clk_export  <= '1'; wait for spi_period / 2; coe_clk_export  <= '0'; wait for spi_period / 2;
        end if;
      end loop;

    if cpol = 1 then
      coe_clk_export  <= '1';
    else
      coe_clk_export  <= '0';
    end if;
      
    end procedure;
  begin
    coe_csn_export  <= (others => '1');
    coe_miso_export <= '0';

    if cpol = 1 then
      coe_clk_export  <= '1';
    else
      coe_clk_export  <= '0';
    end if;

    coe_csn_export <= "11";
    send_data( "10", X"01", 8 );
    coe_csn_export <= "11"; wait for 100 ns;
    send_data( "01", X"02", 8 );
    send_data( "01", X"03", 8 );
    coe_csn_export <= "11";

    wait;
  end process;

  aso_data_p : process
    procedure check_data( sop : std_logic; eop : std_logic; channel : std_logic_vector(7 downto 0); expected : std_logic_vector(7 downto 0) ) is
    begin
      wait until rising_edge(clk) and aso_data_valid = '1';

      assert aso_data_channel = channel
        report "ERROR channel : expected(0x" & to_hstring(channel) & ") : actual(0x" & to_hstring(aso_data_channel) & ")"
        severity ERROR;

      assert aso_data_startofpacket = sop
        report "ERROR : startofpacket : expected(" & std_logic'image(sop) & ") : actual(" & std_logic'image(aso_data_startofpacket) & ")"
        severity ERROR;

      assert aso_data_endofpacket = eop
        report "ERROR : endofpacket : expected(" & std_logic'image(eop) & ") : actual(" & std_logic'image(aso_data_endofpacket) & ")"
        severity ERROR;

      assert aso_data_data = expected
        report "ERROR : data : expected(0x" & to_hstring(expected) & ") : actual(0x" & to_hstring(aso_data_data) & ")"
        severity ERROR;
    end procedure;
  begin
    check_data( '1', '1', X"00", X"01" );
    check_data( '1', '0', X"01", X"02" );
    check_data( '0', '1', X"01", X"03" );

    report "END OF SIMULATION" severity FAILURE;

  end process;

  aso_data_ready  <= '1';

end spi_rx_ut_a;

-- synthesis translate_on
