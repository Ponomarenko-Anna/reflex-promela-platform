// ========== program Controller 

//	clock 0t10ms; *** 1 цикл 
// *** время увеличивается на 1 за цикл
// *** в соотвествии с эти привести значения таймаутов
	
// ============================================
// ============ Input signals =================
// ============================================

//	Sensors
	bool on_top_floor; // bool on_top_floor, on_lower_floor; ?
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
	
// ============================================
// ================ Constants ============
// ============================================

#define ELEV_ACCEL 1;
#define ELEV_MAX_SPEED 5;
#define ELEV_DOWN_COORD 100;
	
// ============================================
// ================ Auxiliary signals ============
// ============================================
short v; // float v = 100.0; ?
short coord;

// *******************************************
// ================ Promela special ============
// ============================================

// ==== Функциональные состояния ====
mtype: FunStates = {Begin, up_down, check_ON_OFF, check_command, check_stop, motion, error, stop};

// Инициализация
mtype : FunStates st_Elevator = stop; 
mtype : FunStates st_top_call_Latch = stop;
mtype : FunStates st_bot_call_Latch = stop;
mtype : FunStates st_up_call_Latch = stop;
mtype : FunStates st_down_call_Latch = stop;
mtype : FunStates st_Motion_p = stop; 
mtype : FunStates st_go_down = stop;
mtype : FunStates st_go_up = stop;


// ====== Таймеры ========
int time_Motion = -1;

// ====== Диспетчерская ========
mtype : process = { Environment_n, Elevator_n, 
					top_call_Latch_n, bot_call_Latch_n,
					up_call_Latch_n, down_call_Latch_n,
					Motion_p_n, go_down_n, go_up_n}; // имена процессов для передачи хода
chan turn = [ 1 ] of { mtype : process} // канал передачи хода

// ====== Активность ========
//mtype : process actv = Environment_n;

//bool act_Elevator; 
//bool act_top_call_Latch;
//bool act_bot_call_Latch;
//bool act_up_call_Latch;
//bool act_down_call_Latch;
//bool act_Motion_p;
bool act_go_down;
bool act_go_up;

// ========== Environment data ==============

proctype Environment() { 
	do
	::	turn ? Environment_n;		
		atomic{
		if 
			:: top_call = true;
			:: top_call = false;
			:: bot_call = true;
			:: bot_call = false;
			:: up_call = true;
			:: up_call = false;
			:: down_call = true;
			:: down_call = false;
			:: top_door_closed = true;
			:: top_door_closed = false;
			:: bot_door_closed = true;
			:: bot_door_closed = false;
			:: else -> skip;
		fi;
		if 
			:: ( time_Motion > -1 ) -> time_Motion++;
			:: else -> skip;
		fi;
		}
		turn ! Elevator_n;
	od;
	}

// ==========  program Plant 

proctype Elevator() { 
	do
	::	turn ? Elevator_n;		
		atomic{
		if 
			:: st_Elevator == Begin -> 	
				v = 0;
				coord = 0;
				st_Elevator = up_down; // next?				
				
			::	st_Elevator == up_down 	
				// calc. velocity (according to the restriction)
				if 
					:: up -> v = v - ELEV_ACCEL;		// if up ? 
					:: down -> v = v + ELEV_ACCEL;
					:: else -> v = 0;
				fi
				if 
					:: v > ELEV_MAX_SPEED -> v = ELEV_MAX_SPEED;
					:: v < -ELEV_MAX_SPEED -> v = -ELEV_MAX_SPEED;
					:: else -> skip;
				fi
				// calc. coordinate (according to the restriction)
				coord = coord + v;
				if 
					:: (coord < 0) -> coord = 0;
					:: coord > ELEV_DOWN_COORD -> coord = ELEV_DOWN_COORD;
					:: else -> skip;
				fi
				// имитация датчиков наличия лифта на этажах по координате:
				on_top_floor = false; // подсветка false ? 
				on_bot_floor = false;
				if 
					:: (coord < 5)  ->	on_top_floor = true;
					:: (coord > 95) ->	on_bot_floor = true;
					:: else -> skip;
				fi
				
			:: 	else -> skip;// 
		fi;
		}
		turn ! top_call_Latch_n;
	od;
	}


