`include "ip_amba_apb_top_defines.vh"
`include "ip_amba_apb_top_parameters.vh"

module ip_amba_apb_master `IP_AMBA_APB_PARAM_DECL (
	//global inputs
	input PCLK,
	input PRESETn,

	//master inputs
	input PREADY,
	input [`PRDATA_width-1:0] PRDATA,
	input PSLVERR,

	//master outputs
	output [PADDR_width-1:0] PADDR,
	output [2:0] PPROT,
	output [PSELx_width-1:0] PSELx,
	output PENABLE,
	output PWRITE,
	output [PWDATA_width-1:0] PWDATA,
	output [PSTRB_width-1:0] PSTRB,
	//to cpu
	output apb_ready_for_txn,
	output [PRDATA_width-1:0] to_cpu_RDATA,
	output to_cpu_RDATA_valid_PWDATA_done,
	output to_cpu_txn_err,
	output to_cpu_txn_timeout,
	//from cpu
	input from_cpu_resetn,
	input from_cpu_valid_txn,
	input from_cpu_wr_rd,
	input [PADDR_width-1:0] from_cpu_addr,
	input [PSTRB_width-1:0] from_cpu_wr_STRB,
	input [PWDATA_width-1:0] from_cpu_wr_WDATA,
	input [PSELx_width-1:0] from_cpu_slave_sel
);

//apb fsm state machine declatations
localparam reg [2:0] IDLE=3'b001,
SETUP = 3'b010,
ACCESS = 3'b100;
reg [2:0] current_state,next_state;
//apb regs and wires
reg [`PADDR_width-1:0] PADDR_next;
reg [2:0] PPROT_next;
reg [`PSELx_width-1:0] PSELx_next;
reg PENABLE_next;
reg PWRITE_next;
reg [`PWDATA_width-1:0] PWDATA_next;
reg [`PSTRB_width-1:0] PSTRB_next;
reg [`PADDR_width-1:0] PADDR_reg;
reg [2:0] PPROT_reg;
reg [`PSELx_width-1:0] PSELx_reg;
reg PENABLE_reg;
reg PWRITE_reg;
reg [`PWDATA_width-1:0] PWDATA_reg;
reg [`PSTRB_width-1:0] PSTRB_reg;

reg to_cpu_txn_err_next;
reg to_cpu_txn_timeout_next;
reg [31:0] pselx_timeout_counter_next;
reg [31:0] pselx_timeout_next;
reg pselx_timeout_flag_next;
reg to_cpu_txn_err_reg;
reg to_cpu_txn_timeout_reg;
reg [31:0] pselx_timeout_counter_reg;
reg [31:0] pselx_timeout_reg;
reg pselx_timeout_flag_reg;
//body
always @(posedge clk or negedge PRESETn or negedge from_cpu_resetn)
begin
	if(~PRESETn || ~from_cpu_resetn)
	begin
		PADDR_reg <= 0;
		PPROT_reg <= 0;
		PSELx_reg <= 0;
		PENABLE_reg <= 0;
		PWRITE_reg <= 0;
		PWDATA_reg <= 0;
		PSTRB_reg <= 0;
		current_state <= IDLE;
	end
	else
	begin
		PADDR_reg <= PADDR_next;
		PPROT_reg <= PPROT_next;
		PSELx_reg <= PSELx_next;
		PENABLE_reg <= PENABLE_next;
		PWRITE_reg <= PWRITE_next;
		PWDATA_reg <= PWDATA_next;
		PSTRB_reg <= PSTRB_next;
		current_state <= next_state;
	end
