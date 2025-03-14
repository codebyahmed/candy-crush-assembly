; Made by: Hanan Noor Jahangiri & Ahmed Iqbal
; 20i-0719 & 20i-0447
; CS-G

include m1.lib
.model small
.stack 100h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.data
    ;STRUCT
        candiesOnBoard STRUCT
            xcoor dw 7 DUP ( 7 DUP (0) )
            ycoor dw 7 DUP ( 7 DUP (0) )
            candyid dw 7 DUP ( 7 DUP (0) )
        candiesOnBoard ends
        boardCandies candiesOnBoard<>
        ; 7x7 grid index val for DW
        ;_______________________
        ; 00 02 04 06 08 10 12
        ; 14 16 18 20 22 24 26  
        ; 28 30 32 34 36 38 40 
        ; 42 44 46 48 50 52 54
        ; 56 58 60 62 64 66 68
        ; 70 72 74 76 79 80 82
        ; 84 86 88 90 92 94 96

    ;Prompts
    w0String db "C A N D Y  C R U S H$"
    w1String db "Please Enter Your Name:$"
    w2String db "Press '1' To Start$"
    w3String db "Press '2' To Exit$"
    xB db ?
    yB db ?

    r0String db "R U L E S$"
    r1String db "> Swap 2 Adjacent Candies$"
    r2String db "> Make a row or column of at least$"
    r3String db "matching-random candies$"
    r4String db "> When Candies are matched, your$"
    r5String db "score Increases$"
    r6String db "> The game is split into 3 levels$"
    r7String db "> Each level must be completed $"
    r8String db "before the next$"
    r9String db "PRESS 'SPACE' TO CONTINUE$"

    ;name
    playerName db "123456789012345$" ;15 length

    scorePrompt db "Score:$"
    scorelvl1Prompt db "LVL-1:$"
    scorelvl2Prompt db "LVL-2:$"
    scorelvl3Prompt db "LVL-3:$"

    movesPrompt db "Moves:$"
    bombString db ": Bomb$"
    finprompt db "fin!$"
    explosionprompt db 'EXPLOSION', '$'
    dashesprompt db '-----------', '$'
    CRUSHINGprompt db "CRUSHING!$"
    lvlpassedprompt db "LEVEL PASSED$"
    tryagainprompt db " TRY AGAIN?$"
    lvlfailedprompt db "LEVEL FAILED$"
    escOrSpaceChoice db "SPACE TO Try again or ESC to Exit$"

    ;VARIABLES
    movesdone db 5
    index dw 0
    Xc dw 160
    Yc dw 100
    oldXc dw ?
    oldYc dw ?
    radius dw 8
    color db 0
    count dw 0
    counter dw 0
    count1 dw 0
    count2 dw 0
    count3 dw 0
    clearcount dw 0
    id dw 0
    selected1 dw 0
    selected2 dw 0
    candyswappedwithbomb dw 0

    score dw 0 
    scorelvl1 dw 0 
    scorelvl2 dw 0 
    scorelvl3 dw 0 
    highestscore dw 0 
    totalscore dw 0 

    newPoints dw 0
    ;used as bool
    broken dw 0
    dropped dw 0
    spawned dw 0
    bombswapped dw 0
    bombingrid dw 0
    currentlevel db 1
    tryagainchoice db 0
    ;ARRAYS

    ;FILE HANDING 
    fileName db 'score.txt', 0
    handle dw ?

    score1Str db "Level 1: "
    score2Str db "Level 2: "
    score3Str db "Level 3: "
    score4Str db "Highest Score: "
    scoreStr db "000"
    newLine db 13
    score1 dw 50
    score2 dw 30
    score3 dw 20
    score4 dw 50
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
main proc
    mov ax, @data
	mov ds, ax

