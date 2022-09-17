`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/03 20:51:57
// Design Name: 
// Module Name: ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 555
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module ctrl(
input wire clk,
     input wire rst,
     input wire stop_from_if,//ȡָ����Ҫ����һ������
    input wire stop_from_id,
    input wire stop_from_exe,
    input wire stop_from_mem,
    output reg      flush,
    output reg inst_flush,
    
    input wire branch_flag,
    
    
    
    output reg[5:0] stop,
    
    output reg [1:0]is_busy,//mem��mul��ˮ���Ƿ�æ
    output reg [2:0]mul_pipline_state,//mem��mul��ˮ�ߵ�״̬��ָ��ִ�����
    
    
    input wire cache_data_valid,//cache����׼����ɣ�mem_stateֱ����ת������
    
    input wire mul_req,
    input wire mem_req,
    
    input wire relive,
    input wire is_rom//,
    
    //input wire mem_ready
    );
    
    
    always @(*) begin 
        if(rst==`RstEnable) begin 
            stop=6'b000000;
            flush = 1'b0;
            inst_flush=1'b0;
            
        end
        else begin  
        stop=6'b000000;
        if(stop_from_mem==`Stop) begin 
            
            if(is_rom==1'b1 && relive==1'b0) begin  //����rom
                stop=6'b011111;
                flush = 1'b0;
                inst_flush=1'b1;
            end
            else if(is_rom==1'b1 && relive==1'b1) begin //�ȴ�rom����
                stop=6'b001111;
                flush = 1'b0;
                inst_flush=1'b1;
            end
            else begin 
                stop=6'b011111;
                flush = 1'b0;
                inst_flush=1'b1;
            end
        end
        else if(stop_from_exe==`Stop) begin 
            stop=6'b001111;
            flush = 1'b0;
            inst_flush=1'b1;
            
        end
        else if(stop_from_if==`Stop) begin 
            stop=6'b000011;
            flush = 1'b0;
            inst_flush=1'b0;
            
        end
        else begin 
             stop=6'b000000;
            flush = 1'b0;
            inst_flush=1'b0;
            
        end
        if(branch_flag==`Branch) begin 
            inst_flush=1'b1;
            
        end
        end
    end
    //���ڼ�¼�˷���ô���ˮ��״̬
    always@(posedge clk) begin 
        if(rst==`RstEnable||flush==1'b1) begin 
            is_busy<=2'b00;
            mul_pipline_state<=3'b000;
            
        end
        else begin 
            if(stop_from_mem==`Stop) begin
                
            end 
            else if(mul_req||mem_req) begin 
                if(mul_req) begin 
                    is_busy[0]<=1'b1;
                    mul_pipline_state<=3'b100;
                end
                if(mem_req) begin 
                    is_busy[1]<=1'b1;
                    
                end
            end
            /*else if (cache_data_valid==`Data_valid) begin  
                mem_pipline_state<=3'b001;
            end*/
            else begin 
                mul_pipline_state<={1'b0,mul_pipline_state[2:1]};
                
            end
            if(cache_data_valid==`MEMready ) begin 
                is_busy[1]<=1'b0;
                
            end
            if(mul_pipline_state[0]==1'b1) begin 
                is_busy[0]<=1'b0;
            end
            
        end
    end
    
    
    
endmodule
