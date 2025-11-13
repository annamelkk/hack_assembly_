// R0: y
// R1: x1 → becomes x1 mod 16 (start_bit)
// R2: x2 → becomes x2 mod 16 (end_bit)
// R3: color
// R4: start_word_address
// R5: end_word_address
// R6: loop counter/general purpose temp
// R7: mask/temp

// Validate y
@R0
D=M
@INVALID
D;JLT	// y < 0
@256
D=D-A
@INVALID
D;JGE	// y >= 256

// Check if x1 > x2, swap if needed
@R1
D=M
@R2
D=D-M
@NO_SWAP
D;JLE

// Swap x1 and x2
@R1
D=M
@R6
M=D	// temp = x1
@R2
D=M
@R1
M=D	// x1 = x2
@R6
D=M
@R2
M=D	// x2 = temp

(NO_SWAP)

// calculate start_word_address = SCREEN + 32*y + x1/16
@R0
D=M
@R4
M=D
D=D+M	// D = 2*y
M=D
D=D+M	// D = 4*y
M=D
D=D+M	// D = 8*y
M=D
D=D+M	// D = 16*y
M=D
D=D+M	// D = 32*y
M=D	// R4 = y * 32

// divide x1 by 16, keep quotient in R4, remainder in R1
@R6
M=0	// quotient counter

(DIV_X1_LOOP)
	@R1
	D=M
	@16
	D=D-A
	@DIV_X1_END
	D;JLT
	@R1
	M=D	// x1 = x1 - 16
	@R6
	D=M
	D=D+1
	M=D	// quotient++
	@DIV_X1_LOOP
	0;JMP
(DIV_X1_END)
// R1 now has x1 mod 16
// R6 has x1 / 16

@R6
D=M
@R4
D=D+M
M=D	// R4 = 32*y + x1/16
@SCREEN
D=A
@R4
D=D+M
M=D	// R4 = SCREEN + 32*y + x1/16

// calculate end_word_address = SCREEN + 32*y + x2/16
@R0
D=M
@R5
M=D
D=D+M	// D = 2*y
M=D
D=D+M	// D = 4*y
M=D
D=D+M	// D = 8*y
M=D
D=D+M	// D = 16*y
M=D
D=D+M	// D = 32*y
M=D	// R5 = y * 32

// Divide x2 by 16
@R6
M=0	// quotient counter

(DIV_X2_LOOP)
	@R2
	D=M
	@16
	D=D-A
	@DIV_X2_END
	D;JLT
	@R2
	M=D	// x2 = x2 - 16
	@R6
	D=M
	D=D+1
	M=D	// quotient++
	@DIV_X2_LOOP
	0;JMP
(DIV_X2_END)
// R2 now has x2 mod 16
// R6 has x2 / 16

@R6
D=M
@R5
D=D+M
M=D	// R5 = 32*y + x2/16
@SCREEN
D=A
@R5
D=D+M
M=D	// R5 = SCREEN + 32*y + x2/16

// determine case based on word addresses
@R5
D=M
@R4
D=D-M	// D = end_address - start_address

@CASE_SINGLE_WORD
D;JEQ

@1
D=D-A
@CASE_TWO_WORDS
D;JEQ

@CASE_MULTIPLE_WORDS
0;JMP

// power of 2
// input R6 = N
// output: R7 = 2^N
(CALC_POWER)
	@1
	D=A
	@R7
	M=D	// R7 = 1
	@R6
	D=M
	@CALC_POWER_END
	D;JEQ	// if N=0, return 1
	
	(CALC_POWER_LOOP)
		@R7
		D=M
		D=D+M	// D = R7 * 2
		@R6
		D=M
		D=D-1
		M=D	// N--
		@CALC_POWER_LOOP
		D;JGT
	
	(CALC_POWER_END)
	@R6
	A=M
	0;JMP	// return to caller (stored in R6 after power calc)

