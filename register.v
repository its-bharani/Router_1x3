module register (
    input wire clock,
    input wire resetn,
    input wire pkt_valid,
    input wire [7:0] data_in,
    input wire fifo_full,
    input wire rst_int_reg,
    input wire detect_add,
    input wire ld_state,
    input wire laf_state,
    input wire full_state,
    output reg parity_done,
    output reg low_pkt_valid,
    output reg [7:0] dout,
    output reg err
);

    reg [7:0] full_state_byte, pkt_parity, first_byte, internal_parity;

    // Parity Done Logic
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            parity_done <= 1'b0;
        else if ((ld_state && !fifo_full && !pkt_valid) || (laf_state && !parity_done && low_pkt_valid))
            parity_done <= 1'b1;
        else if (detect_add)
            parity_done <= 1'b0;
    end

    // Low Packet Valid Logic
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            low_pkt_valid <= 1'b0;
        else if (ld_state && !pkt_valid)
            low_pkt_valid <= 1'b1;
        else if (rst_int_reg)
            low_pkt_valid <= 1'b0;
    end

    // Output Data (dout) Logic
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            dout <= 8'h00;
            first_byte <= 8'h00;
            full_state_byte <= 8'h00;
        end else begin
            if (detect_add && pkt_valid && data_in[1:0] != 2'b11)
                first_byte <= data_in;
            else if (laf_state)
                dout <= (fifo_full) ? full_state_byte : first_byte;
            else if (ld_state) begin
                if (!fifo_full)
                    dout <= data_in;
                else
                    full_state_byte <= data_in;
            end
        end
    end

    // Internal Parity Calculation
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            internal_parity <= 8'h00;
        else if (detect_add)
            internal_parity <= 8'h00;
        else if (laf_state)
            internal_parity <= internal_parity ^ first_byte;
        else if (ld_state && !full_state && pkt_valid)
            internal_parity <= internal_parity ^ data_in;
    end

    // Error Logic
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            err <= 1'b0;
        else if (!parity_done)
            err <= 1'b0;
        else
            err <= (pkt_parity != internal_parity) ? 1'b1 : 1'b0;
    end

    // Packet Parity Update
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            pkt_parity <= 8'h00;
        else if (detect_add)
            pkt_parity <= 8'h00;
        else if ((ld_state && !pkt_valid && !fifo_full) || (laf_state && low_pkt_valid && !parity_done))
            pkt_parity <= data_in;
    end

endmodule