;////////////////////
;MENU
;////////////////////

    ;initial display
    mov ah, 00h
	mov al, 13
	int 10h

    call drawBorders
    call welcome
    
    checkInput:
        mov ah, 07
        int 21h
        cmp al, 49
        je startGame
        cmp al, 50
        je endofgame
    jmp checkInput

    startGame:
        call clearScreen
        call drawBorders
        call printRules
        call checkSpace

startofLevel1:
    mov score, 0
;////////////////////
;LEVEL 1
;////////////////////
    mov currentlevel, 1
    ;initial display
    call clearScreen
    ;Drawing grid and setting candies at the start of the level
    call drawBorders
    call drawGrid
    call displayAndSetInitialCandies
    mov movesdone, 15
    .while(movesdone > 0)
        dec movesdone
        ;break candies 
        mov broken, 1
        .while(broken == 1 || dropped == 1)
            ;break the candies that are in combo
            breakCandies boardCandies
            mov ax, newPoints
            add score, ax
            ;drop candies from top to empty spaces down below
            mov dropped, 1
            .while(dropped == 1)
                call droppingdowncandies
            .ENDW
            ;spawn new candies in the empty spaces left at the top
            spawnNewCandies
            breakCandies boardCandies
            mov ax, newPoints
            add score, ax
        .ENDW

        ;show mouse
        call refreshscreen
        showMouse
        ;select two candies and then swap them
        call select2Candies
        call checkIfBombIsSwapped
        .IF(bombswapped == 0)
            swapcandies selected1, selected2
            call refreshscreen
            ;attempt to break with the newly swapped candies and if there is no break then swap back
            mov newPoints, 0
            breakCandies boardCandies
            mov ax, newPoints
            add score, ax
            .IF(broken == 0)
                swapcandies selected1, selected2
            .ENDIF
        .ELSEIF(bombswapped == 1)
            performBombExplosion
            displayBoomScreen
            mov ax, newPoints
            add score, ax
            call refreshscreen
            spawnNewCandies
            call refreshscreen
        .ENDIF
        ;repeat previous breaks and drops and spawning new candy after player's move
        mov broken, 1
        .while(broken == 1 || dropped == 1)
            ;break the candies that are in combo
            breakCandies boardCandies
            mov ax, newPoints
            add score, ax
            ;drop candies from top to empty spaces down below
            mov dropped, 1
            .while(dropped == 1)
                call droppingdowncandies
            .ENDW
            ;spawn new candies in the empty spaces left at the top
            spawnNewCandies
            breakCandies boardCandies
            mov ax, newPoints
            add score, ax
        .ENDW
        cmp score, 50
        jg level1complete
    .ENDW
level1complete:
    ;tally score
    mov AX, score
    mov scorelvl1, AX
    mov totalscore, AX
    .IF(Score < 50)
        levelfailedScreen
        .IF(tryagainchoice == 1)
            jmp startofLevel1
        .ELSEIF(tryagainchoice == 0)
            jmp endofgame
        .ENDIF
    .ELSEIF
        levelpassedScreen
        call checkSpace
    .ENDIF
    
startofLevel2:
    mov score, 0
;////////////////////
;LEVEL 2
;////////////////////
    mov currentlevel, 2
    ;initial display
    mov ah, 00h
	mov al, 13
	int 10h
    ;Drawing grid and setting candies at the start of the level
    call drawBorders
    call drawGrid
    call displayAndSetInitialCandies
    call changeGridForLevel2
    call clearScreen

    mov movesdone, 15
    .while(movesdone > 0)
        dec movesdone
        ;break candies 
        mov broken, 1
        .while(broken == 1 || dropped == 1)
            ;break the candies that are in combo
            breakCandies boardCandies
            mov ax, newPoints
            add score, ax
            ;drop candies from top to empty spaces down below
            mov dropped, 1
            .while(dropped == 1)
                call droppingdowncandies
            .ENDW
            ;spawn new candies in the empty spaces left at the top
            spawnNewCandies
            breakCandies boardCandies
            mov ax, newPoints
            add score, ax
        .ENDW

        ;show mouse
        call refreshscreen
        showMouse
        ;select two candies and then swap them
        call select2Candies
        call checkIfBombIsSwapped
        .IF(bombswapped == 0)
            swapcandies selected1, selected2
            call refreshscreen
            ;attempt to break with the newly swapped candies and if there is no break then swap back
            mov newPoints, 0
            breakCandies boardCandies
            mov ax, newPoints
            add score, ax
            .IF(broken == 0)
                swapcandies selected1, selected2
            .ENDIF
        .ELSEIF(bombswapped == 1)
            performBombExplosion
            displayBoomScreen
            mov ax, newPoints
            add score, ax
            call refreshscreen
            ;spawnNewCandies
            call refreshscreen
        .ENDIF
        cmp score, 30
        jg level2complete
    .ENDW
