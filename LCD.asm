;Created on Fri Nov 22 2019
;version: 5
;@author: Julie Laguerre, Oscar Gravier
;function: 	In this file are listed subroutines which deal with the LCD, 
		;with the final goal of displaying the right thing in the right place.

#include p18f87k22.inc

    global LCD_Setup
    global LCD_Send_Byte_D
    global LCD_FirstLine, LCD_SecondLine
    global LCD_Temperature_Display
    global LCD_Speed_Display, LCD_Stop_Display
    global LCD_delay_ms
    
    extern LowDecimal, MiddleLowDecimal, MiddleHighDecimal, HighDecimal
    extern Speed_manual
    
acs0    	udata_acs   ; named variables in access ram
LCD_cnt_l   	res 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h   	res 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms  	res 1   ; reserve 1 byte for ms counter
LCD_tmp	    	res 1   ; reserve 1 byte for temporary use
LCD_counter 	res 1   ; reserve 1 byte for counting through message

 
constant    LCD_E=5	; LCD enable bit
constant    LCD_RS=4	; LCD register select bit

LCD	code
    
LCD_Setup ; Sets up the LCD screen to be ready to display a message, data, etc...
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

LCD_Write_Message ; Displays message stored at FSR2, length stored in W
	movwf   LCD_counter
LCD_Loop_message
	movf    POSTINC2, W
	call    LCD_Send_Byte_D
	decfsz  LCD_counter
	bra	LCD_Loop_message
	return

LCD_Send_Byte_I	; Transmits byte stored in W to instruction reg
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

LCD_Send_Byte_D ; Transmits byte stored in W to data reg
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

LCD_Enable ; Creates a pulse enable bit LCD_E for 500ns
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
LCD_delay_ms ; Creates a delay given in ms in W
	movwf	LCD_cnt_ms
lcdlp2	movlw	.250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms
	bra	lcdlp2
	return
    
LCD_delay_x4us ; Creates a delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l   ; now need to multiply by 16
	swapf   LCD_cnt_l,F ; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l,W ; move low nibble to W
	movwf	LCD_cnt_h   ; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l,F ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay ; Creates a delay routine 4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1	decf 	LCD_cnt_l,F	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h,F	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return

LCD_Clear ; Clears the LCD screen
	movlw	b'00000001'	; clear dsiplay
	call	LCD_Send_Byte_I
	movlw	.2		; wait 2ms
	call	LCD_delay_ms
	return
	
LCD_SecondLine ; Writes to the second line of the display
	movlw	b'11000000'	; change of line2
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	return

LCD_FirstLine ; Writes to the first line of the display
	movlw	b'10000000'	; change line1
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	return
	
LCD_HexToDec_Display ; Displays the four digits of the decimal temperature one after the other on the first line of the screen
	movlw 0x30 ; 0x30 is the hexadecimal address of the first number of the ascii table
	addwf HighDecimal, 0 ; stores the result back in W
	call LCD_Send_Byte_D ; sends the HighDecimal converted to decimal
	
	movlw 0x30 ; 0x30 is the hexadecimal address of the first number of the ascii table
	addwf MiddleHighDecimal, 0 ; stores the result back in W
	call LCD_Send_Byte_D ; sends the MiddleHighDecimal converted to decimal
	
	movlw 0x30 ; 0x30 is the hexadecimal address of the first number of the ascii table
	addwf MiddleLowDecimal, 0 ; stores the result back in W
	call LCD_Send_Byte_D ; sends the MiddleLowDecimal converted to decimal
	
	movlw 0x30 ; 0x30 is the hexadecimal address of the first number of the ascii table
	addwf LowDecimal, 0 ; stores the result back in W
	call LCD_Send_Byte_D ; sends the LowDecimal converted to decimal
	
	return
	

LCD_Temperature_Display ; Displays the temperature on the first line of the screen as T=XX,X°C
	movlw 0x54 ; displays "T" for temperature
	call LCD_Send_Byte_D
	
	movlw 0x3D ; displays "="
	call LCD_Send_Byte_D
	
	movlw 0x30 ; 0x30 is the hexadecimal address of the first number of the ascii table
	addwf HighDecimal, 0 ; stores the result back in W
	call LCD_Send_Byte_D ; displays the first decimal number
	
	movlw 0x30 ; 0x30 is the hexadecimal address of the first number of the ascii table
	addwf MiddleHighDecimal, 0 ; stores the result back in W
	call LCD_Send_Byte_D ; displays the second decimal number
	
	movlw 0x2C ; displays a comma
	call LCD_Send_Byte_D
	
	movlw 0x30  ; 0x30 is the hexadecimal address of the first number of the ascii table
	addwf MiddleLowDecimal, 0 ; stores the result back in W
	call LCD_Send_Byte_D ; displays the third	
	
	movlw 0xB0 ; displays a degree
	call LCD_Send_Byte_D
	
	movlw 0x43 ; displays a "C"
	call LCD_Send_Byte_D
	return
	
LCD_Speed_Display ; Displays the fan speed on the second line of the screen as SPEED #
	call LCD_SecondLine ; displays on the second line
	
	movlw 0x53 ; displays a "S"
	call LCD_Send_Byte_D
	
	movlw 0x50 ; displays a "P"
	call LCD_Send_Byte_D
	
	movlw 0x45 ; displays a "E"
	call LCD_Send_Byte_D
	
	movlw 0x45 ; displays a "E"
	call LCD_Send_Byte_D
	
	movlw 0x44 ; displays a "D"
	call LCD_Send_Byte_D
	
	movlw 0x20 ; displays a space
	call LCD_Send_Byte_D
	
	movlw 0x30  ; 0x30 is the hexadecimal address of the first number of the ascii table
	addwf Speed_manual, 0 ; stores the result back in W
	call LCD_Send_Byte_D ; displays the value of the speed which chan be 1, 2 or 3
	
	return

LCD_Stop_Display ; Displays "STOP" on the second line of the screen
	call LCD_SecondLine  ; displays on the second line
	
	movlw 0x53 ; displays a "S"
	call LCD_Send_Byte_D
	
	movlw 0x54 ; displays a "T"
	call LCD_Send_Byte_D
	
	movlw 0x4F ; displays a "O"
	call LCD_Send_Byte_D
	
	movlw 0x50 ; displays a "P"
	call LCD_Send_Byte_D
	
	return

	end
