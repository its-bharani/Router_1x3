module fifo_tb();
    reg clock;
    reg resetn;
    reg soft_reset;
    reg write_en;
    reg read_en;
    reg lfd_state;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire empty;
    wire full;

    fifo dut (
        .clock(clock),
        .resetn(resetn),
        .soft_reset(soft_reset),
        .write_en(write_en),
        .read_en(read_en),
        .lfd_state(lfd_state),
        .data_in(data_in),
        .data_out(data_out),
        .empty(empty),
        .full(full)
    );
integer i;
  
// Clock generation
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    // Test sequence
    initial begin
        // Initialization
        resetn = 0;
        soft_reset = 0;
        write_en = 0;
        read_en = 0;
        lfd_state = 0;
        data_in = 8'h00;
        #10;

        // Release reset
        resetn = 1;
        #10;

        // Fill the FIFO to observe full condition
        write_en = 1;
      for(i = 0; i < 16; i = i + 1)
	begin
            data_in = i;
            #10;
        end
        write_en = 0;

        // Attempt to write when FIFO is full
        data_in = 8'hFF;
        #10;

        // Read all data to observe empty condition
        read_en = 1;
        #80;
        read_en = 0;

        // Attempt to read when FIFO is empty
        #10;

        // Soft reset during operations
        soft_reset = 1;
        #10;
        soft_reset = 0;

        // Finish simulation
        #50;
        $stop;
    end
endmodule