level2complete:
    ;tally score
    mov AX, score
    mov scorelvl2, AX
    add totalscore, AX
    .IF(Score < 30)
        levelfailedScreen
        .IF(tryagainchoice == 1)
            jmp startofLevel2
        .ELSEIF(tryagainchoice == 0)
            jmp endofgame
        .ENDIF
    .ELSEIF
        levelpassedScreen
        call checkSpace
    .ENDIF

startofLevel3:
    mov score, 0
;////////////////////
;LEVEL 3
;////////////////////
    mov currentlevel, 3

    ;initial display
    mov ah, 00h
	mov al, 13
	int 10h

    mov ah, 0Bh
    mov bh, 00
    mov bl, 0111b
    int 10h
    ;Drawing grid and setting candies at the start of the level
    call drawBorders
    call drawGrid
    call displayAndSetInitialCandies
    call changeGridForLevel3
    call clearScreen

    mov movesdone, 5
    .while(movesdone > 0)
        dec movesdone
        ;break candies 
        mov broken, 1
        .while(broken == 1 || dropped == 1)
            ;break the candies that are in combo
            breakCandies boardCandies
            mov ax, newPoints
            add score, ax
            ;spawn new candies in the empty spaces left at the top
            spawnNewCandies
            breakCandies boardCandies
            mov ax, newPoints
            add score, ax
        .ENDW

        ;show mouse
        call refreshscreen
        showMouse
        ;select two candies and then swap them
        call select2Candies
        call checkIfBombIsSwapped
        .IF(bombswapped == 0)
            swapcandies selected1, selected2
            call refreshscreen
            ;attempt to break with the newly swapped candies and if there is no break then swap back
            mov newPoints, 0
            breakCandies boardCandies
            mov ax, newPoints
            add score, ax
            .IF(broken == 0)
                swapcandies selected1, selected2
            .ENDIF
        .ELSEIF(bombswapped == 1)
            performBombExplosion
            displayBoomScreen
            mov ax, newPoints
            add score, ax
            call refreshscreen
            spawnNewCandies
            call refreshscreen
        .ENDIF
        ;repeat previous breaks and drops and spawning new candy after player's move
        mov broken, 1
        .while(broken == 1 || dropped == 1)
            ;break the candies that are in combo
            breakCandies boardCandies
            ;spawn new candies in the empty spaces left at the top
            spawnNewCandies
            breakCandies boardCandies
            mov ax, newPoints
            add score, ax
        .ENDW
        cmp score, 30
        jg level3complete
    .ENDW
level3complete:
    ;tally score
    mov AX, score
    mov scorelvl3, AX
    add totalscore, AX

    .IF(Score < 30)
        levelfailedScreen
        .IF(tryagainchoice == 1)
            jmp startofLevel3
        .ELSEIF(tryagainchoice == 0)
            jmp endofgame
        .ENDIF
    .ELSEIF
        levelpassedScreen
        call checkSpace
    .ENDIF
    
