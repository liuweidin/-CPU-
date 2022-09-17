`default_nettype none
`include "defines.v"
module thinpad_top(
    input wire clk_50M,           //50MHz ʱ������
    input wire clk_11M0592,       //11.0592MHz ʱ�����루���ã��ɲ��ã�

    input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire[31:0] dip_sw,     //32λ���뿪�أ�������ON��ʱΪ1
    output wire[15:0] leds,       //16λLED�����ʱ1����
    output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С���㣬���1����
    output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С���㣬���1����

    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

    //ֱ�������ź�
    output wire txd,  //ֱ�����ڷ��Ͷ�
    input  wire rxd,  //ֱ�����ڽ��ն�

    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0]flash_a,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    inout  wire [15:0]flash_d,      //Flash����
    output wire flash_rp_n,         //Flash��λ�źţ�����Ч
    output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output wire flash_we_n,         //Flashдʹ���źţ�����Ч
    output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    //ͼ������ź�
    output wire[2:0] video_red,    //��ɫ���أ�3λ
    output wire[2:0] video_green,  //��ɫ���أ�3λ
    output wire[1:0] video_blue,   //��ɫ���أ�2λ
    output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire video_vsync,       //��ͬ������ֱͬ�����ź�
    output wire video_clk,         //����ʱ�����
    output wire video_de           //��������Ч�źţ���������������
);

/* =========== Demo code begin =========== */

// PLL��Ƶʾ��
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // �ⲿʱ������
  // Clock out ports
  .clk_out1(clk_10M), // ʱ�����1��Ƶ����IP���ý���������
  .clk_out2(clk_20M), // ʱ�����2��Ƶ����IP���ý���������
  // Status and control signals
  .reset(reset_btn), // PLL��λ����
  .locked(locked)    // PLL����ָʾ�����"1"��ʾʱ���ȶ���
                     // �󼶵�·��λ�ź�Ӧ���������ɣ����£�
 );
wire [`cache_lineBus] inst_read_data,inst_write_data;
wire inst_read_finish,inst_write_finish,inst_addr_valid,we;
wire [19:0] inst_addr;
wire sram_flush;

wire [`cache_lineBus] ram_read_data,dcache_write_data;
wire ram_read_finish,ram_write_finish,ram_addr_valid,ram_we;
wire [19:0] ram_addr;
wire dsram_flush;

