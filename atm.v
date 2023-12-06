`timescale 1ns/1ps

`define true 1'b1
`define false 1'b0

module ATM (
    input clk,
	input rst,
    input [11:0] Account_Number, 
    input [11:0] PIN, 
    input [11:0] Destination_Account,
	input [5:0] WithDraw_Amount,
    input [5:0] Transfer_Amount,
	input [4:0] Deposit_Amount,
	input [2:0] Operation,
	output reg [7:0] FinalBalance,
	input LC);

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
          S14 = 4'b1110, // SUCCESS
          S15 = 4'b1111, // CLEAR
          REG_WIDTH = 12,
          COL_DEPTH = 3;




reg [3:0] current_state, next_state;
reg [2:0] op;
reg	VP, BC = 1'b0, EA = 1'b0, F, IC, PI; //ValidPass, BalanceCheck, EnteredAmount, FoundAccount
reg [REG_WIDTH - 1:0] balance, dst_balance; 
reg [REG_WIDTH - 1:0] database [0 : COL_DEPTH - 1] [0:2];
reg [1:0] index1, index2;
integer i;


initial begin
    $readmemh("atm_database.csv", database);
end

initial begin
    for (i = 0 ; i < COL_DEPTH ; i = i + 1) begin
        if (Account_Number == database[i][0]) begin
            IC <= 1;
            index1 <= i;
            PI <= 1;
        end
    end
end

initial begin
    for (i = 0 ; i < COL_DEPTH ; i = i + 1) begin
        if (Destination_Account == database[i][0]) begin
            F <= 1;
            index2 <= i;
        end
    end
end



always @(posedge clk or posedge rst)
	begin
		if (rst)
			begin
				current_state <= S15;
			end
		else	current_state <= next_state;
	end

always @(*) begin
    case (current_state)

        S0: begin
        if (IC) 
            next_state = S1;
        else
            next_state = S0;
        end

        S1: begin
        if (LC) 
            next_state = S2;
        else
            next_state = S1;
        end

        S2: begin
        if (PI) begin
            if (PIN == database[index1][2]) begin
                VP <= 1;
            end
            next_state = S3;
        end
        else
            next_state = S2;
        end

        S3: begin
        if (VP)
            next_state = S4;
        else 
            next_state = S3;
        end

        S4: begin
        #1
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
        end

        S5: begin
        if (Deposit_Amount > 0) begin
            EA = 1;
            next_state = S10;
        end
        else
            next_state = S5;
        end

        S6: begin
        if (WithDraw_Amount > 0) 
            next_state = S12;
        else
            next_state = S6;
        end

        S7: begin
        balance <= database[index1][1];
        next_state = S11;
        end

        S8: begin
        if (F && Transfer_Amount > 0) 
            next_state = S12;
        else
            next_state = S8;
        end

        S9: begin
            $display("You exited the ATM!");
            next_state = S0;
        end

        S10: begin
        if ((Deposit_Amount > 0) && EA) 
            begin
            balance <= database[index1][1];
            FinalBalance <= balance + Deposit_Amount;
            balance <= FinalBalance;
            database[index1][1] <= balance;
            $writememh("atm_database.csv", database);
            next_state = S11;
            end     
        else if (WithDraw_Amount > 0 && BC) begin
            balance <= database[index1][1];
            FinalBalance <= balance - WithDraw_Amount;
            balance <= FinalBalance;
            database[index1][1] <= balance;
            $writememh("atm_database.csv", database);
            next_state = S13;
            end
        else if (Transfer_Amount > 0 && BC) begin
            balance <= database[index1][1];
            FinalBalance <= balance - Transfer_Amount;
            balance <= FinalBalance;
            database[index1][1] <= balance;
            dst_balance <= database[index2][1];
            dst_balance <= dst_balance + Transfer_Amount;
            database[index2][1] <= dst_balance;
            $writememh("atm_database.csv", database);
            next_state = S14;
            end
        else
            next_state = S4;

        end

        S11: begin
        $display("Transaction has been successful! Current Balance is %d", balance);
        next_state = S4;
        end
        
        S12: begin
        balance <= database[index1][1];
        if (WithDraw_Amount > 0) begin
            if(WithDraw_Amount > balance) begin
                BC = 0;
                next_state = S6;
            end
            else begin
                BC = 1;
                next_state = S10;
            end
        end

        if (Transfer_Amount > 0) begin
            if(Transfer_Amount > balance) begin
                BC = 0;
                next_state = S8;
            end
            else begin
                BC = 1;
                next_state = S10;
            end
        end
        end

        S13: begin
            $display("Withdraw has been successful! Current Balance is %d", balance);
            next_state = S4;
        end       
        

        S14: begin
            $display("Transfer has been successful! Current Balance is %d", balance);
            next_state = S4;
        end

        S15: begin
            op = 0;
            VP = 0;
            BC = 0;
            EA = 0;
            F = 0;
            balance = 0;
            dst_balance = 0;
            index1 = 0;
            index2 = 0;

            next_state = S0;
        end
        
        
        default: next_state = S0;
    endcase
end

always @(*) begin
    case (current_state)
        S11: FinalBalance <= balance;  
        S13: FinalBalance <= balance;  
        S14: FinalBalance <= balance;  
        default: FinalBalance <= 0;
    endcase
end

    
endmodule 