endofgame:
    mov AX, scorelvl1
    mov BX, scorelvl2
    mov CX, scorelvl3
    .IF(AX >= scorelvl2 && AX >= scorelvl3)
        mov highestscore, AX
    .ELSEIF(BX >= scorelvl1 && BX >= scorelvl3)
        mov highestscore, BX
    .ELSE
        mov highestscore, CX
    .ENDIF

    ;WRITE SCORES TO FILE
    call printScoreToFile

    finnishScreen
    mov AH,4Ch
	int 21h
main endp

;this function removes the possibility for a candy to spawn on specific locations of grid
changeGridForLevel2 proc
    mov count3, 0
    .WHILE(count3 <= 96)
        .IF(count3 == 0 || count3 == 6 || count3 == 12 || count3 == 14 || count3 == 26 || count3 == 42 || count3 == 54 || count3 == 70 || count3 == 82 || count3 == 84 || count3 == 90 || count3 == 96)
            mov DI, count3
            mov boardCandies.candyid[DI], -2
            breakBoxOnGrid DI
        .ENDIF
        add count3, 2
    .ENDW
    RET
changeGridForLevel2 endp

;this function removes the possibility for a candy to spawn on specific locations of grid
changeGridForLevel3 proc
    mov count3, 0
    .WHILE(count3 <= 96)
        .IF(count3 == 6 || count3 == 20 || count3 == 34 || count3 == 48 || count3 == 62 || count3 == 76 || count3 == 90 || count3 == 42 || count3 == 44 || count3 == 46 || count3 == 48 || count3 == 50 || count3 == 52  || count3 == 54)
            mov DI, count3
            mov boardCandies.candyid[DI], -2
            breakBoxOnGrid DI
        .ENDIF
        add count3, 2
    .ENDW
    RET
changeGridForLevel3 endp

;This function gives the user the option to select 2 grids on the screen
;the selected grids have to be valid points on the screen
; the second click also needs to be in one of the boxes right next to the first click
select2Candies proc
;SELECTING FIRST BOX
NOTselectedsuccessfully:
    showMouse
    repeat2:
        mov AX, 5
        mov BX, 0
        int 33h
        test AX, 1
    jz repeat2
    shr CX, 1 
    mov Xc, CX
    mov Yc, DX
    mov counter, 0
    mov count1, 0
    ;hide mouse
    mov AX, 02
    int 33h
    .WHILE(count1 < 49)
        mov SI, counter
        mov AX, boardCandies.xcoor[SI]
        mov BX, AX
        mov CX, boardCandies.ycoor[SI]
        mov DX, CX
        add AX, 13
        sub BX, 13
        add CX, 13
        sub DX, 13
        .IF(Xc < AX && Xc > BX && Yc < CX && Yc > DX && boardCandies.candyid[SI] != -2)
            mov CX, boardCandies.xcoor[SI]
            mov DX, boardCandies.ycoor[SI]
            mov selected1, SI
            mov Xc, CX
            mov Yc, DX
            selectSquareOnGrid Xc, Yc
            jmp selectedsuccessfully
        .ENDIF
    
        add counter, 2
        inc count1
    .ENDW
    jmp NOTselectedsuccessfully
selectedsuccessfully:

;SELECTING SECOND BOX
    addDelay 150
NOTselectedsuccessfully2:
    showMouse
    repeat3:
        mov AX, 5
        mov BX, 0
        int 33h
        test AX, 1
    jz repeat3
    shr CX, 1 
    mov Xc, CX
    mov Yc, DX
    mov counter, 0
    mov count1, 0
    mov AX, 02
    int 33h
    .WHILE(count1 < 49)
        mov SI, counter
        mov AX, boardCandies.xcoor[SI]
        mov BX, AX
        mov CX, boardCandies.ycoor[SI]
        mov DX, CX
        add AX, 13
        sub BX, 13
        add CX, 13
        sub DX, 13
        .IF(Xc < AX && Xc > BX && Yc < CX && Yc > DX && boardCandies.candyid[SI] != -2)
            mov selected2, SI
            jmp selectedsuccessfully2
        .ENDIF
    
        add counter, 2
        inc count1
    .ENDW
    jmp NOTselectedsuccessfully2
