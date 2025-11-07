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

// stroing 16 for later
@16
D=A
@R10
M=D
// storing swap temp
@temp
D=A
@R11
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
D=M // D = x2
@temp
M=D // temp = D = x2

@R1
D=M // D = x1
@R2
M=D // x2 = x1

@temp
D=M // D = temp
@R1
M=D // x1 = temp

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
M=D // R4 = y * 32

// dividing x1 by 16
@R8
M=0 // initializing quotient

(DIV_X1_LOOP)
	@R1
	D=M
	@16
	D=D-M // D = x1 - 16
	@DIV_X1_END
	D;JLT // if negative get out of the loop

	@R1
	M=D // x1 = x1 - 16
	@R8
	M=M+1 // quotient++
	@DIV_X1_LOOP
	0;JMP
(DIC_X1_END)
//R1 = x1 mod 16
//R8 = x1 / 16

@R8
D=M
@R4
M=M+D
@SCREEN
D=A
@R4
M=M+D // address of start word SCREEN + 32y + x/16





// for end word address
@R0
D=M
D=D+D
D=D+D
D=D+D
D=D+D
D=D+D
@R5
M=D // R5 = y * 32

// dividing x2 by 16
@R9
M=0 // initializing quotient

(DIV_X2_LOOP)
	@R2
	D=M
	@16
	D=D-M // D = x2 - 16
	@DIV_X2_END
	D;JLT // if negative get out of the loop

	@R2
	M=D // x2 = x2 - 16
	@R9
	M=M+1 // quotient++
	@DIV_X2_LOOP
	0;JMP
(DIC_X2_END)
//R2 = x2 mod 16
//R9 = x2 / 16

@R9
D=M
@R5
M=M+D
@SCREEN
D=A
@R5
M=M+D // address of end word SCREEN + 32y + x/16




// check if x1 and x2 are in the same word
// partial words
// multiple lines (will be combination of filling full words and and the partials)
