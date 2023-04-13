
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_misc.all;
  use ieee.numeric_std.all;

entity uart_axi is
  generic(
    g_clk_freq          : integer := 100000000;
    g_baud_rate         : integer := 115200
  );
  port(
    aclk                : in  std_logic;
    aresetn             : in  std_logic;

    --------------------
    -- Interrupt Request
    --------------------
    irq                 : out std_logic;

    ------------------------
    -- FPGA Fabric Interface
    ------------------------
    s_axi_araddr        : in  std_logic_vector( 7 downto 0);
    s_axi_arvalid       : in  std_logic;
    s_axi_arready       : out std_logic;

    s_axi_rdata         : out std_logic_vector(31 downto 0);
    s_axi_rvalid        : out std_logic;
    s_axi_rready        : in  std_logic;

    s_axi_awaddr        : in  std_logic_vector( 7 downto 0);
    s_axi_awvalid       : in  std_logic;
    s_axi_awready       : out std_logic;

    s_axi_wdata         : in  std_logic_vector(31 downto 0);
    s_axi_wstrb         : in  std_logic_vector( 3 downto 0);
    s_axi_wvalid        : in  std_logic;
    s_axi_wready        : out std_logic;

    s_axi_bresp         : out std_logic_vector( 1 downto 0);
    s_axi_bvalid        : out std_logic;
    s_axi_bready        : in  std_logic
  );
end uart_axi;

architecture uart_avalon_a of uart_axi is

  type reg_state is (S_IDLE, S_READ, S_READ_DONE, S_WRITE, S_WRITE_DONE);

  signal sig_reg_s        : reg_state := S_IDLE;
  signal sig_s_axi_rdata  : std_logic_vector( s_axi_rdata'range );
  signal sig_int_enable   : std_logic_vector( 1 downto 0 );
  signal sig_int          : std_logic_vector( 1 downto 0 );

begin

  s_axi_arready       <= '1' when sig_reg_s = S_READ else '0';
  s_axi_rdata         <= sig_s_axi_rdata;
  s_axi_rvalid        <= '1' when sig_reg_s = S_READ else '0';
  s_axi_awready       <= '1' when sig_reg_s = S_WRITE else '0';
  s_axi_wready        <= '1' when sig_reg_s = S_WRITE else '0';
  s_axi_bresp         <= "00";
  s_axi_bvalid        <= '1' when sig_reg_s = S_WRITE_DONE else '0';

  -- post an interrupt when an event occurs
  irq               <= or_reduce( sig_int_enable and sig_int );

  p_sig_s_axi_rdata : process(aclk) is
  begin
    if rising_edge(aclk) then
      case s_axi_araddr is
        when X"00"   => sig_s_axi_rdata <= X"0000000" & "00" & '0' & '0';
        when X"04"   => sig_s_axi_rdata <= X"0000000" & "00" & sig_int_enable;
        when X"08"   => sig_s_axi_rdata <= X"0000000" & "00" & sig_int;
        when X"0C"   => sig_s_axi_rdata <= X"000000" & X"00";
        when others  => sig_s_axi_rdata <= X"DEADC0DE";
      end case;
    end if;
  end process;

  p_write : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_int_enable  <= (others => '0');
        sig_int         <= (others => '0');
      else
        if sig_reg_s = S_WRITE then
          case s_axi_awaddr is
            when X"04" => sig_int_enable  <= s_axi_wdata( sig_int_enable'range );
            when X"08" => sig_int         <= sig_int and (not s_axi_wdata( sig_int'range ));
            when others  =>
          end case;
        end if;
      end if;
    end if;
  end process;

  p_sig_reg_s : process(aclk) is
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        sig_reg_s <= S_IDLE;
      else
        case sig_reg_s is
          when S_IDLE =>
            if s_axi_arvalid = '1' then
              sig_reg_s <= S_READ;
            elsif s_axi_awvalid = '1' and s_axi_wvalid = '1' then
              sig_reg_s <= S_WRITE;
            end if;

          when S_READ =>
            sig_reg_s <= S_READ_DONE;

          when S_READ_DONE =>
            sig_reg_s <= S_IDLE;

          when S_WRITE =>
            sig_reg_s <= S_WRITE_DONE;

          when S_WRITE_DONE => 
            if s_axi_bready = '1' then
              sig_reg_s <= S_IDLE;
            end if;

        end case;
      end if;
    end if;
  end process;

end uart_avalon_a;

