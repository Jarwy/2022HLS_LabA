`timescale 1 ns / 1 ps

module AESL_deadlock_report_unit #( parameter PROC_NUM = 4 ) (
    input dl_reset,
    input dl_clock,
    input [PROC_NUM - 1:0] dl_in_vec,
    input [15:0] trans_in_cnt_0,
    input [15:0] trans_out_cnt_0,
    input [15:0] trans_in_cnt_1,
    input [15:0] trans_out_cnt_1,
    input [15:0] trans_in_cnt_2,
    input [15:0] trans_out_cnt_2,
    output dl_detect_out,
    output reg [PROC_NUM - 1:0] origin,
    output token_clear);
   
    // FSM states
    localparam ST_IDLE = 3'b000;
    localparam ST_FILTER_FAKE = 3'b001;
    localparam ST_DL_DETECTED = 3'b010;
    localparam ST_DL_REPORT = 3'b100;

    reg find_df_deadlock;
    reg [2:0] CS_fsm;
    reg [2:0] NS_fsm;
    reg [PROC_NUM - 1:0] dl_detect_reg;
    reg [PROC_NUM - 1:0] dl_done_reg;
    reg [PROC_NUM - 1:0] origin_reg;
    reg [PROC_NUM - 1:0] dl_in_vec_reg;
    reg [31:0] dl_keep_cnt;
    integer i;
    integer fp;

    // FSM State machine
    always @ (negedge dl_reset or posedge dl_clock) begin
        if (~dl_reset) begin
            CS_fsm <= ST_IDLE;
        end
        else begin
            CS_fsm <= NS_fsm;
        end
    end
    always @ (CS_fsm or dl_in_vec or dl_detect_reg or dl_done_reg or dl_in_vec or origin_reg or dl_keep_cnt) begin
        case (CS_fsm)
            ST_IDLE : begin
                if (|dl_in_vec) begin
                    NS_fsm = ST_FILTER_FAKE;
                end
                else begin
                    NS_fsm = ST_IDLE;
                end
            end
            ST_FILTER_FAKE: begin
                if (dl_keep_cnt >= 32'd1000) begin
                    NS_fsm = ST_DL_DETECTED;
                end
                else if (dl_detect_reg != (dl_detect_reg & dl_in_vec)) begin
                    NS_fsm = ST_IDLE;
                end
                else begin
                    NS_fsm = ST_FILTER_FAKE;
                end
            end
            ST_DL_DETECTED: begin
                // has unreported deadlock cycle
                if (dl_detect_reg != dl_done_reg) begin
                    NS_fsm = ST_DL_REPORT;
                end
                else begin
                    NS_fsm = ST_DL_DETECTED;
                end
            end
            ST_DL_REPORT: begin
                if (|(dl_in_vec & origin_reg)) begin
                    NS_fsm = ST_DL_DETECTED;
                end
                else begin
                    NS_fsm = ST_DL_REPORT;
                end
            end
            default: NS_fsm = ST_IDLE;
        endcase
    end

    // dl_detect_reg record the procs that first detect deadlock
    always @ (negedge dl_reset or posedge dl_clock) begin
        if (~dl_reset) begin
            dl_detect_reg <= 'b0;
        end
        else begin
            if (CS_fsm == ST_IDLE) begin
                dl_detect_reg <= dl_in_vec;
            end
        end
    end

    always @ (negedge dl_reset or posedge dl_clock) begin
        if (~dl_reset) begin
            dl_keep_cnt <= 32'h0;
        end
        else begin
            if (CS_fsm == ST_FILTER_FAKE && (dl_detect_reg == (dl_detect_reg & dl_in_vec))) begin
                dl_keep_cnt <= dl_keep_cnt + 32'h1;
            end
            else if (CS_fsm == ST_FILTER_FAKE && (dl_detect_reg != (dl_detect_reg & dl_in_vec))) begin
                dl_keep_cnt <= 32'h0;
            end
        end
    end

    // dl_detect_out keeps in high after deadlock detected
    assign dl_detect_out = (|dl_detect_reg) && (CS_fsm == ST_DL_DETECTED || CS_fsm == ST_DL_REPORT);

    // dl_done_reg record the cycles has been reported
    always @ (negedge dl_reset or posedge dl_clock) begin
        if (~dl_reset) begin
            dl_done_reg <= 'b0;
        end
        else begin
            if ((CS_fsm == ST_DL_REPORT) && (|(dl_in_vec & dl_detect_reg) == 'b1)) begin
                dl_done_reg <= dl_done_reg | dl_in_vec;
            end
        end
    end

    // clear token once a cycle is done
    assign token_clear = (CS_fsm == ST_DL_REPORT) ? ((|(dl_in_vec & origin_reg)) ? 'b1 : 'b0) : 'b0;

    // origin_reg record the current cycle start id
    always @ (negedge dl_reset or posedge dl_clock) begin
        if (~dl_reset) begin
            origin_reg <= 'b0;
        end
        else begin
            if (CS_fsm == ST_DL_DETECTED) begin
                origin_reg <= origin;
            end
        end
    end
   
    // origin will be valid for only one cycle
    wire [PROC_NUM*PROC_NUM - 1:0] origin_tmp;
    assign origin_tmp[PROC_NUM - 1:0] = (dl_detect_reg[0] & ~dl_done_reg[0]) ? 'b1 : 'b0;
    genvar j;
    generate
    for(j = 1;j < PROC_NUM;j = j + 1) begin: F1
        assign origin_tmp[j*PROC_NUM +: PROC_NUM] = (dl_detect_reg[j] & ~dl_done_reg[j]) ? ('b1 << j) : origin_tmp[(j - 1)*PROC_NUM +: PROC_NUM];
    end
    endgenerate
    always @ (CS_fsm or origin_tmp) begin
        if (CS_fsm == ST_DL_DETECTED) begin
            origin = origin_tmp[(PROC_NUM - 1)*PROC_NUM +: PROC_NUM];
        end
        else begin
            origin = 'b0;
        end
    end

    
    // dl_in_vec_reg record the current cycle dl_in_vec
    always @ (negedge dl_reset or posedge dl_clock) begin
        if (~dl_reset) begin
            dl_in_vec_reg <= 'b0;
        end
        else begin
            if (CS_fsm == ST_DL_DETECTED) begin
                dl_in_vec_reg <= origin;
            end
            else if (CS_fsm == ST_DL_REPORT) begin
                dl_in_vec_reg <= dl_in_vec;
            end
        end
    end
    
    // find_df_deadlock to report the deadlock
    always @ (negedge dl_reset or posedge dl_clock) begin
        if (~dl_reset) begin
            find_df_deadlock <= 1'b0;
        end
        else begin
            if (CS_fsm == ST_DL_DETECTED && dl_detect_reg == dl_done_reg) begin
                find_df_deadlock <= 1'b1;
            end
            else if (CS_fsm == ST_IDLE) begin
                find_df_deadlock <= 1'b0;
            end
        end
    end
    
    // get the first valid proc index in dl vector
    function integer proc_index(input [PROC_NUM - 1:0] dl_vec);
        begin
            proc_index = 0;
            for (i = 0; i < PROC_NUM; i = i + 1) begin
                if (dl_vec[i]) begin
                    proc_index = i;
                end
            end
        end
    endfunction

    // get the proc path based on dl vector
    function [312:0] proc_path(input [PROC_NUM - 1:0] dl_vec);
        integer index;
        begin
            index = proc_index(dl_vec);
            case (index)
                0 : begin
                    proc_path = "example.proc_1_U0";
                end
                1 : begin
                    proc_path = "example.proc_1_U0.proc_1_1_U0";
                end
                2 : begin
                    proc_path = "example.proc_1_U0.proc_1_2_U0";
                end
                3 : begin
                    proc_path = "example.proc_2_U0";
                end
                4 : begin
                    proc_path = "example.proc_2_U0.proc_2_1_U0";
                end
                5 : begin
                    proc_path = "example.proc_2_U0.proc_2_2_U0";
                end
                default : begin
                    proc_path = "unknown";
                end
            endcase
        end
    endfunction

    // print the headlines of deadlock detection
    task print_dl_head;
        begin
            $display("\n//////////////////////////////////////////////////////////////////////////////");
            $display("// ERROR!!! DEADLOCK DETECTED at %0t ns! SIMULATION WILL BE STOPPED! //", $time);
            $display("//////////////////////////////////////////////////////////////////////////////");
            fp = $fopen("deadlock_db.dat", "w");
        end
    endtask

    // print the start of a cycle
    task print_cycle_start(input reg [312:0] proc_path, input integer cycle_id);
        begin
            $display("/////////////////////////");
            $display("// Dependence cycle %0d:", cycle_id);
            $display("// (1): Process: %0s", proc_path);
            $fdisplay(fp, "Dependence_Cycle_ID %0d", cycle_id);
            $fdisplay(fp, "Dependence_Process_ID 1");
            $fdisplay(fp, "Dependence_Process_path %0s", proc_path);
        end
    endtask

    // print the end of deadlock detection
    task print_dl_end(input integer num, input integer record_time);
        begin
            $display("////////////////////////////////////////////////////////////////////////");
            $display("// Totally %0d cycles detected!", num);
            $display("////////////////////////////////////////////////////////////////////////");
            $fdisplay(fp, "Dependence_Cycle_Number %0d", num);
            $fclose(fp);
        end
    endtask

    // print one proc component in the cycle
    task print_cycle_proc_comp(input reg [312:0] proc_path, input integer cycle_comp_id);
        begin
            $display("// (%0d): Process: %0s", cycle_comp_id, proc_path);
            $fdisplay(fp, "Dependence_Process_ID %0d", cycle_comp_id);
            $fdisplay(fp, "Dependence_Process_path %0s", proc_path);
        end
    endtask

    // print one channel component in the cycle
    task print_cycle_chan_comp(input [PROC_NUM - 1:0] dl_vec1, input [PROC_NUM - 1:0] dl_vec2);
        reg [408:0] chan_path;
        integer index1;
        integer index2;
        begin
            index1 = proc_index(dl_vec1);
            index2 = proc_index(dl_vec2);
            case (index1)
                0 : begin
                    case(index2)
                    3: begin
                        if (~AESL_inst_example.proc_1_U0.proc_1_2_U0.grp_proc_1_2_Pipeline_VITIS_LOOP_55_1_fu_30.data_channel12_blk_n) begin
                            if (~AESL_inst_example.data_channel1_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel1_U' written by process 'example.proc_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel1_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel1_U' read by process 'example.proc_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_1_U0.proc_1_2_U0.grp_proc_1_2_Pipeline_VITIS_LOOP_59_2_fu_41.data_channel23_blk_n) begin
                            if (~AESL_inst_example.data_channel2_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel2_U' written by process 'example.proc_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel2_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel2_U' read by process 'example.proc_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.start_for_proc_2_U0_U.if_full_n & AESL_inst_example.proc_1_U0.ap_start & ~AESL_inst_example.proc_1_U0.real_start & (trans_in_cnt_1 == trans_out_cnt_1) & ~AESL_inst_example.start_for_proc_2_U0_U.if_read) begin
                            $display("//      Blocked by full output start propagation FIFO 'example.start_for_proc_2_U0_U' read by process 'example.proc_2_U0',");
                        end
                    end
                    4: begin
                        if (~AESL_inst_example.proc_1_U0.proc_1_2_U0.grp_proc_1_2_Pipeline_VITIS_LOOP_55_1_fu_30.data_channel12_blk_n) begin
                            if (~AESL_inst_example.data_channel1_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel1_U' written by process 'example.proc_2_U0.proc_2_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel1_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel1_U' read by process 'example.proc_2_U0.proc_2_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_1_U0.proc_1_2_U0.grp_proc_1_2_Pipeline_VITIS_LOOP_59_2_fu_41.data_channel23_blk_n) begin
                            if (~AESL_inst_example.data_channel2_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel2_U' written by process 'example.proc_2_U0.proc_2_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel2_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel2_U' read by process 'example.proc_2_U0.proc_2_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                    end
                    endcase
                end
                1 : begin
                    case(index2)
                    2: begin
                        if (~AESL_inst_example.proc_1_U0.proc_1_1_U0.grp_proc_1_1_Pipeline_VITIS_LOOP_42_1_fu_28.data_channel12_blk_n) begin
                            if (~AESL_inst_example.proc_1_U0.data_channel1_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.proc_1_U0.data_channel1_U' written by process 'example.proc_1_U0.proc_1_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_1_U0.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.proc_1_U0.data_channel1_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.proc_1_U0.data_channel1_U' read by process 'example.proc_1_U0.proc_1_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_1_U0.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_1_U0.proc_1_1_U0.grp_proc_1_1_Pipeline_VITIS_LOOP_46_2_fu_37.data_channel23_blk_n) begin
                            if (~AESL_inst_example.proc_1_U0.data_channel2_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.proc_1_U0.data_channel2_U' written by process 'example.proc_1_U0.proc_1_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_1_U0.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.proc_1_U0.data_channel2_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.proc_1_U0.data_channel2_U' read by process 'example.proc_1_U0.proc_1_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_1_U0.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_1_U0.start_for_proc_1_2_U0_U.if_full_n & AESL_inst_example.proc_1_U0.proc_1_1_U0.ap_start & ~AESL_inst_example.proc_1_U0.proc_1_1_U0.real_start & (trans_in_cnt_0 == trans_out_cnt_0) & ~AESL_inst_example.proc_1_U0.start_for_proc_1_2_U0_U.if_read) begin
                            $display("//      Blocked by full output start propagation FIFO 'example.proc_1_U0.start_for_proc_1_2_U0_U' read by process 'example.proc_1_U0.proc_1_2_U0',");
                        end
                    end
                    endcase
                end
                2 : begin
                    case(index2)
                    3: begin
                        if (~AESL_inst_example.proc_1_U0.proc_1_2_U0.grp_proc_1_2_Pipeline_VITIS_LOOP_55_1_fu_30.data_channel12_blk_n) begin
                            if (~AESL_inst_example.data_channel1_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel1_U' written by process 'example.proc_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel1_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel1_U' read by process 'example.proc_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_1_U0.proc_1_2_U0.grp_proc_1_2_Pipeline_VITIS_LOOP_59_2_fu_41.data_channel23_blk_n) begin
                            if (~AESL_inst_example.data_channel2_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel2_U' written by process 'example.proc_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel2_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel2_U' read by process 'example.proc_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                    end
                    4: begin
                        if (~AESL_inst_example.proc_1_U0.proc_1_2_U0.grp_proc_1_2_Pipeline_VITIS_LOOP_55_1_fu_30.data_channel12_blk_n) begin
                            if (~AESL_inst_example.data_channel1_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel1_U' written by process 'example.proc_2_U0.proc_2_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel1_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel1_U' read by process 'example.proc_2_U0.proc_2_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_1_U0.proc_1_2_U0.grp_proc_1_2_Pipeline_VITIS_LOOP_59_2_fu_41.data_channel23_blk_n) begin
                            if (~AESL_inst_example.data_channel2_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel2_U' written by process 'example.proc_2_U0.proc_2_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel2_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel2_U' read by process 'example.proc_2_U0.proc_2_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                    end
                    1: begin
                        if (~AESL_inst_example.proc_1_U0.proc_1_2_U0.grp_proc_1_2_Pipeline_VITIS_LOOP_55_1_fu_30.data_channel121_blk_n) begin
                            if (~AESL_inst_example.proc_1_U0.data_channel1_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.proc_1_U0.data_channel1_U' written by process 'example.proc_1_U0.proc_1_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_1_U0.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.proc_1_U0.data_channel1_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.proc_1_U0.data_channel1_U' read by process 'example.proc_1_U0.proc_1_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_1_U0.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_1_U0.proc_1_2_U0.grp_proc_1_2_Pipeline_VITIS_LOOP_55_1_fu_30.data_channel232_blk_n) begin
                            if (~AESL_inst_example.proc_1_U0.data_channel2_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.proc_1_U0.data_channel2_U' written by process 'example.proc_1_U0.proc_1_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_1_U0.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.proc_1_U0.data_channel2_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.proc_1_U0.data_channel2_U' read by process 'example.proc_1_U0.proc_1_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_1_U0.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_1_U0.start_for_proc_1_2_U0_U.if_empty_n & AESL_inst_example.proc_1_U0.proc_1_2_U0.ap_idle & ~AESL_inst_example.proc_1_U0.start_for_proc_1_2_U0_U.if_write) begin
                            $display("//      Blocked by missing 'ap_start' from start propagation FIFO 'example.proc_1_U0.start_for_proc_1_2_U0_U' written by process 'example.proc_1_U0.proc_1_1_U0',");
                        end
                    end
                    endcase
                end
                3 : begin
                    case(index2)
                    0: begin
                        if (~AESL_inst_example.proc_2_U0.proc_2_1_U0.grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30.data_channel12_blk_n) begin
                            if (~AESL_inst_example.data_channel1_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel1_U' written by process 'example.proc_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel1_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel1_U' read by process 'example.proc_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_2_U0.proc_2_1_U0.grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30.data_channel23_blk_n) begin
                            if (~AESL_inst_example.data_channel2_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel2_U' written by process 'example.proc_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel2_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel2_U' read by process 'example.proc_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.start_for_proc_2_U0_U.if_empty_n & AESL_inst_example.proc_2_U0.ap_idle & ~AESL_inst_example.start_for_proc_2_U0_U.if_write) begin
                            $display("//      Blocked by missing 'ap_start' from start propagation FIFO 'example.start_for_proc_2_U0_U' written by process 'example.proc_1_U0',");
                        end
                    end
                    2: begin
                        if (~AESL_inst_example.proc_2_U0.proc_2_1_U0.grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30.data_channel12_blk_n) begin
                            if (~AESL_inst_example.data_channel1_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel1_U' written by process 'example.proc_1_U0.proc_1_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel1_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel1_U' read by process 'example.proc_1_U0.proc_1_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_2_U0.proc_2_1_U0.grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30.data_channel23_blk_n) begin
                            if (~AESL_inst_example.data_channel2_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel2_U' written by process 'example.proc_1_U0.proc_1_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel2_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel2_U' read by process 'example.proc_1_U0.proc_1_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                    end
                    endcase
                end
                4 : begin
                    case(index2)
                    0: begin
                        if (~AESL_inst_example.proc_2_U0.proc_2_1_U0.grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30.data_channel12_blk_n) begin
                            if (~AESL_inst_example.data_channel1_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel1_U' written by process 'example.proc_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel1_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel1_U' read by process 'example.proc_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_2_U0.proc_2_1_U0.grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30.data_channel23_blk_n) begin
                            if (~AESL_inst_example.data_channel2_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel2_U' written by process 'example.proc_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel2_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel2_U' read by process 'example.proc_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                    end
                    2: begin
                        if (~AESL_inst_example.proc_2_U0.proc_2_1_U0.grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30.data_channel12_blk_n) begin
                            if (~AESL_inst_example.data_channel1_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel1_U' written by process 'example.proc_1_U0.proc_1_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel1_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel1_U' read by process 'example.proc_1_U0.proc_1_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_2_U0.proc_2_1_U0.grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30.data_channel23_blk_n) begin
                            if (~AESL_inst_example.data_channel2_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.data_channel2_U' written by process 'example.proc_1_U0.proc_1_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.data_channel2_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.data_channel2_U' read by process 'example.proc_1_U0.proc_1_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                    end
                    5: begin
                        if (~AESL_inst_example.proc_2_U0.proc_2_1_U0.grp_proc_2_1_Pipeline_VITIS_LOOP_76_1_fu_30.data_channel121_blk_n) begin
                            if (~AESL_inst_example.proc_2_U0.data_channel1_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.proc_2_U0.data_channel1_U' written by process 'example.proc_2_U0.proc_2_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_2_U0.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.proc_2_U0.data_channel1_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.proc_2_U0.data_channel1_U' read by process 'example.proc_2_U0.proc_2_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_2_U0.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_2_U0.proc_2_1_U0.grp_proc_2_1_Pipeline_VITIS_LOOP_80_2_fu_41.data_channel232_blk_n) begin
                            if (~AESL_inst_example.proc_2_U0.data_channel2_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.proc_2_U0.data_channel2_U' written by process 'example.proc_2_U0.proc_2_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_2_U0.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.proc_2_U0.data_channel2_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.proc_2_U0.data_channel2_U' read by process 'example.proc_2_U0.proc_2_2_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_2_U0.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_2_U0.start_for_proc_2_2_U0_U.if_full_n & AESL_inst_example.proc_2_U0.proc_2_1_U0.ap_start & ~AESL_inst_example.proc_2_U0.proc_2_1_U0.real_start & (trans_in_cnt_2 == trans_out_cnt_2) & ~AESL_inst_example.proc_2_U0.start_for_proc_2_2_U0_U.if_read) begin
                            $display("//      Blocked by full output start propagation FIFO 'example.proc_2_U0.start_for_proc_2_2_U0_U' read by process 'example.proc_2_U0.proc_2_2_U0',");
                        end
                    end
                    endcase
                end
                5 : begin
                    case(index2)
                    4: begin
                        if (~AESL_inst_example.proc_2_U0.proc_2_2_U0.data_channel12_blk_n) begin
                            if (~AESL_inst_example.proc_2_U0.data_channel1_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.proc_2_U0.data_channel1_U' written by process 'example.proc_2_U0.proc_2_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_2_U0.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.proc_2_U0.data_channel1_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.proc_2_U0.data_channel1_U' read by process 'example.proc_2_U0.proc_2_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_2_U0.data_channel1_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_2_U0.proc_2_2_U0.data_channel23_blk_n) begin
                            if (~AESL_inst_example.proc_2_U0.data_channel2_U.if_empty_n) begin
                                $display("//      Blocked by empty input FIFO 'example.proc_2_U0.data_channel2_U' written by process 'example.proc_2_U0.proc_2_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_2_U0.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status EMPTY");
                            end
                            else if (~AESL_inst_example.proc_2_U0.data_channel2_U.if_full_n) begin
                                $display("//      Blocked by full output FIFO 'example.proc_2_U0.data_channel2_U' read by process 'example.proc_2_U0.proc_2_1_U0'");
                                $fdisplay(fp, "Dependence_Channel_path example.proc_2_U0.data_channel2_U");
                                $fdisplay(fp, "Dependence_Channel_status FULL");
                            end
                        end
                        if (~AESL_inst_example.proc_2_U0.start_for_proc_2_2_U0_U.if_empty_n & AESL_inst_example.proc_2_U0.proc_2_2_U0.ap_idle & ~AESL_inst_example.proc_2_U0.start_for_proc_2_2_U0_U.if_write) begin
                            $display("//      Blocked by missing 'ap_start' from start propagation FIFO 'example.proc_2_U0.start_for_proc_2_2_U0_U' written by process 'example.proc_2_U0.proc_2_1_U0',");
                        end
                    end
                    endcase
                end
            endcase
        end
    endtask

    // report
    initial begin : report_deadlock
        integer cycle_id;
        integer cycle_comp_id;
        integer record_time;
        wait (dl_reset == 1);
        cycle_id = 1;
        record_time = 0;
        while (1) begin
            @ (negedge dl_clock);
            case (CS_fsm)
                ST_DL_DETECTED: begin
                    cycle_comp_id = 2;
                    if (dl_detect_reg != dl_done_reg) begin
                        if (dl_done_reg == 'b0) begin
                            print_dl_head;
                            record_time = $time;
                        end
                        print_cycle_start(proc_path(origin), cycle_id);
                        cycle_id = cycle_id + 1;
                    end
                    else begin
                        print_dl_end((cycle_id - 1),record_time);
                        @(negedge dl_clock);
                        @(negedge dl_clock);
                        $finish;
                    end
                end
                ST_DL_REPORT: begin
                    if ((|(dl_in_vec)) & ~(|(dl_in_vec & origin_reg))) begin
                        print_cycle_chan_comp(dl_in_vec_reg, dl_in_vec);
                        print_cycle_proc_comp(proc_path(dl_in_vec), cycle_comp_id);
                        cycle_comp_id = cycle_comp_id + 1;
                    end
                    else begin
                        print_cycle_chan_comp(dl_in_vec_reg, dl_in_vec);
                    end
                end
            endcase
        end
    end
 
endmodule
