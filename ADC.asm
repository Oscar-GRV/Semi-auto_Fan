#include p18f87k22.inc

    global ADC_Setup, ADC_Read
    global ADC_mul_8_16
    global Factor_8_bit, LowBitFactor_16_bit, HighBitFactor_16_bit
    global LowBitResult_8_16, MiddleBit_1_8_16, MiddleBit_2_8_16, MiddleBitResult_8_16, HighBit_NO_CARRY_8_16, HighBitResult_8_16
    
    global ADC_mul_16_16
    global LowBitFactor_1_16_bit, HighBitFactor_1_16_bit, LowBitFactor_2_16_bit, HighBitFactor_2_16_bit
    global LowBit_1_16_16, MiddleBit_1_16_16, HighBit_1_16_16, LowBit_2_16_16, MiddleBit_2_16_16, HighBit_2_16_16
    global LowBitResult_16_16, MiddleLowBitResult_16_16, MiddleHighBit_Result_16_16, HighBit_Result_16_16
    
    global ADC_mul_8_24
    global LowBitFactor_24_bit, MiddleBitFactor_24_bit, HighBitFactor_24_bit
    global HighBit_1_8_24
    global LowBitResult_8_24, MiddleLowBitResult_8_24, MiddleHighBitResult_8_24, HighBitResult_8_24 

    global ADC_HexToDec
    global LowDecimal, MiddleLowDecimal, MiddleHighDecimal, HighDecimal

    
acs0    udata_acs   ; named variables in access ram
    
; 8x16 multiplication
Factor_8_bit		res 1	; reserve one byte for the 8-bit factor
		
LowBitFactor_16_bit	res 1   ; reserve one byte for the low part of the 16-bit factor
HighBitFactor_16_bit	res 1   ; reserve one byte for the high part of the 16-bit factor
	
LowBitResult_8_16	res 1   ; reserve one byte for the low bit of the result of the 8x16 multiplication
MiddleBit_1_8_16	res 1	; reserve one byte for the first middle bit of the 8x16 multiplication
MiddleBit_2_8_16	res 1   ; reserve one byte for the second middle bit of the 8x16 multiplication
MiddleBitResult_8_16	res 1   ; reserve one byte for the middle bit of the result of the 8x16 multiplication
HighBit_NO_CARRY_8_16	res 1   ; reserve one byte for the second middle bit of the result of the 8x16 multiplication WARNING !!! No carry
HighBitResult_8_16	res 1   ; reserve one byte for the second middle bit of the result of the 8x16 multiplication

	
; 16x16 multiplication
LowBitFactor_1_16_bit	res 1
HighBitFactor_1_16_bit	res 1
LowBitFactor_2_16_bit	res 1
HighBitFactor_2_16_bit	res 1
	
LowBit_1_16_16	    res 1 ; reserves one byte for low bit of the 8x16 multiplication of low bit of factor 2 by factor 1
MiddleBit_1_16_16    res 1 ; reserves one byte for middle bit of the 8x16 multiplication of low bit of factor 2 by factor 1	
HighBit_1_16_16	    res 1 ; reserves one byte for high bit of the 8x16 multiplication of low bit of factor 2 by factor 1

LowBit_2_16_16	    res 1 ; reserves one byte for low bit of the 8x16 multiplication of high bit of factor 2 by factor 1
MiddleBit_2_16_16    res 1 ; reserves one byte for middle bit of the 8x16 multiplication of high bit of factor 2 by factor 1	
HighBit_2_16_16	    res 1 ; reserves one byte for high bit of the 8x16 multiplication of high bit of factor 2 by factor 1

LowBitResult_16_16	    res 1
MiddleLowBitResult_16_16    res 1
MiddleHighBit_Result_16_16  res 1
HighBit_Result_16_16	    res 1
	    
	    
; 8x24 multiplication
LowBitFactor_24_bit	    res 1
MiddleBitFactor_24_bit	    res 1
HighBitFactor_24_bit	    res 1

LowBitResult_8_24	    res 1
MiddleLowBitResult_8_24	    res 1 
MiddleHighBitResult_8_24    res 1 	 
HighBitResult_8_24	    res 1 	 

Null			    res 1	 
HighBit_1_8_24		    res 1
			    
		    
;HexToDec
HighDecimal	    res 1
MiddleHighDecimal   res 1
MiddleLowDecimal    res 1
LowDecimal	    res 1
			    
ADC    code
    
ADC_Setup
    bsf	    TRISA,RA3	    ; use pin A3(==AN3) for input: it is the LM35 port04
    clrf    ANCON0
    bsf	    ANCON0,ANSEL3   ; set A3 to analog
    movlw   0x0d	    ; select AN0 for measurement
    movwf   ADCON0	    ; and turn ADC on
    movlw   0x30	    ; Select 4.096V positive reference
    movwf   ADCON1	    ; 0V for -ve reference and -ve input
    movlw   0xF6	    ; Right justified output
    movwf   ADCON2	    ; Fosc/64 clock and acquisition times
    return

    
ADC_Read
    bsf	    ADCON0,GO	    ; Start conversion
adc_loop
    btfsc   ADCON0,GO	    ; check to see if finished
    bra	    adc_loop
    return
    
    
