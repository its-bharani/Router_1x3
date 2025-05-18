
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
# 1. FIFO Module

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

## License  
This design is provided under the MIT License.  
