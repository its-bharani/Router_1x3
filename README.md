
# Router 1x3 Design  

## Overview  
The **Router 1x3** is a device that forwards data packets between computer networks, operating at **OSI Layer 3**. It routes incoming packets to appropriate output channels based on the **address field** in the packet header.  

---

## Features  
- **Packet Routing:** Routes packets to an output port based on the destination address.  
- **Parity Checking:** Ensures data integrity using a bitwise parity check.  
- **Reset Functionality:** Clears FIFO queues and resets output validity signals on reset.  
- **Simultaneous Packet Handling:** Can read up to three packets simultaneously while receiving one packet.  

---

## Functional Description  
1. **Packet Protocol:**  
   - Receives packets byte-by-byte via `data_in` on the positive edge of the clock.  
   - **Start:** Packet initiation is signaled by asserting `pkt_valid`.  
   - **End:** Packet completion is marked by de-asserting `pkt_valid`.  
   - Packets are stored in one of three **FIFO queues** based on their destination address.  

2. **Packet Read Operation:**  
   - Destination networks monitor `vld_out_x` signals.  
   - On assertion of `read_enb_x`, packets are read through `data_out_x`.  

3. **Busy Signal:**  
   - The `busy` signal indicates that the router cannot accept new data when active.  

4. **Error Detection:**  
   - Packet correctness is verified using **parity checking**.  
   - A mismatch triggers the `error` signal, notifying the source to resend the packet.  

---

## **BLOCK DIAGRAM**

