//interface and assertions
interface apb_if;

    logic PCLK;
    logic PRESETn;

    logic PSEL;
    logic PENABLE;
    logic PWRITE;

    logic [7:0]  PADDR;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;

    logic PREADY;
    logic PSLVERR;

    // SETUP must be followed by ACCESS
    property p_setup_to_access;
        @(posedge PCLK)
        disable iff (!PRESETn)
        PSEL && !PENABLE
        |=> PSEL && PENABLE;
    endproperty

    assert property (p_setup_to_access)
        else $error("APB: SETUP not followed by ACCESS");

    // Control and address must remain stable during wait states
    property p_access_stable;
        @(posedge PCLK)
        disable iff (!PRESETn)
        PSEL && PENABLE && !PREADY
        |=> PSEL && PENABLE &&
            $stable({PADDR, PWRITE, PWDATA});
    endproperty

    assert property (p_access_stable)
        else $error("APB: Signals changed during wait state");

    // PENABLE cannot be high without PSEL
    property p_enable_requires_select;
        @(posedge PCLK)
        disable iff (!PRESETn)
        PENABLE |-> PSEL;
    endproperty

    assert property (p_enable_requires_select)
        else $error("APB: PENABLE high without PSEL");

    // PREADY must only be high during ACCESS
    property p_ready_during_access;
        @(posedge PCLK)
        disable iff (!PRESETn)
        PREADY |-> (PSEL && PENABLE);
    endproperty

    assert property (p_ready_during_access)
        else $error("APB: PREADY outside ACCESS");

endinterface
