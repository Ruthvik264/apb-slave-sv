
class apb_sequencer extends uvm_sequencer #(apb_transaction);

    `uvm_component_utils(apb_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass


class apb_driver extends uvm_driver #(apb_transaction);

    `uvm_component_utils(apb_driver)

    virtual apb_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual apb_if)::get(
            this, "", "vif", vif
        ))
            `uvm_fatal("NOVIF", "Virtual interface not found")

    endfunction

    task run_phase(uvm_phase phase);

        apb_transaction req;

        wait (vif.PRESETn === 1'b1);

        @(negedge vif.PCLK);

        vif.PSEL    <= 0;
        vif.PENABLE <= 0;
        vif.PWRITE  <= 0;
        vif.PADDR   <= 0;
        vif.PWDATA  <= 0;

        forever begin

            seq_item_port.get_next_item(req);

            drive_transfer(req);

            seq_item_port.item_done();

        end

    endtask

    task drive_transfer(apb_transaction tr);

        // SETUP phase
        @(negedge vif.PCLK);

        vif.PSEL    <= 1'b1;
        vif.PENABLE <= 1'b0;
        vif.PWRITE  <= tr.write;
        vif.PADDR   <= tr.addr;
        vif.PWDATA  <= tr.data;

        // ACCESS phase
        @(negedge vif.PCLK);

        vif.PENABLE <= 1'b1;

        // Wait for PREADY
        do begin
            @(posedge vif.PCLK);
        end
        while (vif.PREADY !== 1'b1);

        // Return bus to IDLE
        @(negedge vif.PCLK);

        vif.PSEL    <= 1'b0;
        vif.PENABLE <= 1'b0;
        vif.PWRITE  <= 1'b0;
        vif.PADDR   <= 0;
        vif.PWDATA  <= 0;

    endtask

endclass


class apb_agent extends uvm_agent;

    `uvm_component_utils(apb_agent)

    apb_sequencer seqr;
    apb_driver    drv;
    apb_monitor   mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        seqr = apb_sequencer::type_id::create("seqr", this);
        drv  = apb_driver::type_id::create("drv", this);
        mon  = apb_monitor::type_id::create("mon", this);

    endfunction

    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        drv.seq_item_port.connect(seqr.seq_item_export);

    endfunction

endclass