![image](https://github.com/user-attachments/assets/c026b586-7cbb-4045-a356-d33a15388c2a)


## Interface Signals  
| **Signal Name**  | **Direction** | **Description**                                                                                  |  
|-------------------|---------------|--------------------------------------------------------------------------------------------------|  
| **clock**         | Input         | Active high clocking event.                                                                     |  
| **pkt_valid**     | Input         | Detects the arrival of a new packet.                                                            |  
| **resetn**        | Input         | Active low synchronous reset.                                                                   |  
| **data_in**       | Input         | 8-bit input bus transmitting packets from the source network.                                   |  
| **read_enb_0**    | Input         | Active high signal to read packets for destination client network 1.                            |  
| **read_enb_1**    | Input         | Active high signal to read packets for destination client network 2.                            |  
| **read_enb_2**    | Input         | Active high signal to read packets for destination client network 3.                            |  
| **data_out_0**    | Output        | 8-bit output bus transmitting packets to client network 1.                                      |  
| **data_out_1**    | Output        | 8-bit output bus transmitting packets to client network 2.                                      |  
| **data_out_2**    | Output        | 8-bit output bus transmitting packets to client network 3.                                      |  
| **vld_out_0**     | Output        | Active high signal indicating a valid byte for client network 1.                                |  
| **vld_out_1**     | Output        | Active high signal indicating a valid byte for client network 2.                                |  
| **vld_out_2**     | Output        | Active high signal indicating a valid byte for client network 3.                                |  
| **busy**          | Output        | Indicates a busy state where the router cannot accept new data.                                 |  
| **error**         | Output        | Indicates a mismatch in packet parity between source and internally calculated parity.          |  

---

## Packet Format  
Packets are divided into three fields: **Header**, **Payload**, and **Parity**.  

### 1. Header  
- **Destination Address (DA):**  
  - 2 bits wide.  
  - Routes packets to one of three valid output ports (`0`, `1`, or `2`). Address `3` is invalid.  
- **Length:**  
  - 6 bits wide. Specifies the number of data bytes.  
  - Minimum length: 1 byte, Maximum length: 63 bytes.  

### 2. Payload  
- Contains the data being transmitted, ranging from 1 to 63 bytes.  

### 3. Parity  
- A bitwise parity calculated over the header and payload bytes, ensuring data integrity.  

---

## Reset Functionality  
- **Active low synchronous reset (`resetn`):**  
  - Clears FIFO queues.  
  - Sets all output validity signals to low, indicating no valid packets are detected on the output buses.  

---

## Usage  
1. Connect the router inputs and outputs to the respective networks.  
2. Use `pkt_valid` to indicate the arrival of a new packet.  
3. Monitor `vld_out_x` and assert `read_enb_x` to read packets.  
4. Ensure to handle the `busy` and `error` signals appropriately for proper packet management.  

---
# **1. FIFO Module**

This repository contains the implementation of a **First-In-First-Out (FIFO)** buffer, designed for data synchronization and buffering in digital systems. The FIFO supports multi-byte packet-based data handling with robust empty/full indicators.

---

## **Inputs**
| Signal        | Width | Description                                                        |
|---------------|-------|--------------------------------------------------------------------|
| `clock`       | 1-bit | Synchronizes all operations.                                       |
| `resetn`      | 1-bit | Active-low reset; initializes the FIFO.                            |
| `soft_reset`  | 1-bit | Resets internal states without a full system reset.                |
| `write_en`    | 1-bit | Enables writing data into the FIFO.                                |
| `read_en`     | 1-bit | Enables reading data from the FIFO.                                |
| `lfd_state`   | 1-bit | Indicates the start of a new packet (first byte).                  |
| `data_in`     | 8-bit | Input data to be stored in the FIFO.                               |

---

## **Outputs**
| Signal        | Width | Description                                                        |
|---------------|-------|--------------------------------------------------------------------|
| `data_out`    | 8-bit | Output data read from the FIFO.                                    |
| `empty`       | 1-bit | Indicates that the FIFO is empty.                                  |
| `full`        | 1-bit | Indicates that the FIFO is full.                                   |

---

## **Logic Explanation**

### **1. Write Logic**
- **Condition**: Data is written if `write_en` is active and the FIFO is not full.
- **Mechanism**: 
  - Data is written at the location indicated by the `write_ptr`.
  - `lfd_state` is stored as the MSB of the 9-bit memory entry along with the 8-bit `data_in`.
  - `write_ptr` increments after each successful write.

### **2. Read Logic**
- **Condition**: Data is read if `read_en` is active and the FIFO is not empty.
- **Mechanism**:
  - Data is fetched from the location indicated by `read_ptr`.
  - `read_ptr` increments after each successful read.
  - If no read is active, `data_out` is set to a high-impedance state (`8'hZZ`).

### **3. Empty/Full Logic**
- **Empty**: The FIFO is empty when `write_ptr` equals `read_ptr`.
 
  assign empty = (write_ptr == read_ptr);
 -**Full**: The FIFO is full when write_ptr wraps around and matches read_ptr with an i
 
assign full = (write_ptr == {~read_ptr[4], read_ptr[3:0]});


### **4. Down-Counter Logic** 
-**Purpose**: Tracks the length of the current packet during reading.

*-**Mechanism**:

--Initializes with the packet length (extracted from data_in) when lfd_state is set.

--Decrements with each subsequent read until zero.

--Ensures correct packet handling for multi-byte packets.
## **SIMULATION**

<img width="959" alt="fifo_tb" src="https://github.com/user-attachments/assets/5a49e52f-c7aa-4715-815b-bf1eb8604163" />
<img width="945" alt="fifo_tb_2" src="https://github.com/user-attachments/assets/aacd66bb-f16b-47ba-8f89-abe8619f8a50" />

## **RTL SCHEMATIC**

<img width="791" alt="fifo_rtl" src="https://github.com/user-attachments/assets/804cba36-57a1-47f8-bbf6-9f1066fc50f3" />

---
# **2.Synchronizer Module** 


The **Synchronizer Module** is a key component in a router design where a single input needs to be routed to multiple hosts. This module directs the incoming data to one of three FIFO buffers (hosts) and ensures reliable communication through the generation of proper synchronization signals. It is responsible for managing the flow of data, controlling write and read operations, and maintaining the integrity of data transfer between the router FSM and the router FIFO modules.

The `router_sync` module ensures:
1. Efficient routing of data to the appropriate FIFO based on input selection.
2. Monitoring and signaling the full and empty status of FIFOs.
3. Generating control signals like **write enables** and **valid outputs** for seamless data flow.
4. Implementing a soft reset mechanism to handle inactivity scenarios, ensuring robust operation.


## **Inputs**
| Signal         | Width  | Description                                                                 |
|----------------|--------|-----------------------------------------------------------------------------|
| `clock`        | 1-bit  | System clock signal for synchronization.                                   |
| `resetn`       | 1-bit  | Active low reset signal to reset internal logic.                           |
| `detect_add`   | 1-bit  | Signal to latch the input address (`data_in`) for selecting a FIFO.         |
| `data_in`      | 2-bits | Determines which FIFO (0, 1, or 2) is selected for routing data.            |
| `write_en_reg` | 1-bit  | Control signal to enable writing to the selected FIFO.                     |
| `empty`        | 3-bits | Indicates whether each of the three FIFOs is empty.                        |
| `full`         | 3-bits | Indicates whether each of the three FIFOs is full.                         |
| `read_en`      | 3-bits | Read enable signals for the three FIFOs.                                   |

## **Outputs**
| Signal         | Width  | Description                                                                 |
|----------------|--------|-----------------------------------------------------------------------------|
| `write_en`     | 3-bits | Write enable signals for the selected FIFO.                                |
| `fifo_full`    | 1-bit  | Indicates whether the selected FIFO is full.                               |
| `vld_out`      | 3-bits | Valid output signals indicating data availability in each FIFO.            |
| `soft_reset`   | 3-bits | Soft reset signals for each FIFO to handle prolonged inactivity scenarios. |

---

## **Logic Explaination**

### **1. Address Logic**
This block determines which FIFO to target for data routing based on the `data_in` input.

always @(posedge clock) begin
    if (detect_add)
        add <= data_in;
end

### **2. Write Enable Logic**
This block generates the write_en signals for the selected FIFO.

always @(*) begin
    if (!write_en_reg)
        write_en = 3'b000;
    else begin
        case (add)
            2'b00: write_en = 3'b001;
            2'b01: write_en = 3'b010;
            2'b10: write_en = 3'b100;
            default: write_en = 3'b000;
        endcase
    end
end
Enables writing to FIFO_0, FIFO_1, or FIFO_2 based on the value of add.

### **3. FIFO Full Logic**
Determines whether the selected FIFO is full.

always @(*) begin
    case (add)
        2'b00: fifo_full = full[0];
        2'b01: fifo_full = full[1];
        2'b10: fifo_full = full[2];
        default: fifo_full = 0;
    endcase
end

Evaluates the full status of the selected FIFO.

### **4. Valid Output Logic**
Indicates whether valid data is available in each FIFO.

assign vld_out[0] = !empty[0];
assign vld_out[1] = !empty[1];
assign vld_out[2] = !empty[2];
Generates vld_out signals based on the empty status of the FIFOs.

### **5. Soft Reset Logic**
Implements a mechanism to reset FIFOs if no read operation occurs within 30 clock cycles after valid data is detected.

genvar i;
generate
    for (i = 0; i < 3; i = i + 1) begin : soft_reset_logic
        always @(posedge clock) begin
            if (!resetn) begin
                count_read[i] <= 0;
                soft_reset[i] <= 0;
            end else if (!vld_out[i]) begin
                count_read[i] <= 0;
                soft_reset[i] <= 0;
            end else if (read_en[i]) begin
                count_read[i] <= 0;
                soft_reset[i] <= 0;
            end else begin
                if (count_read[i] == 29) begin
                    count_read[i] <= 0;
                    soft_reset[i] <= 1; // Trigger soft reset
                end else begin
                    count_read[i] <= count_read[i] + 1;
                    soft_reset[i] <= 0;
                end
            end
        end
    end
endgenerate
Resets the counter and soft reset signal upon:

Active resetn.

FIFO becoming empty (vld_out[i] = 0).

A read operation (read_en[i] = 1).


## **SIMULATION**

<img width="767" alt="image" src="https://github.com/user-attachments/assets/48ad2017-e852-4e4e-9220-8eb9a8bf82bb" />

## **RTL SCHEMATIC**

![image](https://github.com/user-attachments/assets/d6443e9a-6f79-4dd3-a24c-2a3148864207)


# **3.Register Module in Verilog**

## **Introduction**

This module implements a register system designed to process packet data efficiently. It includes functionality for handling header bytes, managing FIFO states, computing internal parity, and detecting errors. The module ensures reliable data processing by using several internal registers and output control signals.



### **Inputs**:

| Signal        | Width | Description                                                                            |
| ------------- | ----- | -------------------------------------------------------------------------------------- |
| `clock`       | 1-bit | System clock signal used for latching registers.                                       |
| `resetn`      | 1-bit | Active-low reset signal to initialize all registers and outputs.                       |
| `pkt_valid`   | 1-bit | Indicates if the incoming packet is valid.                                             |
| `data_in`     | 8-bit | Input data signal carrying the payload or header.                                      |
| `fifo_full`   | 1-bit | Indicates if the FIFO buffer is full.                                                  |
| `rst_int_reg` | 1-bit | Resets the `low_pkt_valid` signal.                                                     |
| `detect_add`  | 1-bit | Detects the address byte and resets certain signals.                                   |
| `ld_state`    | 1-bit | Indicates that the payload byte is being processed.                                    |
| `laf_state`   | 1-bit | Handles the late arrival of data when the FIFO transitions.                            |
| `full_state`  | 1-bit | Indicates whether the module is in a full state. Used for internal parity calculation. |

### **Outputs**:

| Signal          | Width | Description                                                             |
| --------------- | ----- | ----------------------------------------------------------------------- |
| `parity_done`   | 1-bit | Indicates the completion of parity checking.                            |
| `low_pkt_valid` | 1-bit | Indicates that `pkt_valid` for the current packet has been deasserted.  |
| `dout`          | 8-bit | Output data signal carrying the header or payload data.                 |
| `err`           | 1-bit | Indicates an error if packet parity does not match the internal parity. |

---

## **Logic Explanation**

### **1. Initialization and Reset Behavior**

* **Purpose:** Ensures all outputs and registers are initialized to default values when `resetn` is low.
* **Logic:**

  * Resets `dout`, `err`, `parity_done`, and `low_pkt_valid` to `0`.
  * Resets internal registers (`first_byte`, `full_state_byte`, `internal_parity`, `pkt_parity`) to `8'h00`.

### **2. Parity Done (`parity_done`) Logic**

* **Purpose:** Indicates that parity checking for the current packet is complete.
* **Logic:**

  * Set HIGH:

    * When `ld_state` is high, and both `fifo_full` and `pkt_valid` are low.
    * When `laf_state` and `low_pkt_valid` are high, and `parity_done` was previously low.
  * Reset to LOW when `detect_add` is high.

### **3. Low Packet Valid (`low_pkt_valid`) Logic**

* **Purpose:** Tracks whether `pkt_valid` for the current packet has been deasserted.
* **Logic:**

  * Set HIGH when `ld_state` is high and `pkt_valid` is low.
  * Reset to LOW when `rst_int_reg` is high.

### **4. Output Data (`dout`) Logic**

* **Purpose:** Controls how the input data (`data_in`) or internal registers are latched to `dout`.
* **Behavior:**

  * **Header Byte Latching:**

    * When `detect_add` and `pkt_valid` are high, and `data_in[1:0] != 2'b11`, latch `data_in` to `first_byte`.
  * **Payload Latching:**

    * If `ld_state` is high and `fifo_full` is low, latch `data_in` to `dout`.
    * If `ld_state` is high and `fifo_full` is high, latch `data_in` to `full_state_byte`.
  * **Late Arrival Handling:**

    * When `laf_state` is high, latch `dout` to `full_state_byte` (if `fifo_full` is high) or `first_byte` (if `fifo_full` is low).

### **5. Internal Parity Calculation**

* **Purpose:** Computes parity for error detection using XOR operations.
* **Logic:**

  * Reset to `8'h00` when `detect_add` is high.
  * XOR header byte, payload bytes, and previous parity values based on state conditions (`laf_state` or `ld_state`).

### **6. Error Detection (`err`) Logic**

* **Purpose:** Flags errors when the packet parity does not match the internal parity.
* **Logic:**

  * Set HIGH if `parity_done` is high and `pkt_parity` does not match `internal_parity`.
  * Reset to LOW when `parity_done` is low.

### **7. Packet Parity Update**

* **Purpose:** Stores the received packet parity byte for comparison with `internal_parity`.
* **Logic:**

  * Reset to `8'h00` when `detect_add` is high.
  * Update with `data_in` during specific state conditions (`ld_state` or `laf_state`).
    
### **SIMULATION**

![image](https://github.com/user-attachments/assets/facfce22-7f99-4f9e-af34-ac69bfa71258)

### **RTL SCHEMATIC**

![image](https://github.com/user-attachments/assets/af793174-5063-473c-8382-a873f2657949)




## License  
This design is provided under the MIT License.  
