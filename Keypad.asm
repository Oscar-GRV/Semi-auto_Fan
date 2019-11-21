;choose mode, return mode select 
;1-start/go to temperature speed : * (0E,70)
;2-stop everythings: 0		     (0E,B0)
;3-Faster : B			     (0B,E0)
;4-Lower : C			     (0D,E0)
;5-start rotating : 4		     (0B,70)
;6-Stop rotating : 5		     (0B,B0)

    
#include p18f87k22.inc

global Keypad_reading, Keypad_setup, Keypad_touch
    
acs0    udata_acs   ; named variables in access ram
change		res 1   ; reserve one byte for a counter variable
Keypad_touch    res 1   ; reserve 1 byte for variable Keypad_touch ;GLOBAL ???
First_byte      res 1   ; reserve 1 byte for variable 
Second_byte     res 1   ; reserve 1 byte for variable 

Keypad code

Keypad_reading
    
    call Keypad_setup ;setup the PORTE for reading, other wise problems with ReadingColumn
    call ReadingColumn ;read the column of the pressed key and store it in Second_byte
  
    call Keypad_setup ;setup the PORTE for reading
    call ReadingRow ;read the row of the pressed key and store it in First_byte
    ;here First_byte and Second_byte have been fill
    
    
    call ReadingKey ;detect with key has been pressed and store it into global variable Keypad_touch
    return	
 
Keypad_setup
    banksel PADCFG1; set bank
    bsf PADCFG1,REPU,BANKED ; set the pull-ups on for PORTE
    clrf LATE ; write 0s to LATE register
  
    setf TRISE
    movlw 0x00
    movwf TRISE, ACCESS
    return

ReadingRow
    movlw 0x0F
    movwf change
    movwf TRISE ;set 0-3 low and 4-7 high
    call delay
    movf PORTE,W
    movwf First_byte
    return
    
ReadingColumn
    movlw 0xF0
    movwf change
    movwf TRISE ;set 0-3 high and 4-7 low
    call delay
    movf PORTE,W
    movwf Second_byte
    return
    
ReadingKey
    movlw 0x0E
    cpfseq First_byte
    goto if2 ;goto the end of the peace of code
	movlw 0x70
	cpfseq Second_byte
	goto if1_1 ;goto the end of the little piece of code
	    movlw 0x01
	    movwf Keypad_touch
	    goto ifend;end of the if things
	if1_1 
	movlw 0xB0
	cpfseq Second_byte
	goto ifend
	    movlw 0x02
	    movwf Keypad_touch
	    goto ifend;end of the if things
    if2
    movlw 0x0B
    cpfseq First_byte
    goto if3 ;goto the end of the peace of code
	movlw 0xE0
	cpfseq Second_byte
	goto if2_1 ;goto the end of the little peace of code
	    movlw 0x03
	    movwf Keypad_touch
	    goto ifend;end of the if things
	if2_1 
	movlw 0x70
	cpfseq Second_byte
	goto if2_2
	    movlw 0x05
	    movwf Keypad_touch
	    goto ifend ;end of the if things
	if2_2
	movlw 0xB0
	cpfseq Second_byte
	goto if2_2
	    movlw 0x06
	    movwf Keypad_touch
	    goto ifend ;end of the if things

    if3
    movlw 0x0D
    cpfseq First_byte
    goto ifend ;goto the end of the peace of code
	movlw 0xE0
	cpfseq Second_byte
	goto ifend ;goto the end of the little peace of code
	    movlw 0x04
	    movwf Keypad_touch
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