wire ram_data_req_i;//CPU�������ݣ���λ��Ч
wire[`RegBus] ram_virtual_addr;//�����ַ����ʵ��TLB
wire [`RegBus] ram_write_data;//д����
wire ram_cpu_we;//��д�źţ�1λд��0λ��
wire [3:0]sel;//�ֽ�ʹ���ź�
wire [`RegBus]mem_data_i;//�洢��Ԫ���������
wire [31:0] mem_data_o;
wire dcache_valid,ready,dcache_req,data_valid,dcache_stop;

wire [31:0] read_rom_addr,mem_rom_data;
  wire [31:0] read_rom_data;
  wire is_rom_data;
  wire [31:0] inst;
  wire is_write_rom;
  wire [31:0] write_rom_data;
  wire base_ram_oe,base_ram_we;
  wire is_clearn_inst;
  wire relive;
  wire [19:0] inst_addr2;
  wire base_ram_ce;
  wire mem_stop;
  
  assign base_ram_ce_n=(is_rom_data==1'b1)? 1'b0:base_ram_ce;


  assign base_ram_addr=((is_rom_data==1'b1)&&(is_clearn_inst==1'b1))? read_rom_addr[22:2]:inst_addr2;
  assign base_ram_be_n=(is_rom_data==1'b0)?4'b0000:sel;
 // assign mem_rom_data=(is_write_rom==1'b1)? write_rom_data:32'bz;
  assign base_ram_data=(is_write_rom==1'b1)? write_rom_data:32'bz;//////////////
//assign base_ram_data=(is_rom_data==1'b1)?  mem_rom_data:inst;
  
  assign base_ram_oe_n=(is_write_rom==1'b1)?1'b1:(is_rom_data==1'b1)?1'b0:base_ram_oe;
  assign base_ram_we_n=(is_write_rom==1'b1)?1'b0:base_ram_we;
  //assign base_ram_oe_n=base_ram_oe;
  //assign base_ram_we_n=base_ram_we;
  //assign inst=((is_rom_data==1'b1)&&(is_clearn_inst==1'b1))? 32'b0:base_ram_data;
  //assign inst_read_data=((is_rom_data==1'b1)&&(is_clearn_inst==1'b1))? 32'b0:base_ram_data;
  //assign inst=(is_rom_data==1'b1)? 32'b0:~base_ram_oe_n? base_ram_data:32'bz;////////////////
  assign read_rom_data=~base_ram_oe_n? base_ram_data:32'bz;

MIPS mips(
 .rst(reset_btn),
    .clk(clk_50M),
    
    .is_rom_data(is_rom_data),
    .relive(relive),
    
    
    //��ָ��sram
    .addr(inst_addr),
    .read_data(inst_read_data),
    .write_data(inst_write_data),
    .write_finish(inst_write_finish),
    .read_finish(inst_read_finish),
    .addr_valid(inst_addr_valid),
    .cpu_we(we),
    .isram_flush(sram_flush),
    
    //����arm
    .ram_data_req_i(ram_data_req_i), //CPU�������ݣ���λ��Ч
    .ram_virtual_addr(ram_virtual_addr),//�����ַ����ʵ��TLB
    .ram_write_data(ram_write_data),//д����
    .ram_cpu_we(ram_cpu_we),//��д�źţ�1λд��0λ��
	.sel(sel),//�ֽ�ʹ���ź�
	.mem_data_i(mem_data_i),//�洢��Ԫ���������
    .ready(ready),
    .cache_stop(mem_stop)
);
mem_ctrl mem_ctrl(
     .clk(clk_50M),
      .rst(reset_btn),
      .cpu_addr(ram_virtual_addr),//CPU���ݵĵ�ַ
      .ram_data(mem_data_o),//ram���ص��ź�
      .uart_data_i(ext_uart_rx),
      .cpu_data(ram_write_data),
      .uart_ready_i(ext_uart_ready),

      .we(ram_cpu_we),
      .not_ce(ram_data_req_i),
      .ram_ready(data_valid),
      .data(mem_data_i),//ram_data
      .ready(ready),//�ô��Ƿ����������Ч
      //��rom
     .rom_data(read_rom_data),
    .rom_addr(read_rom_addr),
    .is_rom_data(is_rom_data),
      
    .ram_ce(dcache_req),
    
    .cache_stop(dcache_stop),//cache����ͣ�ź�
    .stop_req(mem_stop),
    
    .rxd_clear(ext_uart_clear),
    .tsd_busy(ext_uart_busy),
    .uart_data_o(ext_uart_tx),
    .txd_start(ext_uart_start),
    //дrom
    .rom_data_o(write_rom_data),
    .is_write_rom(is_write_rom),
    .is_clearn_inst(is_clearn_inst),
    .relive(relive)


);

Dcache Dcache(
     .clk(clk_50M),
     .rst(reset_btn),
     .data_req_i(dcache_req), //CPU�������ݣ���λ��Ч
     .virtual_addr(ram_virtual_addr),//�����ַ����ʵ��TLB
     .write_data(ram_write_data),
     .cpu_we(ram_cpu_we),//��д�źţ�1λд��0λ��
     .ram_addr(ram_addr),
     //input wire ram_ready,
     .ram_data_i(ram_read_data),//sram��ȡ����һ������
     .cache_hit_o(),//cache���У���λ��Ч
     .data_valid_o(data_valid),//���������Ƿ���Ч����λ��Ч
     .data1(mem_data_o),//�������ݵĶ˿�1
     .data2(),//�������ݵĶ˿�2
     //.stopreq(dcache_valid),
     .stopreq(dcache_stop),
     .we(ram_we),
     //��sram�������������ź�
     .write_finish(ram_write_finish),
     .read_finish(ram_read_finish),
     .addr_valid(ram_addr_valid),//��ַ�Ƿ���Ч
     //д��һ������
     .write_back_data(dcache_write_data),
     //�Ƿ������������,��λ��Ч
     .is_single(),
     //�ֽ�дʹ���ź�
     .sel(sel),
     //�����ź�
     .cache_flush()

);

dsram_ctrl dsram_carl(
    .clk(clk_50M),
     .rst(reset_btn),
    
     .write_data(dcache_write_data),//cache�滻��������
     .addr(ram_addr),//д���߶���ַ
     .we(ram_we),//��д�źţ�1Ϊд��0Ϊ��
     .sram_flush(dsram_flush),//sram״̬������
     
     //�����ź�
     .addr_valid(ram_addr_valid),//�����ַ��Ч,����Ч
     .write_finish(ram_write_finish),//д���������,����Ч
     .read_finish(ram_read_finish),//��ȡ������ɣ�����Ч
     //����������
     .read_data(ram_read_data),//��ȡ������
     //���͸�sram���ź�
    .data(ext_ram_data),//˫�����ݴ���˿�
    .ram_ce(ext_ram_ce_n),//ramƬѡ�źţ�����Ч
    .ram_oe(ext_ram_oe_n),//��ʹ�ܣ�����Ч
    .ram_we(ext_ram_we_n),//дʹ�ܣ�����Ч
    .ram_addr(ext_ram_addr),//��д���ݵ�ַ
    .ram_sel(ext_ram_be_n)//�ֽ�Ƭѡ�źţ�0��Ч
);

isram_ctrl isram_carl(
    .clk(clk_50M),
     .rst(reset_btn),
    
     .write_data(inst_write_data),//cache�滻��������
     .addr(inst_addr),//д���߶���ַ
     .we(we),//��д�źţ�1Ϊд��0Ϊ��
     .sram_flush(sram_flush),//sram״̬������
     
     //�����ź�
     .addr_valid(inst_addr_valid),//�����ַ��Ч,����Ч
     .write_finish(inst_write_finish),//д���������,����Ч
     .read_finish(inst_read_finish),//��ȡ������ɣ�����Ч
     //����������
     .read_data(inst_read_data),//��ȡ������
     //���͸�sram���ź�
    .data(base_ram_data),//˫�����ݴ���˿�
    .ram_ce(base_ram_ce),//ramƬѡ�źţ�����Ч
    .ram_oe(base_ram_oe),//��ʹ�ܣ�����Ч
    .ram_we(base_ram_we),//дʹ�ܣ�����Ч
    .ram_addr(inst_addr2),//��д���ݵ�ַ
    .ram_sel()//�ֽ�Ƭѡ�źţ�0��Ч
);



reg reset_of_clk10M;
// �첽��λ��ͬ���ͷţ���locked�ź�תΪ�󼶵�·�ĸ�λreset_of_clk10M
always@(posedge clk_10M or negedge locked) begin
    if(~locked) reset_of_clk10M <= 1'b1;
    else        reset_of_clk10M <= 1'b0;
end

always@(posedge clk_10M or posedge reset_of_clk10M) begin
    if(reset_of_clk10M)begin
        // Your Code
    end
    else begin
        // Your Code
    end
end

// ��ʹ���ڴ桢����ʱ��������ʹ���ź�
/*assign base_ram_ce_n = 1'b1;
assign base_ram_oe_n = 1'b1;
assign base_ram_we_n = 1'b1;

assign ext_ram_ce_n = 1'b1;
assign ext_ram_oe_n = 1'b1;
assign ext_ram_we_n = 1'b1;*/

// ��������ӹ�ϵʾ��ͼ��dpy1ͬ��
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7���������������ʾ����number��16������ʾ�����������
wire[7:0] number;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0�ǵ�λ�����
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1�Ǹ�λ�����

reg[15:0] led_bits;
assign leds = led_bits;

always@(posedge clock_btn or posedge reset_btn) begin
    if(reset_btn)begin //��λ���£�����LEDΪ��ʼֵ
        led_bits <= 16'h1;
    end
    else begin //ÿ�ΰ���ʱ�Ӱ�ť��LEDѭ������
        led_bits <= {led_bits[14:0],led_bits[15]};
    end
end

//ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ
/*wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_clear, ext_uart_busy;
reg ext_uart_start, ext_uart_avai;
    
assign number = ext_uart_buffer;*/

wire [7:0] ext_uart_rx;
wire  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_clear, ext_uart_busy;
wire ext_uart_start, ext_uart_avai;

async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_r(
        .clk(clk_50M),                       //�ⲿʱ���ź�
        .RxD(rxd),                           //�ⲿ�����ź�����
        .RxD_data_ready(ext_uart_ready),  //���ݽ��յ���־
        .RxD_clear(ext_uart_clear),       //������ձ�־
        .RxD_data(ext_uart_rx)             //���յ���һ�ֽ�����
    );

/*assign ext_uart_clear = ext_uart_ready; //�յ����ݵ�ͬʱ�������־����Ϊ������ȡ��ext_uart_buffer��
always @(posedge clk_50M) begin //���յ�������ext_uart_buffer
    if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
    end else if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_avai <= 0;
    end
end
always @(posedge clk_50M) begin //��������ext_uart_buffer���ͳ�ȥ
    if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_tx <= ext_uart_buffer;
        ext_uart_start <= 1;
    end else begin 
        ext_uart_start <= 0;
    end
end
*/
async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_t(
        .clk(clk_50M),                  //�ⲿʱ���ź�
        .TxD(txd),                      //�����ź����
        .TxD_busy(ext_uart_busy),       //������æ״ָ̬ʾ
        .TxD_start(ext_uart_start),    //��ʼ�����ź�
        .TxD_data(ext_uart_tx)        //�����͵�����
    );

//ͼ�������ʾ���ֱ���800x600@75Hz������ʱ��Ϊ50MHz
wire [11:0] hdata;
assign video_red = hdata < 266 ? 3'b111 : 0; //��ɫ����
assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //��ɫ����
assign video_blue = hdata >= 532 ? 2'b11 : 0; //��ɫ����
assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_50M), 
    .hdata(hdata), //������
    .vdata(),      //������
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de)
);
/* =========== Demo code end =========== */
ila_0 ila(
.clk(clk_50M),

.probe0(mips.Regfile.regs[17]),
.probe1(mips.Decode.issue_inst1_o),
.probe2(base_ram_addr),
.probe3(mem_data_i),
//.probe4(base_ram_oe_n),
.probe4(mips.Decode.issue_inst2_o),
.probe5(mips.Regfile.regs[4]),
.probe6(mem_ctrl.cpu_data)
);
endmodule