// SINGLE WORD
(CASE_SINGLE_WORD)
	// create left mask (bits x1 to 15)
	@R1
	D=M
	@R6
	M=D	// R6 = start_bit
	@CALC_POWER_SINGLE_LEFT
	0;JMP
	
	(CALC_POWER_SINGLE_LEFT_RETURN)
	// R7 = 2^start_bit
	D=M
	D=D-1	// D = 2^start_bit - 1
	D=!D	// D = left_mask
	@R4
	A=M
	D=D&M	// D = left_mask & current_word
	@R6
	M=D	// store in R6 temporarily
	
	// create right mask (bits 0 to x2)
	@R2
	D=M
	D=D+1	// D = end_bit + 1
	@R7
	M=D	// store for power calc
	@CALC_POWER_SINGLE_RIGHT
	0;JMP
	
	(CALC_POWER_SINGLE_RIGHT_RETURN)
	// R7 = 2^(end_bit+1)
	D=M
	D=D-1	// D = right_mask
	@R6
	D=D&M	// D = combined_mask & current_word
	@R6
	M=D	// R6 = final mask
	
	// Apply color
	@R3
	D=M
	@SINGLE_BLACK
	D;JNE
	
	// White: clear bits
	@R6
	D=!M
	@R4
	A=M
	D=D&M
	M=D
	@END_DRAW
	0;JMP
	
	(SINGLE_BLACK)
	@R6
	D=M
	@R4
	A=M
	D=D|M
	M=D
	@END_DRAW
	0;JMP

// power calculation jumps for SINGLE_WORD
(CALC_POWER_SINGLE_LEFT)
	@1
	D=A
	@R7
	M=D
	@R6
	D=M
	@CALC_POWER_SINGLE_LEFT_RETURN
	D;JEQ
	
	(LOOP_SINGLE_LEFT)
		@R7
		D=M
		M=D+M	// R7 = R7 * 2
		@R6
		D=M
		D=D-1
		M=D
		@LOOP_SINGLE_LEFT
		D;JGT
	@R7
	D=M
	@CALC_POWER_SINGLE_LEFT_RETURN
	0;JMP

(CALC_POWER_SINGLE_RIGHT)
	@1
	D=A
	@R6
	M=D
	@R7
	D=M
	@CALC_POWER_SINGLE_RIGHT_RETURN
	D;JEQ
	
	(LOOP_SINGLE_RIGHT)
		@R6
		D=M
		M=D+M	// R6 = R6 * 2
		@R7
		D=M
		D=D-1
		M=D
		@LOOP_SINGLE_RIGHT
		D;JGT
	@R6
	D=M
	@R7
	M=D
	@CALC_POWER_SINGLE_RIGHT_RETURN
	0;JMP

// TWO WORDS
(CASE_TWO_WORDS)
	// Left word mask
	@R1
	D=M
	@R6
	M=D
	@CALC_POWER_TWO_LEFT
	0;JMP
	
	(CALC_POWER_TWO_LEFT_RETURN)
	D=M
	D=D-1
	D=!D
	@R6
	M=D	// R6 = left_mask
	
	@R3
	D=M
	@TWO_LEFT_BLACK
	D;JNE
	
	@R6
	D=!M
	@R4
	A=M
	D=D&M
	M=D
	@TWO_RIGHT
	0;JMP
	
	(TWO_LEFT_BLACK)
	@R6
	D=M
	@R4
	A=M
	D=D|M
	M=D
	
	(TWO_RIGHT)
	// Right word mask
	@R2
	D=M
	D=D+1
	@R6
	M=D
	@CALC_POWER_TWO_RIGHT
	0;JMP
	
	(CALC_POWER_TWO_RIGHT_RETURN)
	D=M
	D=D-1
	@R6
	M=D	// R6 = right_mask
	
	@R3
	D=M
	@TWO_RIGHT_BLACK
	D;JNE
	
	@R6
	D=!M
	@R5
	A=M
	D=D&M
	M=D
	@END_DRAW
	0;JMP
	
	(TWO_RIGHT_BLACK)
	@R6
	D=M
	@R5
	A=M
	D=D|M
	M=D
	@END_DRAW
	0;JMP

