#include p18f87k22.inc

    global LCD_Setup;, LCD_Clear
    global LCD_Send_Byte_D
    ;global LCD_Write_Message, LCD_Write_MessagePGR
    global LCD_FirstLine, LCD_SecondLine
    global LCD_HexToDec_Display, LCD_Temperature_Display
    global LCD_Speed_Display, LCD_Stop_Display
    global LCD_delay_ms
    
    extern LowDecimal, MiddleLowDecimal, MiddleHighDecimal, HighDecimal
    extern Speed_manual
    
acs0    udata_acs   ; named variables in access ram
LCD_cnt_l   res 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h   res 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms  res 1   ; reserve 1 byte for ms counter
LCD_tmp	    res 1   ; reserve 1 byte for temporary use
LCD_counter res 1   ; reserve 1 byte for counting through message
;counter	    res 1   ; reserve one byte for a counter variable
;delay_count res 1   ; reserve one byte for counter in the delay routine
 
constant    LCD_E=5	; LCD enable bit
constant    LCD_RS=4	; LCD register select bit
 
;tables	udata	0x400    ; reserve data anywhere in RAM (here at 0x400)
;myArray res 0x80    ; reserve 128 bytes for message data

LCD	code
    
LCD_Setup
	clrf    LATB
	movlw   b'11000000'	    ; RB0:5 all outputs
	movwf	TRISB
	movlw   .40
	call	LCD_delay_ms	; wait 40ms for LCD to start up properly
	
	movlw	b'00110000'	; Function set 4-bit
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	
	movlw	b'00101000'	; 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	
	movlw	b'00101000'	; repeat, 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	
	movlw	b'00001111'	; display on, cursor on, blinking on
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	
	movlw	b'00000001'	; display clear
	call	LCD_Send_Byte_I
	movlw	.2		; wait 2ms
	call	LCD_delay_ms
	
	movlw	b'00000110'	; entry mode incr by 1 no shift
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	return

LCD_Write_Message	    ; Message stored at FSR2, length stored in W
	movwf   LCD_counter
LCD_Loop_message
	movf    POSTINC2, W
	call    LCD_Send_Byte_D
	decfsz  LCD_counter
	bra	LCD_Loop_message
	return

LCD_Send_Byte_I		    ; Transmits byte stored in W to instruction reg
	movwf   LCD_tmp
	swapf   LCD_tmp,W   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB	    ; output data bits to LCD
	bcf	LATB, LCD_RS	; Instruction write clear RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp,W   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB	    ; output data bits to LCD
	bcf	LATB, LCD_RS    ; Instruction write clear RS bit
        call    LCD_Enable  ; Pulse enable Bit 
	return

LCD_Send_Byte_D		    ; Transmits byte stored in W to data reg
	movwf   LCD_tmp
	swapf   LCD_tmp,W   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB	    ; output data bits to LCD
	bsf	LATB, LCD_RS	; Data write set RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp,W   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB	    ; output data bits to LCD
	bsf	LATB, LCD_RS    ; Data write set RS bit	    
        call    LCD_Enable  ; Pulse enable Bit 
	movlw	.10	    ; delay 40us
	call	LCD_delay_x4us
	return

LCD_Enable	    ; pulse enable bit LCD_E for 500ns
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	    LATB, LCD_E	    ; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	    LATB, LCD_E	    ; Writes data to LCD
	return
    
; ** a few delay routines below here as LCD timing can be quite critical ****
LCD_delay_ms		    ; delay given in ms in W
	movwf	LCD_cnt_ms
lcdlp2	movlw	.250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms
	bra	lcdlp2
	return
    
LCD_delay_x4us		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l   ; now need to multiply by 16
	swapf   LCD_cnt_l,F ; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l,W ; move low nibble to W
	movwf	LCD_cnt_h   ; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l,F ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1	decf 	LCD_cnt_l,F	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h,F	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return

