`define PSTRB_width 4
`define PWDATA_width 8 * `PSTRB_width
`define PRDATA_width  32
`define PADDR_width 32
`define PSELx_width 1
`define APB_base_addr 1
`define MEM_ARRAY_SIZE_INT 2

`ifndef GB
	`ifndef MB
		`ifndef B
			`define B 1
		`else 
			`define KB 1
		`endif
	`else 
		`define MB 1
	`endif
`else
	`define GB 1
`endif