-- ==============================================================
-- RTL generated by Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2022.1 (64-bit)
-- Version: 2022.1
-- Copyright (C) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- 
-- ===========================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity example_proc_2_1 is
port (
    ap_clk : IN STD_LOGIC;
    ap_rst : IN STD_LOGIC;
    ap_start : IN STD_LOGIC;
    start_full_n : IN STD_LOGIC;
    ap_done : OUT STD_LOGIC;
    ap_continue : IN STD_LOGIC;
    ap_idle : OUT STD_LOGIC;
    ap_ready : OUT STD_LOGIC;
    start_out : OUT STD_LOGIC;
    start_write : OUT STD_LOGIC;
    data_channel12_dout : IN STD_LOGIC_VECTOR (31 downto 0);
    data_channel12_num_data_valid : IN STD_LOGIC_VECTOR (6 downto 0);
    data_channel12_fifo_cap : IN STD_LOGIC_VECTOR (6 downto 0);
    data_channel12_empty_n : IN STD_LOGIC;
    data_channel12_read : OUT STD_LOGIC;
    data_channel23_dout : IN STD_LOGIC_VECTOR (31 downto 0);
    data_channel23_num_data_valid : IN STD_LOGIC_VECTOR (6 downto 0);
    data_channel23_fifo_cap : IN STD_LOGIC_VECTOR (6 downto 0);
    data_channel23_empty_n : IN STD_LOGIC;
    data_channel23_read : OUT STD_LOGIC;
    data_channel121_din : OUT STD_LOGIC_VECTOR (31 downto 0);
    data_channel121_num_data_valid : IN STD_LOGIC_VECTOR (6 downto 0);
    data_channel121_fifo_cap : IN STD_LOGIC_VECTOR (6 downto 0);
    data_channel121_full_n : IN STD_LOGIC;
    data_channel121_write : OUT STD_LOGIC;
    data_channel232_din : OUT STD_LOGIC_VECTOR (31 downto 0);
    data_channel232_num_data_valid : IN STD_LOGIC_VECTOR (6 downto 0);
    data_channel232_fifo_cap : IN STD_LOGIC_VECTOR (6 downto 0);
    data_channel232_full_n : IN STD_LOGIC;
    data_channel232_write : OUT STD_LOGIC );
end;


architecture behav of example_proc_2_1 is 
    constant ap_const_logic_1 : STD_LOGIC := '1';
    constant ap_const_logic_0 : STD_LOGIC := '0';
    constant ap_ST_fsm_state1 : STD_LOGIC_VECTOR (4 downto 0) := "00001";
    constant ap_ST_fsm_state2 : STD_LOGIC_VECTOR (4 downto 0) := "00010";
    constant ap_ST_fsm_state3 : STD_LOGIC_VECTOR (4 downto 0) := "00100";
    constant ap_ST_fsm_state4 : STD_LOGIC_VECTOR (4 downto 0) := "01000";
    constant ap_ST_fsm_state5 : STD_LOGIC_VECTOR (4 downto 0) := "10000";
    constant ap_const_boolean_1 : BOOLEAN := true;
    constant ap_const_lv32_0 : STD_LOGIC_VECTOR (31 downto 0) := "00000000000000000000000000000000";
    constant ap_const_lv32_1 : STD_LOGIC_VECTOR (31 downto 0) := "00000000000000000000000000000001";
    constant ap_const_lv32_3 : STD_LOGIC_VECTOR (31 downto 0) := "00000000000000000000000000000011";
    constant ap_const_lv32_4 : STD_LOGIC_VECTOR (31 downto 0) := "00000000000000000000000000000100";
    constant ap_const_lv7_0 : STD_LOGIC_VECTOR (6 downto 0) := "0000000";

