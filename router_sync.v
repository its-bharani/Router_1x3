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