selectedsuccessfully2:
    mov AX, selected2
    add AX, 2
    mov BX, selected2
    sub BX, 2
    mov CX, selected2
    add CX, 14
    mov DX, selected2
    sub DX, 14
    .IF(selected1 != AX && selected1 != BX && selected1 != CX && selected1 != DX)
        jmp NOTselectedsuccessfully2
    .ENDIF
    mov SI, selected2
    mov CX, boardCandies.xcoor[SI]
    mov DX, boardCandies.ycoor[SI]
    mov Xc, CX
    mov Yc, DX
    selectSquareOnGrid Xc, Yc

    addDelay 500
    RET
select2Candies endp

checkIfBombIsSwapped proc
    mov SI, selected1
    mov DI, selected2
    .IF(boardCandies.candyid[SI] == 0 || boardCandies.candyid[DI] == 0)
        mov bombswapped, 1
        .IF(boardCandies.candyid[SI] != 0)
            mov candyswappedwithbomb, SI
        .ELSE
            mov candyswappedwithbomb, DI
        .ENDIF
    .ELSE
        mov bombswapped, 0
    .ENDIF
    RET
checkIfBombIsSwapped endp

checkIfBombInGrid proc
    mov oldXc, 0
    .WHILE(oldXc <= 96)
        mov SI, oldXc
        .IF(boardCandies.candyid[SI]==0)
            mov bombingrid, 1
            jmp bombfound
        .ENDIF
        add oldXc, 2
    .ENDW
    mov bombingrid, 0
    bombfound:
    RET
checkIfBombInGrid endp

;procedure that displays all the candies that are currently stored in boardCandies struct
showCurrentCandies proc
    mov count1, 0
    mov counter, 0
    .WHILE(count1 < 49)
    ;taking out the candy id and its coordinates from the struct
        mov SI, counter
        mov DI, boardCandies.xcoor[SI]
        mov Xc, DI
        mov DI, boardCandies.ycoor[SI]
        mov Yc, DI
        mov DI, boardCandies.candyid[SI]
        mov id, DI
        add counter, 2
        mov radius, 8
    ;Display candy on the board
        spawnCandy Xc, Yc, radius, id
        inc count1
    .ENDW
    RET
showCurrentCandies endp

;Draws horizontal and vertical line to display grid
drawGrid proc
    ;Drawing grid
    .IF(currentlevel == 3)
        mov color, 1000b
    .ELSE
        mov color, 1111b
    .ENDIF
    mov Yc, 10
    .WHILE(Yc <= 192)
        drawHorizontalLine 19, 201, Yc, color
        add Yc, 26
    .ENDW
    mov Xc, 19
    .WHILE(Xc <= 201)
        drawVerticalLine Xc, 10, 192, color
        add Xc, 26
    .ENDW
    RET
drawGrid endp

;generates a random number between 1 to 5 (so no spawn of bomb) and mov it into id variable
randomId proc
    addDelay 203
    MOV AH, 00h         
    INT 1AH         
    mov  ax, dx
    mov dx, 0
    mov  cx, 5    
    div  cx       
    inc dx
    mov id, dx
    ret
randomId endp

;generates a random number between 0 to 5 and mov it into id variable
randomIdwithBomb proc
randagain:
    addDelay 203
    MOV AH, 00h  ; input for interrupts that puts system time in CX and DX        
    INT 1AH      ; int called
    mov  ax, dx
    mov dx, 0
    mov  cx, 6    
    div  cx   
    mov id, dx
    call checkIfBombInGrid
    .IF(bombingrid == 1 && id == 0)
        je randagain
    .ENDIF
    ret
randomIdwithBomb endp