// ========== program Controller 

proctype top_call_Latch() { //
	bool prev_in;
	bool prev_out;
		
	do
	::	turn ? top_call_Latch_n;		
		atomic{
		if
			:: 	st_top_call_Latch == Begin -> 	
					prev_in = !top_call;
					prev_out = !top_door_closed;
					st_top_call_Latch = check_ON_OFF; // next?				
				
			::	st_top_call_Latch == check_ON_OFF -> 
					if 
						:: (top_call && !prev_in) -> top_call_LED = true;// pushing
						:: else -> skip;
					fi;
					if 
						:: (!top_door_closed && prev_out) -> top_call_LED = false; // opening 
						:: else -> skip;
					fi;				
					prev_in = top_call;
					prev_out = top_door_closed;
				
			:: 	else -> skip;// 
		fi;
		}
		turn ! bot_call_Latch_n;
	od;
	}
	
proctype bot_call_Latch() { //
	bool prev_in;
	bool prev_out;
		
	do
	::	turn ? bot_call_Latch_n;		
		atomic{
		if
			:: 	st_bot_call_Latch == Begin -> {	
					prev_in = !bot_call;
					prev_out = !bot_door_closed;
					st_bot_call_Latch = check_ON_OFF; // next?				
				}
			::	st_bot_call_Latch == check_ON_OFF -> {	
					if 
						:: (bot_call && !prev_in) -> bot_call_LED = true;// pushing
						:: else -> skip;
					fi;
					if 
						:: (!bot_door_closed && prev_out) -> bot_call_LED = false; // opening 
						:: else -> skip;
					fi;				
					prev_in = bot_call;
					prev_out = bot_door_closed;
				}
			:: 	else -> skip;// 
		fi;
		}
		turn ! up_call_Latch_n;
	od;
	}	

proctype up_call_Latch() { //
	bool prev_in;
	bool prev_out;
		
	do
	::	turn ? up_call_Latch_n;		
		atomic{
		if
			:: 	st_up_call_Latch == Begin -> {	
					prev_in = !up_call;
					prev_out = !top_door_closed;
					st_up_call_Latch = check_ON_OFF; // next?				
				}
			::	st_up_call_Latch == check_ON_OFF -> {	
					if 
						:: (up_call && !prev_in) -> up_call_LED = true;// pushing
						:: else -> skip;
					fi;
					if 
						:: (!top_door_closed && prev_out) -> up_call_LED = false; // opening 
						:: else -> skip;
					fi;				
					prev_in = up_call;
					prev_out = top_door_closed;
				}
			:: 	else -> skip;// 
		fi;
		}
		turn ! down_call_Latch_n;
	od;
	}	

proctype down_call_Latch() { //
	bool prev_in;
	bool prev_out;
		
	do
	::	turn ? down_call_Latch_n;		
		atomic{
		if
			:: 	st_down_call_Latch == Begin -> {	
					prev_in = !down_call;
					prev_out = !bot_door_closed;
					st_down_call_Latch = check_ON_OFF; // next?				
				}
			::	st_down_call_Latch == check_ON_OFF -> {	
					if 
						:: (down_call && !prev_in) -> down_call_LED = true;// pushing
						:: else -> skip;
					fi;
					if 
						:: (!bot_door_closed && prev_out) -> down_call_LED = false; // opening 
						:: else -> skip;
					fi;				
					prev_in = down_call;
					prev_out = bot_door_closed;
				}
			:: 	else -> skip;// 
		fi;
		}
		turn ! Motion_p_n;
	od;
	}	

