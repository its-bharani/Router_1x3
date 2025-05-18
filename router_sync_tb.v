module tb_router_sync;

    // Testbench signals
    reg clock;
    reg resetn;
    reg detect_add;
    reg [1:0] data_in;
    reg write_en_reg;
    reg [2:0] empty;
    reg [2:0] full;
    reg [2:0] read_en;
    wire [2:0] write_en;
    wire fifo_full;
    wire [2:0] vld_out;
    wire [2:0] soft_reset;

    // Instantiate the design under test (DUT)
    router_sync dut (
        .clock(clock),
        .resetn(resetn),
        .detect_add(detect_add),
        .data_in(data_in),
        .write_en_reg(write_en_reg),
        .empty(empty),
        .full(full),
        .read_en(read_en),
        .write_en(write_en),
        .fifo_full(fifo_full),
        .vld_out(vld_out),
        .soft_reset(soft_reset)
    );
  initial begin
    $dumpfile("syn.vcd");
    $dumpvars;
  end

    // Clock generation
    initial begin
        clock = 0;
        forever #5 clock = ~clock; // 10 ns clock period
    end

    // Testbench sequence
    initial begin
        // Initialize inputs
        resetn = 0;
        detect_add = 0;
        data_in = 0;
        write_en_reg = 0;
        empty = 3'b111;  // All FIFOs initially empty
        full = 3'b000;   // All FIFOs initially not full
        read_en = 3'b000;

        // Reset the DUT
        #10 resetn = 1;

        // Test Case 1: Write to FIFO 0
        #10 detect_add = 1; data_in = 2'b00; write_en_reg = 1;
        #10 detect_add = 0; // Disable detect_add
        #20;

        // Test Case 2: Write to FIFO 1
        #10 detect_add = 1; data_in = 2'b01;
        #10 detect_add = 0; // Disable detect_add
        #20;

        // Test Case 3: FIFO Full and Empty conditions
        #10 full = 3'b001; // FIFO 0 is full
        #10 empty = 3'b110; // FIFO 1 and 2 are empty
        #20;

        // Test Case 4: Read enable and soft reset
        #10 read_en = 3'b001; // Enable read for FIFO 0
        #10 read_en = 3'b000;
        #50; // Wait for count to increment and trigger soft reset

        // End simulation
        #100 $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("Time=%0t | resetn=%b | detect_add=%b | data_in=%b | write_en_reg=%b | empty=%b | full=%b | read_en=%b | write_en=%b | fifo_full=%b | vld_out=%b | soft_reset=%b",
                 $time, resetn, detect_add, data_in, write_en_reg, empty, full, read_en, write_en, fifo_full, vld_out, soft_reset);
    end

endmodule
