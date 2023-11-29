`timescale 1ns/1ps

`define true 1'b1
`define false 1'b0

module ATM (
    input clk,
	input rst,
	input [5:0] WithDraw_Amount,
	input [4:0] Deposit_Amount,
	input [2:0] Operation,
	output reg[7:0] FinalBalance, CB,
	input IC, LC, Ex, goMain
);

parameter S0 = 4'b0000, // WAITING
          S1 = 4'b0001, // LANGUAGE CHOICE
          S2 = 4'b0010, // REQUEST PIN
          S3 = 4'b0011, // AUTHORIZATION
          S4 = 4'b0100, // MAIN MENU
          S5 = 4'b0101, // DEPOSIT
          S6 = 4'b0110, // WITHDRAW
          S7 = 4'b0111, // BALANCE SERVICE
          S8 = 4'b1000, // TRANSFER
          S9 = 4'b1001, // EXIT
          S10 = 4'b1010, // CHANGE BALANCE
          S11 = 4'b1011, // RECEIPT
          S12 = 4'b1100, // CHECK BALANCE
          S13 = 4'b1101, // MONEY OUT
          S14 = 4'b1110, //  SUCCESS
          S15 = 4'b1111; // CLEAR


reg [3:0] current_state, next_state;
reg [2:0] op;
reg	VP, PI, BC = 1'b0, EA = 1'b0, GM = 1'b0; //ValidPass, BalanceCheck, EnteredAmount, goMain

always @(posedge clk or posedge rst)
	begin
		if (rst)
			begin
				current_state <= reset;
			end
		else	current_state <= next_state;
	end

always @(*) begin
    case (current_state)
        S0: if (IC) 
            next_state = S1;
            else
            next_state = S0;
        S1: if (LC) 
            next_state = S2;
            else
            next_state = S1;
        S2: if (PI) 
            next_state = S3;
            else
            next_state = S2;
        S3: if (VP)
            next_state = S4;
            else 
            next_state = S3;
        S4: #1
        op = Operation;
        case (op)
            3'b000:
            next_state = S5;
            3'b001:
            next_state = S6;
            3'b010:
            next_state = S7;
            3'b011:
            next_state = S8;
            3'b100:
            next_state = S9; 
            default: next_state = S4;
        endcase
        S5:
        default: 
    endcase
end

always @(*) begin
    case (current_state)
        :  
        default: 
    endcase
end

    
endmodule