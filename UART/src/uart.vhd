
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity uart is
  generic(
    g_clk_freq    : integer := 100000000;
    g_baud_rate   : integer := 115200
  );
  port(
    aclk          : in  std_logic;
    aresetn       : in  std_logic;
    
    rx            : in  std_logic;
    tx            : out std_logic;
    
    m_axis_tdata  : out std_logic_vector(7 downto 0);
    m_axis_tlast  : out std_logic;
    m_axis_tvalid : out std_logic;
    m_axis_tready : in  std_logic;
    
    s_axis_tdata  : in  std_logic_vector(7 downto 0);
    s_axis_tlast  : in  std_logic;
    s_axis_tvalid : in  std_logic;
    s_axis_tready : out std_logic
  );
end uart;

architecture struct_uart of uart is
begin

  U_uart_rx : entity work.uart_rx
    generic map(
      g_clk_freq    => g_clk_freq,
      g_baud_rate   => g_baud_rate
    )
    port map(
      aclk          => aclk,
      aresetn       => aresetn,
      
      rx            => rx,
      
      m_axis_tdata  => m_axis_tdata,
      m_axis_tlast  => m_axis_tlast,
      m_axis_tvalid => m_axis_tvalid,
      m_axis_tready => m_axis_tready
    );

  U_uart_tx : entity work.uart_tx
    generic map(
      g_clk_freq    => g_clk_freq,
      g_baud_rate   => g_baud_rate
    )
    port map(
      aclk          => aclk,
      aresetn       => aresetn,
      
      tx            => tx,
      
      s_axis_tdata  => s_axis_tdata,
      s_axis_tlast  => s_axis_tlast,
      s_axis_tvalid => s_axis_tvalid,
      s_axis_tready => s_axis_tready
    );
  
end struct_uart;
