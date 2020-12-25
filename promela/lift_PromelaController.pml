//24.12.2020
//МОДЕЛЬ ПРОГРАММЫ УПРАВЛЕНИЯ
//Данная модель описывает задачу лифта для маломобильных 
//пользователей. Лифт представляет собой альтернативу пандусу 
//и предназначен для вертикального перемещения пассажира
//на кресле-каталке между двумя разновысокими горизонтальным 
//поверхностями, этажами.
//В состав лифта входит 
//    * платформа
//    * две двери для каждого из этажей(открываются вручную) 
//    * двигатель
//    * датчики закрытия дверей (top_door_closed, bot_door_closed)
//    * кнопки вызова лифта (top_call, bot_call)
//    * кнопки управления перемещением(up_call, down_call) 
//    * датчики присутствия на этаже(on_top_floor и on_bot_floor)
//Двигатель вертикального перемещения платформы лифта управляется 
//посредством сигналов up и down.
//Данная модель построена на основе текста программы управления
//лифтом на языке Reflex - lift_ReflexController

#define on 1
#define off 0
/*===== VARIABLES =============*/
//Sensors
    bool on_top_floor; 
    bool on_bot_floor;

// Controls
	bool top_call;
	bool bot_call;
	bool up_call;
	bool down_call;
	bool top_door_closed;
	bool bot_door_closed;
	
// ============================================
// ================ Output signals ============
// ============================================
// Indicators
	bool top_call_LED;
	bool bot_call_LED;
	bool up_call_LED;
	bool down_call_LED;
	
// Actuators
	bool up;
	bool down;

// Processes state variables
    mtype: call_Latch_states = {Begin, check_ON_OFF };
    mtype : call_Latch_states state_Init;
    mtype : call_Latch_states state_top_call_Latch;
    mtype : call_Latch_states state_bot_call_Latch;
    mtype : call_Latch_states state_up_call_Latch;
    mtype : call_Latch_states state_down_call_Latch;
    
    mtype: motion_states = {check_command, check_stop} 
    mtype : motion_states state_Motion;

    mtype: go_states = {motion, inactive} 
    mtype : go_states state_go_down;
    mtype : go_states state_go_up;

//Timers variables
    int time_Motion;

// processes definition
proctype go_down() {
	atomic {
    if
	:: (state_go_down == motion)-> {
		if 
            :: (top_door_closed && bot_door_closed) -> {
                down = true;
            }
            ::else -> skip
        fi;
		if 
            :: (on_bot_floor) -> {
			    down = false;
			    //stop;
		    }
            ::else -> skip
        fi;
	}
    ::else -> skip
    fi;
    }	
}
	
proctype go_up() {
    atomic {
    if
	:: (state_go_up == motion) -> {
		if 
        :: (top_door_closed && bot_door_closed) -> {
            up = true;
        }
        ::else -> skip
        fi;
		if 
        :: (on_top_floor) -> {
			up = false;
			//stop;
        }
        ::else -> skip
        fi;
	}
    ::else -> skip
    fi;
    }	
}	

proctype Motion() { 
    atomic {
    if
	:: (state_Motion == check_command) -> {	
		if 
            :: (bot_call_LED) -> {
			run go_down();
			state_Motion = check_stop;
		}
		:: else -> {
            if 
            :: (top_call_LED) -> {
                run go_up();
                state_Motion = check_stop;
            }
            :: else -> {
                if 
                    :: (down_call_LED) -> {
                    run go_down();
                    state_Motion = check_stop;
                }
                :: else -> {
                    if 
                    :: (up_call_LED) -> {
                        run go_up();
                        state_Motion = check_stop;
                    }
                    ::else -> skip
                    fi;
                }
                fi;
            }
            fi;
        }
        fi;

        if 
        //timeout (0t20s)
        ::(time_Motion == 20) -> {// limit = timeout/time
			run go_down();//TODO change state of go_down
			state_Motion = check_stop;
		}//TODO inc time_Motion
        :: else -> skip
        fi;  							
	}
	:: (state_Motion == check_stop) -> {	
		if 
        :: ((state_go_down == inactive) &&
			    (state_go_up == inactive)) -> {
                // restart - looped
			    state_Motion = check_command; 
        }
        ::else -> skip
        fi;
	}
    ::else -> skip
    fi;
    }
}	
	
proctype down_call_Latch() { 
	bool prev_in;
	bool prev_out;
		
	atomic{
    if
	:: (state_down_call_Latch == Begin) -> {	
			prev_in = !down_call;
			prev_out = !bot_door_closed;
			state_down_call_Latch = check_ON_OFF; // next?				
		}
    //TODO if Reflex-state is looped, should be any constraints? 
	:: (state_down_call_Latch == check_ON_OFF) -> {	
		if 
            :: (down_call && !prev_in) -> {
                // pushing
				down_call_LED = true;
            }
        fi;
        if
			:: (!bot_door_closed && prev_out) -> {
                // opening 
				down_call_LED = false;
            }
        fi;
		prev_in = down_call;
		prev_out = bot_door_closed;
		}
    fi;
    }
}

proctype up_call_Latch() { 
	bool prev_in;
	bool prev_out;
		
    atomic{
    if
	:: (state_up_call_Latch == Begin) -> {	
		prev_in = !up_call;
		prev_out = !top_door_closed;
		state_up_call_Latch = check_ON_OFF; // next?				
	}
    //TODO if Reflex-state is looped, should be any constraints? 
	:: (state_up_call_Latch == check_ON_OFF) -> {	
		if 
            :: (up_call && !prev_in) -> {
                // pushing
			    up_call_LED = true;
            }
        fi;
        if
		    :: (!top_door_closed && prev_out) -> {
                 // opening 
			    up_call_LED = false;
            }
        fi;
		prev_in = up_call;
		prev_out = top_door_closed;
	} 
    fi;
    }
}

proctype bot_call_Latch() { 
	bool prev_in;
	bool prev_out;

	atomic{
    if
	:: (state_bot_call_Latch == Begin) -> {	
		prev_in = !bot_call;
		prev_out = !bot_door_closed;
		state_bot_call_Latch = check_ON_OFF; // next?				
	}
    //TODO if Reflex-state is looped, should be any constraints? 
	:: (state_bot_call_Latch == check_ON_OFF ) -> {	
		if 
            :: (bot_call && !prev_in) -> {
                // pushing
			    bot_call_LED = true;
            }
        fi;
        if
		    :: (!bot_door_closed && prev_out) -> {
                // opening 
			    bot_call_LED = false;
            }
        fi;
		prev_in = bot_call;
		prev_out = bot_door_closed;
	} 
    fi;
    }
}

proctype top_call_Latch() {
    bool prev_in;
	bool prev_out;

    atomic{
    if
    :: (state_top_call_Latch == Begin) -> {
        prev_in = !top_call;
		prev_out = !top_door_closed;
		state_top_call_Latch = check_ON_OFF;
    }
    //TODO if Reflex-state is looped, should be any constraints? 
    :: (state_top_call_Latch == check_ON_OFF) -> {
		if  
            :: (top_call && !prev_in)->{ 
                // pushing
			    top_call_LED = true;
            }
        fi;
        if
            :: (!top_door_closed && prev_out)->{ 
                // opening 
			    top_call_LED = false;
            }
        fi;
		prev_in = top_call;
		prev_out = top_door_closed;	
    }
    fi;
    }     
}

init {
    printf("Controller Initialization\n");
            run top_call_Latch();
			run bot_call_Latch();
			run up_call_Latch();
			run down_call_Latch();
			run Motion();
			//stop;      
}

