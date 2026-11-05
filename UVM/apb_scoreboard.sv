
class apb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(apb_scoreboard)

    uvm_analysis_imp #(apb_transaction, apb_scoreboard)
        analysis_export;

    bit [31:0] expected_ctrl;
    bit [31:0] expected_data;
    bit [31:0] expected_scratch;

    int passed;
    int failed;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        expected_ctrl    = 32'h00000000;
        expected_data    = 32'h00000000;
        expected_scratch = 32'hA5A5_A5A5;

        passed = 0;
        failed = 0;

    endfunction

    function void write(apb_transaction tr);

        bit expected_error;
        bit [31:0] expected_read;

        expected_error = 0;
        expected_read  = 0;

        // Calculate expected response
        case (tr.addr)

            8'h00: begin
                if (!tr.write)
                    expected_read = expected_ctrl;
            end

            8'h04: begin
                if (!tr.write)
                    expected_read = expected_data;
            end

            8'h08: begin
                if (tr.write)
                    expected_error = 1;
                else
                    expected_read = 32'd1;
            end

            8'h0C: begin
                if (!tr.write)
                    expected_read = expected_scratch;
            end

            default: begin
                expected_error = 1;
            end

        endcase

        // Compare error response
        if (tr.error !== expected_error) begin

            `uvm_error("SCOREBOARD",
                $sformatf(
                    "ERROR mismatch at %02h: Expected=%0b Actual=%0b",
                    tr.addr, expected_error, tr.error
                ))

            failed++;

        end

        // Expected error was correctly generated
        else if (expected_error) begin

            `uvm_info("SCOREBOARD",
                $sformatf("PASS: Expected error at address %02h",
                          tr.addr),
                UVM_LOW)

            passed++;

        end

        // Successful write: update reference model
        else if (tr.write) begin

            case (tr.addr)
                8'h00: expected_ctrl    = tr.data;
                8'h04: expected_data    = tr.data;
                8'h0C: expected_scratch = tr.data;
                default: ;
            endcase

            `uvm_info("SCOREBOARD",
                $sformatf("PASS: WRITE Addr=%02h Data=%08h",
                          tr.addr, tr.data),
                UVM_LOW)

            passed++;

        end

        // Successful read: compare against reference model
        else if (tr.rdata !== expected_read) begin

            `uvm_error("SCOREBOARD",
                $sformatf(
                    "READ mismatch at %02h: Expected=%08h Actual=%08h",
                    tr.addr, expected_read, tr.rdata
                ))

            failed++;

        end

        else begin

            `uvm_info("SCOREBOARD",
                $sformatf(
                    "PASS: READ Addr=%02h Data=%08h",
                    tr.addr, tr.rdata
                ),
                UVM_LOW)

            passed++;

        end

    endfunction

    function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        `uvm_info("SUMMARY",
            $sformatf("Passed=%0d Failed=%0d",
                      passed, failed),
            UVM_NONE)

        if (failed > 0)
            `uvm_error("SUMMARY", "APB VERIFICATION FAILED")

    endfunction

endclass
