module top (
    input clock,
    input resetn,
    input pkt_valid,
    input [7:0] data_in,
    input [2:0] read_en,
    output [2:0] vld_out,
    output [7:0] data_out_0,
    output [7:0] data_out_1,
    output [7:0] data_out_2,
    output [2:0] full,
    output [2:0] empty
);

    // Internal signals
    wire [2:0] write_en;
    wire [2:0] soft_reset;
    wire fifo_full;
    wire [7:0] dout;
    wire parity_done, low_pkt_valid, err;
    wire detect_add, lfd_state, ld_state, write_enb_reg, full_state, laf_state, rst_int_reg;

    // FIFO instances
    fifo fifo_0 (
        .clock(clock),
        .resetn(resetn),
        .soft_reset(soft_reset[0]),
        .write_en(write_en[0]),
        .read_en(read_en[0]),
        .lfd_state(lfd_state),
        .data_in(dout),
        .data_out(data_out_0),
        .empty(empty[0]),
        .full(full[0])
    );

    fifo fifo_1 (
        .clock(clock),
        .resetn(resetn),
        .soft_reset(soft_reset[1]),
        .write_en(write_en[1]),
        .read_en(read_en[1]),
        .lfd_state(lfd_state),
        .data_in(dout),
        .data_out(data_out_1),
        .empty(empty[1]),
        .full(full[1])
    );

    fifo fifo_2 (
        .clock(clock),
        .resetn(resetn),
        .soft_reset(soft_reset[2]),
        .write_en(write_en[2]),
        .read_en(read_en[2]),
        .lfd_state(lfd_state),
        .data_in(dout),
        .data_out(data_out_2),
        .empty(empty[2]),
        .full(full[2])
    );

    // Register instance
    register reg_inst (
        .clock(clock),
        .resetn(resetn),
        .pkt_valid(pkt_valid),
        .data_in(data_in),
        .fifo_full(fifo_full),
        .rst_int_reg(rst_int_reg),
        .detect_add(detect_add),
        .ld_state(ld_state),
        .laf_state(laf_state),
        .full_state(full_state),
        .parity_done(parity_done),
        .low_pkt_valid(low_pkt_valid),
        .dout(dout),
        .err(err)
    );

    // Synchronizer instance
    router_sync sync_inst (
        .clock(clock),
        .resetn(resetn),
        .detect_add(detect_add),
        .data_in(data_in[1:0]),
        .write_en_reg(write_enb_reg),
        .empty(empty),
        .full(full),
        .read_en(read_en),
        .write_en(write_en),
        .fifo_full(fifo_full),
        .vld_out(vld_out),
        .soft_reset(soft_reset)
    );

    // FSM instance
    router_fsm fsm_inst (
        .clock(clock),
        .resetn(resetn),
        .pkt_valid(pkt_valid),
        .fifo_full(fifo_full),
        .data_in(data_in[1:0]),
        .parity_done(parity_done),
        .low_pkt_valid(low_pkt_valid),
        .soft_reset_0(soft_reset[0]),
        .soft_reset_1(soft_reset[1]),
        .soft_reset_2(soft_reset[2]),
        .busy(), // Optional if needed
        .detect_add(detect_add),
        .lfd_state(lfd_state),
        .ld_state(ld_state),
        .write_enb_reg(write_enb_reg),
        .full_state(full_state),
        .laf_state(laf_state),
        .rst_int_reg(rst_int_reg)
    );

endmodule
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
module router_sync(
    input clock,
    input resetn,
    input detect_add,
    input [1:0] data_in,
    input write_en_reg,
    input [2:0] empty,
    input [2:0] full,
    input [2:0] read_en,
    output reg [2:0] write_en,
    output reg fifo_full,
  output [2:0]vld_out,
    output reg [2:0] soft_reset
);
    reg [1:0] add;
    reg [4:0] count_read [2:0]; // Array for count_read logic

    // Address logic
    always @(posedge clock) begin
        if (detect_add)
            add <= data_in;
    end

    // Write enable logic
    always @(*) begin
        if (!write_en_reg)
            write_en = 3'b000;
        else begin
            case (add)
                2'b00: write_en = 3'b001;
                2'b01: write_en = 3'b010;
                2'b10: write_en = 3'b100;
                default: write_en = 3'b000;
            endcase
        end
    end

    // Valid output signals
  assign vld_out[0] = !empty[0];
  assign vld_out[1] = !empty[1];
  assign vld_out[2] = !empty[2];

    // Soft reset logic using generate block
    genvar i;
    generate
        for (i = 0; i < 3; i = i + 1) begin : soft_reset_logic
            always @(posedge clock) begin
                if (!resetn) begin
                    count_read[i] <= 0;
                    soft_reset[i] <= 0;
                end else if (!vld_out[i]) begin
                    count_read[i] <= 0;
                    soft_reset[i] <= 0;
                end else if (read_en[i]) begin
                    count_read[i] <= 0;
                    soft_reset[i] <= 0;
                end else begin
                    if (count_read[i] == 29) begin
                        count_read[i] <= 0;
                        soft_reset[i] <= 1; // Activate soft reset
                    end else begin
                        count_read[i] <= count_read[i] + 1;
                        soft_reset[i] <= 0;
                    end
                end
            end
        end
    endgenerate
   always@(*)
    begin
      case(add)
        2'b00:fifo_full=full[0];
        2'b01:fifo_full=full[1];
        2'b10:fifo_full=full[2];
        default:fifo_full=0;
      endcase
    end
endmodule
module fifo(input clock,
            input resetn,
            input soft_reset,
            input write_en,
            input read_en,
            input lfd_state,
            input [7:0] data_in,
            output reg [7:0] data_out,
            output empty,
            output full);
  reg [8:0] memory[15:0];
  reg [4:0] write_ptr,read_ptr;
  reg [6:0] count;
  integer i;
  
  //emtpy and full
  assign empty=(write_ptr == read_ptr);
  assign full=(write_ptr =={!read_ptr[4],read_ptr[3:0]});
               
   //write operation
               always@(posedge clock)
                 begin
                   if(!resetn)
                     begin
                       write_ptr<=0;
                       for (i=0;i<16;i=i+1)
                         memory[i]<=0;
                     end
                   else if(soft_reset)
                     begin
                       write_ptr <=0;
                       for(i=0;i<16;i=i+1)
                         memory[i]<=0;
                     end
                   else
                     begin
                       if(write_en && !full)
                       begin
                       write_ptr <=write_ptr+1;
                       
                         memory[write_ptr[3:0]] <={lfd_state,data_in};
                     end
                                end
                  end
  //read operation              
 always@(posedge clock) begin
    if (!resetn || soft_reset) begin
        read_ptr <= 0;
        data_out <= 8'h00;
    end else if (read_en && !empty) begin
        data_out <= memory[read_ptr[3:0]][7:0]; // Ensure 8-bit data is assigned
        read_ptr <= read_ptr + 1;
    end else if (!read_en) begin
        data_out <= 8'hZZ; // Set to high-impedance only if no read is active
    end
end
    //down_counter logic
   always@(posedge clock)
     begin
       if(!resetn)
         count<=0;
       else if(soft_reset)
         count<=0;
       else if(read_en && !empty)
         begin
         if(memory[read_ptr[3:0]][8] ==1)
           count<=memory[read_ptr[3:0]][7:2]+1'b1;
           else if (count!=0)
			count<=count-1'b1;
         end
     end
         endmodule
                                
 module register(
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