LCD_Clear
	
	movlw	b'00000001'	; display clear
	call	LCD_Send_Byte_I
	movlw	.2		; wait 2ms
	call	LCD_delay_ms
	return
	
LCD_SecondLine
	movlw	b'11000000'	; change of line2
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	return

LCD_FirstLine
	movlw	b'10000000'	; change line1
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	return
	
LCD_Write_MessagePGR	    ; Message stored at TABLAT, length stored in W
	movwf   LCD_counter
LCD_Loop_messagePGR
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movf	TABLAT, W       ; move data from TABLAT to W
	call    LCD_Send_Byte_D
	decfsz  LCD_counter
	bra	LCD_Loop_messagePGR
	return
	
LCD_HexToDec_Display
	movlw 0x30
	addwf HighDecimal, 0
	call LCD_Send_Byte_D ; sends the low byte converted to decimal
	
	movlw 0x30
	addwf MiddleHighDecimal, 0
	call LCD_Send_Byte_D
	
	movlw 0x30
	addwf MiddleLowDecimal, 0
	call LCD_Send_Byte_D
	
	movlw 0x30
	addwf LowDecimal, 0
	call LCD_Send_Byte_D
	
	return
	

LCD_Temperature_Display
	movlw 0x54 ; displays "T" for temperature
	call LCD_Send_Byte_D
	
	movlw 0x3D ; displays "="
	call LCD_Send_Byte_D
	
	movlw 0x30 ; displays the first decimal number != 0
	addwf HighDecimal, 0
	call LCD_Send_Byte_D
	
	movlw 0x30 ; displays the second decimal number
	addwf MiddleHighDecimal, 0
	call LCD_Send_Byte_D
	
	movlw 0x2C ; displays a comma
	call LCD_Send_Byte_D
	
	movlw 0x30 ; displays the third and last decimal number
	addwf MiddleLowDecimal, 0
	call LCD_Send_Byte_D	
	
	movlw 0xB0 ; displays a degree
	call LCD_Send_Byte_D
	
	movlw 0x43 ; displays a "C"
	call LCD_Send_Byte_D
	return
	
LCD_Speed_Display
	call LCD_SecondLine
	
	movlw 0x53
	call LCD_Send_Byte_D
	
	movlw 0x50
	call LCD_Send_Byte_D
	
	movlw 0x45
	call LCD_Send_Byte_D
	
	movlw 0x45
	call LCD_Send_Byte_D
	
	movlw 0x44
	call LCD_Send_Byte_D
	
	movlw 0x20
	call LCD_Send_Byte_D
	
	movlw 0x30
	addwf Speed_manual, 0	
	call LCD_Send_Byte_D
	
	return

LCD_Stop_Display
	call LCD_SecondLine
	
	movlw 0x53
	call LCD_Send_Byte_D
	
	movlw 0x54
	call LCD_Send_Byte_D
	
	movlw 0x4F
	call LCD_Send_Byte_D
	
	movlw 0x50
	call LCD_Send_Byte_D
	
	return
;LCD_Speed_Display
;	myTable data	    "Speed"	; message, plus carriage return
;	constant    myTable_l=.13	; length of data
;	call LCD_SecondLine
;	lfsr	FSR0, myArray	; Load FSR0 with address in RAM	
;	movlw	upper(myTable)	; address of data in PM
;	movwf	TBLPTRU		; load upper bits to TBLPTRU
;	movlw	high(myTable)	; address of data in PM
;	movwf	TBLPTRH		; load high byte to TBLPTRH
;	movlw	low(myTable)	; address of data in PM
;	movwf	TBLPTRL		; load low byte to TBLPTRL
;	movlw	myTable_l	; bytes to read
;	movwf 	counter		; our counter register
;loop 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
;	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
;	decfsz	counter		; count down to zero
;	bra	loop		; keep going until finished
		
;	movlw	myTable_l-1	; output message to LCD (leave out "\n")
;	lfsr	FSR2, myArray
;	call	LCD_Write_Message	
	
;	return
   
	end