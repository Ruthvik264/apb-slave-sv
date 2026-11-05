
class apb_monitor extends uvm_monitor;

    `uvm_component_utils(apb_monitor)

    virtual apb_if vif;

    uvm_analysis_port #(apb_transaction) ap;

    covergroup apb_cov with function sample(
        bit [7:0] addr,
        bit write,
        bit error
    );

        option.per_instance = 1;

        cp_addr: coverpoint addr {
            bins ctrl    = {8'h00};
            bins data    = {8'h04};
            bins status  = {8'h08};
            bins scratch = {8'h0C};
            bins invalid = default;
        }

        cp_write: coverpoint write {
            bins read  = {0};
            bins write = {1};
        }

        cp_error: coverpoint error {
            bins success = {0};
            bins failure = {1};
        }

        addr_operation: cross cp_addr, cp_write;

    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
        apb_cov = new();
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual apb_if)::get(
            this, "", "vif", vif
        ))
            `uvm_fatal("NOVIF", "Virtual interface not found")

    endfunction

    task run_phase(uvm_phase phase);

        apb_transaction tr;

        forever begin

            @(posedge vif.PCLK);

            if (vif.PRESETn &&
                vif.PSEL &&
                vif.PENABLE &&
                vif.PREADY) begin

                tr = apb_transaction::type_id::create("tr");

                tr.addr  = vif.PADDR;
                tr.write = vif.PWRITE;
                tr.data  = vif.PWDATA;
                tr.rdata = vif.PRDATA;
                tr.ready = vif.PREADY;
                tr.error = vif.PSLVERR;

                apb_cov.sample(tr.addr, tr.write, tr.error);

                `uvm_info("MONITOR",
                    $sformatf(
                        "ADDR=%02h WRITE=%0b WDATA=%08h RDATA=%08h ERROR=%0b",
                        tr.addr, tr.write, tr.data,
                        tr.rdata, tr.error
                    ),
                    UVM_MEDIUM)

                ap.write(tr);

            end
        end

    endtask

    function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        `uvm_info("COVERAGE",
            $sformatf("Functional coverage = %0.2f%%",
                      apb_cov.get_coverage()),
            UVM_NONE)

    endfunction

endclass
