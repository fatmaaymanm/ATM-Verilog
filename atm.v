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
    input LC,
	output reg [11:0] FinalBalance,
	output reg [11:0] Final_DstBalance,
	output reg [11:0] O1,
	output reg [11:0] O2,
	output reg [11:0] O3,
	output reg [11:0] O4,
	output reg [11:0] O5,
	output reg [11:0] O6,
	output reg [11:0] O7,
	output reg [11:0] O8,
	output reg [11:0] O9,
	output reg ValidPass,
	output reg BalanceChecked,
	output reg EnteredAmount,
	output reg InsertedCard,
	output reg FoundAccount,
	output reg PinEnter);

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
reg	VP, BC = 1'b0, EA = 1'b0, F, IC, PI; //ValidPass, BalanceCheck, EnteredAmount, FoundAccount, InsertedCard, PinEnter
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
            #1
        if (IC) 
            next_state = S1;
        else
            next_state = S0;
        end

        S1: begin
            #1
        if (LC) 
            next_state = S2;
        else
            next_state = S1;
        end

        S2: begin
            #1
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
            #1
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
            #1
        if (Deposit_Amount > 0) begin
            EA = 1;
            next_state = S10;
        end
        else
            next_state = S5;
        end

        S6: begin
            #1
        if (WithDraw_Amount > 0) 
            next_state = S12;
        else
            next_state = S6;
        end

        S7: begin
            #1
        balance <= database[index1][1];
        next_state = S11;
        end

        S8: begin
            #1
        if (F && Transfer_Amount > 0) 
            next_state = S12;
        else
            next_state = S8;
        end

        S9: begin
            #1
            $display("You exited the ATM!");
            next_state = S0;
        end

        S10: begin
            #1
        if ((Deposit_Amount > 0) && EA) 
            begin
            balance <= database[index1][1] + Deposit_Amount;
            database[index1][1] <= balance;
            $writememh("atm_database.csv", database);
            next_state = S11;
            end     
        else if (WithDraw_Amount > 0 && BC) begin
            balance <= database[index1][1] - WithDraw_Amount;
            database[index1][1] <= balance;
            $writememh("atm_database.csv", database);
            next_state = S13;
            end
        else if (Transfer_Amount > 0 && BC) begin
            balance <= database[index1][1] - Transfer_Amount;
            database[index1][1] <= balance;
            dst_balance <= database[index2][1] + Transfer_Amount;
            database[index2][1] <= dst_balance;
            $writememh("atm_database.csv", database);
            next_state = S14;
            end
        else
            next_state = S4;

        end

        S11: begin
            #1
        $display("Transaction has been successful! Current Balance is %d", balance);
        next_state = S4;
        end
        
        S12: begin
            #1
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
            #1
            $display("Withdraw has been successful! Current Balance is %d", balance);
            next_state = S4;
        end       
        

        S14: begin
            #1
            $display("Transfer has been successful! Current Balance is %d", balance);
            next_state = S4;
        end

        S15: begin
            #1
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
        S0: begin
             InsertedCard <= IC;
             O1 <= database[0][0];
             O2 <= database[0][1];
             O3 <= database[0][2];
             O4 <= database[1][0];
             O5 <= database[1][1];
             O6 <= database[1][2];
             O7 <= database[2][0];
             O8 <= database[2][1];
             O9 <= database[2][2];
        end
        S2: PinEnter <= PI;
        S3: ValidPass <= VP;
        S5: EnteredAmount <= EA;
        S8: FoundAccount <= F;
        S11: FinalBalance <= balance;
        S12: BalanceChecked <= BC;  
        S13: FinalBalance <= balance;  
        S14: begin 
            FinalBalance <= balance;
            Final_DstBalance <= dst_balance;
            end  
        default: FinalBalance <= 0;
    endcase
end

    
endmodule 