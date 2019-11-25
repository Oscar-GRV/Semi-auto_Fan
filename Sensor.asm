;Created on Fri Nov 22 2019
;version: 5
;@author: Julie Laguerre, Oscar Gravier
;function: 	The sensor outputs an analog voltage proportional to the temperature, 
		; which is converted to an hexadecimal digital value (ADC) 
		; which we calibrate and store as TemperatureLow and TemperatureHigh
		; which is then converted to a decimal value 

#include p18f87k22.inc
	
global Temperature_reading
global TemperatureLow
global TemperatureHigh
    
extern ADC_mul_8_16, Factor_8_bit, LowBitFactor_16_bit, HighBitFactor_16_bit, LowBitResult_8_16, MiddleBitResult_8_16
extern ADC_Setup, ADC_Read
extern ADC_HexToDec
extern LCD_Temperature_Display
extern LowBitFactor_1_16_bit, HighBitFactor_1_16_bit, LowBitFactor_2_16_bit, HighBitFactor_2_16_bit


acs0		udata_acs   ; named variables in access ram
TemperatureLow	res 1 ; reserves one byte for the low 8 bit of the temperature
TemperatureHigh	res 1 ; reserves one byte for the high 8 bit of the temperature

Sensor code

Temperature_reading ; Reads the temperature, adjusts it according to calibration, converts it to decimal and displays it on the screen
    call ADC_Setup ; prepares to read a value
    call ADC_Read ; triggers a measurement and stores the value in ADRESH:ADRESL
    
    movlw 0x07 ; coefficient by which we multiply the temperature according to the calibration process (see reports)
    movwf Factor_8_bit
    movff ADRESL, LowBitFactor_16_bit
    movff ADRESH, HighBitFactor_16_bit
    call ADC_mul_8_16 ; multiplies 0x07 by the hexadecimal temperature stored in ADRESH:ADRESL
    
    movlw 0xB9 ; coefficient that we add to the temperature according to the calibration process (see reports)
    addwf LowBitResult_8_16, 0 ; adds 0xB9 to the low bit of the 8x16 multiplication result and stores it back in W
    movwf LowBitFactor_1_16_bit ; stores it into LowBitFactor_1_16_bit to prepare the hexadecimal to decimal conversion
    movff LowBitFactor_1_16_bit, TemperatureLow ; stores it into TemperatureLow
    
    movlw 0x00
    addwfc MiddleBitResult_8_16, 0 ; adds 0x00 with carry to the middle bit of the 8x16 multiplication result and stores it back in W
    movwf HighBitFactor_1_16_bit ; stores it into HighBitFactor_1_16_bit to prepare the hexadecimal to decimal conversion
    movff HighBitFactor_1_16_bit, TemperatureHigh ; stores it into TemperatureHigh
	
    ; loads the value 0x418A in the right variables to start the hexadecimal to decimal conversion
    movlw 0x8A
    movwf LowBitFactor_2_16_bit
    movlw 0x41
    movwf HighBitFactor_2_16_bit
	
    call ADC_HexToDec ; converts the hexadecimal value of the temperature into a decimal value

    call LCD_Temperature_Display ; displays the temperature on the screen
    
    return
    
end