;used multidigit output of numbers
output1 proc
	mov count, 0
	continuepushing:
		mov DX, 0
		mov BX, 10
		div BX
		push DX
		inc count
		cmp AX, 0
	jne continuepushing
		continuepopping:
		pop DX
		add DX, 48
		mov AH, 02h
		int 21h
		dec count
		cmp count,0
	jne continuepopping
	stoppopping:
	mov DX, 10
	mov AH, 02
	int 21h
	RET
output1 endp

;populates the board with random candies at the start of the game
;also fills the boardCandies(struct) with those candies' coordinates and id
displayAndSetInitialCandies proc
    ;Loop to display all the candies candies
    mov Yc, 23
    mov count1, 0
    mov counter, 0
    .WHILE(count1 < 7)
        mov Xc, 32
        mov count2, 0
        mov bx, Yc
        mov oldYc, bx
        .WHILE(count2 < 7)
            mov bx, Xc
            mov oldXc, bx
            call randomId
            mov radius, 8
            call randomId
        ;storing current candies and their coordinates in the struct
            mov SI, counter
            mov DI, Xc
            mov boardCandies.xcoor[SI], DI
            mov DI, Yc
            mov boardCandies.ycoor[SI], DI
            mov DI, id
            mov boardCandies.candyid[SI], DI
            add counter, 2
        ;Display candy on the board
            spawnCandy Xc, Yc, radius, id
            inc count2
            mov bx, oldXc
            mov Xc, bx
            add Xc, 26
        .ENDW
        inc count1
        mov bx, oldYc
        mov Yc, bx
        add Yc, 26
    .ENDW
    RET
displayAndSetInitialCandies endp

droppingdowncandies proc
    mov count1, 0
    .WHILE(count1 <= 82)
        mov SI, count1
        mov DI, SI
        add DI, 14
        .IF(boardCandies.candyid[DI] == -1 && boardCandies.candyid[SI] != -1 && boardCandies.candyid[SI] != -2 && boardCandies.candyid[DI] != -2)
            swapcandies SI, DI
            call refreshscreenwithoutGRID
            addDelay 250
            mov dropped, 1
            jmp droppedsuccessfully
        .ENDIF
        inc count1
    .ENDW
    mov dropped, 0
    droppedsuccessfully:
    RET
droppingdowncandies endp

clearScreen proc
    mov ah, 00h
	mov al, 13
	int 10h
    .IF(currentlevel == 3)
        mov ah, 0Bh
        mov bh, 00
        mov bl, 0111b
        int 10h
    .ENDIF
    RET
clearScreen endp

refreshscreen proc
    call clearScreen
    call drawBorders
    call drawGrid
    call DisplayscorePrompt
    call displayPlayerNameAndBomb
    call DisplayMovesPrompt
    call showCurrentCandies
    RET
refreshscreen endp

refreshscreenwithoutGRID proc
    call clearScreen
    call showCurrentCandies
    RET
refreshscreenwithoutGRID endp

DisplayscorePrompt proc
;displaying "score: " text
    mov ah, 02h
    mov dh, 4
    mov dl, 28
    int 10h
    mov ah,09h
    mov dx,offset scorePrompt
    int 21h
; Displaying Player Score
    mov ah, 02h
    mov dh, 4
    mov dl, 35
    int 10h
    mov AX, score
    call output1
    RET
DisplayscorePrompt endp

DisplayMovesPrompt proc
;displaying "score: " text
    mov ah, 02h
    mov dh, 10
    mov dl, 28
    int 10h
    mov ah,09h
    mov dx, offset movesPrompt
    int 21h
; Displaying Player Score
    mov ah, 02h
    mov dh, 10
    mov dl, 35
    int 10h
    mov AL, movesdone
    mov AH, 0
    inc AL
    call output1
    RET
DisplayMovesPrompt endp

