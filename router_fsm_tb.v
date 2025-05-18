module router_fsm_tb;
    // Inputs
    reg clock;
    reg resetn;
    reg pkt_valid;
    reg fifo_full;
    reg [1:0] data_in;
    reg parity_done;
    reg low_pkt_valid;
    reg soft_reset_0;
    reg soft_reset_1;
    reg soft_reset_2;

    // Outputs
    wire busy;
    wire detect_add;
    wire lfd_state;
    wire ld_state;
    wire write_enb_reg;
    wire full_state;
    wire laf_state;
    wire rst_int_reg;

    // Instantiate the FSM
    router_fsm uut (
        .clock(clock),
        .resetn(resetn),
        .pkt_valid(pkt_valid),
        .fifo_full(fifo_full),
        .data_in(data_in),
        .parity_done(parity_done),
        .low_pkt_valid(low_pkt_valid),
        .soft_reset_0(soft_reset_0),
        .soft_reset_1(soft_reset_1),
        .soft_reset_2(soft_reset_2),
        .busy(busy),
        .detect_add(detect_add),
        .lfd_state(lfd_state),
        .ld_state(ld_state),
        .write_enb_reg(write_enb_reg),
        .full_state(full_state),
        .laf_state(laf_state),
        .rst_int_reg(rst_int_reg)
    );
  initial begin
    $dumpfile("fsm.vcd");
    $dumpvars;
  end

    // Clock generation
    initial begin
        clock = 0;
        forever #5 clock = ~clock; // 10ns clock period
    end

    // Test sequence
    initial begin
        // Initialize inputs
        resetn = 0;
        pkt_valid = 0;
        fifo_full = 0;
        data_in = 2'b00;
        parity_done = 0;
        low_pkt_valid = 0;
        soft_reset_0 = 0;
        soft_reset_1 = 0;
        soft_reset_2 = 0;

        // Apply reset
        #10 resetn = 1;

        // Test Case 1: Normal packet processing
        #10 pkt_valid = 1; data_in = 2'b01; // DECODE_ADDRESS to LOAD_FIRST_DATA
        #10 pkt_valid = 1; fifo_full = 0; // LOAD_FIRST_DATA to LOAD_DATA
        #10 pkt_valid = 0; parity_done = 0; // LOAD_DATA to LOAD_PARITY
        #10 parity_done = 1; // LOAD_PARITY to CHECK_PARITY_ERROR
        #10 fifo_full = 0; // CHECK_PARITY_ERROR back to DECODE_ADDRESS

        // Test Case 2: FIFO full condition
        #10 pkt_valid = 1; data_in = 2'b10; fifo_full = 1; // Transition to FIFO_FULL_STATE
        #10 fifo_full = 0; // Back to LOAD_AFTER_FULL and normal flow

        // Test Case 3: Soft reset handling
        #10 soft_reset_0 = 1; // Apply soft reset
        #10 soft_reset_0 = 0; // Release soft reset

        // End simulation
        #50 $finish;
    end
endmodule