attribute shreg_extract : string;
    signal real_start : STD_LOGIC;
    signal start_once_reg : STD_LOGIC := '0';
    signal ap_done_reg : STD_LOGIC := '0';
    signal ap_CS_fsm : STD_LOGIC_VECTOR (4 downto 0) := "00001";
    attribute fsm_encoding : string;
    attribute fsm_encoding of ap_CS_fsm : signal is "none";
    signal ap_CS_fsm_state1 : STD_LOGIC;
    attribute fsm_encoding of ap_CS_fsm_state1 : signal is "none";
    signal internal_ap_ready : STD_LOGIC;
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_start : STD_LOGIC;
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_done : STD_LOGIC;
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_idle : STD_LOGIC;
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_ready : STD_LOGIC;
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel12_read : STD_LOGIC;
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel23_read : STD_LOGIC;
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel121_din : STD_LOGIC_VECTOR (31 downto 0);
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel121_write : STD_LOGIC;
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_add_phi_out : STD_LOGIC_VECTOR (31 downto 0);
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_add_phi_out_ap_vld : STD_LOGIC;
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_start : STD_LOGIC;
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_done : STD_LOGIC;
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_idle : STD_LOGIC;
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_ready : STD_LOGIC;
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_data_channel232_din : STD_LOGIC_VECTOR (31 downto 0);
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_data_channel232_write : STD_LOGIC;
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_start_reg : STD_LOGIC := '0';
    signal ap_block_state1_ignore_call6 : BOOLEAN;
    signal ap_CS_fsm_state2 : STD_LOGIC;
    attribute fsm_encoding of ap_CS_fsm_state2 : signal is "none";
    signal grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_start_reg : STD_LOGIC := '0';
    signal ap_CS_fsm_state4 : STD_LOGIC;
    attribute fsm_encoding of ap_CS_fsm_state4 : signal is "none";
    signal ap_CS_fsm_state5 : STD_LOGIC;
    attribute fsm_encoding of ap_CS_fsm_state5 : signal is "none";
    signal ap_NS_fsm : STD_LOGIC_VECTOR (4 downto 0);
    signal ap_block_state1 : BOOLEAN;
    signal ap_ST_fsm_state1_blk : STD_LOGIC;
    signal ap_ST_fsm_state2_blk : STD_LOGIC;
    signal ap_ST_fsm_state3_blk : STD_LOGIC;
    signal ap_ST_fsm_state4_blk : STD_LOGIC;
    signal ap_ST_fsm_state5_blk : STD_LOGIC;
    signal ap_ce_reg : STD_LOGIC;

    component example_proc_2_1_Pipeline_VITIS_LOOP_76_1 IS
    port (
        ap_clk : IN STD_LOGIC;
        ap_rst : IN STD_LOGIC;
        ap_start : IN STD_LOGIC;
        ap_done : OUT STD_LOGIC;
        ap_idle : OUT STD_LOGIC;
        ap_ready : OUT STD_LOGIC;
        data_channel12_dout : IN STD_LOGIC_VECTOR (31 downto 0);
        data_channel12_num_data_valid : IN STD_LOGIC_VECTOR (6 downto 0);
        data_channel12_fifo_cap : IN STD_LOGIC_VECTOR (6 downto 0);
        data_channel12_empty_n : IN STD_LOGIC;
        data_channel12_read : OUT STD_LOGIC;
        data_channel23_dout : IN STD_LOGIC_VECTOR (31 downto 0);
        data_channel23_num_data_valid : IN STD_LOGIC_VECTOR (6 downto 0);
        data_channel23_fifo_cap : IN STD_LOGIC_VECTOR (6 downto 0);
        data_channel23_empty_n : IN STD_LOGIC;
        data_channel23_read : OUT STD_LOGIC;
        data_channel121_din : OUT STD_LOGIC_VECTOR (31 downto 0);
        data_channel121_num_data_valid : IN STD_LOGIC_VECTOR (6 downto 0);
        data_channel121_fifo_cap : IN STD_LOGIC_VECTOR (6 downto 0);
        data_channel121_full_n : IN STD_LOGIC;
        data_channel121_write : OUT STD_LOGIC;
        add_phi_out : OUT STD_LOGIC_VECTOR (31 downto 0);
        add_phi_out_ap_vld : OUT STD_LOGIC );
    end component;


    component example_proc_2_1_Pipeline_VITIS_LOOP_80_2 IS
    port (
        ap_clk : IN STD_LOGIC;
        ap_rst : IN STD_LOGIC;
        ap_start : IN STD_LOGIC;
        ap_done : OUT STD_LOGIC;
        ap_idle : OUT STD_LOGIC;
        ap_ready : OUT STD_LOGIC;
        data_channel232_din : OUT STD_LOGIC_VECTOR (31 downto 0);
        data_channel232_num_data_valid : IN STD_LOGIC_VECTOR (6 downto 0);
        data_channel232_fifo_cap : IN STD_LOGIC_VECTOR (6 downto 0);
        data_channel232_full_n : IN STD_LOGIC;
        data_channel232_write : OUT STD_LOGIC;
        add_phi_reload : IN STD_LOGIC_VECTOR (31 downto 0) );
    end component;