displayExplosionPrompt proc
    mov ah,02h				
    mov dh,19
    mov dl,27
    int 10h
    mov ah,09h
    mov dx, offset dashesprompt 
    int 21h
    mov ah,02h				
    mov dh,20
    mov dl,28
    int 10h
    mov ah,09h
    mov dx, offset explosionprompt 
    int 21h
    mov ah,02h				
    mov dh,21
    mov dl,27
    int 10h
    mov ah,09h
    mov dx, offset dashesprompt 
    int 21h
    RET
displayExplosionPrompt endp

displayCRUSHINGprompt proc
    mov ah,02h				
    mov dh,19
    mov dl,27
    int 10h
    mov ah,09h
    mov dx, offset dashesprompt 
    int 21h
    mov ah,02h				
    mov dh,20
    mov dl,28
    int 10h
    mov ah,09h
    mov dx, offset CRUSHINGprompt 
    int 21h
    mov ah,02h				
    mov dh,21
    mov dl,27
    int 10h
    mov ah,09h
    mov dx, offset dashesprompt 
    int 21h
    addDelay 500
    RET
displayCRUSHINGprompt endp

displayPlayerNameAndBomb proc
    ; Displaying Bomb Prompt
    mov ah, 02h
    mov dh, 7
    mov dl, 31
    int 10h
    mov ah,09h
    mov dx,offset bombString
    int 21h
    ; Bomb
    mov radius, 8
    mov Xc, 230
    mov Yc, 59
    mov id, 0
    spawnCandy Xc, Yc, radius, id
    ; Displaying Player Namne
    mov ah, 02h
    mov dh, 2	
    mov dl, 28
    int 10h
    mov ah,09h
    mov dx,offset playerName
    int 21h
    RET
displayPlayerNameAndBomb endp

checkSpace proc
    checkInput:
        mov ah, 07
        int 21h
        cmp al, 32
    jne checkInput
ret
checkSpace endp

drawBorders proc
    ;bottom border
    mov Yc, 200
    mov count1, 0
    .while(count1 < 320)
        mov di, count1
        mov Xc, di
        mov radius, 8
        hexagonCandyRed Xc, Yc, radius
        add count1,15
    .endw
    ;top border
    mov Yc, -3
    mov count1, 0
    .while(count1 < 320)
        mov di, count1
        mov Xc, di
        mov radius, 8
        hexagonCandyRed Xc, Yc, radius
        add count1,15
    .endw
    ;left border
    mov Xc, 0
    mov count1, 0
    .while(count1 < 200)
        mov di, count1
        mov Yc, di
        mov radius, 8
        hexagonCandyRed Xc, Yc, radius
        add count1,15
    .endw
    ;right border
    mov Xc, 320
    mov count1, 0
    .while(count1 < 200)
        mov di, count1
        mov Yc, di
        mov radius, 8
        hexagonCandyRed Xc, Yc, radius
        add count1,15
    .endw
ret
drawBorders endp

welcome proc
    candyTowers
    ;print candy crush
    mov xB, 10
    mov yB, 4
    printText w0String, xB, yB

    ;print take name input
    mov xB, 9
    mov yB, 8
    printText w1String, xB, yB 
    ;take Name input
    call takeNameInput

    ;print 1 to play
    mov xB, 11
    mov yB, 14
    printText w2String, xB, yB

    ;print 3 to exit
    mov xB, 11
    mov yB, 16
    printText w3String, xB, yB
ret
welcome endp

takeNameInput proc
    ;move cursor to centre position
    mov ah, 02
    mov dh, 10
    mov dl, 14
    int 10h
    ;take name input
    mov si, 0
    takeInput:
        cmp si, 15
        je nameTaken ;max length of name
        mov ah, 01
        int 21h
        cmp al, 13
        je nameTaken
        mov playerName[si], al
        inc si
    jmp takeInput
    nameTaken:
    mov playerName[si], '$'
ret
takeNameInput endp

