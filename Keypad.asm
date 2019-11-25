;Created on Fri Nov 22 2019
;version: 5
;@author: Julie Laguerre, Oscar Gravier
;function: 	The main role of this Keypad file is to determine what key pressed 
		; and to load the corresponding number into the global variable Keypad_touch


;1-Set the fan speed according to the temperature  : * (First_byte=0x0E, Second_byte=0x70)
;3-Increase the fan speed : B		(0B,E0)
;4-Decrease the fan speed : C		(0D,E0)
;5-Start rotation of the base : 4	(0B,70)
;6-Stop rotation of the base : 5	(0B,B0)

    
#include p18f87k22.inc

global Keypad_reading, Keypad_setup, Keypad_touch
    
acs0    udata_acs   ; named variables in access ram
change		res 1   ; reserve one byte for a counter variable
Keypad_touch    res 1   ; reserve 1 byte for variable Keypad_touch ;GLOBAL ???
First_byte      res 1   ; reserve 1 byte for variable 
Second_byte     res 1   ; reserve 1 byte for variable 

Keypad code

Keypad_reading ; reads the key pressed 
    
    call Keypad_setup ; sets up PORTE for reading
    call ReadingColumn ; reads the column of the pressed key and stores it into Second_byte
  
    call Keypad_setup ; sets up PORTE for reading
    call ReadingRow ; reads the row of the pressed key and stores it into First_byte
    
    ;here First_byte and Second_byte have been filled
    
    call ReadingKey ; detects which key has been pressed and stores the associated number into the global variable Keypad_touch
    return	
 
Keypad_setup ; set up PORTE to receive input from the keypad
    banksel PADCFG1 ; sets bank
    bsf PADCFG1,REPU,BANKED ; sets the pull-ups on for PORTE
    clrf LATE ; writes 0s to LATE register
  
    setf TRISE 
    movlw 0x00
    movwf TRISE, ACCESS ; clears TRISE
    return

ReadingRow ; reads the row of the key pressed and stores it into First_byte
    movlw 0x0F
    movwf change
    movwf TRISE ; sets 0-3 low and 4-7 high
    call delay
    movf PORTE,W ; moves the hexadecimal value of 3 ones and 1 zero at the position of the row pressed into W
    movwf First_byte ; moves the content of W into First_byte
    return
    
ReadingColumn ; reads the column of the key pressed and stores it into Second_byte
    movlw 0xF0
    movwf change
    movwf TRISE ; sets 0-3 high and 4-7 low
    call delay
    movf PORTE,W ; moves the hexadecimal value of 3 ones and 1 zero at the position of the column pressed into W
    movwf Second_byte ; moves the content of W into Second_byte
    return
    
ReadingKey ; stores the value of Keypad_touch corresponding to the couple {First_byte;Second_Byte}
    movlw 0x0E
    cpfseq First_byte ; checks if the first byte is 0x0E
    goto if2 ; if not, goes to the end of the piece of code
	movlw 0x70 ; if it is, starts checking the second byte
	cpfseq Second_byte ; checks if the second byte is 0x70
	goto if1_1 ; if not, goes to the end of the small piece of code
	    movlw 0x01 ; if it is, then the couple is {0x0E;0X70} which corresponds to the key n°1
	    movwf Keypad_touch ; 0x01 is stored into Keypad_touch
	    goto ifend
	
	; we used to have another key corresponding to the couple {0x0E,0xB0} but we didn't use it in the end
	if1_1 
	movlw 0xB0
	cpfseq Second_byte
	goto ifend
	    movlw 0x02
	    movwf Keypad_touch
	    goto ifend
    if2
    movlw 0x0B
    cpfseq First_byte ; checks if the first byte is 0x0B
    goto if3 ; if not, goes to the end of the piece of code
	movlw 0xE0 ; if it is, starts checking the second byte
	cpfseq Second_byte ; checks if the second byte is 0xE0
	goto if2_1 ; if not, goes to the end of the small piece of code
	    movlw 0x03 ; if it is, then the couple is {0x0B;0xE0} which corresponds to the key n°3
	    movwf Keypad_touch ; 0x03 is stored into Keypad_touch
	    goto ifend
	if2_1 
	movlw 0x70 ; starts checking the second byte
	cpfseq Second_byte ; checks if the second byte is 0x70
	goto if2_2 ; if not, goes to the end of the small piece of code
	    movlw 0x05 ; if it is, then the couple is {0x0B;0x70} which corresponds to the key n°5
	    movwf Keypad_touch ; 0x05 is stored into Keypad_touch
	    goto ifend
	if2_2
	movlw 0xB0 ; starts checking the second byte
	cpfseq Second_byte ; checks if the second byte is 0xB0
	goto ifend
	    movlw 0x06 ; if it is, then the couple is {0x0B;0xB0} which corresponds to the key n°6
	    movwf Keypad_touch ; 0x06 is stored into Keypad_touch
	    goto ifend 

    if3
    movlw 0x0D
    cpfseq First_byte ; checks if the first byte is 0x0D
    goto ifend ; if not, goes to the end of the piece of code
	movlw 0xE0 ; starts checking the second byte
	cpfseq Second_byte ; checks if the second byte is 0xE0
	goto ifend ; if not, goes to the end of the piece of code
	    movlw 0x04 ; if it is, then the couple is {0x0D;0xE0} which corresponds to the key n°4
	    movwf Keypad_touch ; 0x04 is stored into Keypad_touch
	    goto ifend	
    ifend
    return
    
delay
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    return
end
