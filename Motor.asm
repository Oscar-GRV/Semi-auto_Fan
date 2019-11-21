#include p18f87k22.inc

    global  stepper_step, Motor_step, step_counter ;start_fan, stop_fan, start_rotating,stop_rotating
    global increase_speed, decrease_speed, Motor_PWM, set_speed, temperature_speed
    global Speed_manual
    global fan_state, check_fan
    extern HighDecimal
    
    acs0	    udata_acs   ; named variables in access ram
    Motor_step	    res 1   ; reserve 1 byte for variable Motor_step
    Speed_manual    res 1   ; reserve 1 byte for variable Speed_manual
    PWM_period	    res 1   ; reserve 1 byte for variable PWM_period
    PWM_duty	    res 1   ; reserve 1 byte for variable PWM_duty
    PWM_time_pres   res 1   ; reserve 1 byte for variable PWM_time_pres    
    fan_state	    res 1   ; reserve 1 byte for variable fan_state
    step_counter    res 1   ; reserve 1 byte for variable step_counter
    
Motor    code
    
    ;Fonctions to control the fan speed :
    ;3 different speeds :
    ;Speed_manual=1, settings :
    ;Speed_manual=2, settings :
    ;Speed_manual=3, settings :
    
    increase_speed
	movlw 0x02
	cpfsgt Speed_manual ;if Speed_manual is higher than 0x02 can't be increment
	incf  Speed_manual
	call set_speed	    ;to set the speed at this new value
	return
	
    decrease_speed
	movlw 0x02
	cpfslt Speed_manual ;if Speed_manual is lower than 0x02 can't be decrement
	decf Speed_manual
	call set_speed	    ;to set the speed at this new value
	return
	
    temperature_speed
	movlw 0x02		
	cpfsgt HighDecimal
	goto temperature_if1
		movlw 0x03
		movwf Speed_manual
		call set_speed	    ;to set the speed at this new value
		goto temperature_end
		
	temperature_if1 ;go here if the high byte is 0x00  
	movlw 0x02
	cpfslt HighDecimal
	goto temperature_if2
		movlw 0x01
		movwf Speed_manual
		call set_speed	    ;to set the speed at this new value   
		goto temperature_end
	
	temperature_if2
	    movlw 0x02
	    movwf Speed_manual
	    call set_speed	    ;to set the speed at this new value   
	    goto temperature_end
	
	temperature_end
	return
	   
    set_speed
	movlw 0x02
	cpfslt Speed_manual ;if Speed_manual=1 set the fan at the speed 1
	goto set_speed_if1
    
	    movlw 0xFF ;Set the PWM PERIOD
	    movwf PWM_period

	    
	    movlw B'00000110' ;time prescaler : last 2bit : 00 =1 01=4 10=16
	    movwf PWM_time_pres
	    
	    movlw 0x01
	    movwf PWM_duty
	    call Motor_PWM
	    goto set_speed_ifend 
	    
	set_speed_if1
	movlw 0x02
	cpfseq Speed_manual ;if Speed_manual=2 set the fan at the speed 2
	goto set_speed_if2
	    movlw 0x17 ;Set the PWM PERIOD
	    movwf PWM_period
	    
	    movlw B'00000110' ;time prescaler : last 2bit : 00 =1 01=4 10=16
	    movwf PWM_time_pres
	    
	    movlw 0x10
	    movwf PWM_duty
	    call Motor_PWM
	    
	    goto set_speed_ifend
    
	set_speed_if2
	movlw 0x02
	cpfsgt Speed_manual ;if Speed_manual=3 set the fan at the speed 3
	goto set_speed_ifend
	    movlw 0x17 ;Set the PWM PERIOD
	    movwf PWM_period

	    movlw B'00000110' ;time prescaler : last 2bit : 00 =1 01=4 10=16
	    movwf PWM_time_pres
	    
	    movlw 0x14
	    movwf PWM_duty
	    call Motor_PWM
	    
	set_speed_ifend
	return 
	
	
    ;fonction to control the rotation :
    
    ;stepper_step
    ;Each call will do a step in the rotation.
	
	;step 1 : red=-;yellow=-;green=+,blue=+
	;so input11=L input12=L and input21=H input22=H
	
	;step 2 : red=+;yellow=-;green=-,blue=+
	;so input11=H input12=L and input21=L input22=H
	
	;step 3 : red=+;yellow=+;green=-,blue=-
	;so input11=H input12=H and input21=L input22=L
	
	;step 4 : red=-;yellow=+;green=+,blue=-
	;so input11=L input12=H and input21=H input22=L
	
	stepper_step
	
	incf step_counter
	
	;Direction of rotation
	movlw 0x3C
	cpfslt step_counter ;When the fan has done a return set the counter to 0
	clrf step_counter
	
	movlw 0x1E
	cpfsgt step_counter ;When we have done 30 steps, change the direction
	goto other_direction
	
	;Chek Motor_step, if Motor_step>=0x04 set Motor_step to 0
	;here for =
	movlw 0x04
	cpfseq Motor_step
	goto sup
	    movlw 0x00		;If Motor_step=4 set Motor_step to 0
	    movwf Motor_step
	
	;here for >
	sup
	movlw 0x04
	cpfsgt Motor_step
	goto incr
	    movlw 0x00		;If Motor_step>4 set Motor_step to 0
	    movwf Motor_step
	
	;Increment Motor_step to do the next step
	incr
	movlw 0x01
	addwf	Motor_step	;Add 0x01 to Motor_step
	
	movlw 	0x0
	movwf	TRISD, ACCESS	;PORTD all output, input of the L298N chip
	
	movlw 0x01
	cpfseq Motor_step
	goto if1
	    ;step 1 : red=-;yellow=-;blue=+,white=+
	    ;so input11=L input12=L and input21=H input22=H
	    ;PORTD : RB0=L RB1=L RB2=H RB3=H
	    bcf PORTD,0
	    bcf PORTD,2
	    bsf PORTD,3
	    bsf PORTD,4
	    bsf PORTD,5
	    goto ifend
	if1
	movlw 0x02
	cpfseq Motor_step
	goto if2
	    ;step 2 : red=+;yellow=-;blue=-,white=+
	    ;so input11=H input12=L and input21=L input22=H
	    ;PORTD : RB0=H RB1=L RB2=L RD3=H
	    bsf PORTD,0
	    bcf PORTD,2
	    bcf PORTD,3
	    bsf PORTD,4
	    bsf PORTD,5
	    goto ifend
	if2
	movlw 0x03
	cpfseq Motor_step
	goto if3
	    ;step 3 : red=+;yellow=+;blue=-,white=-
	    ;so input11=H input12=H and input21=L input22=L
	    ;PORTD : RB0=H RB1=H RB2=L RB3=L
	    bsf PORTD,0
	    bsf PORTD,2
	    bcf PORTD,3
	    bcf PORTD,4
	    bsf PORTD,5
	    goto ifend
	if3
	movlw 0x04
	cpfseq Motor_step
	goto ifend
	    ;step 4 : red=-;yellow=+;blue=+,white=-
	    ;so input11=L input12=H and input21=H input22=L
	    ;PORTD : RB0=L RB1=H RB2=H RB3=L
	    bcf PORTD,0
	    bsf PORTD,2
	    bsf PORTD,3
	    bcf PORTD,4
	    bsf PORTD,5
	    goto ifend
	    
	ifend
	goto stepper_motor_end
	
	
	;;;OTHER DIRECTION;;;
	other_direction
	
	;chek Motor_step, if Motor_step>=0x04 set Motor_step to 0
	;here for =
	movlw 0x04
	cpfseq Motor_step
	goto sup2
	    movlw 0x00
	    movwf Motor_step
	
	;here for >
	sup2
	movlw 0x04
	cpfsgt Motor_step
	goto incr2
	    movlw 0x00
	    movwf Motor_step
	;increment Motor_step to do the next step
	incr2
	movlw 0x01
	addwf	Motor_step
	
	movlw 	0x0
	movwf	TRISD, ACCESS	;PORTD all output
	
	movlw 0x04
	cpfseq Motor_step
	goto if12
	    ;step 1 (other direction step 4) : red=-;yellow=-;blue=+,white=+
	    ;so input11=L input12=L and input21=H input22=H
	    ;PORTD : RB0=L RB1=L RB2=H RB3=H
	    bcf PORTD,0
	    bcf PORTD,2
	    bsf PORTD,3
	    bsf PORTD,4
	    bsf PORTD,5
	    bsf PORTD,6
	    goto ifend2
	if12
	movlw 0x03
	cpfseq Motor_step
	goto if22
	    ;step 2 (other direction step 3): red=+;yellow=-;blue=-,white=+
	    ;so input11=H input12=L and input21=L input22=H
	    ;PORTD : RB0=H RB1=L RB2=L RD3=H
	    bsf PORTD,0
	    bcf PORTD,2
	    bcf PORTD,3
	    bsf PORTD,4
	    bsf PORTD,5
	    bsf PORTD,6
	    goto ifend2
	if22
	movlw 0x02
	cpfseq Motor_step
	goto if32
	    ;step 3 (other direction step 2): red=+;yellow=+;blue=-,white=-
	    ;so input11=H input12=H and input21=L input22=L
	    ;PORTD : RB0=H RB1=H RB2=L RB3=L
	    bsf PORTD,0
	    bsf PORTD,2
	    bcf PORTD,3
	    bcf PORTD,4
	    bsf PORTD,5
	    bsf PORTD,6
	    goto ifend2
	if32
	movlw 0x01
	cpfseq Motor_step
	goto ifend2
	    ;step 4 (other direction step 1): red=-;yellow=+;blue=+,white=-
	    ;so input11=L input12=H and input21=H input22=L
	    ;PORTD : RB0=L RB1=H RB2=H RB3=L
	    bcf PORTD,0
	    bsf PORTD,2
	    bsf PORTD,3
	    bcf PORTD,4
	    bsf PORTD,5
	    bsf PORTD,6
	    goto ifend2
	    
	ifend2
	
	stepper_motor_end

	
	return
	

    ;PWM PERIOD = [(PR2)+1] * 4 * TOSC * (TMR2 PRESCALE VALUE) ;PR2 = TMR2 PERIOD REGISTER, TOSC = PIC CLOCK PERIOD (FOSC = 1 / TOSC)
    ;PWM DUTY CYCLE = (CCPR1L:CCP1CON<5:4>) * TOSC * (TMR2 PRESCALE VALUE)
    
    Motor_PWM
    ;;;SET PWM FREQUENCY;;;
	MOVF PWM_period,W ;SET PR2 TO 128 DECIMAL SO THE PWM PERIOD = 2064uS => PWM FREQUENCY = 484Hz
	MOVWF PR2

    ;;;SET PWM STARTING DUTY CYCLE;;;
	movf PWM_duty, W
	movwf CCPR4L

	bsf CCP4CON,DC4B1  ;CCP1CON5
	bsf CCP4CON,DC4B0  ;CCP1CON4
    
    ;;;SET PWM PIN TO OUTPUT MODE;;;
	setf TRISG
	movlw 0x00
	movwf TRISG, ACCESS
	
    ;;;SET TIMER 2 PRESCALE VALUE;;;
	;PRESCALE = 16 SO THE PWM PERIOD = 2064uS => PWM FREQUENCY = 484Hz
	MOVf PWM_time_pres, W
	MOVWF T2CON

	;;;CLEAR TIMER 2 MODULE;;;
	CLRF TMR2
	
	;;;ENABLE TIMER 2 MODULE;;;
	BSF T2CON, TMR2ON
	
	BCF PMD3,CCP4MD
	bsf CCP4CON, CCP4M3
	bsf CCP4CON, CCP4M2
	
    return
    
check_fan
    bsf TRISC,6
    movf PORTC, W
    movwf fan_state
    return
    
    end