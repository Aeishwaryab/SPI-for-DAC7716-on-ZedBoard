----------------------------------------------------------------------------------
-- Company: Technical University of Munich
-- Engineer: Aeishwarya Baviskar
-- 
-- Create Date: 22.06.2018 13:20:08
-- Design Name: 
-- Module Name: CsnClk - GenCSn
-- Project Name: Project Course on Power Electronics and Drive Systems
-- Target Devices: ZedBoard
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CsnClk is
    Port ( ClkIp : in STD_LOGIC;
           Clkop : out STD_LOGIC;
           CSn : out STD_LOGIC;
           LatchN : out STD_LOGIC := '1';
           Dout : out STD_LOGIC; 
           Rstn: in STD_LOGIC := '0';
           RstSPI: out STD_LOGIC;
           Din0: in STD_LOGIC_VECTOR(11 downto 0);
           Din1: in STD_LOGIC_VECTOR(11 downto 0);
           Din2: in STD_LOGIC_VECTOR(11 downto 0);
           Din3: in STD_LOGIC_VECTOR(11 downto 0)););
end CsnClk;

architecture GenCSn of CsnClk is

type address is array(0 to 3) of STD_LOGIC_VECTOR(3 downto 0);
type Datasig is array(0 to 16) of STD_LOGIC_VECTOR(11 downto 0);
signal addrs: address;
signal Din: Datasig;
signal Clkop_sig : STD_LOGIC :='0';
signal Csn_sig : STD_LOGIC := '0';
signal LatchN_sig : STD_LOGIC := '0';
signal Do_sig : STD_LOGIC;
signal D2trns : STD_LOGIC_VECTOR(23 downto 0):= (others=> '0');
shared variable CSnLowFlag : INTEGER := 0;
-- Test signals
--signal count_bit2 :integer :=0;
begin

addrs(0)<="0100";
addrs(1)<="0101";
addrs(2)<="0110";  
addrs(3)<="0111";

Clkop<=Clkop_sig;
CSn <= Csn_sig;
LatchN<= LatchN_sig;
Dout <= Do_sig;
RstSPI<= Rstn;

-- Clock Division by 4
GenClock: process(ClkIp)
    constant div_by : integer := 4;
    variable count_clk : integer:= 0;
begin
    if (Rstn = '0' AND ClkIp'event AND ClkIp = '1') then
--        for i in 1 to div_by loop
            count_clk := count_clk+1;
            if count_clk = div_by then
                Clkop_sig <= Clkop_sig XOR '1' ;
                count_clk := 0;
            end if;
--        end loop;
     end if;
end process;
         --------------------
-- Generate Chip select
SwitchCSn : process(Clkop_sig)
    constant bit24 : integer :=25;
    variable count_bit : integer:= 0;
    variable Csn_flag : integer :=0;
begin
    if (Clkop_sig'event AND Clkop_sig = '1') then

            if Csn_flag = 1 then
                Csn_sig<= '0';
                CSnLowFlag := 1;
                
            end if;
            if count_bit = bit24 then
                Csn_sig <= '1' ;
                CSnLowFlag:= 0;
                count_bit := 0;
                Csn_flag := 1;
            end if;
             count_bit := count_bit+1;
     end if;
end process;

         -----------------------
         -- Generate Latch Signal
GenLATCH : process(Clkop_sig)
    constant RegNo : integer :=1;
    constant bit24 : integer :=25;
    variable count_reg : integer:= 0; 
    variable LatchN_flag : integer :=0;
begin
    if (Clkop_sig'event AND Clkop_sig = '0') then
            if LatchN_flag = 1 then
                LatchN_sig<= '1';
            end if;
            if count_reg = RegNo*bit24 then
                LatchN_sig <= '0' ;
                count_reg := 0;
                LatchN_flag := 1;
            end if;
            count_reg := count_reg+1;
     end if;
end process;

         -----------------------
         -- Update Data to transfer
updateD2Trns: process(Csn_sig)
    constant ChannelNo : integer := 4;
    
    variable count_channel : integer := 0;

begin
    if (Csn_sig'event AND Csn_sig = '1' ) then
            D2trns(20 downto 17) <= addrs(count_channel);
            if count_channel = 0 then
                D2trns(16 downto 5) <= Din0;    
            elsif count_channel = 1 then
                D2trns(16 downto 5) <= Din1;
            elsif count_channel = 2 then
                D2trns(16 downto 5) <= Din2;
            elsif count_channel = 3 then
                D2trns(16 downto 5) <= Din3;
            end if; 
            count_channel := count_channel+1;
            if count_channel = ChannelNo then
                count_channel := 0;
            end if;
     end if;
end process; 
--------------------------------
         -- Sending Data through Serial Port
DataOut: process (Clkop_sig)
    constant data_length : integer :=23; 
    variable count_bit : integer :=0;
begin
    if (Clkop_sig'event AND Clkop_sig = '1' AND CSnLowFlag =1) then
        Do_sig <= D2trns(data_length-count_bit);
        count_bit:= count_bit+1; 
        if count_bit = data_length+1 then
            count_bit := 0;
        end if;     
    end if;
end process;
end GenCSn;
