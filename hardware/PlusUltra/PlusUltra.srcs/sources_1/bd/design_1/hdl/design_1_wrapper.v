//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.3 (lin64) Build 2405991 Thu Dec  6 23:36:41 MST 2018
//Date        : Thu Feb 28 14:15:15 2019
//Host        : whitebox running 64-bit Linux Mint 18.3 Sylvia
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (BT_ctsn,
    BT_rtsn,
    GPIO_SENSORS_tri_io,
    UART0_ctsn,
    UART0_rtsn,
    UART0_rxd,
    UART0_txd);
  input BT_ctsn;
  output BT_rtsn;
  inout [5:0]GPIO_SENSORS_tri_io;
  input UART0_ctsn;
  output UART0_rtsn;
  input UART0_rxd;
  output UART0_txd;

  wire BT_ctsn;
  wire BT_rtsn;
  wire [0:0]GPIO_SENSORS_tri_i_0;
  wire [1:1]GPIO_SENSORS_tri_i_1;
  wire [2:2]GPIO_SENSORS_tri_i_2;
  wire [3:3]GPIO_SENSORS_tri_i_3;
  wire [4:4]GPIO_SENSORS_tri_i_4;
  wire [5:5]GPIO_SENSORS_tri_i_5;
  wire [0:0]GPIO_SENSORS_tri_io_0;
  wire [1:1]GPIO_SENSORS_tri_io_1;
  wire [2:2]GPIO_SENSORS_tri_io_2;
  wire [3:3]GPIO_SENSORS_tri_io_3;
  wire [4:4]GPIO_SENSORS_tri_io_4;
  wire [5:5]GPIO_SENSORS_tri_io_5;
  wire [0:0]GPIO_SENSORS_tri_o_0;
  wire [1:1]GPIO_SENSORS_tri_o_1;
  wire [2:2]GPIO_SENSORS_tri_o_2;
  wire [3:3]GPIO_SENSORS_tri_o_3;
  wire [4:4]GPIO_SENSORS_tri_o_4;
  wire [5:5]GPIO_SENSORS_tri_o_5;
  wire [0:0]GPIO_SENSORS_tri_t_0;
  wire [1:1]GPIO_SENSORS_tri_t_1;
  wire [2:2]GPIO_SENSORS_tri_t_2;
  wire [3:3]GPIO_SENSORS_tri_t_3;
  wire [4:4]GPIO_SENSORS_tri_t_4;
  wire [5:5]GPIO_SENSORS_tri_t_5;
  wire UART0_ctsn;
  wire UART0_rtsn;
  wire UART0_rxd;
  wire UART0_txd;

  IOBUF GPIO_SENSORS_tri_iobuf_0
       (.I(GPIO_SENSORS_tri_o_0),
        .IO(GPIO_SENSORS_tri_io[0]),
        .O(GPIO_SENSORS_tri_i_0),
        .T(GPIO_SENSORS_tri_t_0));
  IOBUF GPIO_SENSORS_tri_iobuf_1
       (.I(GPIO_SENSORS_tri_o_1),
        .IO(GPIO_SENSORS_tri_io[1]),
        .O(GPIO_SENSORS_tri_i_1),
        .T(GPIO_SENSORS_tri_t_1));
  IOBUF GPIO_SENSORS_tri_iobuf_2
       (.I(GPIO_SENSORS_tri_o_2),
        .IO(GPIO_SENSORS_tri_io[2]),
        .O(GPIO_SENSORS_tri_i_2),
        .T(GPIO_SENSORS_tri_t_2));
  IOBUF GPIO_SENSORS_tri_iobuf_3
       (.I(GPIO_SENSORS_tri_o_3),
        .IO(GPIO_SENSORS_tri_io[3]),
        .O(GPIO_SENSORS_tri_i_3),
        .T(GPIO_SENSORS_tri_t_3));
  IOBUF GPIO_SENSORS_tri_iobuf_4
       (.I(GPIO_SENSORS_tri_o_4),
        .IO(GPIO_SENSORS_tri_io[4]),
        .O(GPIO_SENSORS_tri_i_4),
        .T(GPIO_SENSORS_tri_t_4));
  IOBUF GPIO_SENSORS_tri_iobuf_5
       (.I(GPIO_SENSORS_tri_o_5),
        .IO(GPIO_SENSORS_tri_io[5]),
        .O(GPIO_SENSORS_tri_i_5),
        .T(GPIO_SENSORS_tri_t_5));
  design_1 design_1_i
       (.BT_ctsn(BT_ctsn),
        .BT_rtsn(BT_rtsn),
        .GPIO_SENSORS_tri_i({GPIO_SENSORS_tri_i_5,GPIO_SENSORS_tri_i_4,GPIO_SENSORS_tri_i_3,GPIO_SENSORS_tri_i_2,GPIO_SENSORS_tri_i_1,GPIO_SENSORS_tri_i_0}),
        .GPIO_SENSORS_tri_o({GPIO_SENSORS_tri_o_5,GPIO_SENSORS_tri_o_4,GPIO_SENSORS_tri_o_3,GPIO_SENSORS_tri_o_2,GPIO_SENSORS_tri_o_1,GPIO_SENSORS_tri_o_0}),
        .GPIO_SENSORS_tri_t({GPIO_SENSORS_tri_t_5,GPIO_SENSORS_tri_t_4,GPIO_SENSORS_tri_t_3,GPIO_SENSORS_tri_t_2,GPIO_SENSORS_tri_t_1,GPIO_SENSORS_tri_t_0}),
        .UART0_ctsn(UART0_ctsn),
        .UART0_rtsn(UART0_rtsn),
        .UART0_rxd(UART0_rxd),
        .UART0_txd(UART0_txd));
endmodule
