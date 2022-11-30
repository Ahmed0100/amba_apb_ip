`include "ip_amba_apb_slave_defines.vh"
`include "ip_amba_apb_slave_parameters.vh"


module ip_amba_apb_slave `IP_AMBA_APB_SLAVE_PARAM_DECL (
	//global inputs
	input PCLK,
	input PRESETn,
	//slave inputs
	input [PADDR_width-1:0] PADDR,
	input [2:0] PPROT,
	input [PSELx_width-1:0] PSELx,
	input PENABLE,
	input PWRITE,
	input [PWDATA_width-1:0] PWDATA,
	input [PSTRB_width-1:0] PSTRB,
	//slave outputs 
	output PREADY,
	output [PRDATA_width-1:0] PRDATA,
	output PSLVERR
);

localparam BASE_ADDR  = 0;
reg [WORD_LENGTH-1:0] mem [2** MEM_DEPTH];

reg PREADY_next;
reg [PRDATA_width-1:0] PRDATA_next;
reg PSLVERR_next;
reg PREADY_reg;
reg [PRDATA_width-1:0] PRDATA_reg;
reg PSLVERR_reg;
reg [PWDATA_width-1:0] base_addr_reg,base_addr_next;
reg [PWDATA_width-1:0] mem_write_data_next,mem_write_data_reg;

always @(posedge PCLK or negedge PRESETn)
begin
	if(~PRESETn)
	begin
		PREADY_reg <= 0;
		PRDATA_reg <= 0;
		PSLVERR_reg <= 0;
		base_addr_reg <= 0;
		base_addr_reg[0] <= 1;
		mem_write_data_reg <= 0;
	end
	else
	begin
		PREADY_reg <= PREADY_next;
		PRDATA_reg <= PRDATA_next;
		PSLVERR_reg <= PSLVERR_next;
		base_addr_reg <= base_addr_next;
		mem_write_data_reg <= mem_write_data_next;
	end
end

always @*
begin
	PREADY_next = PREADY_reg;
	PRDATA_next = PRDATA_reg;
	PSLVERR_next = PSLVERR_reg;
	base_addr_next = base_addr_reg;
	mem_write_data_next = mem_write_data_reg; 
	mem[(PADDR-base_address_reg)/PSTRB_width] = mem_write_data_reg;

	if(PSELx[0] && !PREADY_reg && !PENABLE && ((PADDR<base_addr_reg) || (PADDR>(base_addr_reg+ 2**MEM_DEPTH-1))))
	begin
		PSLVERR_next = 1;
		PRDATA_next = 0;
		PREADY_next = 1;		
	end	
	else if(PSELx[0] && !PWRITE)
	begin
		if(!PREADY_reg && !PENABLE)
		begin
			PRDATA_next = mem[(PADDR-base_addr_reg)/PSTRB_width];
			PREADY_next = 1;
		end
		else if(PREADY_reg && PENABLE)
			PREADY_next = 0;
	end
	else if(PSELx[0] && PWRITE)
	begin
		if(PREADY_reg && PENABLE)
		begin
			int i;
			PREADY_next = 0;
			if((PADDR/PSTRB_width) == 0)
			begin
				for(i = 0; i<PSTRB_width;i=i+1)
				begin
					if(PSTRB[i])
						base_addr_next[(i*8)+:8] = PWDATA[(i*8)+:8]; 
				end
			end
			else
			begin
				for(i = 0; i< PSTRB_width; i=i+1)
				begin
					if(PSTRB[i])
						mem_write_data_next[(i*8)+:8] = PWDATA[(i*8)+:8];
				end
			end
		end
		else if(!PREADY_reg && !PENABLE)
		begin	
			PREADY_next = 1;
		end
	end
end
endmodule : ip_amba_apb_slave