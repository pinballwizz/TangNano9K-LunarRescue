-------------------------------------------------------------------------------
--                         Lunar Rescue - Tang Nano 9k
--                     For Original Code (see notes below)
--
--                         Modified for Tang Nano 9k 
--                            by pinballwiz.org 
--                               04/08/2025
-------------------------------------------------------------------------------
-- Space Invaders top level for
-- ps/2 keyboard interface with sound and scan doubler MikeJ
--
-- Version : 0300
--
-- Copyright (c) 2002 Daniel Wallner (jesus@opencores.org)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-- The latest version of this file can be found at:
--      http://www.fpgaarcade.com
--
-- Limitations :
--
-- File history :
--
--      0241 : First release
--
--      0242 : Moved the PS/2 interface to ps2kbd.vhd, added the ROM from mw8080.vhd
--
--      0300 : MikeJ tidy up for audio release
--------------------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
--------------------------------------------------------------------------------------------
entity lrescue_top is
	port(
		Clock_27          : in    std_logic;
		I_RESET           : in    std_logic;
        ps2_clk           : in    std_logic;
        ps2_dat           : inout std_logic;
		O_VIDEO_R         : out   std_logic;
		O_VIDEO_G         : out   std_logic;
		O_VIDEO_B         : out   std_logic;
		O_HSYNC           : out   std_logic;
		O_VSYNC           : out   std_logic;
		O_AUDIO_L         : out   std_logic;
		O_AUDIO_R         : out   std_logic;
        led               : out    std_logic_vector(5 downto 0)
		);
end lrescue_top;
--------------------------------------------------------------------------------------------
architecture rtl of lrescue_top is

-- Signals
	signal reset           : std_logic;
	signal Clock_10        : std_logic;
	signal Clock_20        : std_logic;
	signal Rst_n_s         : std_logic;
    --
	signal DIP             : std_logic_vector(8 downto 1);
	signal RWE_n           : std_logic;
	signal CAB			   : std_logic_vector(9 downto 0);
	signal Video           : std_logic;
	signal VideoRGB        : std_logic_vector(2 downto 0);
	signal VideoRGB_o        : std_logic_vector(2 downto 0);
	signal VideoRGB_X2     : std_logic_vector(7 downto 0);
	signal HSync           : std_logic;
	signal VSync           : std_logic;
	signal HSync_X2        : std_logic;
	signal VSync_X2        : std_logic;
	signal hs       	   : std_logic;
	signal vs      		   : std_logic;
    --
	signal AD              : std_logic_vector(15 downto 0);
	signal RAB             : std_logic_vector(12 downto 0);
	signal RDB             : std_logic_vector(7 downto 0);
	signal RWD             : std_logic_vector(7 downto 0);
	signal IB              : std_logic_vector(7 downto 0);
	signal SoundCtrl3      : std_logic_vector(5 downto 0);
	signal SoundCtrl5      : std_logic_vector(5 downto 0);
    --
	signal rom_data_0      : std_logic_vector(7 downto 0);
	signal rom_data_1      : std_logic_vector(7 downto 0);
	signal rom_data_2      : std_logic_vector(7 downto 0);
	signal rom_data_3      : std_logic_vector(7 downto 0);
	signal rom_data_4      : std_logic_vector(7 downto 0);
	signal rom_data_5      : std_logic_vector(7 downto 0);
	signal ram_we          : std_logic;
    --
	signal Audio           : std_logic_vector(7 downto 0);
	signal AudioPWM        : std_logic;
    --
    signal kbd_intr        : std_logic;
    signal kbd_scancode    : std_logic_vector(7 downto 0);
    signal joyHBCPPFRLDU   : std_logic_vector(9 downto 0);
    --
    constant CLOCK_FREQ    : integer := 27E6;
    signal counter_clk     : std_logic_vector(25 downto 0);
    signal clock_4hz       : std_logic;
    signal pll_locked      : std_logic;
---------------------------------------------------------------------------------------------
component Gowin_rPLL
    port (
        clkout: out std_logic;
        lock: out std_logic;
        clkoutd: out std_logic;
        clkin: in std_logic
    );
end component;
----------------------------------------------------------------------------------------------
    begin

    reset <= not I_RESET;
    pll_locked <= '1';
	DIP <= "00000000";
----------------------------------------------------------------------------------------------
clocks: Gowin_rPLL
    port map (
        clkout => clock_20,
        lock => pll_locked,
        clkoutd => clock_10,
        clkin => clock_27
    );
------------------------------------------------------------------------------------------------
-- Main
	core : entity work.invaderst
		port map(
			Rst_n      => I_RESET,
			Clk        => Clock_10,
			Coin       => joyHBCPPFRLDU(7),
			Sel1Player => not joyHBCPPFRLDU(5),
			Sel2Player => not joyHBCPPFRLDU(6),
			Fire       => not joyHBCPPFRLDU(4),
			MoveLeft   => not joyHBCPPFRLDU(2),
			MoveRight  => not joyHBCPPFRLDU(3),
			DIP        => DIP,
			RDB        => RDB,
			IB         => IB,
			RWD        => RWD,
			RAB        => RAB,
			AD         => AD,
			SoundCtrl3 => SoundCtrl3,
			SoundCtrl5 => SoundCtrl5,
			Rst_n_s    => Rst_n_s,
			RWE_n      => RWE_n,
			Video      => Video,
			CAB		   => CAB,
			HSync      => HSync,
			VSync      => VSync
			);