(CALC_POWER_TWO_LEFT)
	@1
	D=A
	@R7
	M=D
	@R6
	D=M
	@CALC_POWER_TWO_LEFT_RETURN
	D;JEQ
	
	(LOOP_TWO_LEFT)
		@R7
		D=M
		M=D+M	// R7 = R7 * 2
		@R6
		D=M
		D=D-1
		M=D
		@LOOP_TWO_LEFT
		D;JGT
	@R7
	D=M
	@CALC_POWER_TWO_LEFT_RETURN
	0;JMP

(CALC_POWER_TWO_RIGHT)
	@1
	D=A
	@R7
	M=D
	@R6
	D=M
	@CALC_POWER_TWO_RIGHT_RETURN
	D;JEQ
	
	(LOOP_TWO_RIGHT)
		@R7
		D=M
		M=D+M	// R7 = R7 * 2
		@R6
		D=M
		D=D-1
		M=D
		@LOOP_TWO_RIGHT
		D;JGT
	@R7
	D=M
	@CALC_POWER_TWO_RIGHT_RETURN
	0;JMP

// MULTIPLE WORDS
(CASE_MULTIPLE_WORDS)
	// left edge
	@R1
	D=M
	@R6
	M=D
	@CALC_POWER_MULTI_LEFT
	0;JMP
	
	(CALC_POWER_MULTI_LEFT_RETURN)
	D=M
	D=D-1
	D=!D
	@R7
	M=D	// R7 = left_mask
	
	@R3
	D=M
	@MULTI_LEFT_BLACK
	D;JNE
	
	@R7
	D=!M
	@R4
	A=M
	D=D&M
	M=D
	@MULTI_MIDDLE
	0;JMP
	
	(MULTI_LEFT_BLACK)
	@R7
	D=M
	@R4
	A=M
	D=D|M
	M=D

	(MULTI_MIDDLE)
	// fill middle words
	@R4
	D=M
	D=D+1
	@R6
	M=D
	
	(FILL_LOOP)
		@R6
		D=M
		@R5
		D=D-M
		@FILL_END
		D;JGE

		@R3
		D=M
		@FILL_BLACK
		D;JNE
		
		@R6
		A=M
		M=0
		@FILL_CONTINUE
		0;JMP
		
		(FILL_BLACK)
		@R6
		A=M
		M=-1
		
		(FILL_CONTINUE)
		@R6
		D=M
		D=D+1
		M=D
		@FILL_LOOP
		0;JMP
	(FILL_END)

	// right edge
	@R2
	D=M
	D=D+1
	@R6
	M=D
	@CALC_POWER_MULTI_RIGHT
	0;JMP
	
	(CALC_POWER_MULTI_RIGHT_RETURN)
	D=M
	D=D-1
	@R7
	M=D	// R7 = right_mask
	
	@R3
	D=M
	@MULTI_RIGHT_BLACK
	D;JNE
	
	@R7
	D=!M
	@R5
	A=M
	D=D&M
	M=D
	@END_DRAW
	0;JMP
	
	(MULTI_RIGHT_BLACK)
	@R7
	D=M
	@R5
	A=M
	D=D|M
	M=D
	@END_DRAW
	0;JMP

(CALC_POWER_MULTI_LEFT)
	@1
	D=A
	@R7
	M=D
	@R6
	D=M
	@CALC_POWER_MULTI_LEFT_RETURN
	D;JEQ
	
	(LOOP_MULTI_LEFT)
		@R7
		D=M
		M=D+M	// R7 = R7 * 2
		@R6
		D=M
		D=D-1
		M=D
		@LOOP_MULTI_LEFT
		D;JGT
	@R7
	D=M
	@CALC_POWER_MULTI_LEFT_RETURN
	0;JMP

(CALC_POWER_MULTI_RIGHT)
	@1
	D=A
	@R7
	M=D
	@R6
	D=M
	@CALC_POWER_MULTI_RIGHT_RETURN
	D;JEQ
	
	(LOOP_MULTI_RIGHT)
		@R7
		D=M
		M=D+M	// R7 = R7 * 2
		@R6
		D=M
		D=D-1
		M=D
		@LOOP_MULTI_RIGHT
		D;JGT
	@R7
	D=M
	@CALC_POWER_MULTI_RIGHT_RETURN
	0;JMP

(END_DRAW)
(INVALID)
@INVALID
0;JMP
