#include p18f87k22.inc

;extern keypad
extern Keypad_reading, Keypad_touch
;extern motor
extern stepper_step, Motor_step, step_counter
extern Motor_PWM, set_speed, increase_speed, decrease_speed, temperature_speed    ;, Speed_temperature, Speed_manual, Speed_rotation ;DAC_Setup
extern Speed_manual ;, Speed_temperature;Speed_rotation
extern fan_state, check_fan
    
extern ADC_Setup, ADC_Read

extern ADC_mul_16_16
extern LowBitFactor_1_16_bit, HighBitFactor_1_16_bit, LowBitFactor_2_16_bit, HighBitFactor_2_16_bit
extern ADC_HexToDec
extern LCD_HexToDec_Display
extern LCD_Temperature_Display
extern LowDecimal, MiddleLowDecimal, MiddleHighDecimal, HighDecimal
extern Temperature_reading
extern TemperatureLow
extern TemperatureHigh
	
    
extern LCD_Setup, LCD_delay_ms;, LCD_8_16_Display
    
;externe sensor
extern Temperature_reading
extern LCD_Speed_Display, LCD_Stop_Display


acs0		udata_acs   ; named variables in access ram
speed_state	res 1   ; reserve 1 byte for variable speed_state
rotating_mode	res 1   ; reserve 1 byte for variable speed_state
	
rst code 0x0000 ; reset vector
goto start

main code
start

;Mesure the temperature and display it
call LCD_Setup ; ALWAYS!!!!!!

call Temperature_reading
   
;set PORTC to 0x00 for on/off test
movlw 0x00
movwf PORTC
 
;add the function to set the speed regarding the temperature
call temperature_speed
movlw 0x00
movwf speed_state

;set the step counter to 0
movlw 0x00
movwf step_counter
 
general_loop

;Mesure the temperature and display it
call LCD_Setup ; ALWAYS!!!!!!
call Temperature_reading

;chek if the fan is running or not if not skip all the rest
clrf TRISC
call check_fan
movlw 0x00
cpfseq fan_state    ;if PORTC != 0x00 the fan is working
goto check_end
    call LCD_Stop_Display
    goto start
check_end
    
;display the speed of the fan
call LCD_Speed_Display 

;set the speed of the fan at temperature speed if not in control mode
;speed_state=0 temperature mode
;speed_state=1 control mode
movlw 0x01
cpfseq speed_state
call temperature_speed

;roatation of the fan if rotating_mode = 1
movlw 0x00
cpfseq rotating_mode  
call stepper_step

;Keypad reading
call Keypad_reading
 
;read the Keypad_touch variable and call function in function of this
;1-start/go to temperature speed : * (0E,70)
;2-stop everythings: 0     (0E,B0)
;3-Faster : B     (0B,E0)
;4-Lower : C     (0D,E0)
;5-start rotating : 4     (0B,70)
;6-Stop rotating : 5     (0B,B0)

;if keypad_touch=1 call temperature_speed  -> set speed fan to temperature_speed
;if keypad_touch=2 call stop_fan   -> set all to zero : speed = 0 and rotating speed =0
;if keypad_touch=3 call increase_speed -> ad a constant to Speed_manual
;if keypad_touch=4 call decrease_speed -> remove a constant to Speed_manual
;if keypad_touch=5 call start_rotating -> set Speed_rotation to the choice value (by us)
;if keypad_touch=6 call stop_rotating -> set Speed_rotation to zero
; At the end of each if : keypad_touch is set to 0

;at the end, set keypad_touch to 0 so no double reading

;then display Speed_manual and Sensor_temperature
;goto $ -> do it again !

;if fonction to decomented

movlw 0x01
 cpfseq Keypad_touch
 goto if2
    call temperature_speed
    clrf Keypad_touch
    movlw 0x00		    ; set speed_state to 0 (temperature one)
    movwf speed_state
    goto ifend
   
; if1
; movlw 0x02
; cpfseq keypad_touch
; goto if2
;    call temperature_speed
;    bcf keypad_touch
;    goto ifend
    
 if2
 movlw 0x03
 cpfseq Keypad_touch
 goto if3
    call increase_speed
    clrf Keypad_touch
    movlw 0x01		    ; set speed_state to 1 (temperature one)
    movwf speed_state
    goto ifend

 if3
 movlw 0x04
 cpfseq Keypad_touch
 goto if4
    call decrease_speed
    clrf Keypad_touch
    movlw 0x01		    ; set speed_state to 1 (temperature one)
    movwf speed_state
    goto ifend

 if4
 movlw 0x05
 cpfseq Keypad_touch
 goto if5
    clrf Keypad_touch
    movlw 0x01		    ; set rotating_mode to 1 (temperature one)
    movwf rotating_mode
    goto ifend
    
 if5
 movlw 0x06
 cpfseq Keypad_touch
 goto ifend
    clrf Keypad_touch
    movlw 0x00		    ; set rotating_mode to 0 (temperature one)
    movwf rotating_mode
   goto ifend
   
ifend



    goto general_loop ; Sit in infinite loop

end

