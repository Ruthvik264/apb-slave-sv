
class apb_test extends uvm_test;

    `uvm_component_utils(apb_test)

    apb_env env;

function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        env = apb_env::type_id::create("env", this);

    endfunction

    task run_phase(uvm_phase phase);

        apb_sequence seq;

        phase.raise_objection(this);

        seq = apb_sequence::type_id::create("seq");

        seq.start(env.agent.seqr);

        phase.drop_objection(this);

    endtask

endclass
