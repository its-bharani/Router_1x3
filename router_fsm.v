module router_fsm (
    input clock,
    input resetn,
    input pkt_valid,
    input fifo_full,
    input [1:0] data_in,
    input parity_done,
    input low_pkt_valid,
    input soft_reset_0,
    input soft_reset_1,
    input soft_reset_2,
    output reg busy,
    output reg detect_add,
    output reg lfd_state,
    output reg ld_state,
    output reg write_enb_reg,
    output reg full_state,
    output reg laf_state,
    output reg rst_int_reg
);
    // State Encoding
localparam [3:0] DECODE_ADDRESS  = 4'b0000,
                 LOAD_FIRST_DATA = 4'b0001,
                 LOAD_DATA       = 4'b0010,
                 LOAD_PARITY     = 4'b0011,
                 FIFO_FULL_STATE = 4'b0100,
                 LOAD_AFTER_FULL = 4'b0101,
                 WAIT_TILL_EMPTY = 4'b0110,
                 CHECK_PARITY_ERR= 4'b0111;

reg [3:0] state;


    reg [3:0] current_state, next_state;
    reg [15:0] timeout_counter; // Timeout counter (example size)
    parameter TIMEOUT_LIMIT = 16'hFFFF; // Adjust timeout limit

    // FSM State Transitions
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            current_state <= DECODE_ADDRESS;
            timeout_counter <= 0;
        end else if (soft_reset_0 || soft_reset_1 || soft_reset_2) begin
            current_state <= DECODE_ADDRESS; // Handle soft-reset
            timeout_counter <= 0;
        end else begin
            current_state <= next_state;
            timeout_counter <= (timeout_counter == TIMEOUT_LIMIT) ? 0 : timeout_counter + 1;
        end
    end

    // FSM Next State Logic
    always @(*) begin
        // Default outputs and next state
        next_state = current_state;
        {busy, detect_add, lfd_state, ld_state, write_enb_reg, full_state, laf_state, rst_int_reg} = 0;

        case (current_state)
            DECODE_ADDRESS: begin
                detect_add = 1;
                if (pkt_valid && (data_in == 2'b00)) next_state = LOAD_FIRST_DATA;
                else if (pkt_valid && (data_in == 2'b01)) next_state = WAIT_TILL_EMPTY;
                else if (pkt_valid && (data_in == 2'b10)) next_state = WAIT_TILL_EMPTY;
                else if (pkt_valid && (data_in == 2'b11)) next_state = WAIT_TILL_EMPTY;
            end

            LOAD_FIRST_DATA: begin
                lfd_state = 1;
                busy = 1;
                next_state = LOAD_DATA;
            end

            LOAD_DATA: begin
                ld_state = 1;
                write_enb_reg = 1;
                if (fifo_full) next_state = FIFO_FULL_STATE;
                else if (!pkt_valid) next_state = LOAD_PARITY;
            end

            LOAD_PARITY: begin
                busy = 1;
                write_enb_reg = 1;
                next_state = CHECK_PARITY_ERR;
            end

            CHECK_PARITY_ERR: begin
                busy = 1;
                rst_int_reg = 1;
                if (fifo_full) next_state = FIFO_FULL_STATE;
                else next_state = DECODE_ADDRESS;
            end

            FIFO_FULL_STATE: begin
                busy = 1;
                full_state = 1;
                if (!fifo_full) next_state = LOAD_AFTER_FULL;
            end

            LOAD_AFTER_FULL: begin
                busy = 1;
                laf_state = 1;
                write_enb_reg = 1;
                if (parity_done && low_pkt_valid) next_state = LOAD_PARITY;
                else if (parity_done) next_state = DECODE_ADDRESS;
                else next_state = LOAD_DATA;
            end

            WAIT_TILL_EMPTY: begin
                busy = 1;
                if (!fifo_full) next_state = DECODE_ADDRESS;
            end

            default: next_state = DECODE_ADDRESS;
        endcase

        // Timeout handling
        if (timeout_counter == TIMEOUT_LIMIT) begin
            next_state = DECODE_ADDRESS;
        end
    end

endmodule
