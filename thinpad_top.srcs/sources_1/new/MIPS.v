`timescale 1ns / 1ps
`include "defines.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/03 22:57:27
// Design Name: 
// Module Name: MIPS
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MIPS(
    input wire rst,
    input wire clk,
    
    
    
    //��ָ��sram
    output wire [19:0] addr,
    input wire [`cache_lineBus] read_data,
    output wire [`cache_lineBus] write_data,
    input wire write_finish,
    input wire read_finish,
    output wire addr_valid,
    output wire cpu_we,
    //output wire cpu_ce,
    output wire isram_flush,//����sram�ڲ�״̬��
    //����arm
    output wire ram_data_req_i, //CPU�������ݣ���λ��Ч
    output wire[`RegBus] ram_virtual_addr,//�����ַ����ʵ��TLB
    output wire [`RegBus] ram_write_data,//д����
    output wire ram_cpu_we,//��д�źţ�1λд��0λ��
	output wire [3:0]sel,//�ֽ�ʹ���ź�
	input wire [`RegBus]mem_data_i,//�洢��Ԫ���������
    
    input wire is_rom_data,
    input wire relive,
    
    input wire cache_stop,
    input wire ready//�ô��Ƿ����
    //input wire cache_data_valid
    );
    wire [`InstAddrBus] pc,npc;
    
    wire [5:0]stop;
    
    wire flush,stop_from_cache,issue_finish,issue_ok,alu_valid,buffer_flush_o;
    wire full;
    wire is_single,is_single_issue,issue_finish_o,is_single_issue_o;
    wire icache_data_valid;
    wire [1:0]is_busy;//mem��mul��ˮ���Ƿ�æ
    wire [2:0]mul_pipline_state;//mem��mul��ˮ�ߵ�״̬��ָ��ִ�����
    wire [2:0]mem_pipline_state;
    
    //�͸�ָ��cache
    wire [`InstAddrBus] inst_addr;
    wire inst_addr_valid,we;
    
    //����if_id�Ĵ���
    wire [`InstBus] inst1,inst2;
    wire inst_flush;//��ͣʱ����״̬��
    wire stop_from_if;
    //FIFO
    //���
    
    wire [`InstBus] issue_inst1_o;
    wire [`InstBus] issue_inst2_o;
    wire [`InstAddrBus] issue_inst1_addr_o;
    wire [`InstAddrBus] issue_inst2_addr_o;
    //����
    wire inst_valid;
    wire [`InstBus]		fetch_inst1_i;
    wire [`InstBus]fetch_inst2_i;
    wire [`InstAddrBus]	fetch_inst2_addr_i;
    wire [`InstAddrBus] fetch_inst1_addr_i;
    
    //�͵�regfile
    wire [`RegAddrBus] raddr1;
    wire [`RegAddrBus] raddr2;
    wire [`RegAddrBus] raddr3;
    wire [`RegAddrBus] raddr4;
    
    wire re1;
    wire re2;
    wire re3;
    wire re4;
    
    wire [`RegBus] data1;
    wire [`RegBus] data2;
    wire [`RegBus] data3;
    wire [`RegBus] data4;
    
    wire[`RegAddrBus] waddr1;
    wire[`InstBus] wdata1;
    wire we1;
    
    wire[`RegAddrBus] waddr2;
    wire[`InstBus] wdata2;
    wire we2;
    
    //�͵�fu_exe�׶�
    wire[`AluOpBus]         alu_aluop_i;
	wire[`AluSelBus]        alu_alusel_i;
	wire[`RegBus]           alu_reg1_i;
	wire[`RegBus]           alu_reg2_i;
	wire[`RegAddrBus]       alu_wd_i;
	wire                    alu_wreg_i;
    wire [`RegBus] link_addr_o;
    wire [`RegBus] link_addr_alu;
    
    wire fu_valid;
    //exe
    wire[`RegAddrBus] ex_wd;
	wire ex_wreg;
	wire[`RegBus] ex_wdata;
	
	wire[`AluOpBus]         aluop_i;
	wire[`AluSelBus]        alusel_i;
	wire[`RegBus]           reg1_i;
	wire[`RegBus]           reg2_i;
	wire[`RegAddrBus]       wd_i;
	wire                    wreg_i;
	
	//mem
	wire [`RegAddrBus] mem_wd;
	wire mem_wreg;
	wire[`RegBus] mem_wdata;
	
	/////�͵�mul_fu
	wire[`AluOpBus]         mul_aluop_o;
	wire[`AluSelBus]        mul_alusel_o;
	wire[`RegBus]           mul_reg1_o;
	wire[`RegBus]           mul_reg2_o;
	wire[`RegAddrBus]      mul_wd_o;
	wire                    mul_wreg_o;
	wire mul_valid;
	
	//�͵�mem_fu
	wire[`AluOpBus]         mem_aluop_o;
	wire[`AluSelBus]        mem_alusel_o;
	wire[`RegBus]           mem_reg1_o;
	wire[`RegBus]           mem_reg2_o;
	wire[`RegAddrBus]      mem_wd_o;
	wire                    mem_wreg_o;
	wire mem_valid;
	wire [`InstBus]inst;
	
	wire is_single_o;
	///������д��fuѡ��
	wire					alu_wb_wreg_i;
	wire[`RegBus]			alu_wb_wdata_i;
	wire[`RegAddrBus]     alu_wb_wd_i;
	
	wire					mul_wb_wreg_i;
	wire[`RegBus]			mul_wb_wdata_i;
	wire[`RegAddrBus]     mul_wb_wd_i;
	wire wb_valid;
	
	wire[`RegAddrBus]      mem_wb_wd;
	wire                   mem_wb_wreg;
	wire[`RegBus]           mem_wb_data;
	wire mem_wb_valid;
	
	wire[`RegAddrBus]      wb_wd;
	wire                   wb_wreg;
	wire[`RegBus]           wb_data;
	wire m_wb_valid;
	//����mult
	wire [`RegBus] A,B;
	wire [63:0] p;
	////////////////////������·
/*	 //alu_fu������·
     //����ִ�н׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
	wire					alu_ex_wreg_i,
	wire[`RegBus]			alu_ex_wdata_i,
	wire[`RegAddrBus]     alu_ex_wd_i,
	
	//���ڷô�׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
	wire					alu_mem_wreg_i,
	wire[`RegBus]			alu_mem_wdata_i,
	wire[`RegAddrBus]    alu_mem_wd_i,
	*/
    //decode
    /*wire [`InstBus]		issue_inst1_o;
    wire [`InstBus]		issue_inst2_o;
    wire [`InstAddrBus] issue_inst1_addr_o;
    wire [`InstAddrBus]	issue_inst2_addr_o;*/
    wire[`RegBus] branch_addr;
	wire next_in_delaysolt;
	wire is_in_delaysolt;
	wire branch_flag;
    wire buffer_flush;//������֧��תʱ���instbuffer
    
    wire [`InstBus]		issue_inst1_i;
    wire [`InstBus]		issue_inst2_i;
    wire [`InstAddrBus] issue_inst1_addr_i;
     wire [`InstAddrBus]	issue_inst2_addr_i;
     
     wire[`AluOpBus]         id1_aluop1_o;
	wire[`AluSelBus]        id1_alusel1_o;
	wire                    id1_reg1_read_o;
	wire                    id1_reg2_read_o;     
	wire[`RegAddrBus]       id1_reg1_addr_o;
	wire[`RegAddrBus]       id1_reg2_addr_o;

	wire[`RegAddrBus]       id1_wd1_o;
	wire                    id1_wreg1_o;
	wire[`RegBus]	id1_imm1;
    wire id1_is_alu1;
    wire id1_is_mul1;
    wire id1_is_jb1;
    wire id1_is_mem1;
	/////////////////////�ڶ���ָ��//////////////////
	wire[`AluOpBus]         id1_aluop2_o;
	wire[`AluSelBus]        id1_alusel2_o;
	wire                   id1_reg3_read_o;
	wire                    id1_reg4_read_o;     
	wire[`RegAddrBus]       id1_reg3_addr_o;
	wire[`RegAddrBus]       id1_reg4_addr_o;
	wire[`RegAddrBus]       id1_wd2_o;
	wire                    id1_wreg2_o;
	wire[`RegBus]	id1_imm2;
	wire id1_is_alu2;
	wire id1_is_mul2;
	wire id1_is_jb2;
	wire id1_is_mem2;
	
	wire[`AluOpBus]         id2_aluop1_o;
	wire[`AluSelBus]        id2_alusel1_o;
	wire                    id2_reg1_read_o;
	wire                    id2_reg2_read_o;     
	wire[`RegAddrBus]       id2_reg1_addr_o;
	wire[`RegAddrBus]       id2_reg2_addr_o;

	wire[`RegAddrBus]       id2_wd1_o;
	wire                    id2_wreg1_o;
	wire[`RegBus]	id2_imm1;
    wire id2_is_alu1;
    wire id2_is_mul1;
    wire id2_is_jb1;
    wire id2_is_mem1;
	/////////////////////�ڶ���ָ��//////////////////
	wire[`AluOpBus]         id2_aluop2_o;
	wire[`AluSelBus]        id2_alusel2_o;
	wire                   id2_reg3_read_o;
	wire                    id2_reg4_read_o;     
	wire[`RegAddrBus]       id2_reg3_addr_o;
	wire[`RegAddrBus]       id2_reg4_addr_o;
	wire[`RegAddrBus]       id2_wd2_o;
	wire                    id2_wreg2_o;
	wire[`RegBus]	id2_imm2;
	wire id2_is_alu2;
	wire id2_is_mul2;
	wire id2_is_jb2;
	wire id2_is_mem2;
	
	wire mem_req,mul_req;
    /*
    //mul_fu��·��Ϣ
    wire					mul_wreg_i;
	wire[`RegBus]			mul_wdata_i;
	wire[`RegAddrBus]    mul_wd_i;
	//mem_fu��·��Ϣ
    wire					m_wreg_i;
	wire[`RegBus]			m_wdata_i;
	wire[`RegAddrBus]    m_wd_i;*/
    
    assign isram_flush=inst_flush;

    assign inst_addr=pc;
    //assign buffer_flush=(branch_flag==1'b1)? 1'b1:1'b0;
    fetch pc_reg(
        .clk(clk),
        .rst(rst),
        .npc(npc),
        .pc(pc),
        .inst_req(inst_addr_valid)
    );
    pre_fetch NPC(
        .rst(rst),
        .current_pc(pc),//��ǰpc���
        .branch_flag(branch_flag),//��֧�ź�
        .acctual_pc(branch_addr),//��ָ֧��ִ�н��
        .is_single(is_single),//cache�Ƿ�ȡ������ָ��
    
        .inst_valid(icache_data_valid),//cache���ص������Ƿ���Ч
        .stop(stop),
    
        .npc(npc)
    );
    
    icache inst_cache(
      .clk(clk),
     .rst(rst),
     .data_req_i(inst_addr_valid), //CPU�������ݣ���λ��Ч
     .virtual_addr(pc),//�����ַ����ʵ��TLB
     .write_data(),
     .cpu_we(1'b0),//��д�źţ�1λд��0λ��
     .ram_addr(addr),
     //input wire ram_ready,
     .ram_data_i(read_data),//sram��ȡ����һ������
     .cache_hit_o(),//cache���У���λ��Ч
     .data_valid_o(icache_data_valid),//���������Ƿ���Ч����λ��Ч
     .data1(inst1),//�������ݵĶ˿�1
     .data2(inst2),//�������ݵĶ˿�2
     .stopreq(stop_from_cache),
     .ce(cpu_ce),
     .we(cpu_we),
     //��sram�������������ź�
     .write_finish(write_finish),
     .read_finish(read_finish),
     .addr_valid(addr_valid),//��ַ�Ƿ���Ч
     //д��һ������
     .write_back_data(write_data),
     //�Ƿ������������,��λ��Ч
     .is_single(is_single),
     //�ֽ�дʹ���ź�
     .sel(4'b0000),
     //�����ź�
     .cache_flush(inst_flush)
);
    IF_ID if_id(
     .rest(rst),
     .clk(clk),
     .is_single(is_single),
     .if_pc1(pc),
    .if_inst1(inst1),
      .if_pc2(pc+4'h4),
    .if_inst2(inst2),
    .cache_data_valid(icache_data_valid),
    
      .stop(stop),
      .flush(flush),
      .inst_flush(inst_flush),
    
    .id_pc1(fetch_inst1_addr_i),
    .id_inst1(fetch_inst1_i), 

    .id_pc2(fetch_inst2_addr_i),
    .id_inst2(fetch_inst2_i),
    
    .is_single_o(is_single_o),
    .inst_valid(inst_valid)
    );
    
    InstBuffer InstBuffer(
        .rst(rst),
        .clk(clk),
        .flush(flush),
        .buffer_flush(buffer_flush),
    
    //issue
        .is_single_issue(is_single_issue),//��ʾ�Ƿ��䵥��ָ���λ���䵥��ָ��
        .issue_finish(issue_finish),//��ʾ����ָ���Ƿ����,��λ��Ч
    
    .issue_inst1_o(issue_inst1_o),
    .issue_inst2_o(issue_inst2_o),
    .issue_inst1_addr_o(issue_inst1_addr_o),
    .issue_inst2_addr_o(issue_inst2_addr_o),
    
    .issue_ok(issue_ok),//FIFO�Ƿ���ܷ���
    
    //fetch�׶�����������
    .fetch_inst1_i(fetch_inst1_i),
    .fetch_inst2_i(fetch_inst2_i),
    .fetch_inst1_addr_i(fetch_inst1_addr_i),
    .fetch_inst2_addr_i(fetch_inst2_addr_i),
    .is_single_fetch(is_single_o),//��ʾcache�Ƿ��������ָ��
    .inst_valid(inst_valid),//��ʾif_+id�Ĵ�������Ƿ���Ч
    
    .buffer_full(full),//��ʾinstbuffer�Ƿ�װ��
    
    .next_in_delaysolt(next_in_delaysolt)
    );
    assign stop_from_if=(stop_from_cache==`Stop)||(full==1'b1);
    
    Decode Decode(
        .rst(rst),
    //��FIFO�Ľ����ź�
    .issue_inst1_o(issue_inst1_o),
    .issue_inst2_o(issue_inst2_o),
    .issue_inst1_addr_o(issue_inst1_addr_o),
    .issue_inst2_addr_o(issue_inst2_addr_o),
    
    .issue_ok(issue_ok),//FIFO�Ƿ���ܷ���
    
    .is_single_issue(is_single_issue),//��ʾ�Ƿ��䵥��ָ���λ���䵥��ָ��
    .issue_finish(issue_finish),//��ʾ����ָ���Ƿ����,��λ��Ч
    //mul_fu,mem_fu״̬
    //fu״̬
   
	.is_busy(is_busy),
    
     //alu_fu������·
     //����ִ�н׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
	/*.ex_wreg_i(ex_wreg),
	.ex_wdata_i(ex_wdata),
	.ex_wd_i(ex_wd),*/
	//mul_fu��·��Ϣ
    .mul_wreg_i(mul_wb_wreg_i),
	.mul_wdata_i(mul_wb_wdata_i),
	.mul_wd_i(mul_wb_wd_i),
	//mem_fu��·��Ϣ
    .m_wreg_i(mem_wb_wreg),
	
	.m_wd_i(mem_wb_wd),
	
	
	//���ڷô�׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
	/*.mem_wreg_i(mem_wreg),
	.mem_wdata_i(mem_wdata),
	.mem_wd_i(mem_wd),*/
    .mem_req(mem_req),
    .mul_req(mul_req),

    .stop(stop),
    
    .id2_wd1_o(id2_wd1_o),
    .id2_wreg1_o(id2_wreg1_o),
    .id2_wd2_o(id2_wd2_o),
    .id2_wreg2_o(id2_wreg2_o),
    /*
    //�͵�ִ�н׶ε���Ϣ
    ///////alu_fu����//////////////
	.alu_aluop_o(alu_aluop_i),
	.alu_alusel_o(alu_alusel_i),
	.alu_reg1_o(alu_reg1_i),
	.alu_reg2_o(alu_reg2_i),
	.alu_wd_o(alu_wd_i),
	.alu_wreg_o(alu_wreg_i),
	.alu_valid(alu_valid),
	
	//////////mul_fu///////////////
	.mul_aluop_o(mul_aluop_o),
	.mul_alusel_o(mul_alusel_o),
	.mul_reg1_o(mul_reg1_o),
	.mul_reg2_o(mul_reg2_o),
	.mul_wd_o(mul_wd_o),
	.mul_wreg_o(mul_wreg_o),
	.mul_valid(mul_valid),
	
	//////////mem_fu///////
	.mem_aluop_o(mem_aluop_o),
	.mem_alusel_o(mem_alusel_o),
	.mem_reg1_o(mem_reg1_o),
	.mem_reg2_o(mem_reg2_o),
	 .mem_wd_o(mem_wd_o),
	.mem_wreg_o(mem_wreg_o),
	.mem_valid(mem_valid),
	.inst(inst),*/
	/*
	//regfile����ź�
	.reg1_read_o(re1),
	.reg2_read_o(re2),     
	.reg1_addr_o(raddr1),
	.reg2_addr_o(raddr2),
	.reg3_read_o(re3),
	.reg4_read_o(re4),     
	.reg3_addr_o(raddr3),
	.reg4_addr_o(raddr4),
	
	.reg1_data_i(data1),
	.reg2_data_i(data2),
	.reg3_data_i(data3),
	.reg4_data_i(data4),*/
	.is_delaysolt(next_in_delaysolt),
	.buffer_flush(buffer_flush),
	.aluop1_o(id1_aluop1_o),
	.alusel1_o(id1_alusel1_o),
	.reg1_read_o(id1_reg1_read_o),
	.reg2_read_o(id1_reg2_read_o),     
	.reg1_addr_o(id1_reg1_addr_o),
	.reg2_addr_o(id1_reg2_addr_o),

	.wd1_o(id1_wd1_o),
	.wreg1_o(id1_wreg1_o),
	.imm1(id1_imm1),
    .is_alu1(id1_is_alu1),
    .is_mul1(id1_is_mul1),
    .is_jb1(id1_is_jb1),
    .is_mem1(id1_is_mem1),
	/////////////////////�ڶ���ָ��//////////////////
	.aluop2_o(id1_aluop2_o),
	.alusel2_o(id1_alusel2_o),
	.reg3_read_o(id1_reg3_read_o),
	.reg4_read_o(id1_reg4_read_o),     
	.reg3_addr_o(id1_reg3_addr_o),
	.reg4_addr_o(id1_reg4_addr_o),
	.wd2_o(id1_wd2_o),
	.wreg2_o(id1_wreg2_o),
	.imm2(id1_imm2),
	.is_alu2(id1_is_alu2),
	.is_mul2(id1_is_mul2),
	.is_jb2(id1_is_jb2),
	.is_mem2(id1_is_mem2)
	

	/*
	
	//jump_branch
	.link_addr(link_addr_o),
	
	.branch_addr(branch_addr),
	.next_in_delaysolt(next_in_delaysolt),
	.branch_flag(branch_flag),
	.is_delaysolt(is_in_delaysolt),
	.buffer_flush(buffer_flush_o)*/
    );
    id_issue id_issue(
        .rst(rst),
        .clk(clk),
        .flush(flush),
    
        .stop(stop),
    
    .reg1_read_o(re1),
	.reg2_read_o(re2),     
	.reg1_addr_o(raddr1),
	.reg2_addr_o(raddr2),
	.reg3_read_o(re3),
	.reg4_read_o(re4),     
	.reg3_addr_o(raddr3),
	.reg4_addr_o(raddr4),
    
    .aluop1_i(id1_aluop1_o),
	.alusel1_i(id1_alusel1_o),
	.reg1_read_i(id1_reg1_read_o),
	.reg2_read_i(id1_reg2_read_o),     
	.reg1_addr_i(id1_reg1_addr_o),
	.reg2_addr_i(id1_reg2_addr_o),

	.wd1_i(id1_wd1_o),
	.wreg1_i(id1_wreg1_o),
	.imm1_i(id1_imm1),
    .is_alu1_i(id1_is_alu1),
    .is_mul1_i(id1_is_mul1),
    .is_jb1_i(id1_is_jb1),
    .is_mem1_i(id1_is_mem1),
	/////////////////////�ڶ���ָ��//////////////////
	.aluop2_i(id1_aluop2_o),
	.alusel2_i(id1_alusel2_o),
	.reg3_read_i(id1_reg3_read_o),
	.reg4_read_i(id1_reg4_read_o),     
	.reg3_addr_i(id1_reg3_addr_o),
	.reg4_addr_i(id1_reg4_addr_o),
	.wd2_i(id1_wd2_o),
	.wreg2_i(id1_wreg2_o),
	.imm2_i(id1_imm2),
	.is_alu2_i(id1_is_alu2),
	.is_mul2_i(id1_is_mul2),
	.is_jb2_i(id1_is_jb2),
	.is_mem2_i(id1_is_mem2),
    
	
   .aluop1_o(id2_aluop1_o),
	.alusel1_o(id2_alusel1_o),
	

	.wd1_o(id2_wd1_o),
	.wreg1_o(id2_wreg1_o),
	.imm1(id2_imm1),
    .is_alu1(id2_is_alu1),
    .is_mul1(id2_is_mul1),
    .is_jb1(id2_is_jb1),
    .is_mem1(id2_is_mem1),
	/////////////////////�ڶ���ָ��//////////////////
	.aluop2_o(id2_aluop2_o),
	.alusel2_o(id2_alusel2_o),
	
	.wd2_o(id2_wd2_o),
	.wreg2_o(id2_wreg2_o),
	.imm2(id2_imm2),
	.is_alu2(id2_is_alu2),
	.is_mul2(id2_is_mul2),
	.is_jb2(id2_is_jb2),
	.is_mem2(id2_is_mem2),
	
	//��inst buffer
	.is_single_issue(is_single_issue),
	.issue_finish(issue_finish),
	
	.issue_finish_o(issue_finish_o),
	.is_single_issue_o(is_single_issue_o),
	
	.issue_inst1_i(issue_inst1_o),
    .issue_inst2_i(issue_inst2_o),
    .issue_inst1_addr_i(issue_inst1_addr_o),
    .issue_inst2_addr_i(issue_inst2_addr_o),
    .issue_inst1_o(issue_inst1_i),
    .issue_inst2_o(issue_inst2_i),
    .issue_inst1_addr_o(issue_inst1_addr_i),
    .issue_inst2_addr_o(issue_inst2_addr_i)
    );
    
    Issue Issue(
        .rst(rst),
        .stop(stop),
    
    .issue_inst1_o(issue_inst1_i),
    .issue_inst2_o(issue_inst2_i),
    .issue_inst1_addr_o(issue_inst1_addr_i),
    .issue_inst2_addr_o(issue_inst2_addr_i),
    .issue_finish(issue_finish_o),
    .is_single_issue(is_single_issue_o),
    
    .reg1_read_o(re1),
	.reg2_read_o(re2),     
	.reg1_addr_o(raddr1),
	.reg2_addr_o(raddr2),
	.reg3_read_o(re3),
	.reg4_read_o(re4),     
	.reg3_addr_o(raddr3),
	.reg4_addr_o(raddr4),
	
	.reg1_data_i(data1),
	.reg2_data_i(data2),
	.reg3_data_i(data3),
	.reg4_data_i(data4),

	
	.aluop1_o(id2_aluop1_o),
	.alusel1_o(id2_alusel1_o),
	

	.wd1_o(id2_wd1_o),
	.wreg1_o(id2_wreg1_o),
	.imm1(id2_imm1),
    .is_alu1(id2_is_alu1),
    .is_mul1(id2_is_mul1),
    .is_jb1(id2_is_jb1),
    .is_mem1(id2_is_mem1),
	/////////////////////�ڶ���ָ��//////////////////
	.aluop2_o(id2_aluop2_o),
	.alusel2_o(id2_alusel2_o),
	
	
	.wd2_o(id2_wd2_o),
	.wreg2_o(id2_wreg2_o),
	.imm2(id2_imm2),
	.is_alu2(id2_is_alu2),
	.is_mul2(id2_is_mul2),
	.is_jb2(id2_is_jb2),
	.is_mem2(id2_is_mem2),
	
	
	 //alu_fu������·
     //����ִ�н׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ

	.ex_wreg_i(ex_wreg),
	.ex_wdata_i(ex_wdata),
	.ex_wd_i(ex_wd),
	//���ڷô�׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ

	.mem_wreg_i(mem_wreg),
	.mem_wdata_i(mem_wdata),
	.mem_wd_i(mem_wd),

	//�͵�ִ�н׶ε���Ϣ
    ///////alu_fu����//////////////
	.alu_aluop_o(alu_aluop_i),
	.alu_alusel_o(alu_alusel_i),
	.alu_reg1_o(alu_reg1_i),
	.alu_reg2_o(alu_reg2_i),
	.alu_wd_o(alu_wd_i),
	.alu_wreg_o(alu_wreg_i),
	.alu_valid(alu_valid),
	
	//////////mul_fu///////////////
	.mul_aluop_o(mul_aluop_o),
	.mul_alusel_o(mul_alusel_o),
	.mul_reg1_o(mul_reg1_o),
	.mul_reg2_o(mul_reg2_o),
	.mul_wd_o(mul_wd_o),
	.mul_wreg_o(mul_wreg_o),
	.mul_valid(mul_valid),
	
	//////////mem_fu///////
	.mem_aluop_o(mem_aluop_o),
	.mem_alusel_o(mem_alusel_o),
	.mem_reg1_o(mem_reg1_o),
	.mem_reg2_o(mem_reg2_o),
	 .mem_wd_o(mem_wd_o),
	.mem_wreg_o(mem_wreg_o),
	.mem_valid(mem_valid),
	.inst(inst),
	
	//jump_branch
	.link_addr(link_addr_o),
	
	.branch_addr(branch_addr),
	.next_in_delaysolt(next_in_delaysolt),
	.branch_flag(branch_flag),
	
	.buffer_flush(buffer_flush)
    );
    
    Regfile Regfile(
        .rest(rst),
    .clk(clk),
    //д�ź�1
    .waddr1(waddr1),
    .wdata1(wdata1),
    .we1(we1),
    //д�ź�2
    .waddr2(waddr2),
    .wdata2(wdata2),
    .we2(we2),
    //���źţ���Ϊ����I/O����������Ĵ�����ֵ
    .raddr1(raddr1),
    .re1(re1),
    .raddr2(raddr2),
    .re2(re2),
    .raddr3(raddr3),
    .re3(re3),
    .raddr4(raddr4),
    .re4(re4),
    
    .data1(data1),
    .data2(data2),
    .data3(data3),
    .data4(data4)
    );
    id_alu_exe id_alu_exe(
        .clk(clk),
    .rest(rst),
    .aluop_i(alu_aluop_i),
	.alusel_i(alu_alusel_i),
	.reg1_i(alu_reg1_i),
	.reg2_i(alu_reg2_i),
	.wd_i(alu_wd_i),
	.wreg_i(alu_wreg_i),
    .stop(stop),
    .fu_valid(alu_valid),
   // input wire id_is_in_delayslot,
   // input wire[`RegBus] id_link_addr,
   // input wire next_in_delayslot,
   // input wire[`RegBus] inst_i,
    .link_addr_i(link_addr_o),
    .link_addr_o(link_addr_alu),
    .flush(flush),

    
    .aluop_o(aluop_i),
	.alusel_o(alusel_i),
	.reg1_o(reg1_i),
	.reg2_o(reg2_i),
	.wd_o(wd_i),
	.wreg_o(wreg_i)
	/*
	.next_in_delaysolt(next_in_delaysolt),
	.is_in_delaysolt(is_in_delaysolt),
	.buffer_flush_i(buffer_flush_o),
	.buffer_flush_o(buffer_flush)*/
	//output reg ex_is_in_delayslot,
	//output reg [`RegBus]ex_link_addr,
	//output reg is_in_delayslot_o,
	//output reg[`RegBus] inst_o,
    );
    alu fu_alu(
        .rest(rst),//ʹ���ź�
    
    //id_exe�� ������ź�
    .aluop_i(aluop_i),
	.alusel_i(alusel_i),
	.reg1_i(reg1_i),
	.reg2_i(reg2_i),
	.wd_i(wd_i),
	.wreg_i(wreg_i),
	
	//input wire[`RegBus] inst_i,
	
	.link_addr(link_addr_alu),
	//input wire [`RegBus] link_addr,//д�ؼĴ����ĵ�ַ
	
	//ִ�н��
	.wd_o(ex_wd),
	.wreg_o(ex_wreg),
	.wdata_o(ex_wdata)
    
    );
    
    alu_fu_ex_mem alu_fu_ex_mem(
        .clk(clk),
        .rest(rst),
        .ex_wd(ex_wd),
	    .ex_wreg(ex_wreg),
	    .ex_wdata(ex_wdata), 
	
        .stop(stop),
        .flush(flush),

        .mem_wd(mem_wd),
	   .mem_wreg(mem_wreg),
	   .mem_wdata(mem_wdata)
    );
    
    alu_fu_mem_wb alu_fu_mem_wb(
        .clk(clk),
        .rest(rst),
        .mem_wd_o(mem_wd),
	    .mem_wreg_o(mem_wreg),
	    .mem_wdata_o(mem_wdata),
	//
	
	    .stop(stop),

	    .flush(flush),
	
	    .wb_wd_o(alu_wb_wd_i),//�Ĵ�����
	    .wb_wreg_o(alu_wb_wreg_i),//дʹ��
	    .wb_wdata_o(alu_wb_wdata_i)
    );
    mul_fu_reg mul_fu_reg(
        .clk(clk),
        .rst(rst),
        .aluop_i(mul_aluop_o),
        
	    .reg1_i(mul_reg1_o),
	    .reg2_i(mul_reg2_o),
	    .wd_i(mul_wd_o),
	    .wreg_i(mul_wreg_o),
        .stop(stop),
       .fu_valid(mul_valid),//�Ƿ�ʹ�����fu
   // input wire id_is_in_delayslot,
   // input wire[`RegBus] id_link_addr,
   // input wire next_in_delayslot,
   // input wire[`RegBus] inst_i,
    
    .flush(flush),
    .is_busy(is_busy),
    .mul_fu_state(mul_pipline_state),


	.reg1_o(A),
	.reg2_o(B),
	.wd_o(mul_wb_wd_i),
	.wreg_o(mul_wb_wreg_i),
	.wb_valid(wb_valid),//ָʾ�˷��Ƿ����
    .wdata_o(mul_wb_wdata_i),
    .p(p)
    );
    mult_gen_0 mult(
         .CLK(clk),
         .A(A),
        .B(B),
        .SCLR(rst),
        .P(p)
    );
    
    wb_mux wb_mux(
        .rst(rst),
    //alu_fu���д��
    .alu_wb_wd_o(alu_wb_wd_i),
	.alu_wb_wreg_o(alu_wb_wreg_i),
	.alu_wb_wdata_o(alu_wb_wdata_i),
	//mul_fu���д��
	.mul_data_valid(wb_valid),
	.mul_wb_wd_o(mul_wb_wd_i),
	.mul_wb_wreg_o(mul_wb_wreg_i),
	.mul_wb_wdata_o(mul_wb_wdata_i), 
	//mem_fu���д��
	.mem_data_valid(m_wb_valid),
	.mem_wb_wd_o(wb_wd),
	.mem_wb_wreg_o(wb_wreg),
	.mem_wb_wdata_o(wb_data),
	
	.wd1_o(waddr1),
	.wreg1_o(we1),
	.wdata1_o(wdata1),  
	
	.wd2_o(waddr2),
	.wreg2_o(we2),
	.wdata2_o(wdata2)
    );

    mem_fu_ex mem_fu_ex(
        .clk(clk),
        .rst(rst),
    
    .inst(inst),//�ô�ָ��
    .aluop_i(mem_aluop_o),//������
	.reg1_i(mem_reg1_o),
	.reg2_i(mem_reg2_o),//�洢ָ���д������
	.wd_i(mem_wd_o),//д�Ĵ�����
	.wreg_i(mem_wreg_o),//дʹ��
	.fu_valid(mem_valid),//mem_fu�Ƿ�����
	
	.flush(flush),//��ˮ�߳�ˢ
	//mem_fu��״̬
    .is_busy(is_busy),
    //.mem_fu_state(mem_pipline_state),
    //��ˮ����ͣ
    .stop(stop),
	//��洢����Ԫ�Ľ����ź�
	.data_req_i(ram_data_req_i), //CPU�������ݣ���λ��Ч
    .virtual_addr(ram_virtual_addr),//�����ַ����ʵ��TLB
    .write_data(ram_write_data),//д����
    .cpu_we(ram_cpu_we),//��д�źţ�1λд��0λ��
	.sel(sel),//�ֽ�ʹ���ź�
	.mem_data_i(mem_data_i),//�洢��Ԫ���������
	.mem_ready(ready),
	
	//��wb
	.wb_wd(mem_wb_wd),
	.wb_wreg(mem_wb_wreg),
	.wb_data(mem_wb_data),
	.wb_valid(mem_wb_valid)
    
    );
    mem_fu_wb mem_fu_wb(
    .clk(clk),
    .rst(rst),
    .stop(stop),
    .flush(flush),
    
    .wb_valid_i(mem_wb_valid),
    .wb_wd_i(mem_wb_wd),
	.wb_wreg_i(mem_wb_wreg),
	.wb_data_i(mem_wb_data),
	
    .wb_wd(wb_wd),
	.wb_wreg(wb_wreg),
	.wb_data(wb_data),
	.wb_valid(m_wb_valid)
    
    );
    
    ctrl CTRL(
        .clk(clk),
         .rst(rst),
         .stop_from_if(stop_from_if),//ȡָ����Ҫ����һ������
         .stop_from_id(),
        .stop_from_exe(),
        .stop_from_mem(cache_stop),
        .flush(flush),
        .inst_flush(inst_flush),
        .branch_flag(branch_flag),
        
        .is_busy(is_busy),//mem��mul��ˮ���Ƿ�æ

        .mem_req(mem_req),
        .mul_req(mul_req),
        .cache_data_valid(ready),
        
        .is_rom(is_rom_data),
        .relive(relive),
        .stop(stop)
    );
    
endmodule