------------------------------------------------------------------------------------------------
-- Roms
	u_rom_0 : entity work.LRESCUE_PROM_1
	  port map (
		CLK         => Clock_10,
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_0
		);
	--
	u_rom_1 : entity work.LRESCUE_PROM_2
	  port map (
		CLK         => Clock_10,
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_1
		);
	--
	u_rom_2 : entity work.LRESCUE_PROM_3
	  port map (
		CLK         => Clock_10,
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_2
		);
	--
	u_rom_3 : entity work.LRESCUE_PROM_4
	  port map (
		CLK         => Clock_10,
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_3
		);
		
	u_rom_4 : entity work.LRESCUE_PROM_5
	  port map (
		CLK         => Clock_10,
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_4
		);
		
	u_rom_5 : entity work.LRESCUE_PROM_6
	  port map (
		CLK         => Clock_10,
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_5
		);
------------------------------------------------------------------------------------------------
-- RomSel
	p_rom_data : process(AD, rom_data_0, rom_data_1, rom_data_2, rom_data_3, rom_data_4, rom_data_5)
	begin
	  IB <= (others => '0');
	  case AD(15 downto 11) is
		when "00000" => IB <= rom_data_0;
		when "00001" => IB <= rom_data_1;
		when "00010" => IB <= rom_data_2;
		when "00011" => IB <= rom_data_3;
		when "01000" => IB <= rom_data_4;
		when "01001" => IB <= rom_data_5;
		when others => null;
	  end case;
	end process;
------------------------------------------------------------------------------------------------
-- Ram
	ram_we <= not RWE_n;

	rams : for i in 0 to 3 generate

    u_ram : entity work.gen_ram generic map (2,13)
    port map (
		q   => RDB((i*2)+1 downto (i*2)),
		addr => RAB,
		clk  => Clock_10,
		d   => RWD((i*2)+1 downto (i*2)),
		we   => ram_we   
    );
	end generate;
------------------------------------------------------------------------------------------------
-- Video

 Overlay : entity work.LunarRescue_Overlay
		port map(
			Video  	     => Video,
			CLK			 => Clock_10,
			Rst_n_s		 => Rst_n_s,
			HSync  	     => HSync,
			VSync  	     => VSync,
			CAB			 => CAB,
			VideoRGB	 => VideoRGB_o
		);
------------------------------------------------------------------------------------------------
-- Scandoubler
		
  u_dblscan : entity work.DBLSCAN
	port map (
	  RGB_IN(7 downto 3) => "00000",
	  RGB_IN(2 downto 0) => VideoRGB_o,
	  HSYNC_IN           => HSync,
	  VSYNC_IN           => VSync,

	  RGB_OUT            => VideoRGB_X2,
	  HSYNC_OUT          => HSync_X2,
	  VSYNC_OUT          => VSync_X2,
	  --  NOTE CLOCKS MUST BE PHASE LOCKED !!
	  CLK                => Clock_10,
	  CLK_X2             => Clock_20,
      scanlines          => '0'
	);
-----------------------------------------------------------------------------------------------
  O_VIDEO_R <= VideoRGB_X2(2);
  O_VIDEO_G <= VideoRGB_X2(1);
  O_VIDEO_B <= VideoRGB_X2(0);
  O_HSYNC   <= not HSync_X2;
  O_VSYNC   <= not VSync_X2;
-----------------------------------------------------------------------------------------------
-- get scancode from keyboard

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_10, -- use same clock as main core
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);
----------------------------------------------------------------------------------------------
-- translate scancode to joystick

joystick : entity work.kbd_joystick
port map (
  clk          => clock_10, -- use same clock as main core
  kbdint       => kbd_intr,
  kbdscancode  => std_logic_vector(kbd_scancode), 
  joyHBCPPFRLDU => joyHBCPPFRLDU
);
-----------------------------------------------------------------------------------------------
-- Audio

  u_audio : entity work.invaders_audio
	port map (
	  Clk => Clock_10,
	  S1  => SoundCtrl3,
	  S2  => SoundCtrl5,
	  Aud => Audio
	  );
------------------------------------------------------------------------------------------------
-- DAC

  u_dac : entity work.dac
	generic map(
	  msbi_g => 7
	)
	port  map(
	  clk_i   => Clock_10,
	  res_n_i => Rst_n_s,
	  dac_i   => Audio,
	  dac_o   => AudioPWM
	);

  O_AUDIO_L <= AudioPWM;
  O_AUDIO_R <= AudioPWM;
------------------------------------------------------------------------------------------------
-- debug

process(reset, clock_27)
begin
  if reset = '1' then
    clock_4hz <= '0';
    counter_clk <= (others => '0');
  else
    if rising_edge(clock_27) then
      if counter_clk = CLOCK_FREQ/8 then
        counter_clk <= (others => '0');
        clock_4hz <= not clock_4hz;
        led(5 downto 0) <= not AD(9 downto 4);
      else
        counter_clk <= counter_clk + 1;
      end if;
    end if;
  end if;
end process;
----------------------------------------------------------------------------------
end;