end
always @*
begin
	PADDR_next <= PADDR_reg;
	PPROT_next <= PPROT_reg;
	PSELx_next <= PSELx_reg;
	PENABLE_next <= PENABLE_reg;
	PWRITE_next <= PWRITE_reg;
	PWDATA_next <= PWDATA_reg;
	PSTRB_next <= PSTRB_reg;
	next_state <= current_state;
	case(current_state)
		IDLE:
		begin
			if(from_cpu_valid_txn & from_cpu_slave_sel)
			begin
				next_state = SETUP;
				PADDR_next = from_cpu_addr;
				PPROT_next = 0;
				PSELx_next = from_cpu_slave_sel;
				PWRITE_next = from_cpu_wr_rd;
				if(from_cpu_wr_rd)
				begin
					PWDATA_next = from_cpu_wr_WDATA;
					PSTRB_next = from_cpu_wr_STRB;
				end
				else
				begin 
					PSTRB_next = 0;
				end
			end
		end
		SETUP:
		begin
			if(from_cpu_valid_txn &&from_cpu_slave_sel)
			begin
				PADDR_next = from_cpu_addr;
				PPROT_next = 0;
				PSELx_next = from_cpu_slave_sel;
				PWRITE_next = from_cpu_wr_rd;
				if(from_cpu_wr)
				begin
					PWDATA_next = from_cpu_wr_WDATA;
					PSTRB_next = from_cpu_wr_STRB; 
				end
				else
				begin
					PSTRB_next = 0;
				end
			end
			PENABLE_next = 1;
			next_state = ACCESS;
		end
		ACCESS:
		begin
			if(PSLVERR)
			begin
				next_state = IDLE;
				PENABLE_next = 0;
				PSELx_next = 0;
			end
			else if(PREADY && from_cpu_valid_txn && from_cpu_slave_sel)
			begin
				next_state = SETUP;
				PENABLE_next = 0;
				
				PADDR_next = from_cpu_addr;
				PPROT_next = 0;
				PSELx_next = from_cpu_slave_sel;
				PWRITE_next = from_cpu_wr_rd;
				if(from_cpu_wr)
				begin
					PWDATA_next = from_cpu_wr_WDATA;
					PSTRB_next = from_cpu_wr_STRB; 
				end
				else
				begin
					PSTRB_next = 0;
				end
			end
			else if(PREADY && ~from_cpu_valid_txn)
			begin
				next_state = IDLE;
				PENABLE_next = 0;
				PSELx_next = 0;
			end
		end
	endcase
	if(pselx_timeout_flag_reg)
	begin
		PSELx_next =0;
		PENABLE_next = 0;
		next_state = IDLE;
	end
end
//apb port output assignments
assign PADDR = PADDR_reg;
assign PWDATA = PWDATA_reg;
assign PPROT = PPROT_reg;
assign PSELx = PSELx_reg;
assign PENABLE = PENABLE_reg;
assign PWRITE = PWRITE_reg;
assign PSTRB = PSTRB_reg;

//cpu outputs
always @(posedge clk or negedge PRESETn or negedge from_cpu_resetn)
begin
	if(~PRESETn || ~from_cpu_resetn)
	begin
		to_cpu_txn_err_reg <= 0;
	end
	else
	begin
		to_cpu_txn_err_reg <= to_cpu_txn_err_next;
	end
end
always @*
begin
	to_cpu_txn_err_next = to_cpu_txn_err_reg;
	case(current_state)
		IDLE:
		begin
		end
		SETUP:
		begin
			if(from_cpu_valid_txn)
				to_cpu_txn_err_next = 0;
		end
		ACCESS:
		begin
			if(PSLVERR)
				to_cpu_txn_err_next = 1;
		end
	endcase
end
assign apb_ready_for_txn = (current_state == IDLE || current_state == SETUP) ||
(PSELx_reg && PENABLE_reg && PREADY);

assign to_cpu_RDATA = PRDATA;
assign to_cpu_RDATA_valid_PWDATA_done = PREADY;
assign to_cpu_txn_err = to_cpu_txn_err_reg;
assign to_cpu_txn_timeout = to_cpu_txn_timeout_reg;

always @(posedge clk or negedge PRESETn or negedge from_cpu_resetn)
begin
	if(~PRESETn || ~from_cpu_resetn)
	begin
		pselx_timeout_counter_reg <= 0;
		pselx_timeout_flag_reg <= 0;
		pselx_timeout_reg <= `ifdef PSELx_TIMEOUT_VAL `PSELx_TIMEOUT_VAL-1 `else 'd20-1 `endif;
		to_cpu_txn_timeout_reg <= 0;
	end
	else
	begin
		pselx_timeout_counter_reg <= pselx_timeout_counter_next;
		pselx_timeout_flag_reg <= pselx_timeout_flag_next;
		pselx_timeout_reg <= pselx_timeout_next;
		to_cpu_txn_timeout_reg <= to_cpu_txn_timeout_next;
	end
end
always @*
begin
	pselx_timeout_counter_next = pselx_timeout_counter_reg; 
	pselx_timeout_flag_next = pselx_timeout_flag_reg;
	pselx_timeout_next = pselx_timeout_reg;
	to_cpu_txn_timeout_next = to_cpu_txn_timeout_reg;
	if(PSELx_reg && PENABLE_reg && PREADY)
	begin
		pselx_timeout_flag_next = 0;
		pselx_timeout_counter_next = 0; 
	end
	else if(PSELx_reg)
	begin
		if(pselx_timeout_counter_reg == pselx_timeout_reg)
		begin
			pselx_timeout_counter_next = 0;
			pselx_timeout_flag_next = 1;
			to_cpu_txn_timeout_next = 1;
		end
		else
			pselx_timeout_counter_next = pselx_timeout_counter_reg + 1;
	end
	else if(~PSELx_reg)
	begin
		pselx_timeout_flag_next = 0;
		pselx_timeout_counter_next = 0; 
	end
end
endmodule