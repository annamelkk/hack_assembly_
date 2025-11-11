// coord_num in R4, word1 in R5, bit1 in R6, word2 in R7, bit2 in R8
// where is coord num pookie??
@R4 // assuming here
D=M
@j
M=D

// if (coord_num == 1) goto POINT_FILL
@R4
D=M
D=D-1
@POINT_FILL
D;JEQ

(FILL_LEFT)
// word = word1
@R5
D=M
@word
M=D

// bit = bit1
@R6
D=M
@bit
M=D

@END_FILL_F
0;JMP

(FILL_RIGHT)
// word = word2
@R3
D=M
@word
M=D

//bit = bit2
@R4
D=M
@bit
M=D

(END_FILL_F)
// i = 0
@i
M=0

// mult = 1
@mult
M=1

(BIWISE_LOOP)
// if (i == bit) goto BITWISE_LOOP_END
@i
D=M
@bit
D=D-M
@BITWISE_LOOP_END
D;JEQ

//  M[word] = M[word] + mult (flipping bits)
@word
D=M
@addr
M=D
@mult
D=M
@addr
A=M
M=D+M

@mult
D=M
M=D+M

@i
M=M+1

@BITWISE_LOOP
0;JMP

(BITWISE_LOOP_END)
// j = j - 1
@j
M=M-1

(END_FILL_END)
// if (j == 1) goto FILL_RIGHT
@j
D=M
D=D-1
@FILL_RIGHT
D;JEQ

@END
0;JMP

(POINT_FILL)
// i = 0
@i
M=0

//M[word1] = 1
@R5
D=M
@addr
M=D
@addr
A=M
M=1

(POINT_LOOP)
// if (i == bit1) goto POINT_END
@i
D=M
@R2
D=D-M
@POINT_END
D;JEQ

// M[word1] = M[word1] + M[word1] (left shift)
@R1
D=M
@addr
M=D
@addr
A=M
D=M
M=D+M

// i = i + 1
@i
M=M+1

@POINT_LOOP
0;JMP

(POINT_END)


