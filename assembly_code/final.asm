// R0: y
// R1: x1 → becomes x1 mod 16 (start_bit)
// R2: x2 → becomes x2 mod 16 (end_bit)
// R3: color
// R4: start_word_address
// R5: end_word_address
// R6: loop counter/current address
// R7: temp/mask
// R8: x1 / 16 (quotient)
// R9: x2 / 16 (quotient)
// R10: constant 16
// R11: temp for swap
// R12: another loop counter we used for building masks
// R13-R28 powers of 2 (2^0 through 2^15) 

// validating y
@R0
D=M
@INVALID
D;JLT	// y < 0
@256
D=D-A
@INVALID
D;JGE	// y>=256

// storing 16 for later
@16
D=A
@R10
M=D

// check if x1 > x2
@R1
D=M
@R2
D=D-M
@NO_SWAP
D;JLE

// swap using temp variable
@R2
D=M	// D = x2
@temp
M=D	// temp = x2

@R1
D=M	// D = x1
@R2
M=D	// x2 = x1

@temp
D=M	// D = temp
@R1
M=D	// x1 = temp

(NO_SWAP)

// for start_word_address = 32y + x1/16 + SCREEN
@R0
D=M
@R0
M=D+M	// y = y*2
D=M
@R0
M=D+M	// y = y*2
D=M
@R0
M=D+M	// y = y*2
D=M
@R0
M=D+M	// y = y*2
D=M
@R0
M=D+M	// y = y*2
D=M
@R4
M=D	// R4 = y * 32

// dividing x1 by 16
@R8
M=0	// initializing quotient

(DIV_X1_LOOP)
	@R1
	D=M
	@16
	D=D-A	// D = x1 - 16
	@DIV_X1_END
	D;JLT	// if negative get out of the loop

	@R1
	M=D	// x1 = x1 - 16
	@R8
	M=M+1	// quotient++
	@DIV_X1_LOOP
	0;JMP
(DIV_X1_END)
//R1 = x1 mod 16
//R8 = x1 / 16

@R8
D=M
@R4
M=D+M
@SCREEN
D=A
@R4
M=D+M	// address of start word SCREEN + 32y + x1/16

// for end word address
@R0
D=M
@R5
M=D	// R5 = y * 32

// dividing x2 by 16
@R9
M=0	// initializing quotient

(DIV_X2_LOOP)
	@R2
	D=M
	@16
	D=D-A	// D = x2 - 16
	@DIV_X2_END
	D;JLT	// if negative get out of the loop

	@R2
	M=D	// x2 = x2 - 16
	@R9
	M=M+1	// quotient++
	@DIV_X2_LOOP
	0;JMP
(DIV_X2_END)
//R2 = x2 mod 16
//R9 = x2 / 16

@R9
D=M
@R5
M=D+M
@SCREEN
D=A
@R5
M=D+M	// address of end word SCREEN + 32y + x2/16

// before checking for each case and masking we need a table if powers of twos, since the
// hack assembly doesn't support bit shifing ((((

// generate powers of 2 in R13-R28
@1
D=A
@R13
M=D

@14	// loop 14 more times
D=A
@R12
M=D	// counter

@13
D=A
@R11
M=D	// current register index

(GEN_POWERS)

	// aka pointers!

	@R11
	A=M	// A = register index
	D=M	// value at address stored in A
	@R11
	D=M+1	// increment index
	M=D
	A=M	// A = next register index
	M=D
	D=M
	M=D+M	// M = D*2

	@R12
	D=M
	D=D-1
	M=D
	@GEN_POWERS
	D;JGT

// check if x1 and x2 are in the same word
@R5
D=M
@R4
D=D-M	// D = end - start

@CASE_SINGLE_WORD
D;JEQ

@1
D=D-A
@CASE_TWO_WORDS
D;JEQ	// if D-1=0 then two adjacent words

// else multiple words
@CASE_MULTIPLE_WORDS
0;JMP


// checked, now functions

(CASE_SINGLE_WORD)
	// Both x1 and x2 in same word
	// Create left mask (bits x1 to 15)
	@R1
	D=M     // D = start_bit
	@R11
	M=D     // R11 = start_bit
	@13
	D=A     // D = 13
	@R11
	D=D+M   // D = 13 + start_bit
	A=D     // A = address of register
	D=M     // D = 2^start_bit
	D=D-1   // D = 2^start_bit - 1
	D=!D    // D = mask with bits [start_bit..15] set
	@R7
	M=D     // R7 = left_mask
	
	// Create right mask (bits 0 to x2)
	@R2
	D=M     // D = end_bit
	D=D+1   // D = end_bit + 1
	@R11
	M=D     // R11 = end_bit + 1
	@13
	D=A     // D = 13
	@R11
	D=D+M   // D = 13 + (end_bit+1)
	A=D     // A = address of register
	D=M     // D = 2^(end_bit+1)
	D=D-1   // D = mask with bits [0..end_bit] set
	
	// Combine masks with AND
	@R7
	D=D&M   // D = left_mask & right_mask
	@R7
	M=D     // R7 = combined_mask
	
	// Apply color
	@R3
	D=M
	@SINGLE_BLACK
	D;JNE   // if color != 0, draw black
	
	// White: clear the masked bits
	@R7
	D=!M    // invert mask
	@R4
	A=M
	D=M
	M=D&M   // clear bits
	@END_DRAW
	0;JMP
	
	(SINGLE_BLACK)
	@R7
	D=M
	@R4
	A=M
	D=D|M
	M=D   // set bits
	@END_DRAW
	0;JMP

(CASE_TWO_WORDS)
	// x1 and x2 in adjacent words
	
	// Left word: bits from x1 to 15
	@R1
	D=M     // D = start_bit
	@R11
	M=D
	@13
	D=A
	@R11
	D=D+M
	A=D
	D=M     // D = 2^start_bit
	D=D-1
	D=!D    // left_mask
	@R7
	M=D
	
	@R3
	D=M
	@TWO_LEFT_BLACK
	D;JNE
	
	@R7
	D=!M
	@R4
	A=M
	D=D&M
	M=D
	@TWO_RIGHT
	0;JMP
	
	(TWO_LEFT_BLACK)
	@R7
	D=M
	@R4
	A=M
	D=D|M
	M=D
	
	(TWO_RIGHT)
	// Right word: bits from 0 to x2
	@R2
	D=M
	D=D+1
	@R11
	M=D
	@13
	D=A
	@R11
	D=D+M
	A=D
	D=M
	D=D-1   // right_mask
	@R7
	M=D
	
	@R3
	D=M
	@TWO_RIGHT_BLACK
	D;JNE
	
	@R7
	D=!M
	@R5
	A=M
	D=D&M
	M=D
	@END_DRAW
	0;JMP
	
	(TWO_RIGHT_BLACK)
	@R7
	D=M
	@R5
	A=M
	D=D|M
	M=D
	@END_DRAW
	0;JMP

(CASE_MULTIPLE_WORDS)
	// Left edge mask (start word)
	@R1
	D=M
	@R11
	M=D
	@13
	D=A
	@R11
	D=D+M
	A=D
	D=M
	D=D-1
	D=!D
	@R7
	M=D
	
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
	// Fill middle words
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

	// Right edge mask (end word)
	@R2
	D=M
	D=D+1
	@R11
	M=D
	@13
	D=A
	@R11
	D=D+M
	A=D
	D=M
	D=D-1
	@R7
	M=D
	
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

(END_DRAW)
(INVALID)
@INVALID
0;JMP
