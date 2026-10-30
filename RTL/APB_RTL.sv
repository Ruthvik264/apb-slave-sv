`timescale 1ns / 1ps

module APB_RTL #(
    parameter int WAIT_STATES = 2
)(
    input  logic        PCLK,
    input  logic        PRESETn,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic [7:0]  PADDR,
    input  logic [31:0] PWDATA,
    output logic        PREADY,
    output logic        PSLVERR,
    output logic [31:0] PRDATA
);

    // ---------------- constants (from the spec table) ----------------
    localparam logic [7:0]  ADDR_CTRL    = 8'h00;
    localparam logic [7:0]  ADDR_DATA    = 8'h04;
    localparam logic [7:0]  ADDR_STATUS  = 8'h08;   // RO
    localparam logic [7:0]  ADDR_SCRATCH = 8'h0C;
    localparam logic [31:0] STATUS_VAL   = 32'h0000_0001;
    localparam logic [31:0] SCRATCH_RST  = 32'hA5A5_A5A5;

    // elaboration-time constant: sizes the counter when the design is built
    localparam int COUNT_WIDTH = (WAIT_STATES < 1) ? 1 : $clog2(WAIT_STATES + 1);

    logic [COUNT_WIDTH-1:0] wait_count;
    logic [31:0] ctrl, data, scratch;      // STATUS has no flop: it is a constant
    logic        addr_valid, addr_ro, transfer_done;

    // ---------------- address decode ---------------
    // reads of invalid addresses also give PSLVERR.
    always_comb begin
        addr_valid = 1'b0;
        addr_ro    = 1'b0;
        case (PADDR)
            ADDR_CTRL, ADDR_DATA, ADDR_SCRATCH: addr_valid = 1'b1;
            ADDR_STATUS: begin
                addr_valid = 1'b1;
                addr_ro    = 1'b1;
            end
            default: ;
        endcase
    end

    // ---------------- wait counter ----------------
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            wait_count <= '0;
        else if (!PSEL || !PENABLE)
            wait_count <= '0;
        else if (wait_count < WAIT_STATES)
            wait_count <= wait_count + 1'b1;
    end

    // ---------------- response ----------------
    // PREADY is 1 outside ACCESS (legal: the master ignores it there)
    always_comb begin
        PREADY = 1'b1;
        if (PSEL && PENABLE && (wait_count < WAIT_STATES))
            PREADY = 1'b0;
    end

    assign transfer_done = PSEL && PENABLE && PREADY;

    // error counts only in the completion cycle
    assign PSLVERR = transfer_done && (!addr_valid || (PWRITE && addr_ro));

    //  register writes
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            ctrl    <= 32'h0;
            data    <= 32'h0;
            scratch <= SCRATCH_RST;
        end
        else if (transfer_done && PWRITE && addr_valid && !addr_ro) begin
            case (PADDR)
                ADDR_CTRL:    ctrl    <= PWDATA;
                ADDR_DATA:    data    <= PWDATA;
                ADDR_SCRATCH: scratch <= PWDATA;
                default: ;
            endcase
        end
    end

    // ---------------- read mux ----------------
    always_comb begin
        PRDATA = '0;
        if (PSEL && PENABLE && !PWRITE) begin
            case (PADDR)
                ADDR_CTRL:    PRDATA = ctrl;
                ADDR_DATA:    PRDATA = data;
                ADDR_STATUS:  PRDATA = STATUS_VAL;
                ADDR_SCRATCH: PRDATA = scratch;
                default:      PRDATA = '0;
            endcase
        end
    end

endmodule
