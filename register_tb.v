module register_tb;

  // Inputs
  reg clock;
  reg resetn;
  reg pkt_valid;
  reg [7:0] data_in;
  reg fifo_full;
  reg rst_int_reg;
  reg detect_add;
  reg ld_state;
  reg laf_state;
  reg full_state;

  // Outputs
  wire parity_done;
  wire low_pkt_valid;
  wire [7:0] dout;
  wire err;

  // Instantiate the Unit Under Test (UUT)
  register uut (
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

  initial begin
    $dumpfile("reg.vcd");
    $dumpvars;
  end
    
             
  // Clock generation
  initial begin
    clock = 0;
    forever #5 clock = ~clock; // 10ns clock period
  end

  // Stimulus
  initial begin
    // Initialize Inputs
    resetn = 0;
    pkt_valid = 0;
    data_in = 8'h00;
    fifo_full = 0;
    rst_int_reg = 0;
    detect_add = 0;
    ld_state = 0;
    laf_state = 0;
    full_state = 0;

    // Reset the system
    #10 resetn = 1;

    // Test Case 1: Packet detection
    #10 detect_add = 1; pkt_valid = 1; data_in = 8'hA5;
    #10 detect_add = 0; ld_state = 1; pkt_valid = 1; data_in = 8'h3C;

    // Test Case 2: FIFO full handling
    #10 fifo_full = 1; ld_state = 1; data_in = 8'h7F;
    #10 fifo_full = 0;

    // Test Case 3: Parity computation and error
    #10 laf_state = 1; data_in = 8'hA5; pkt_valid = 0;
    #10 laf_state = 0; ld_state = 1; pkt_valid = 0; data_in = 8'hB6;

    // Test Case 4: Resetting low_pkt_valid
    #10 rst_int_reg = 1;
    #10 rst_int_reg = 0;

    // Test Case 5: Error condition
    #10 pkt_valid = 0; ld_state = 1; data_in = 8'h55;
    #10 laf_state = 1; data_in = 8'h33;

    // Test Case 6: End simulation
    #50 $finish;
  end

  // Monitor outputs
  initial begin
    $monitor(
      "Time=%0t | resetn=%b | detect_add=%b | pkt_valid=%b | data_in=%h | dout=%h | parity_done=%b | low_pkt_valid=%b | err=%b",
      $time, resetn, detect_add, pkt_valid, data_in, dout, parity_done, low_pkt_valid, err
    );
  end

endmodule