begin
    grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30 : component example_proc_2_1_Pipeline_VITIS_LOOP_76_1
    port map (
        ap_clk => ap_clk,
        ap_rst => ap_rst,
        ap_start => grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_start,
        ap_done => grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_done,
        ap_idle => grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_idle,
        ap_ready => grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_ready,
        data_channel12_dout => data_channel12_dout,
        data_channel12_num_data_valid => ap_const_lv7_0,
        data_channel12_fifo_cap => ap_const_lv7_0,
        data_channel12_empty_n => data_channel12_empty_n,
        data_channel12_read => grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel12_read,
        data_channel23_dout => data_channel23_dout,
        data_channel23_num_data_valid => ap_const_lv7_0,
        data_channel23_fifo_cap => ap_const_lv7_0,
        data_channel23_empty_n => data_channel23_empty_n,
        data_channel23_read => grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel23_read,
        data_channel121_din => grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel121_din,
        data_channel121_num_data_valid => ap_const_lv7_0,
        data_channel121_fifo_cap => ap_const_lv7_0,
        data_channel121_full_n => data_channel121_full_n,
        data_channel121_write => grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel121_write,
        add_phi_out => grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_add_phi_out,
        add_phi_out_ap_vld => grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_add_phi_out_ap_vld);

    grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41 : component example_proc_2_1_Pipeline_VITIS_LOOP_80_2
    port map (
        ap_clk => ap_clk,
        ap_rst => ap_rst,
        ap_start => grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_start,
        ap_done => grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_done,
        ap_idle => grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_idle,
        ap_ready => grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_ready,
        data_channel232_din => grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_data_channel232_din,
        data_channel232_num_data_valid => ap_const_lv7_0,
        data_channel232_fifo_cap => ap_const_lv7_0,
        data_channel232_full_n => data_channel232_full_n,
        data_channel232_write => grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_data_channel232_write,
        add_phi_reload => grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_add_phi_out);





    ap_CS_fsm_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                ap_CS_fsm <= ap_ST_fsm_state1;
            else
                ap_CS_fsm <= ap_NS_fsm;
            end if;
        end if;
    end process;


    ap_done_reg_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                ap_done_reg <= ap_const_logic_0;
            else
                if ((ap_continue = ap_const_logic_1)) then 
                    ap_done_reg <= ap_const_logic_0;
                elsif (((grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_done = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_state5))) then 
                    ap_done_reg <= ap_const_logic_1;
                end if; 
            end if;
        end if;
    end process;


    grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_start_reg_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_start_reg <= ap_const_logic_0;
            else
                if ((not(((ap_done_reg = ap_const_logic_1) or (real_start = ap_const_logic_0))) and (ap_const_logic_1 = ap_CS_fsm_state1))) then 
                    grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_start_reg <= ap_const_logic_1;
                elsif ((grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_ready = ap_const_logic_1)) then 
                    grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_start_reg <= ap_const_logic_0;
                end if; 
            end if;
        end if;
    end process;


    grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_start_reg_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_start_reg <= ap_const_logic_0;
            else
                if ((ap_const_logic_1 = ap_CS_fsm_state4)) then 
                    grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_start_reg <= ap_const_logic_1;
                elsif ((grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_ready = ap_const_logic_1)) then 
                    grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_start_reg <= ap_const_logic_0;
                end if; 
            end if;
        end if;
    end process;


    start_once_reg_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                start_once_reg <= ap_const_logic_0;
            else
                if (((internal_ap_ready = ap_const_logic_0) and (real_start = ap_const_logic_1))) then 
                    start_once_reg <= ap_const_logic_1;
                elsif ((internal_ap_ready = ap_const_logic_1)) then 
                    start_once_reg <= ap_const_logic_0;
                end if; 
            end if;
        end if;
    end process;


    ap_NS_fsm_assign_proc : process (real_start, ap_done_reg, ap_CS_fsm, ap_CS_fsm_state1, grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_done, grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_done, ap_CS_fsm_state2, ap_CS_fsm_state5)
    begin
        case ap_CS_fsm is
            when ap_ST_fsm_state1 => 
                if ((not(((ap_done_reg = ap_const_logic_1) or (real_start = ap_const_logic_0))) and (ap_const_logic_1 = ap_CS_fsm_state1))) then
                    ap_NS_fsm <= ap_ST_fsm_state2;
                else
                    ap_NS_fsm <= ap_ST_fsm_state1;
                end if;
            when ap_ST_fsm_state2 => 
                if (((grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_done = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_state2))) then
                    ap_NS_fsm <= ap_ST_fsm_state3;
                else
                    ap_NS_fsm <= ap_ST_fsm_state2;
                end if;
            when ap_ST_fsm_state3 => 
                ap_NS_fsm <= ap_ST_fsm_state4;
            when ap_ST_fsm_state4 => 
                ap_NS_fsm <= ap_ST_fsm_state5;
            when ap_ST_fsm_state5 => 
                if (((grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_done = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_state5))) then
                    ap_NS_fsm <= ap_ST_fsm_state1;
                else
                    ap_NS_fsm <= ap_ST_fsm_state5;
                end if;
            when others =>  
                ap_NS_fsm <= "XXXXX";
        end case;
    end process;
    ap_CS_fsm_state1 <= ap_CS_fsm(0);
    ap_CS_fsm_state2 <= ap_CS_fsm(1);
    ap_CS_fsm_state4 <= ap_CS_fsm(3);
    ap_CS_fsm_state5 <= ap_CS_fsm(4);

    ap_ST_fsm_state1_blk_assign_proc : process(real_start, ap_done_reg)
    begin
        if (((ap_done_reg = ap_const_logic_1) or (real_start = ap_const_logic_0))) then 
            ap_ST_fsm_state1_blk <= ap_const_logic_1;
        else 
            ap_ST_fsm_state1_blk <= ap_const_logic_0;
        end if; 
    end process;


    ap_ST_fsm_state2_blk_assign_proc : process(grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_done)
    begin
        if ((grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_done = ap_const_logic_0)) then 
            ap_ST_fsm_state2_blk <= ap_const_logic_1;
        else 
            ap_ST_fsm_state2_blk <= ap_const_logic_0;
        end if; 
    end process;

    ap_ST_fsm_state3_blk <= ap_const_logic_0;
    ap_ST_fsm_state4_blk <= ap_const_logic_0;

    ap_ST_fsm_state5_blk_assign_proc : process(grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_done)
    begin
        if ((grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_done = ap_const_logic_0)) then 
            ap_ST_fsm_state5_blk <= ap_const_logic_1;
        else 
            ap_ST_fsm_state5_blk <= ap_const_logic_0;
        end if; 
    end process;


    ap_block_state1_assign_proc : process(real_start, ap_done_reg)
    begin
                ap_block_state1 <= ((ap_done_reg = ap_const_logic_1) or (real_start = ap_const_logic_0));
    end process;


    ap_block_state1_ignore_call6_assign_proc : process(real_start, ap_done_reg)
    begin
                ap_block_state1_ignore_call6 <= ((ap_done_reg = ap_const_logic_1) or (real_start = ap_const_logic_0));
    end process;


    ap_done_assign_proc : process(ap_done_reg, grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_done, ap_CS_fsm_state5)
    begin
        if (((grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_done = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_state5))) then 
            ap_done <= ap_const_logic_1;
        else 
            ap_done <= ap_done_reg;
        end if; 
    end process;


    ap_idle_assign_proc : process(real_start, ap_CS_fsm_state1)
    begin
        if (((ap_const_logic_1 = ap_CS_fsm_state1) and (real_start = ap_const_logic_0))) then 
            ap_idle <= ap_const_logic_1;
        else 
            ap_idle <= ap_const_logic_0;
        end if; 
    end process;

    ap_ready <= internal_ap_ready;
    data_channel121_din <= grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel121_din;

    data_channel121_write_assign_proc : process(grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel121_write, ap_CS_fsm_state2)
    begin
        if ((ap_const_logic_1 = ap_CS_fsm_state2)) then 
            data_channel121_write <= grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel121_write;
        else 
            data_channel121_write <= ap_const_logic_0;
        end if; 
    end process;


    data_channel12_read_assign_proc : process(grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel12_read, ap_CS_fsm_state2)
    begin
        if ((ap_const_logic_1 = ap_CS_fsm_state2)) then 
            data_channel12_read <= grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel12_read;
        else 
            data_channel12_read <= ap_const_logic_0;
        end if; 
    end process;

    data_channel232_din <= grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_data_channel232_din;

    data_channel232_write_assign_proc : process(grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_data_channel232_write, ap_CS_fsm_state5)
    begin
        if ((ap_const_logic_1 = ap_CS_fsm_state5)) then 
            data_channel232_write <= grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_data_channel232_write;
        else 
            data_channel232_write <= ap_const_logic_0;
        end if; 
    end process;


    data_channel23_read_assign_proc : process(grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel23_read, ap_CS_fsm_state2)
    begin
        if ((ap_const_logic_1 = ap_CS_fsm_state2)) then 
            data_channel23_read <= grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_data_channel23_read;
        else 
            data_channel23_read <= ap_const_logic_0;
        end if; 
    end process;

    grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_start <= grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30_ap_start_reg;
    grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_start <= grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_start_reg;

    internal_ap_ready_assign_proc : process(grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_done, ap_CS_fsm_state5)
    begin
        if (((grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41_ap_done = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_state5))) then 
            internal_ap_ready <= ap_const_logic_1;
        else 
            internal_ap_ready <= ap_const_logic_0;
        end if; 
    end process;


    real_start_assign_proc : process(ap_start, start_full_n, start_once_reg)
    begin
        if (((start_once_reg = ap_const_logic_0) and (start_full_n = ap_const_logic_0))) then 
            real_start <= ap_const_logic_0;
        else 
            real_start <= ap_start;
        end if; 
    end process;

    start_out <= real_start;

    start_write_assign_proc : process(real_start, start_once_reg)
    begin
        if (((start_once_reg = ap_const_logic_0) and (real_start = ap_const_logic_1))) then 
            start_write <= ap_const_logic_1;
        else 
            start_write <= ap_const_logic_0;
        end if; 
    end process;

end behav;
