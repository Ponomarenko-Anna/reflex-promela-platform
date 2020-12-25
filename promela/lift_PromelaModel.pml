//24.12.2020
//МОДЕЛЬ ЛИФТА
//Данная модель описывает модель лифта для маломобильных 
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
//лифтом на языке Reflex - lift_ReflexModel

//Variables
//clock 0t10ms;
#define ELEV_ACCEL 1
#define ELEV_MAX_SPEED 5
#define ELEV_DOWN_COORD 100
	
	bool up;
	bool down;
	bool on_top_floor; // bool on_top_floor, on_lower_floor; ?
	bool on_lower_floor; 
	
	int v;
	int coord;
//States of process
    mtype: states = {Begin, up_down};
    mtype : states state = Begin;
    

proctype ElevatorSim() {
    do:: atomic{   
    if
	:: (state == Begin) -> {	
		v = 0;
		coord = 0;
		state = up_down; // next?				
	}
	:: (state == up_down) -> {
		// calc. velocity (according to the restriction)
		if
        // if up ? 
        :: (up) -> {  
			v = v - ELEV_ACCEL;
        }
		:: else -> {
            if 
            :: (down) -> { 
			    v = v + ELEV_ACCEL;
            }
            :: else ->{
			    v = 0;
            }
            fi;
        }
		fi;


		if 
        ::(v > ELEV_MAX_SPEED) -> {
			v = ELEV_MAX_SPEED;
        }
		::else -> {
            if 
            ::(v < (0 - ELEV_MAX_SPEED)) -> { 
			    v = 0 - ELEV_MAX_SPEED;
            }
            :: else -> skip
            fi;
        }
        fi; 
		
		// calc. coordinate (according to the restriction)
		coord = coord + v;
		if 
        ::(coord < 0) -> {
			coord = 0;
        }
		::else -> {
            if
            :: (coord > ELEV_DOWN_COORD) -> {
			    coord = ELEV_DOWN_COORD;
            }
            ::else -> skip
            fi;
        }
        fi;
		
		// имитация датчиков наличия лифта на этажах по координате:
		on_top_floor = false; // подсветка false ? 
		on_lower_floor = false;
		
		if 
        ::(coord < 5) -> {  
			on_top_floor = true;
        }
		:: else -> {
            if 
            :: (coord > 95) -> { 
			on_lower_floor = true;
            }
            :: else -> skip
            fi;
        }
        fi;
	}
    :: else -> skip;
    fi;
    } od;
}

init {
    printf("Hello");
    run ElevatorSim();
}