#include p18f87k22.inc
	
global Temperature_reading
global TemperatureLow
global TemperatureHigh
    
extern ADC_mul_8_16, Factor_8_bit, LowBitFactor_16_bit, HighBitFactor_16_bit, LowBitResult_8_16, MiddleBitResult_8_16
extern ADC_Setup, ADC_Read
extern ADC_HexToDec
extern LCD_HexToDec_Display
extern LCD_Temperature_Display
extern LowBitFactor_1_16_bit, HighBitFactor_1_16_bit, LowBitFactor_2_16_bit, HighBitFactor_2_16_bit


acs0		udata_acs   ; named variables in access ram
TemperatureLow	res 1 ; reserves one byte for the low 8 bit of the temperature
TemperatureHigh	res 1 ; reserves one byte for the high 8 bit of the temperature

Sensor code

Temperature_reading ; DO NOT FORGET LCD_Setup
    call ADC_Setup ; prepares to read a value
    call ADC_Read ; triggers a measurement and stores the value in ADRESH:ADRESL
    
    movlw 0x07
    movwf Factor_8_bit
    movff ADRESL, LowBitFactor_16_bit
    movff ADRESH, HighBitFactor_16_bit
    call ADC_mul_8_16
    
    movlw 0xB9
    addwf LowBitResult_8_16, 0
    movwf LowBitFactor_1_16_bit
    movff LowBitFactor_1_16_bit, TemperatureLow 
    
    movlw 0x00
    addwfc MiddleBitResult_8_16, 0 
    movwf HighBitFactor_1_16_bit
    movff HighBitFactor_1_16_bit, TemperatureHigh 
    
    ;movff ADRESL, LowBitFactor_1_16_bit
    ;movff ADRESH, HighBitFactor_1_16_bit
	
    movlw 0x8A
    movwf LowBitFactor_2_16_bit
    movlw 0x41
    movwf HighBitFactor_2_16_bit
	
    call ADC_HexToDec

    call LCD_Temperature_Display
    
    return
    
end