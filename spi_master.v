//////////////////////////////////////////////////////////////////////////////////
// Module Name:		spi_master
// By: Benton Gray
//////////////////////////////////////////////////////////////////////////////////
module spi_master(
						clk,
						rst,
						get_rdid
		);
/* Parameters for FSM and Readability */
parameter	  idle									= 2'b00,
						send_instruction			= 2'b01,
						finish_transmission		= 2'b10,
						high									= 1'b1,
						low										= 1'b0;

/* Parameters for Clock Dividing */
parameter		clock_div							= 2'b11;

/* Port Declarations */
input 	clk, rst, get_rdid, MISO;
output 	MOSI, CHIP_SELECT, WRITE_PROTECT, HOLD;

/* Nettype Declarations */
wire 		clk, rst, get_rdid, WRITE_PROTECT, CHIP_SELECT, MISO;
reg    	MOSI, HOLD;

/* Register Declaration */
reg SPICLK;
reg [1:0]		current_state, next_state;
reg [4:0]   cnt, datacount;
reg [7:0]	  out_data, transcount;
reg [24:0]  receive_data;


/* Combinatorial Assignments for nettype wire */
assign WRITE_PROTECT = high;
assign CHIP_SELECT   = high;

/* Sequential Logic for FSM */
always@(negedge clk or negedge rst) begin
	if(rst == high)
		current_state <= idle;
	else
		current_state <= next_state;
end 	///

/* SPICLK using counter */
always@(negedge clk or posedge rst) begin
	if(rst == high) begin
		cnt <= low;
		SPICLK <= high;
	end
	else begin
		cnt <= cnt + high;
		if(cnt == clock_div) begin
			SPICLK <= ~SPICLK;
			cnt <= low;
		end		///
	end		////
end 	//////

/* Transaction Clock Counter */
always @( SPICLK ) begin
	if(rst == high) begin
	  transcount = low;
		datacount = low;
	end
	else
		transcount += 1;

	if( SPICLK == low )
		datacount += 1;

	if(current_state == send_instruction)
		if( datacount > 7 )
			datacount = low;

	if(current_state == finish_transmission)
		if( datacount > 24 )
			datacount = low;
end 	///

/* Lets talk to the slave */
always @( SPICLK ) begin
	out_data = 8'h9F;
	if(current_state == send_instruction) begin
		if(SPICLK == low)
			MOSI = out_data[7 - datacount];
		else
			MOSI = MOSI;
	end
	else begin
		out_data = low;
		MOSI = low;
	end
end

/* Let the slave talk to us */
always @( SPICLK ) begin
	if(current_state == finish_transmission)
		if(SPICLK == low)
			receive_data[24 - datacount] = MISO;
		else
			receive_data = receive_data;
	else
		receive_data = low;
end


/* Combinatorial Block */
always@( cnt )  begin
	next_state = current_state;
	case (current_state)
		idle: begin
			HOLD = low;
			if (get_rdid)
				next_state = send_instruction;
		end
		send_instruction: begin
			HOLD = high;
			next_state = send_instruction;
			if (transcount == 8 * 2) begin
				next_state = finish_transmission;
			end
		end
		finish_transmission: begin
			next_state = finish_transmission;
			if (transcount == 24 * 2)
				next_state = idle;
		end
	endcase
end 	///



m25p16 micro (
		.c(SPICLK),
		.data_in(MOSI),
		.s(CHIP_SELECT),
		.w(WRITE_PROTECT),
		.hold(HOLD),
		.data_out(MISO)
		);



endmodule
