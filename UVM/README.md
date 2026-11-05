# APB Slave Verification using SystemVerilog UVM

## Overview

This project implements a UVM-based verification environment for an APB Slave with programmable wait states and a memory-mapped register interface.

The testbench uses standard UVM components to generate transactions, drive APB signals, monitor completed transfers, and check DUT responses using a reference model.

## DUT Features

- APB slave supporting programmable wait states.
- CTRL register (0x00): Read/Write.
- DATA register (0x04): Read/Write.
- STATUS register (0x08): Read-only.
- SCRATCH register (0x0C): Read/Write.
- Error response for invalid addresses and writes to the read-only STATUS register.

## Verification Environment

The testbench is organized using the following UVM components:

- **Sequence Item:** Defines APB read/write transactions.
- **Sequence:** Generates transactions for different register operations.
- **Sequencer:** Sends transactions from the sequence to the driver.
- **Driver:** Converts transactions into APB bus activity.
- **Monitor:** Observes completed APB transfers and publishes transactions.
- **Scoreboard:** Compares DUT responses against an expected register model.
- **Agent:** Groups the sequencer, driver, and monitor.
- **Environment:** Instantiates the agent and scoreboard.
- **Test:** Creates and starts the verification sequence.

## Verification Scenarios

- Register write and read-back operations.
- Read-only register access.
- Write attempt to read-only register.
- Invalid address read and write operations.
- APB transfers with configured wait states.

## Simulation Results

**Simulator:** EDA PLAYGROUND--QuestaSim  
**Methodology:** SystemVerilog UVM 1.2

| Metric | Result |
|---|---:|
| Transactions checked | 10 |
| Scoreboard passed | 10 |
| Scoreboard failed | 0 |
| Functional coverage | 100% |
| UVM errors | 0 |
| UVM warnings | 0 |
| UVM fatals | 0 |

Functional coverage represents the bins defined in the testbench covergroup.

## Running the Simulation

The project was simulated using QuestaSim with UVM 1.2 on EDA Playground.

Compile `design.sv` and `testbench.sv`. The remaining verification files are included through the testbench file.

Top-level module: `tb_top`

## Tools and Languages

- SystemVerilog
- Universal Verification Methodology (UVM)
- QuestaSim
- EDA Playground