proctype Motion_p() { // уникальные имена
		
	do
	::	turn ? Motion_p_n;		
		atomic{
		if
			:: st_Motion_p == check_command -> 	
				if  // ******  if-else-if -- важен ли приоритет??
				:: (bot_call_LED) ->{
					st_go_down = motion;
					act_go_down = true;
					st_Motion_p = check_stop;
						time_Motion = -1;
						}
				:: else -> 
					if 
					:: (top_call_LED) -> {
						st_go_up = motion;
						act_go_up = true;
						st_Motion_p = check_stop;
						time_Motion = -1;
						}
					:: else -> 
						if 
						:: (down_call_LED) -> {
							st_go_down = motion;
							act_go_down = true;
							st_Motion_p = check_stop;
							time_Motion = -1;
							}
						:: else -> 
							if 
							:: (up_call_LED) -> {
								st_go_up = motion;
								act_go_up = true;
								st_Motion_p = check_stop;
								time_Motion = -1;
								}	
							:: else -> 
								if 
								:: (on_top_floor && time_Motion == -1) -> time_Motion = 0;
								:: (on_top_floor && time_Motion == 20) -> {
									st_go_down = motion;
									act_go_down = true;
									time_Motion = -1;
									st_Motion_p = check_stop;
									}
								:: else -> skip;														
								fi;
							fi;
						fi;
					fi;
				fi;
			:: st_Motion_p == check_stop -> 	
					if 
						:: ((!act_go_down) && (!act_go_up)) ->
								st_Motion_p = check_command; // restart - looped
						:: else -> skip;
					fi;
					
			:: else -> skip;
		fi;
		}
		turn ! go_down_n;
	od;
	}
	
proctype go_down() { //
	do
	::	turn ? go_down_n;		
		atomic{
		if
			:: st_go_down == motion -> {
				if 
					:: (top_door_closed && bot_door_closed) -> down = true;
					:: else -> skip;
				fi
				if 
					:: (on_bot_floor) -> {
							down = false;
							st_go_down = stop;
							act_go_down = false;
						}
					:: else -> skip;
				fi
				}
			:: st_go_down == stop -> skip;
			:: else -> skip;
		fi;
		}
		turn ! go_up_n;
	od;
	}
	
proctype go_up() { //
	do
	::	turn ? go_up_n;		
		atomic{
		if
			:: st_go_up == motion -> {
				if 
					:: (top_door_closed && bot_door_closed) -> up = true;
					:: else -> skip;
				fi
				if 
					:: (on_top_floor) -> {
							up = false;
							st_go_up = stop;
							act_go_up = false;
						}
					:: else -> skip;
				fi
				}
			:: st_go_up == stop -> skip;
			:: else -> skip;
		fi;
		}
		turn ! Environment_n;
	od;
	}

init { // *** напрямую, состояния ему не надо 
	
	// *** Нужно тут запустить (run) вообще все процессы системы, 
	// *** но активны они будут только когда до них очередь дойдёт.
	run Environment();
	run Elevator();
	run top_call_Latch();
	run bot_call_Latch();
	run up_call_Latch();
	run down_call_Latch();
	run Motion_p();
	run go_down();
	run go_up();
	
	// Активности
// эти тут не нужны
//	act_Elevator = true; 
//	act_top_call_Latch = true;
//	act_bot_call_Latch = true;
//	act_up_call_Latch = true;
//	act_down_call_Latch = true;
//	act_Motion_p = true;	
	
	// Состояния
	st_Elevator = Begin; 
	st_top_call_Latch = Begin;
	st_bot_call_Latch = Begin;
	st_up_call_Latch = Begin;
	st_down_call_Latch = Begin;
	st_Motion_p = check_command; 
	
	// Поехали!
	turn ! Environment_n;
	}
	
// ltl p1 {[]!(up && down)}	// TRUE

// G ¬ ( open ∧ move ), move = up ∨ down, open = ¬(top_door_closed ∧ bot_door_closed)
// ltl p2 {[]!( !(top_door_closed && bot_door_closed) && (up || down))} // FALSE
 ltl p2 {[]((up || down) -> (top_door_closed && bot_door_closed))} // FALSE

// (¬ move W (up_call ∨ down_call ∨ bot_call ∨ top_call ))
 // ltl p3 {[]( !(up || down) -> !(up || down) W (up_call || down_call || bot_call || top_call) )} // FALSE

// (wait W (wait_time ≥ 20 ∧ down)), wait = on_top ∧  ¬ (up_call ∨ down_call ∨ top_call ∨ bot_call) 
// ltl p4 {[]((on_top_floor && !(up_call || down_call || top_call || bot_call)) -> (on_top_floor && !(up_call || down_call || top_call || bot_call)) W ( time_Motion >= 2 && down ))}
	



