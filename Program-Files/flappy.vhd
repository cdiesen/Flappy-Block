library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity flappy is
  port (
    clk_in : in std_logic; -- system clock
    VGA_red : out std_logic_vector (3 downto 0); -- VGA outputs
    VGA_green : out std_logic_vector (3 downto 0);
    VGA_blue : out std_logic_vector (3 downto 0);
    VGA_hsync : out std_logic;
    VGA_vsync : out std_logic;
    --        ADC_CS : OUT STD_LOGIC; -- ADC signals
    --        ADC_SCLK : OUT STD_LOGIC;
    --        ADC_SDATA1 : IN STD_LOGIC;
    --        ADC_SDATA2 : IN STD_LOGIC;
    btn0 : in std_logic; -- button to initiate serve
    btnl : in std_logic; --button left
    btnr : in std_logic; --button right
--    SW : in std_logic_vector (4 downto 0);
    SEG7_anode : out std_logic_vector (3 downto 0); -- anodes of four 7-seg displays
    SEG7_seg : out std_logic_vector (6 downto 0) -- common segments of 7-seg displays
  );
end flappy;

architecture Behavioral of flappy is
  signal pxl_clk : std_logic := '0'; -- 25 MHz clock to VGA sync module
  -- internal signals to connect modules
  signal S_red, S_green, S_blue : std_logic; --_VECTOR (3 DOWNTO 0);
  signal S_vsync : std_logic;
  signal S_pixel_row, S_pixel_col : std_logic_vector (10 downto 0);
--  signal gap_pos : std_logic_vector (10 downto 0); -- 9 downto 0
  signal gap_pos : std_logic_vector (10 downto 0);
  SIGNAL count : STD_LOGIC_VECTOR (20 DOWNTO 0);
--  signal serial_clk, sample_clk : std_logic;
  --    SIGNAL adout : STD_LOGIC_VECTOR (11 DOWNTO 0);
  signal display : std_logic_vector (15 downto 0); -- value to be displayed
  signal led_mpx : std_logic_vector (1 downto 0); -- 7-seg multiplexing clock
  signal cnt : std_logic_vector(20 downto 0); -- counter to generate timing signals
  --        COMPONENT adc_if IS
  --        PORT (
  --            SCK : IN STD_LOGIC;
  --            SDATA1 : IN STD_LOGIC;
  --            SDATA2 : IN STD_LOGIC;
  --            CS : IN STD_LOGIC;
  --            data_1 : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
  --            data_2 : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
  --        );
  --    END COMPONENT;
  component bird_n_buildings is
    port (
      v_sync : in std_logic;
      pixel_row : in std_logic_vector(10 downto 0);
      pixel_col : in std_logic_vector(10 downto 0);
      bird_x : in std_logic_vector (10 downto 0);
      serve : in std_logic;
--      SW : in std_logic_vector (4 downto 0);
      red : out std_logic;
      green : out std_logic;
      blue : out std_logic;
      hits : out std_logic_vector (15 downto 0)
    );
  end component;
  component vga_sync is
    port (
      pixel_clk : in std_logic;
      red_in : in std_logic_vector (3 downto 0);
      green_in : in std_logic_vector (3 downto 0);
      blue_in : in std_logic_vector (3 downto 0);
      red_out : out std_logic_vector (3 downto 0);
      green_out : out std_logic_vector (3 downto 0);
      blue_out : out std_logic_vector (3 downto 0);
      hsync : out std_logic;
      vsync : out std_logic;
      pixel_row : out std_logic_vector (10 downto 0);
      pixel_col : out std_logic_vector (10 downto 0)
    );
  end component;
  component clk_wiz_0 is
    port (
      clk_in1 : in std_logic;
      clk_out1 : out std_logic
    );
  end component;
  component leddec16 is
    port (
      dig : in std_logic_vector (1 downto 0);
      data : in std_logic_vector (15 downto 0);
      anode : out std_logic_vector (3 downto 0);
      seg : out std_logic_vector (6 downto 0)
    );
  end component;
begin
  -- Process to generate clock signals
  --    BEGIN
  pos : process (clk_in) is
  begin
    if rising_edge(clk_in) then
      count <= count + 1;
      if (btnl = '1' and gap_pos > 0 and count = 0) then
        gap_pos <= gap_pos - 10;
      elsif (btnr = '1' and gap_pos < 800 and count = 0) then
        gap_pos <= gap_pos + 10;
      end if;
    end if;
  end process;
  --    ckp : PROCESS
  --    BEGIN
  --        WAIT UNTIL rising_edge(clk_in);
  --        count <= count + 1; -- counter to generate ADC timing signals
  --    END PROCESS;
  led_mpx <= cnt(18 downto 17); -- 7-seg multiplexing clock
  --    serial_clk <= NOT count(4); -- 1.5 MHz serial clock for ADC
  --    ADC_SCLK <= serial_clk;
  --    sample_clk <= count(9); -- sampling clock is low for 16 SCLKs
  --    ADC_CS <= sample_clk;
  -- Multiplies ADC output (0-4095) by 5/32 to give bat position (0-640)
  --batpos <= ('0' & adout(11 DOWNTO 3)) + adout(11 DOWNTO 5);
  --    gap_pos <= ("00" & adout(11 DOWNTO 3)) + adout(11 DOWNTO 4);
  -- 512 + 256 = 768
  --    adc : adc_if
  --    PORT MAP(-- instantiate ADC serial to parallel interface
  --        SCK => serial_clk, 
  --        CS => sample_clk, 
  --        SDATA1 => ADC_SDATA1, 
  --        SDATA2 => ADC_SDATA2, 
  --        data_1 => OPEN, 
  --        data_2 => adout 
  --    );
  add_bb : bird_n_buildings
  port map(--instantiate bat and ball component
    v_sync => S_vsync,
    pixel_row => S_pixel_row,
    pixel_col => S_pixel_col,
    bird_x => gap_pos,
    --        duck_y => duck_y,
    serve => btn0,
--    SW => SW,
    red => S_red,
    green => S_green,
    blue => S_blue,
    hits => display
  );
  vga_driver : vga_sync
  port map(--instantiate vga_sync component
    pixel_clk => pxl_clk,
    red_in => S_red & "000",
    green_in => S_green & "000",
    blue_in => S_blue & "000",
    red_out => VGA_red,
    green_out => VGA_green,
    blue_out => VGA_blue,
    pixel_row => S_pixel_row,
    pixel_col => S_pixel_col,
    hsync => VGA_hsync,
    vsync => S_vsync
  );
  VGA_vsync <= S_vsync; --connect output vsync

  clk_wiz_0_inst : clk_wiz_0
  port map(
    clk_in1 => clk_in,
    clk_out1 => pxl_clk
  );
  led1 : leddec16
  port map(
    dig => led_mpx, data => display,
    anode => SEG7_anode, seg => SEG7_seg
  );
end Behavioral;