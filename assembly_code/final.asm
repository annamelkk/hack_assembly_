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

// if (y < 0 || y >= 256)
@R0
D=M
// goto INVALID
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

// if (x1 > x2)
@R1
D=M
@R2
D=D-M
@NO_SWAP
D;JLE

// temp = x1
@R2
D=M	// D = x2
@temp
M=D	// temp = x2

// x1 = x2
@R1
D=M	// D = x1
@R2
M=D	// x2 = x1

// x2 = temp
@temp
D=M	// D = temp
@R1
M=D	// x1 = temp

(NO_SWAP)

// start_word_address = SCREEN + 32*y + x1/16
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
// after division R1 = x1 mod 16 (start_bit position)
// R8 = x1 / 16

@R8
D=M
@R4
M=D+M
@SCREEN
D=A
@R4
M=D+M	// address of start word SCREEN + 32y + x1/16

// end_word_address = SCREEN + 32*y + x2/16
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
// after division R2 = x2 mod 16 (end_bit position)
// R9 = x2 / 16

@R9
D=M
@R5
M=D+M
@SCREEN
D=A
@R5
M=D+M	// address of end word SCREEN + 32y + x2/16

// Generate powers of 2 in R13-R28 for bit masking
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

// diff = end_word_address - start_word_address
@R5
D=M
@R4
D=D-M	// D = end - start

// if (diff == 0)
// goto CASE_SINGLE_WORD
@CASE_SINGLE_WORD
D;JEQ

// else if (diff == 1)
@1
D=D-A
// goto CASE_TWO_WORDS
@CASE_TWO_WORDS
D;JEQ	// if D-1=0 then two adjacent words

// else
// goto CASE_MULTIPLE_WORDS
@CASE_MULTIPLE_WORDS
0;JMP


// CASE_SINGLE_WORD:
(CASE_SINGLE_WORD)
	// create left mask bits from start_bit to 15
	// left_mask = ~(2^start_bit - 1)
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
	
	// create right mask - bits from 0 to end_bit
	// right_mask = 2^(end_bit + 1) - 1
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
	
	// Combine masks
	// combined_mask = left_mask & right_mask
	@R7
	D=D&M   // D = left_mask & right_mask
	@R7
	M=D     // R7 = combined_mask
	
	// if (color == 0)
	@R3
	D=M
	@SINGLE_BLACK
	D;JNE   // if color != 0, draw black
	
	// white
	// *start_word_address = *start_word_address & ~combined_mask
	@R7
	D=!M    // invert mask
	@R4
	A=M
	D=M
	M=D&M   // clear bits
	// goto END_DRAW
	@END_DRAW
	0;JMP
	
	(SINGLE_BLACK)
	// else black
	// *start_word_address = *start_word_address | combined_mask
	@R7
	D=M
	@R4
	A=M
	D=D|M
	M=D   // set bits
	// goto END_DRAW
	@END_DRAW
	0;JMP

// CASE_TWO_WORDS:
(CASE_TWO_WORDS)
	// handle left word - bits from start_bit to 15
	// left_mask = ~(2^start_bit - 1)
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
	
	// if (color == 0)
	@R3
	D=M
	@TWO_LEFT_BLACK
	D;JNE
	
	// white
	// *start_word_address = *start_word_address & ~left_mask
	@R7
	D=!M
	@R4
	A=M
	D=D&M
	M=D
	@TWO_RIGHT
	0;JMP
	
	(TWO_LEFT_BLACK)
	// else black
	// *start_word_address = *start_word_address | left_mask
	@R7
	D=M
	@R4
	A=M
	D=D|M
	M=D
	
	(TWO_RIGHT)
	// handle right word - bits from 0 to end_bit
	// right_mask = 2^(end_bit + 1) - 1
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
	
	// if (color == 0)
	@R3
	D=M
	@TWO_RIGHT_BLACK
	D;JNE
	
	// white
	// *end_word_address = *end_word_address & ~right_mask
	@R7
	D=!M
	@R5
	A=M
	D=D&M
	M=D
	// goto END_DRAW
	@END_DRAW
	0;JMP
	
	(TWO_RIGHT_BLACK)
	// else black
	// *end_word_address = *end_word_address | right_mask
	@R7
	D=M
	@R5
	A=M
	D=D|M
	M=D
	// goto END_DRAW
	@END_DRAW
	0;JMP

// CASE_MULTIPLE_WORDS:
(CASE_MULTIPLE_WORDS)
	// handle left edge word - bits from start_bit to 15
	// left_mask = ~(2^start_bit - 1)
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
	
	// if (color == 0)
	@R3
	D=M
	@MULTI_LEFT_BLACK
	D;JNE
	
	// white
	// *start_word_address = *start_word_address & ~left_mask
	@R7
	D=!M
	@R4
	A=M
	D=D&M
	M=D
	@MULTI_MIDDLE
	0;JMP
	
	(MULTI_LEFT_BLACK)
	// else black
	// *start_word_address = *start_word_address | left_mask
	@R7
	D=M
	@R4
	A=M
	D=D|M
	M=D

	(MULTI_MIDDLE)
	// fill middle words
	// current_address = start_word_address + 1
	@R4
	D=M 
	D=D+1
	@R6
	M=D

	// while (current_address < end_word_address)
	(FILL_LOOP)
		@R6
		D=M
		@R5
		D=D-M
		@FILL_END
		D;JGE

		// if (color == 0)
		@R3
		D=M
		@FILL_BLACK
		D;JNE
		
		// white
		// *current_address = 0x0000
		@R6
		A=M
		M=0
		@FILL_CONTINUE
		0;JMP
		
		(FILL_BLACK)
		// else black
		// *current_address = 0xFFFF
		@R6
		A=M
		M=-1
		
		(FILL_CONTINUE)
		// current_address++
		@R6
		D=M
		D=D+1
		M=D
		@FILL_LOOP
		0;JMP
	(FILL_END)

	// handle right edge word - bits from 0 to end_bit
	// right_mask = 2^(end_bit + 1) - 1
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
	
	// if (color == 0)
	@R3
	D=M
	@MULTI_RIGHT_BLACK
	D;JNE
	
	// white
	// *end_word_address = *end_word_address & ~right_mask
	@R7
	D=!M
	@R5
	A=M
	D=D&M
	M=D
	// goto END_DRAW
	@END_DRAW
	0;JMP
	
	(MULTI_RIGHT_BLACK)
	// else black
	// *end_word_address = *end_word_address | right_mask
	@R7
	D=M
	@R5
	A=M
	D=D|M
	M=D

// END_DRAW:
// INVALID:
// goto INVALID
(END_DRAW)
(INVALID)
@INVALID
0;JMP
