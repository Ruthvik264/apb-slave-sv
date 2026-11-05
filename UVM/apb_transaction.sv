
class apb_transaction extends uvm_sequence_item;

    rand bit [7:0]  addr;
    rand bit [31:0] data;
    rand bit        write;

    bit [31:0] rdata;
    bit        ready;
    bit        error;

    `uvm_object_utils_begin(apb_transaction)
        `uvm_field_int(addr,  UVM_ALL_ON)
        `uvm_field_int(data,  UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(ready, UVM_ALL_ON)
        `uvm_field_int(error, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "apb_transaction");
        super.new(name);
    endfunction

endclass
