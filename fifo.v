//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 //~~~~~~~~~~~~~~~~~~~FIFO~~~~~~~~~~~~~~~~~~~~~~
 //
 // clock frequencies: 33MHz and 25MHz
 // data width = 8 bits
 // data depth = 96 entries
 // adresses = 8 bits
 //
 // Full and Empty Signal
 // Half full and Half empty signals
 // Reset, read, write (simultaneous)
 //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

`timescale 1 ns / 100 ps
module fifo (size, data_out, full, empty, halffull, halfempty, data_in, write, read, clk_actual, rst);
    parameter   data_width = 8;
    parameter   data_depth = 96;
    parameter   address_width = 8;

    output [data_width-1:0]     data_out;
    output                      full;
    output                      empty;
    output                      halfempty;
    output                      halffull;
	 output [7:0]						size;

    input [data_width-1:0]      data_in;
    input                       write, read;
    input                       clk_actual, rst; //ONE CLOCK

    reg  [data_width-1:0]  	    data_out;
    reg                         full, empty, halffull, halfempty;
    reg  [data_width-1:0]        data [data_depth -1:0]; //holds data in queue
    reg                         just_readorwrote; //0 = read, wrote = 1
    reg  [7:0]                        size;
    reg [24:0]							count;
	 reg 									clk;
	 
    wire [address_width-1:0]    nextread_ptr, nextwrite_ptr;
    wire                        nextread_en, nextwrite_en; // works like boolean
    wire                        read_equals_write; // works like boolean
    wire                        full_indicator, empty_indicator, halffull_indicator, halfempty_indicator; //indicators that update outputs at clock

    counter write_counter(nextwrite_ptr, nextwrite_en, rst, clk); //increment pointer if writing
    counter read_counter(nextread_ptr, nextread_en, rst, clk); //increment pointer if reading
	
	 always @(posedge clk_actual)
	 begin
	 if (count == 24999999)
	 begin
	  count <=0;
	  clk = ~clk;
	 end
	 else 
	 count <= count+1;
	 end
	 
	 
    always @ (posedge clk or posedge rst) //check if we should write every clk1 posedge
    begin
      if (rst) //WRITE RESET
      begin
	    full <= 0;
	    halffull <= 0;
        empty <= 1;
        halfempty <=0;
        just_readorwrote <= 0; //reset to just read so stays set to empty
      end
      else 
      begin
        if(read & write & !full & !empty) begin
            data[nextwrite_ptr] <= data_in;
            data_out <= data[nextread_ptr];
            just_readorwrote <= 0; end

        else if(write & !full) begin //WHEN TO WRITE
            data[nextwrite_ptr] <= data_in; 
            just_readorwrote <= 1; end

        else if(read & !empty) begin //WHEN TO READ
            data_out <= data[nextread_ptr];
            just_readorwrote <= 0; end

        if(full_indicator) full <= 1; 
        else if(!just_readorwrote)
		  full <= 0;

        if(halffull_indicator) halffull <= 1;
        else halffull<=0;

        if(empty_indicator) empty <= 1; 
        else if (just_readorwrote)
		  empty <= 0;

        if(halfempty_indicator) halfempty <= 1;
        else  halfempty<=0;

      end
    end

    assign nextread_en = read & ~empty_indicator; //only read when not empty
    assign nextwrite_en = write & ~full_indicator; //only write when not full
    
    assign read_equals_write = (nextwrite_ptr == nextread_ptr);
    assign empty_indicator = ~just_readorwrote & read_equals_write; //empty if just read and ptrs equal
    assign full_indicator = just_readorwrote & read_equals_write; //full if just wrote and ptrs equal
    assign halfempty_indicator = (size == 48) & ~just_readorwrote; //0 -> 95 (half is 47)
    assign halffull_indicator = (size == 48) & just_readorwrote;

    always @ (nextwrite_ptr or nextread_ptr or size or just_readorwrote) //calc size and update at rising edge of either clock because involves both reading and writing
        begin
        if(nextwrite_ptr > nextread_ptr)
            size = nextwrite_ptr - nextread_ptr;  
        else if (nextwrite_ptr < nextread_ptr)
            size = data_depth - (nextread_ptr - nextwrite_ptr);
		  else //pointers equal	
				if (just_readorwrote) //just wrote
					size = data_depth;
				else						//just read
					size = 0;
        end



endmodule
