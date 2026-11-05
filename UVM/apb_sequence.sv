
class apb_sequence extends uvm_sequence #(apb_transaction);

    `uvm_object_utils(apb_sequence)

    function new(string name = "apb_sequence");
        super.new(name);
    endfunction

    task automatic do_transfer(
        input bit [7:0]  address,
        input bit        wr,
        input bit [31:0] wdata
    );

        apb_transaction tr;

        tr = apb_transaction::type_id::create("tr");

        start_item(tr);

        if (!tr.randomize() with {
            addr  == address;
            write == wr;
            data  == wdata;
        }) begin
            `uvm_fatal("RANDFAIL", "Transaction randomization failed")
        end

        finish_item(tr);

    endtask

    task body();

        // CTRL write/read
        do_transfer(8'h00, 1'b1, $urandom);
        do_transfer(8'h00, 1'b0, 32'h0);

        // DATA write/read
        do_transfer(8'h04, 1'b1, $urandom);
        do_transfer(8'h04, 1'b0, 32'h0);

        // SCRATCH write/read
        do_transfer(8'h0C, 1'b1, $urandom);
        do_transfer(8'h0C, 1'b0, 32'h0);

        // STATUS read
        do_transfer(8'h08, 1'b0, 32'h0);

        // STATUS write - expected error
        do_transfer(8'h08, 1'b1, $urandom);

        // Invalid address read - expected error
        do_transfer(8'h10, 1'b0, 32'h0);

        // Invalid address write - expected error
        do_transfer(8'h10, 1'b1, $urandom);

    endtask

endclass