ADC_mul_8_16 ; fill in Factor_8_bit, LowBitFactor_16_bit and HighBitFactor_16_bit in the main
    movf Factor_8_bit, W ; 8 bit variable
    mulwf LowBitFactor_16_bit ; Low 8 bit of the 16 bit factor multiplied by the content of W
    movf PRODL,W
    movwf LowBitResult_8_16 ; the low bit of the result is directly stored into LowBitResult_8_16
    movf PRODH,W
    movwf MiddleBit_1_8_16
    
    movf Factor_8_bit, W ; 8 bit variable
    mulwf HighBitFactor_16_bit ;8 bit of the 16 bit factor multiplied by the content of W
    movf PRODL,W
    movwf MiddleBit_2_8_16 
    movf PRODH,W
    movwf HighBit_NO_CARRY_8_16
    
    movf MiddleBit_1_8_16, W
    addwf MiddleBit_2_8_16, 0 ;with 0, the result is stored back in W
    movwf MiddleBitResult_8_16 ; the middle bit result is stored into MiddleBitResult_8_16
    movlw 0x00
    addwfc HighBit_NO_CARRY_8_16, 0 ;;with 0, the result is stored back in W
    movwf HighBitResult_8_16 ; the high bit result is stored into HighBitResult_8_16

    return
    
    
ADC_mul_16_16 ; fill in LowBitFactor_1_16_bit, HighBitFactor_1_16_bit, LowBitFactor_2_16_bit and HighBitFactor_2_16_bit in the main
    movff LowBitFactor_2_16_bit, Factor_8_bit
    movff LowBitFactor_1_16_bit, LowBitFactor_16_bit
    movff HighBitFactor_1_16_bit, HighBitFactor_16_bit
    call ADC_mul_8_16		; 0x8A x 0xBEEF
    movff LowBitResult_8_16, LowBitResult_16_16 ; the result is directly put into Result
    movff MiddleBitResult_8_16, MiddleBit_1_16_16
    movff HighBitResult_8_16, HighBit_1_16_16
	
    movff HighBitFactor_2_16_bit, Factor_8_bit
    call ADC_mul_8_16		; 0x41 x 0xBEEF
    movff LowBitResult_8_16, LowBit_2_16_16
    movff MiddleBitResult_8_16, MiddleBit_2_16_16
    movff HighBitResult_8_16, HighBit_2_16_16

    movf MiddleBit_1_16_16, W
    addwf LowBit_2_16_16, 0
    movwf MiddleLowBitResult_16_16
    
    movf HighBit_1_16_16, W
    addwfc MiddleBit_2_16_16, 0
    movwf MiddleHighBit_Result_16_16
   
    movlw 0x00
    addwfc HighBit_2_16_16, 0
    movwf HighBit_Result_16_16
    
    return
    
    
ADC_mul_8_24 ; fill in Factor_8_bit, LowBitFactor_24_bit, MiddleBitFactor_24_bit and HighBitFactor_24_bit in the main
    movff LowBitFactor_24_bit, LowBitFactor_16_bit
    movff MiddleBitFactor_24_bit, HighBitFactor_16_bit
    call ADC_mul_8_16
    movff LowBitResult_8_16, LowBitResult_8_24 ; the result is directly put into Result
    movff MiddleBitResult_8_16, MiddleLowBitResult_8_24 ; the result is directly put into Result
    movff HighBitResult_8_16, HighBit_1_8_24
    
    movf HighBitFactor_24_bit, W
    mulwf Factor_8_bit
    
    movf PRODL, W
    addwf HighBit_1_8_24, 0
    movwf MiddleHighBitResult_8_24
    
    movlw 0x00
    movwf Null
    movf PRODH, W
    addwfc Null, 0
    movwf HighBitResult_8_24
    
    return

ADC_HexToDec ; fill in LowBitFactor_1_16_bit, HighBitFactor_1_16_bit, LowBitFactor_2_16_bit and HighBitFactor_2_16_bit in the main
    call ADC_mul_16_16
    
    movff HighBit_Result_16_16, HighDecimal ; result
    
    movff MiddleHighBit_Result_16_16, HighBitFactor_24_bit
    movff MiddleLowBitResult_16_16, MiddleBitFactor_24_bit
    movff LowBitResult_16_16, LowBitFactor_24_bit
    movlw 0x0A
    movwf Factor_8_bit
    
    call ADC_mul_8_24
    
    movff HighBitResult_8_24, MiddleHighDecimal
    
    movff MiddleHighBitResult_8_24, HighBitFactor_24_bit
    movff MiddleLowBitResult_8_24, MiddleBitFactor_24_bit
    movff LowBitResult_8_24,LowBitFactor_24_bit
    
    call ADC_mul_8_24
    
    movff HighBitResult_8_24, MiddleLowDecimal
    
    movff MiddleHighBitResult_8_24, HighBitFactor_24_bit
    movff MiddleLowBitResult_8_24, MiddleBitFactor_24_bit
    movff LowBitResult_8_24,LowBitFactor_24_bit
    
    call ADC_mul_8_24
    
    movff HighBitResult_8_24, LowDecimal
    
    return
    
;ADC_HexToDec_ANCIEN ;put the Hex in as : first bit in 0x51 and  second in 0x52
    ;call ADC_mul_16_16
    ;34 is the first dec
    ;movff 0x31, 0x51
    ;movff 0x32, 0x52
    ;movff 0x33, 0x53
    ;movlw 0x0A
    ;call ADC_mul_8_24
    ;F4 is the second dec, we put in in 0x1A
    ;movff 0x4F,0x1A
    
    ;movff 0x1F, 0x51
    ;movff 0x2F, 0x52
    ;movff 0x3F, 0x53
    ;movlw 0x0A
    ;call ADC_mul_8_24
    ;F4 is the 3rd dec, we put it in 0x2A
    ;movff 0x4F,0x2A
    
    ;movff 0x1F, 0x51
    ;movff 0x2F, 0x52
    ;movff 0x3F, 0x53
    ;movlw 0x0A
    ;call ADC_mul_8_24
    ;F4 is the 4th dec, we put it in 0x3A
    ;movff 0x4F,0x3A
    
    ;decimal number is in 34,1A,2A,3A
    
    ;return
    
    end