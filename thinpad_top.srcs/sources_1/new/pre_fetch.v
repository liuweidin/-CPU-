`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/25 18:49:38
// Design Name: 
// Module Name: pre_fetch
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
`define Data_valid 1'b1
`define Data_invalid 1'b0
`include "defines.v"
module pre_fetch(
    input wire rst,
    input wire [`InstAddrBus] current_pc,//��ǰpc���
    input wire branch_flag,//��֧�ź�
    input wire [`InstAddrBus]acctual_pc,//��ָ֧��ִ�н��
    input wire is_single,//cache�Ƿ�ȡ������ָ��
    
    input wire inst_valid,//cache���ص������Ƿ���Ч
    input wire [5:0]stop,
    
    output reg [`InstAddrBus]npc
    );
    always @(*) begin 
        if(rst==`RstEnable) begin 
            npc=current_pc;
        end
        else begin 
            if(stop[0]==`Stop) begin 
                if(branch_flag==`Branch) begin 
                    npc=acctual_pc;
                end
                else begin 
                    npc=current_pc;
                end
                
            end
            else if(branch_flag==`Branch) begin //��֧����
                npc=acctual_pc;
            end
            else if(is_single==1'b1 && inst_valid==`Data_valid)begin 
                npc=current_pc+5'h4;
            end
            else if(is_single==1'b0 && inst_valid==`Data_valid)begin 
                npc=current_pc+5'h8;
            end
            else begin 
                npc=current_pc;
            end
        end
    end
    
    
    
endmodule
