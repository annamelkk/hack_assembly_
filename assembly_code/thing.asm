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
// R12:
// R13-R28 powers of 2 (2^0 through 2^15) 



// validating y
@R0
D=M
@INVALD
D;JLT	// y < 0
@256
D=D-A
@INVALID
D;JGE	// y>=256



// stroing 16 for later
@16
D=A
@R10
M=D


// check is x1 > x2
@R1
D=M
@R2
D=D-M
@NO_SWAP
D;JLE

// function for swap using temp variable
@R2
D=M	// D = x2
@temp
M=D	// temp = D = x2

@R1
D=M	// D = x1
@R2
M=D	// x2 = x1

@temp
D=M	// D = temp
@R1
M=D	// x1 = temp

(NO_SWAP)



//for start_word_address = 32y + x/16 + SCREEN
@R0
D=M
D=D+D
D=D+D
D=D+D
D=D+D
D=D+D
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
M=M+D
@SCREEN
D=A
@R4
M=M+D	// address of start word SCREEN + 32y + x/16





// for end word address
@R0
D=M
D=D+D
D=D+D
D=D+D
D=D+D
D=D+D
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
M=M+D
@SCREEN
D=A
@R5
M=M+D	// address of end word SCREEN + 32y + x/16




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
M=D	// current address = 13

(GEN_POWERS)
	@R11
	A=M	// A= value in R11
	D=M	// value at address stored in A 
	D=D+D	// D=D*2

	@R11
	M=M+1
	A=M
	M=D	// store next power

	@R12
	M=M-1
	D=M
	@GEN_POWERS
D;JGT

// we found all needed quantities now it is time to draw the functions, below are the cases we need to check

// check if x1 and x2 are in the same word
// partial words
// multiple lines (will be combination of filling full words and and the partials)


// calculating between the start and end
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

// else 3 words
@CASE_MULTIPLE_WORDS
0;JMP


(CASE_SINGLE_WORDS)
	// the code
@END_DRAW
0;JMP

(CASE_TWO_WORDS)
	// the code
@END_DRAW
0;JMP

(CASE_MULTIPLE_WORDS)
	// the code for left edge mask


	// fill middle words
	@R4
	D=M 
	D=D+1 // increment address by one
	@R6
	M=D	// we store in R6 the address count which starts at start+1
	
	(FILL_LOOP)
		@R6
		D=M
		@R5
		D=D-M	// check if we are before end
		@FILL_END
		D;JGE	// if current >= end, done

		@R6
		A=M	// "dereference"
		M=-1	// set everything to black

		@R6
		M=M+1	// increment counter
		0;JMP
	(FILL_END)

	// the code for right edge mask
@END_DRAW
0;JMP

(END_DRAW)

