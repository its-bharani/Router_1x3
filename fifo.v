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
                   if(!resetn|| soft_reset)
                     begin
                       write_ptr<=0;
                       for (i=0;i<16;i=i+1)
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
        read_ptr<=0;
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
                                
            
