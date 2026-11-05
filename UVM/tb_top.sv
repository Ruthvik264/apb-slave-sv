
module tb_top;

    import uvm_pkg::*;
    import apb_pkg::*;

    apb_if intf();

    // DUT
    apb_slave #(
        .WAIT_STATES(3)
    ) dut (
        .PCLK    (intf.PCLK),
        .PRESETn (intf.PRESETn),
        .PSEL    (intf.PSEL),
        .PENABLE (intf.PENABLE),
        .PWRITE  (intf.PWRITE),
        .PADDR   (intf.PADDR),
        .PWDATA  (intf.PWDATA),
        .PRDATA  (intf.PRDATA),
        .PREADY  (intf.PREADY),
        .PSLVERR (intf.PSLVERR)
    );

    // Clock
    initial begin
        intf.PCLK = 0;
        forever #5 intf.PCLK = ~intf.PCLK;
    end

    // Reset
    initial begin

        intf.PRESETn = 0;

        intf.PSEL    = 0;
        intf.PENABLE = 0;
        intf.PWRITE  = 0;
        intf.PADDR   = 0;
        intf.PWDATA  = 0;

        repeat (3) @(negedge intf.PCLK);

        intf.PRESETn = 1;

    end

    // Start UVM at time 0
    initial begin

        uvm_config_db#(virtual apb_if)::set(
            null, "*", "vif", intf
        );

        run_test("apb_test");

    end

endmodule