printRules proc
    mov xB, 16
    mov yB, 3
    printText r0String, xB, yB

    mov xB, 4
    mov yB, 5
    printText r1String, xB, yB

    mov xB, 4
    mov yB, 7
    printText r2String, xB, yB

    mov xB, 6
    mov yB, 9
    printText r3String, xB, yB

    mov xB, 4
    mov yB, 11
    printText r4String, xB, yB

    mov xB, 6
    mov yB, 13
    printText r5String, xB, yB

    mov xB, 4
    mov yB, 15
    printText r6String, xB, yB

    mov xB, 4
    mov yB, 17
    printText r7String, xB, yB

    mov xB, 6
    mov yB, 19
    printText r8String, xB, yB

    mov xB, 8
    mov yB, 22
    printText r9String, xB, yB
ret
printRules endp

printScoreToFile proc
    ;create and open new file
    mov ah, 3ch
    mov dx, offset(fileName)
    mov cl, 1
    int 21h
    mov handle, ax

    mov ax, scorelvl1
    call intToStr

    ;write player name to file
    mov ah, 40h
    mov bx, handle
    mov si, 0
    .while (playerName[si] != "$")
        inc si
    .endw
    mov cx, si
    mov dx, offset(playerName)
    int 21h
    mov ah, 40h
    mov bx, handle
    mov cx, lengthof newLine
    mov dx, offset(newLine)
    int 21h

    ;write level 1 score to file
    mov ah, 40h
    mov bx, handle
    mov cx, lengthof score1Str
    mov dx, offset(score1Str)
    int 21h
    mov ax, scorelvl1
    call intToStr
    mov ah, 40h
    mov bx, handle
    mov cx, lengthof scoreStr
    mov dx, offset(scoreStr)
    int 21h
    mov ah, 40h
    mov bx, handle
    mov cx, lengthof newLine
    mov dx, offset(newLine)
    int 21h

    ;write level 2 score to file
    mov ah, 40h
    mov bx, handle
    mov cx, lengthof score2Str
    mov dx, offset(score2Str)
    int 21h
    mov ax, scorelvl2
    call intToStr
    mov ah, 40h
    mov bx, handle
    mov cx, lengthof scoreStr
    mov dx, offset(scoreStr)
    int 21h
    mov ah, 40h
    mov bx, handle
    mov cx, lengthof newLine
    mov dx, offset(newLine)
    int 21h

    ;write level 3 score to file
    mov ah, 40h
    mov bx, handle
    mov cx, lengthof score3Str
    mov dx, offset(score3Str)
    int 21h
    mov ax, scorelvl3
    call intToStr
    mov ah, 40h
    mov bx, handle
    mov cx, lengthof scoreStr
    mov dx, offset(scoreStr)
    int 21h
    mov ah, 40h
    mov bx, handle
    mov cx, lengthof newLine
    mov dx, offset(newLine)
    int 21h

    ;write high score to file
    mov ah, 40h
    mov bx, handle
    mov cx, lengthof score4Str
    mov dx, offset(score4Str)
    int 21h
    mov ax, highestscore
    call intToStr
    mov ah, 40h
    mov bx, handle
    mov cx, lengthof scoreStr
    mov dx, offset(scoreStr)
    int 21h

    ;close file
    mov ah, 3eh
    mov dx, handle
    int 21h
    ret
printScoreToFile endp

;converts integer in ax to string (max 3 length integer)
intToStr proc
    mov si, 0

    pushNum:
    cmp ax, 0
    je setZero
    mov dx, 0
    mov bx, 10
    div bx
    push dx
    inc si
    jmp pushNum

    setZero:
    .if (si == 1)
        mov di, 2
        mov scoreStr[0], '0'
        mov scoreStr[1], '0'
    .elseif (si == 2)
        mov di, 1
        mov scoreStr[0], '0'
    .elseif (si == 3)
        mov di, 0
    .endif

    popNum:
    cmp si, 0
    je return
    pop dx
    add dl, 48
    mov scoreStr[di], dl
    inc di
    dec si
    jmp popNum

    return:
    ret
intToStr endp

end