`timescale 1ns / 1ps

module APB_TB;
    localparam int WS = 3;                 // can be varied from 0, 1, 2, 3

    logic        PCLK, PRESETn, PSEL, PENABLE, PWRITE;
    logic [7:0]  PADDR;
    logic [31:0] PWDATA;
    logic        PREADY, PSLVERR;
    logic [31:0] PRDATA;

    int error_count = 0;
    int check_count = 0;

    initial $timeformat(-9, 0, " ns", 8);

    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end

    APB_RTL #(.WAIT_STATES(WS)) DUT (
        .PCLK(PCLK), .PRESETn(PRESETn),
        .PSEL(PSEL), .PENABLE(PENABLE), .PWRITE(PWRITE),
        .PADDR(PADDR), .PWDATA(PWDATA),
        .PREADY(PREADY), .PSLVERR(PSLVERR), .PRDATA(PRDATA)
    );

    // watchdog: a stuck wait loop must not hang the simulation
    initial begin
        #1000000;
        $fatal(1, "WATCHDOG: simulation timed out");
    end

    // reset
    initial begin
        PRESETn = 0; PSEL = 0; PENABLE = 0; PWRITE = 0; PADDR = 0; PWDATA = 0;
        repeat (2) @(posedge PCLK);
        @(negedge PCLK);
        PRESETn = 1;
    end

    task automatic apb_write(input logic [7:0] addr,
                             input logic [31:0] data,
                             input logic exp_err);
        @(negedge PCLK);                       // SETUP
        PSEL = 1; PENABLE = 0; PWRITE = 1; PADDR = addr; PWDATA = data;

        @(negedge PCLK);                       // ACCESS
        PENABLE = 1;

        do @(posedge PCLK); while (PREADY !== 1'b1);   // sample at each edge

        // completion edge: PSLVERR is valid now
        check_count++;
        if (PSLVERR !== exp_err) begin
            error_count++;
            $display("[%0t] WRITE FAIL addr=%h exp_err=%b got_err=%b",
                     $time, addr, exp_err, PSLVERR);
        end else
            $display("[%0t] WRITE PASS addr=%h data=%h err=%b",
                     $time, addr, data, PSLVERR);

        @(negedge PCLK);                       // back to IDLE
        PSEL = 0; PENABLE = 0;
    endtask

    task automatic apb_read(input logic [7:0] addr,
                            input logic [31:0] exp_data,
                            input logic exp_err);
        @(negedge PCLK);                       // SETUP
        PSEL = 1; PENABLE = 0; PWRITE = 0; PADDR = addr;

        @(negedge PCLK);                       // ACCESS
        PENABLE = 1;

        do @(posedge PCLK); while (PREADY !== 1'b1);

        // completion edge: PRDATA and PSLVERR are valid now
        check_count++;
        if (PRDATA !== exp_data || PSLVERR !== exp_err) begin
            error_count++;
            $display("[%0t] READ FAIL addr=%h exp=%h/%b got=%h/%b",
                     $time, addr, exp_data, exp_err, PRDATA, PSLVERR);
        end else
            $display("[%0t] READ PASS addr=%h data=%h err=%b",
                     $time, addr, PRDATA, PSLVERR);

        @(negedge PCLK);
        PSEL = 0; PENABLE = 0;
    endtask
    
    
    task automatic apply_reset;  //to check if reg are getting reset after writing
    @(negedge PCLK);
    PRESETn = 0;
    PSEL    = 0;
    PENABLE = 0;
    PWRITE  = 0;
    PADDR   = 0;
    PWDATA  = 0;

    repeat (2) @(posedge PCLK);

    @(negedge PCLK);
    PRESETn = 1;
endtask

    initial begin
        wait (PRESETn == 1);

        // reset values, straight from the spec
        apb_read (8'h00, 32'h0000_0000, 1'b0);
        apb_read (8'h04, 32'h0000_0000, 1'b0);
        apb_read (8'h08, 32'h0000_0001, 1'b0);
        apb_read (8'h0C, 32'hA5A5_A5A5, 1'b0);

        // RW registers
        apb_write(8'h00, 32'h1234_5678, 1'b0);
        apb_read (8'h00, 32'h1234_5678, 1'b0);
        apb_write(8'h0C, 32'hDEAD_BEEF, 1'b0);
        apb_read (8'h0C, 32'hDEAD_BEEF, 1'b0);

        // write to RO: error, STATUS unchanged
        apb_write(8'h08, 32'hFFFF_FFFF, 1'b1);
        apb_read (8'h08, 32'h0000_0001, 1'b0);

        // invalid addresses: error, read returns 0, nothing else changes
        apb_read (8'h10, 32'h0000_0000, 1'b1);
        apb_write(8'h10, 32'hCAFE_F00D, 1'b1);
        apb_read (8'h01, 32'h0000_0000, 1'b1);
        apb_read (8'h00, 32'h1234_5678, 1'b0);   // no aliasing of 0x10 onto 0x00
         
         
         
                // Reset after modifying registers
         apply_reset();

         apb_read(8'h00, 32'h0000_0000, 1'b0);
         apb_read(8'h04, 32'h0000_0000, 1'b0);
         apb_read(8'h08, 32'h0000_0001, 1'b0);
         apb_read(8'h0C, 32'hA5A5_A5A5, 1'b0);
         
         
         // Back-to-back register writes
      @(negedge PCLK);
      PSEL = 1'b1;
      PENABLE = 1'b0;
      PWRITE = 1'b1;
      PADDR = 8'h00;
      PWDATA = 32'h11112222;

      @(negedge PCLK);
      PENABLE = 1'b1;

       do @(posedge PCLK); while (PREADY !== 1'b1);

      @(negedge PCLK);
      PENABLE = 1'b0;
      PADDR = 8'h04;
      PWDATA = 32'h33334444;

      @(negedge PCLK);
      PENABLE = 1'b1;

      do @(posedge PCLK); while (PREADY !== 1'b1);

      @(negedge PCLK);
      PSEL = 1'b0;
      PENABLE = 1'b0;

      apb_read(8'h00, 32'h11112222, 1'b0);
      apb_read(8'h04, 32'h33334444, 1'b0);
        repeat (2) @(posedge PCLK);
        if (error_count == 0)
            $display("TEST PASSED: %0d checks", check_count);
        else
            $display("TEST FAILED: %0d errors in %0d checks", error_count, check_count);
        $finish;
        end


endmodule
