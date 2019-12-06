module PokemonSelect
	(
		CLOCK_50,						//	On Board 50 MHz
		KEY,							// On Board Keys
		SW,
		LEDR,
		HEX2,
		HEX4,
		// The ports below are for the VGA output.  
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;	
	input	[9:0]	SW;
	output [9:0] LEDR;
	output [6:0] HEX2;
	output [6:0] HEX4;	
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	
	wire resetn;
	assign resetn = SW[0];
	wire go = ~KEY[0];
	
	wire [5:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	
   wire [7:0] data_out;
   wire [6:0] pokemon1;
   wire [6:0] pokemon2;
   wire [3:0] d1; 
   wire [3:0] d2;
	
	wire writeEn = 1'b1;  //write enable for VGA, always on
	
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 2;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
		
		//Displays pokemon on HEXs (1 for charmander, 2 for squirtle, etc) for debugging, taken out for now
		//assign HEX0 = pokemon1; 
		//assign HEX1 = pokemon2;
		assign LEDR [7:0] = data_out;

		//Health of each pokemon on HEXS
		seg7 player1(d1[3], d1[2], d1[1], d1[0], HEX4[0],HEX4[1],HEX4[2],HEX4[3],HEX4[4],HEX4[5],HEX4[6]);
		seg7 player2(d2[3], d2[2], d2[1], d2[0], HEX2[0],HEX2[1],HEX2[2],HEX2[3],HEX2[4],HEX2[5],HEX2[6]);
		
		//calling top module of data and control
		dataAndControl D1(CLOCK_50,resetn,~KEY[3],~KEY[2],~KEY[1],go,colour,x,y,data_out,pokemon1,pokemon2,d1,d2,LEDR[9],LEDR[8]);
		
		
endmodule


module dataAndControl(
    input clk,
    input resetn,
    input select1,
	 input select2,
	 input select3,
	 input go,
	 
	 output [5:0] data_c,
    output [7:0] data_x,
	 output [6:0] data_y,
	 
	 output [7:0] data,
	 output [6:0] pokemon1,
	 output [6:0] pokemon2,
	 output [3:0] healthP1,
	 output [3:0] healthP2,
	 output p1win, p2win
	 
    );

    // lots of wires to connect our datapath and control
    wire control_m, control_s, control_g;
	 wire p1_o1,p1_o2,p1_o3,p2_o1,p2_o2,p2_o3,p1s,p2s, p1m, p2m, player_1_wins, player_2_wins;
	 wire first_background, fight_background, draw_poke1, draw_poke_2, draw_anim, draw_anim2, draw_anim3, draw_background_back, draw_message, draw_message2; 
	 
	 wire sp_mv1, sp_mv2, basic1, basic2;
	 
	 
	 //wires for RateDivider
	 wire done_full;
	 wire done_sprite;
	 wire done_full_2;
	 wire done_sprite_2;
	 wire done_anim;
	 wire done_anim2;
	 wire done_anim3;
	 wire done_background_back;
	 wire done_draw_message;
	 wire done_draw_message2;
	 wire [25:0] rate1;
	 wire [25:0] rate2;
	 wire [25:0] rate3;
	 wire [25:0] rate4;
	 wire [25:0] rate5;
	 wire [25:0] rate6;
	 wire [25:0] rate7;
	 wire [25:0] rate8;
	 wire [25:0] rate9;
	 wire [25:0] rate10;
	 wire counter_enable;
	 wire counter_enable_fightscreen;
	 wire counter_enable_sprite1;
	 wire counter_enable_sprite2;
	 wire counter_enable_anim;
	 wire counter_enable_anim2;
	 wire counter_enable_anim3;
	 wire counter_enable_background_back;
	 wire counter_enable_message;
	 wire counter_enable_message2;
	 
	
	 
	 RateDivider ratedivider_big (26'b00000000001111111111111111, rate1, clk, counter_enable);
	 RateDivider ratedivider_small (26'b00000000001111111111111111, rate2, clk, counter_enable_sprite1);
	 
	 RateDivider ratedivider_big_2(26'b00000000001111111111111111, rate3, clk, counter_enable_fightscreen);
	 
	 RateDivider ratedivider_small_2(26'b00000000001111111111111111, rate4, clk, counter_enable_sprite2);
	 
	 RateDivider ratedivider_anim (26'b00000000001111111111111111, rate5, clk, counter_enable_anim);
	 
	 RateDivider ratedivider_background_back (26'b00000000001111111111111111, rate6, clk, counter_enable_background_back);
	 
	 RateDivider ratedivider_message (26'b10111110101111000001111111, rate7, clk, counter_enable_message);
	 
	 RateDivider ratedivider_message2 (26'b10111110101111000001111111, rate9, clk, counter_enable_message2);
	 
	 RateDivider ratedivider_anim2 (26'bb00000000001111111111111111, rate8, clk, counter_enable_anim2);

	 RateDivider ratedivider_anim3 (26'bb00000000001111111111111111, rate10, clk, counter_enable_anim3); 
	  

	 //signals mean that drawing is done
	 assign done_full = (rate1 == 26'b00000000000000000000000000) ? 1 : 0;
	 assign done_sprite = (rate2 == 26'b00000000000000000000000000) ? 1 : 0;
	 assign done_full_2 = (rate3  == 26'b00000000000000000000000000) ? 1 : 0;
	 assign done_sprite_2 = (rate4  == 26'b00000000000000000000000000) ? 1 : 0;
	 assign done_anim = (rate5 == 26'b00000000000000000000000000) ? 1 : 0;
	 assign done_anim2 = (rate8 == 26'b00000000000000000000000000) ? 1 : 0;
	 assign done_background_back = (rate6 == 26'b00000000000000000000000000) ? 1 : 0;
	 assign done_draw_message = (rate7 == 26'b00000000000000000000000000) ? 1 : 0; 
	 assign done_draw_message2 = (rate9 == 26'b00000000000000000000000000) ? 1 : 0;
	 assign done_anim3 = (rate10 == 26'b00000000000000000000000000) ? 1 : 0;
	 

	 
	 //instantiate control and datapath and connect them together
    control C0(
        .clk(clk),
        .resetn(resetn),
        
        .select1(select1),
		  .select2(select2),
		  .select3(select3),
		  .go(go),
		  
		  .finished_battle_print(done_full),
		  .finish_first_poke_print(done_sprite),
		  
		  .finish_actual_battle_print(done_full_2),
		  
		  .finish_second_poke_print(done_sprite_2),
		  
		  .finished_anim(done_anim),
		  
		  .finished_anim2(done_anim2),
		  
		  .finished_anim3(done_anim3),
		  
		  .finished_background_back(done_background_back),
		  
		  .finished_message(done_draw_message),
		  
		  .finished_message2(done_draw_message2),
        
		  .p11(p1_o1),
		  .p12(p1_o2),
		  .p13(p1_o3),
		  .p21(p2_o1),
		  .p22(p2_o2),
		  .p23(p2_o3),
		  .p1_select(p1s),
		  .p2_select(p2s),
		  .p1_move(p1m),
		  .p2_move(p2m),
		  
		  .p1_win(p1win), 
		  .p2_win(p2win),
			  
		  .basic1(basic1),
		  .basic2(basic2),
		  .sp1(sp_mv1),
		  .sp2(sp_mv2),
		  
        .start(control_s),
		  
		  .player_1_wins(player_1_wins),
		  .player_2_wins(player_2_wins),
		  
		  
		  .counter_enable(counter_enable),
		  .counter_enable_fightscreen(counter_enable_fightscreen),
		  .counter_enable_sprite1(counter_enable_sprite1),
		  .counter_enable_sprite2(counter_enable_sprite2),
		  
		  .counter_enable_anim(counter_enable_anim),
		  .counter_enable_anim2(counter_enable_anim2),
		  .counter_enable_anim3(counter_enable_anim3),
		  .counter_enable_background_back(counter_enable_background_back),
	     .counter_enable_message(counter_enable_message),
		  .counter_enable_message2(counter_enable_message2),
	 
		  
		  .first_background(first_background),
		  .fight_background(fight_background),
		  .draw_poke1(draw_poke1),
		  .draw_poke_2(draw_poke_2),
		  .draw_anim(draw_anim),
		  .draw_anim2(draw_anim2),
		  .draw_anim3(draw_anim3),
		  .draw_background_back(draw_background_back),
		  .draw_message(draw_message),
		  .draw_message2(draw_message2)
		  
		
    );

    datapath D0(
        .clk(clk),
        .resetn(resetn),
		  
		  .p11(p1_o1),
		  .p12(p1_o2),
		  .p13(p1_o3),
		  .p21(p2_o1),
		  .p22(p2_o2),
		  .p23(p2_o3),
		  .p1_select(p1s),
		  .p2_select(p2s),
		  .p1_move(p1m),
		  .p2_move(p2m),
		  
		  .select1(select1),
		  .select2(select2),
		  .select3(select3),
		  .go(go),
		 
		  .basic1(basic1),
		  .basic2(basic2),
		  .sp1(sp_mv1),
		  .sp2(sp_mv2),
		  .player_1_wins(player_1_wins),
		  .player_2_wins(player_2_wins),
		  
		  
        .start(control_s),
		  
		  .first_background(first_background),
		  .fight_background(fight_background),
		  .draw_poke1(draw_poke1),
		  .draw_poke_2(draw_poke_2),
		  .draw_anim(draw_anim),
		  .draw_anim2(draw_anim2),
		  .draw_anim3(draw_anim3),
		  .draw_background_back(draw_background_back),
		  .draw_message(draw_message),
		  .draw_message2(draw_message2),
		  
		  .data(data),
		  .pokemon1(pokemon1),
		  .pokemon2(pokemon2),
		  .health_output_p1(healthP1),
		  .health_output_p2(healthP2),
		 
		  .p1_win(p1win), 
		  .p2_win(p2win),
		  


		  .data_c(data_c),
		  .data_x(data_x),
		  .data_y(data_y)
		  
    );
                
 endmodule        


//control, has state diagram and decides when to move on to next state
module control(
    input clk,
    input resetn,
    input select1, select2, select3,
	 input go,
	 input finished_battle_print,
	 input finish_first_poke_print,
	 input finish_actual_battle_print,
	 input finish_second_poke_print,
	 input finished_anim,
	 input finished_anim2,
	 input finished_anim3, 
	 input finished_background_back,
	 input finished_message,
	 input finished_message2,
	 
	 input p1_win, p2_win,
	 
	 output reg sp1, sp2, basic1, basic2,
	 
    output reg  p11, p12, p13, p21, p22, p23, p1_select, p2_select, p1_move, p2_move, first_background, fight_background, draw_poke1, draw_poke_2, draw_anim, draw_anim2, draw_anim3, draw_background_back, draw_message, draw_message2, player_1_wins, player_2_wins,
	 output reg counter_enable, counter_enable_fightscreen, counter_enable_sprite1, counter_enable_sprite2, counter_enable_anim, counter_enable_anim2, counter_enable_anim3, counter_enable_background_back, counter_enable_message, counter_enable_message2,
	 
	 output reg start 
    );
	 
	 reg [6:0] current_state, next_state;
	 
	 localparam  //states
					 DRAW_BACKGROUND      = 6'd0,
					 LOAD_POKEMON_1  		 = 6'd1,
					 PLAYER_1_WAIT        = 6'd2,
                LOAD_POKEMON_2       = 6'd3,
					 PLAYER_2_WAIT        = 6'd4,
                START_GAME        	 = 6'd5,
					 START_GAME_WAIT    	 = 6'd6,		
					 FIGHT_BACKGROUND_DRAW = 6'd7,
					 DRAW_POKE_1          = 6'd8,
					 DRAW_POKE_2          = 6'd9,
					 
					 
					 PLAYER1_MOVE     = 6'd10,
					 P1_BASICMOVE  	= 6'd11,
					 P1_SPECIALMOVE   = 6'd12,
					 DRAW_P1_BASICMOVE = 6'd13,
					 DRAW_P1_SPECIALMOVE = 6'd14,
					 P1_MOVE_WAIT     = 6'd15,
				    CHECK_P1_WIN     = 6'd16,
					 P1_WINSTATE   	= 6'd17,
					 PLAYER2_MOVE     = 6'd18,
					 P2_BASICMOVE     = 6'd19,
					 P2_SPECIALMOVE   = 6'd20,
					 DRAW_P2_BASICMOVE = 6'd21,
					 DRAW_P2_SPECIALMOVE = 6'd22,
					 P2_MOVE_WAIT     = 6'd23,
					 CHECK_P2_WIN     = 6'd24,
					 DRAW_BACKGROUND_BACK1 = 6'd25,
					 DRAW_BACKGROUND_BACK2 = 6'd26,
					 DRAW_MESSAGE     =6'd27,
					 DRAW_MESSAGE2     =6'd28,
					 P2_WINSTATE      = 6'd29,
					 EXIT_GAME_STATE_WAIT = 6'd30,
					 DRAW_BACKGROUND_BACK_WAIT1 = 6'd31,
					 DRAW_BACKGROUND_BACK_WAIT2 = 6'd32;
					 
					 
					 
					 
	 always@(*)
    begin: state_table 
            case (current_state)
					 
					 DRAW_BACKGROUND: next_state = finished_battle_print ? LOAD_POKEMON_1 : DRAW_BACKGROUND;
					 
					 LOAD_POKEMON_1: next_state = go ? PLAYER_1_WAIT : LOAD_POKEMON_1;
					 PLAYER_1_WAIT: next_state = go ? PLAYER_1_WAIT : LOAD_POKEMON_2;
					 LOAD_POKEMON_2: next_state = go ? PLAYER_2_WAIT : LOAD_POKEMON_2;
					 PLAYER_2_WAIT: next_state = go ? PLAYER_2_WAIT : START_GAME;
					 START_GAME: next_state = go ? START_GAME_WAIT : START_GAME;
					 START_GAME_WAIT: next_state = go ? START_GAME_WAIT : FIGHT_BACKGROUND_DRAW;
					 
					 FIGHT_BACKGROUND_DRAW: next_state = finish_actual_battle_print ? DRAW_POKE_1 : FIGHT_BACKGROUND_DRAW;
					 DRAW_POKE_1: next_state = finish_first_poke_print ? DRAW_POKE_2 : DRAW_POKE_1; 
					 DRAW_POKE_2: next_state = finish_second_poke_print ? PLAYER1_MOVE: DRAW_POKE_2;
					 
					 
					 
					PLAYER1_MOVE: 
					begin
						case({go, select3, select2, select1}) 
							4'b0001: next_state = P1_BASICMOVE;
							4'b0010: next_state = P1_SPECIALMOVE;
							4'b1000: next_state = EXIT_GAME_STATE_WAIT;
							default: next_state = PLAYER1_MOVE;
						endcase
					end
					
					P1_BASICMOVE: next_state = DRAW_P1_BASICMOVE;
					
					P1_SPECIALMOVE: next_state = DRAW_P1_SPECIALMOVE;
					
					DRAW_P1_BASICMOVE: next_state = finished_anim ? DRAW_MESSAGE: DRAW_P1_BASICMOVE;
					
					DRAW_P1_SPECIALMOVE: next_state = finished_anim2 ? DRAW_MESSAGE: DRAW_P1_SPECIALMOVE;
					
					DRAW_MESSAGE: next_state = finished_message ? DRAW_BACKGROUND_BACK1: DRAW_MESSAGE;
					
					DRAW_BACKGROUND_BACK1: next_state = finished_background_back ? DRAW_BACKGROUND_BACK_WAIT1: DRAW_BACKGROUND_BACK1;
					
					DRAW_BACKGROUND_BACK_WAIT1: next_state = finished_background_back ? DRAW_BACKGROUND_BACK_WAIT1: P1_MOVE_WAIT; 

					P1_MOVE_WAIT:
					begin
						case({go, select3, select2, select1}) 
							4'b0000: next_state = CHECK_P1_WIN;
							default: next_state = P1_MOVE_WAIT;
						endcase
					end
					
					CHECK_P1_WIN:
					begin
						if (p1_win == 1'b1)
							next_state = P1_WINSTATE;
						else
							next_state = PLAYER2_MOVE;
					end
					
					P1_WINSTATE: 
					begin 
						if (go == 1'b1)
							next_state = EXIT_GAME_STATE_WAIT;
						else 
							next_state = P1_WINSTATE;
					end
					
					PLAYER2_MOVE: 
					begin
						case({go, select3, select2, select1}) 
							4'b0001: next_state = P2_BASICMOVE;
							4'b0010: next_state = P2_SPECIALMOVE;
							4'b1000: next_state = EXIT_GAME_STATE_WAIT;
							default: next_state = PLAYER2_MOVE;
						endcase
					end
					
					P2_BASICMOVE: next_state = DRAW_P2_BASICMOVE;
					
					P2_SPECIALMOVE: next_state = DRAW_P2_SPECIALMOVE;
					
					DRAW_P2_BASICMOVE: next_state = finished_anim ? DRAW_MESSAGE2: DRAW_P2_BASICMOVE;
					
					DRAW_P2_SPECIALMOVE: next_state = finished_anim3 ? DRAW_MESSAGE2: DRAW_P2_SPECIALMOVE;
					
					DRAW_MESSAGE2: next_state = finished_message2 ? DRAW_BACKGROUND_BACK2: DRAW_MESSAGE2;
					
					DRAW_BACKGROUND_BACK2: next_state = finished_background_back ? DRAW_BACKGROUND_BACK_WAIT2: DRAW_BACKGROUND_BACK2;
					
					DRAW_BACKGROUND_BACK_WAIT2: next_state = finished_background_back ? DRAW_BACKGROUND_BACK_WAIT2: P2_MOVE_WAIT; 
				

					P2_MOVE_WAIT:
					begin
						case({go, select3, select2, select1}) 
							4'b0000: next_state = CHECK_P2_WIN;
							default: next_state = P2_MOVE_WAIT;
						endcase
					end
					
					CHECK_P2_WIN:
					begin
						if (p2_win == 1'b1)
							next_state = P2_WINSTATE;
						else
							next_state = PLAYER1_MOVE;
					end
					
					P2_WINSTATE: 
					begin 
						if (go == 1'b1)
							next_state = EXIT_GAME_STATE_WAIT;
						else 
							next_state = P2_WINSTATE;
					end
					
					EXIT_GAME_STATE_WAIT: 
					begin
						if (go == 1'b0)
							next_state = DRAW_BACKGROUND;
						else
							next_state = EXIT_GAME_STATE_WAIT;
					end
					

					 default: next_state = DRAW_BACKGROUND;
					 
				endcase
	  end
					 
		
	 always @(*) //enable signals to be sent to datapath
	 begin: enable_signals
	 
	     p11 = 1'b0;
		  p12 = 1'b0;
		  p13 = 1'b0;
		  p21 = 1'b0;
		  p22 = 1'b0;
		  p23 = 1'b0;
		  p1_select = 1'b0;
		  p2_select = 1'b0;
		  p1_move = 1'b0;
		  p2_move = 1'b0;
		  start = 1'b0;
		  
		  basic1 = 1'b0;
		  basic2 = 1'b0;
		  sp1 = 1'b0;
		  sp2 = 1'b0;
		  
		  first_background = 1'b0;
		  fight_background = 1'b0;
		  draw_poke1 = 1'b0;
		  draw_poke_2 = 1'b0;
		  draw_anim = 1'b0;
		  draw_anim2 = 1'b0;
		  draw_anim3 = 1'b0;
		  draw_background_back = 1'b0;
		  draw_message = 1'b0;
		  draw_message2 = 1'b0;
		  
		  player_1_wins = 1'b0;
		  player_2_wins = 1'b0;
		  
		  
		  counter_enable = 1'b0;
		  counter_enable_fightscreen = 1'b0;
		  counter_enable_sprite1 = 1'b0;
		  counter_enable_sprite2 = 1'b0;
		  counter_enable_anim = 1'b0;
		  counter_enable_anim2 = 1'b0;
		  counter_enable_anim3 = 1'b0;
		  counter_enable_background_back = 1'b0;
		  counter_enable_message = 1'b0;
		  counter_enable_message2 = 1'b0;
		  
		  case (current_state)
				
				DRAW_BACKGROUND: 
					begin
						first_background = 1'b1;
						counter_enable = 1'b1;
					end	
				
				LOAD_POKEMON_1: 
					begin
					
						p1_select = 1'b1;
						
						case({select3, select2, select1}) 
							3'b001: p11 = 1'b1;
							3'b010: p12 = 1'b1;
							3'b100: p13 = 1'b1;
							default: begin
								p11 = 1'b0;
							   p12 = 1'b0;
								p13 = 1'b0;
							end
						endcase
					end
				
				LOAD_POKEMON_2: 
					begin
					
						p2_select = 1'b1;
						
						case({select3, select2, select1}) 
							3'b001: p21 = 1'b1;
							3'b010: p22 = 1'b1;
							3'b100: p23 = 1'b1;
							default: begin
								p21 = 1'b0;
							   p22 = 1'b0;
							   p23 = 1'b0;
							end
						endcase
					end
				
            START_GAME: start = 1'b1;
				
            FIGHT_BACKGROUND_DRAW: 
			
					begin
						fight_background = 1'b1;
						counter_enable_fightscreen = 1'b1;
					end	
				
				DRAW_POKE_1: 
				
					begin
						draw_poke1 = 1'b1;
						counter_enable_sprite1 = 1'b1;
					end	
				
				DRAW_POKE_2: 
					begin
						draw_poke_2 = 1'b1;
						counter_enable_sprite2 = 1'b1;
					end
					
				PLAYER1_MOVE:
					begin
						p1_move = 1'b1;
					end
					
				P1_BASICMOVE:	
					begin
						basic1 = 1'b1;
					end
				
				DRAW_P1_BASICMOVE: 
					begin
						draw_anim = 1'b1;
						counter_enable_anim = 1'b1;
					end
					
				P1_SPECIALMOVE:
					begin
						sp1 = 1'b1;
						
					end
					
				DRAW_P1_SPECIALMOVE:
					begin
						draw_anim2 = 1'b1;
						counter_enable_anim2 = 1'b1;
					end
					
				DRAW_MESSAGE:
					begin
						draw_message = 1'b1;
						counter_enable_message = 1'b1;
					end
					
				DRAW_MESSAGE2:
					begin
						draw_message2 = 1'b1;
						counter_enable_message2 = 1'b1;
					end
					
				DRAW_BACKGROUND_BACK1:
					begin
						draw_background_back = 1'b1;
						counter_enable_background_back = 1'b1;
					end
					
				DRAW_BACKGROUND_BACK2:
					begin
						draw_background_back = 1'b1;
						counter_enable_background_back = 1'b1;
					end	
					
				PLAYER2_MOVE:
					begin
						p2_move = 1'b1;
					end
					
				P2_BASICMOVE:
					begin
						basic2 = 1'b1;
						
					end
					
				DRAW_P2_BASICMOVE: 
					begin
						draw_anim = 1'b1;
						counter_enable_anim = 1'b1;
					end
					
				P2_SPECIALMOVE:
					begin
						sp2 = 1'b1;
						
					end
					
				DRAW_P2_SPECIALMOVE:
					begin
						draw_anim3 = 1'b1;
						counter_enable_anim3 = 1'b1;
					end
					
				P1_WINSTATE:
					begin
						player_1_wins = 1'b1;
						first_background = 1'b0;
						counter_enable = 1'b0;
					end
					
				P2_WINSTATE:
					begin
						player_2_wins = 1'b1;
						first_background = 1'b0;
						counter_enable = 1'b0;
					end	
					
				
					
				
				
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
// current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= DRAW_BACKGROUND;
        else
            current_state <= next_state;
    end // state_FFS
endmodule		  
					 				 
	 
module datapath(
	 input clk,
    input resetn,

    
	 input p11,p12,p13,p21,p22,p23,p1_select,p2_select, p1_move, p2_move, select1, select2, select3, player_1_wins, player_2_wins,
	 input start, first_background, fight_background, draw_poke1, draw_poke_2, draw_anim, draw_anim2, draw_anim3, draw_background_back, draw_message, draw_message2,
	 
	 
	 input go,
	 
	 input sp1, sp2, basic1, basic2,
	 
	 output reg [7:0] data_x,
	 output reg [6:0] data_y,
	 output reg [5:0] data_c,
	 
	 output reg [7:0] data,
	 output reg [8:0] pokemon1,
	 output reg [8:0] pokemon2,
	  
	 output reg [3:0] health_output_p1, health_output_p2,
	  
	 output reg p1_win, p2_win
	 
    );
	 
	 wire [7:0] x_fullScreenCounter;
	 wire [6:0] y_fullScreenCounter;
	 
	 wire [7:0] x_animCounter;
	 wire [6:0] y_animCounter;
	 
	 wire [7:0] x_messageCounter;
	 wire [6:0] y_messageCounter;
	 
	 wire [7:0] x_playerSelectCounter;
	 wire [6:0] y_playerSelectCounter;
	 
	 wire [7:0] x_spriteCounter;
	 wire [6:0] y_spriteCounter;
	 wire [5:0] colour_sprite_char;
	 wire [5:0] colour_sprite_squir;
	 wire [5:0] colour_sprite_bulb;
	 
	 
	 wire [5:0] colour_choosing_screen;
	 wire [5:0] colour_battling_screen;
	 
	 wire [14:0] address;
	 
	 wire [7:0] x_playerselect;
	 wire [6:0] y_playerselect;
	 
	 wire [5:0] colour_player1;
	 wire [5:0] colour_player2;
	 wire [5:0] colour_gameStart;
	 
	 wire [5:0] colour_anim;
	 wire [5:0] colour_message;
	 
	 wire [5:0] colour_criticalhit;
	 wire [5:0] colour_supereffective;
	 wire [5:0] colour_notveryeffective;
	 wire [5:0] colour_directhit;
	 wire [5:0] colour_miss;
	 
	 wire [5:0] colour_ember;
	 wire [5:0] colour_watergun;
	 wire [5:0] colour_razorleaf;
	 wire [5:0] colour_tackle;
	 
	 wire [5:0] colour_squir_moves;
	 wire [5:0] colour_char_moves;
	 wire [5:0] colour_bulb_moves;
	 
	 reg [7:0] x;
	 reg [6:0] y;	
	
	 reg [1:0] chosen_one;
	 reg [1:0] chosen_two;
	 
	 reg [4:0] counter;
	 reg [3:0] healthP1, healthP2;
	 
	 reg normal_move_1;
	 reg normal_move_2;
	 
	 wire [5:0] bulb_green;
	 wire [5:0] squir_blue;
	 wire [5:0] char_red;
	 
	 wire [1:0] addDamage;
	 wire [1:0] addDamage2;
	 
	 reg [1:0] addDamageReg;
	 reg [1:0] addDamageReg2;
	 
	 reg effective3;
	 reg effective4;
	 
	 wire [5:0] colour_player1wins;
	 wire [5:0] colour_player2wins;
	 
	 wire effective1, effective2;

	 specialMoveDamageP1 md1(
		.clk(clk), 
		.p1_select(chosen_one), 
		.p2_select(chosen_two), 
		.count(counter), 
		.damageAdd(addDamage),
		.effective(effective1)
	 );
	
	 specialMoveDamageP1 md2(
		.clk(clk), 
		.p1_select(chosen_two), 
		.p2_select(chosen_one), 
		.count(counter), 
		.damageAdd(addDamage2),
		.effective(effective2)
	 );
	 
	 //counters
	 fullScreenCounter fullScreenCounter (x_fullScreenCounter, y_fullScreenCounter, clk);
	 
	 fullScreenCounter playerselect_little_window (x_playerselect, y_playerselect, clk);
	 defparam playerselect_little_window.X_limit = 152;
	 defparam playerselect_little_window.Y_limit = 2;

	 
	 fullScreenCounter gameStartCounter (x_playerSelectCounter, y_playerSelectCounter, clk);
	 defparam gameStartCounter.X_limit = 80;
	 defparam gameStartCounter.Y_limit = 20;
	 
	 fullScreenCounter spriteCounter (x_spriteCounter, y_spriteCounter, clk);
	 defparam spriteCounter.X_limit = 64; 
	 defparam spriteCounter.Y_limit = 42; 
	 
	 animCounter animCounter (x_animCounter, y_animCounter, clk);
	 defparam animCounter.X_limit = 27; 
	 defparam animCounter.Y_limit = 25; 	 
	 
	 messageCounter messageCounter (x_messageCounter, y_messageCounter, clk);
	 defparam messageCounter.X_limit = 160; 
	 defparam messageCounter.Y_limit = 30; 
	 
	 //translator
	 vga_address_translator translator (x, y, address);
	 defparam translator.RESOLUTION = "160x120";
	 
	 //acessing ROMS
	 selectPokemon selectPokemonScreen (address, clk, colour_choosing_screen);
	 battle_background battle_background (address, clk, colour_battling_screen);
	 
	 player1select player1select (address, clk, colour_player1);
	 player2 player2select (address, clk, colour_player2);
	 
	 player_bulb bulb_pick (address, clk, bulb_green);
	 player_squir squir_pick (address, clk, squir_blue);
	 player_char char_pick (address, clk, char_red);
	 
	 char char (address, clk, colour_sprite_char);
	 squir squir (address, clk, colour_sprite_squir);
	 bulb bulb (address, clk, colour_sprite_bulb);
	 
	 notveryeffective notveryeffective (address, clk, colour_notveryeffective);
	 supereffective supereffective (address, clk, colour_supereffective);
	 directhit directhit (address, clk, colour_directhit);
	 criticalhit criticalhit (address, clk, colour_criticalhit);
	 miss miss (address, clk, colour_miss);
	 
	 ember ember (address, clk, colour_ember);
	 watergun watergun (address, clk, colour_watergun);
	 razorleaf razorleaf (address, clk, colour_razorleaf);
	 tackle tackle (address, clk, colour_tackle);
	 
	 squir_moves squir_moves (address, clk, colour_squir_moves);
	 char_moves char_moves (address, clk, colour_char_moves);
	 bulb_moves bulb_moves (address, clk, colour_bulb_moves);
	 
	 player1wins player1wins (address, clk, colour_player1wins);
	 player2wins player2wins (address, clk, colour_player2wins);
	 
	 
	 
	 gameStart gameStart (address, clk, colour_gameStart);
	 
	     always@(posedge clk) begin
        if(!resetn) begin
			   x <= 7'b0000000;
				y <= 6'b000000;
				data <= 8'b00000000;
            data_x <= 7'b0000000; 
            data_y <= 6'b000000; 
            data_c <= 6'b000000;
				chosen_one <= 0;
				chosen_two <= 0;
				healthP1 <= 4'b1001;
				healthP2 <= 4'b1001;
				counter <= 5'b00000;
				p1_win <= 1'b0;
				p2_win <= 1'b0;
				health_output_p1 <= 4'b1001;
				health_output_p2 <= 4'b1001;
				normal_move_1 <= 1'b0;
				normal_move_2 <= 1'b0;
				addDamageReg <= 2'b00;
				addDamageReg2 <= 2'b00;
				effective3 <= 1'b0;
				effective4 <= 1'b0;
				
        end
        else begin
				if (start) 
					begin
						data_x <= x_playerSelectCounter;               //ask for game start
						data_y <= y_playerSelectCounter; 
						x <= data_x;
						y <= data_y;
						data_c <= colour_gameStart;
					end
					
				if (first_background)
					begin
						p1_win <= 1'b0;                                //choose pokemon screen
						p2_win <= 1'b0;
						data_x <= x_fullScreenCounter;
						data_y <= y_fullScreenCounter; 
						x <= x_fullScreenCounter;
						y <= y_fullScreenCounter;
						data_c <= colour_choosing_screen;
					end
					
				if (p1_select)
					begin
					
						healthP1 <= 4'b1001;
						healthP2 <= 4'b1001;
					
						if (p11) 
							begin
								x <= x_playerselect;
								y <= y_playerselect;
								data_x <= x_playerselect + 4;             //pick bulbasaur
								data_y <= y_playerselect + 89;
								data_c <= bulb_green;
								chosen_one <= 2'b01;
							end
						
						if (p12)
							begin
								x <= x_playerselect;
								y <= y_playerselect;
								data_x <= x_playerselect + 4;               //pick squirtle
								data_y <= y_playerselect + 89; 
								data_c <= squir_blue;
								chosen_one <= 2'b10;
							end	
						if (p13)
							begin
								x <= x_playerselect;
								y <= y_playerselect;
								data_x <= x_playerselect + 4;               // pick charmander
								data_y <= y_playerselect + 89; 
								data_c <= char_red;
								chosen_one <= 2'b11;
							end
					end
				
				if (p2_select)
					begin
						if (p21) 
							begin
								x <= x_playerselect;								     //pick bulbasaur
								y <= y_playerselect;
								data_x <= x_playerselect + 4;
								data_y <= y_playerselect + 92; 
								data_c <= bulb_green;
								chosen_two <= 2'b01;
							end
						
						if (p22)
							begin
								x <= x_playerselect;
								y <= y_playerselect;
								data_x <= x_playerselect + 4;             //pick squirtle
								data_y <= y_playerselect + 92; 
								data_c <= squir_blue;
								chosen_two <= 2'b10;
							end
						if (p23)
							begin
								x <= x_playerselect;
								y <= y_playerselect;
								data_x <= x_playerselect + 4;
								data_y <= y_playerselect + 92; 
								data_c <= char_red;
								chosen_two <= 2'b11;
							end					
					end
				
					
				if (fight_background) 
					begin
						data_x <= x_fullScreenCounter;               //game begin
						data_y <= y_fullScreenCounter; 
						x <= x_fullScreenCounter;
						y <= y_fullScreenCounter;
						data_c <= colour_battling_screen;
					end
				if (draw_poke1)                 //draws first sprite (bulbasaur, charmander, or squirtle)

					begin
					if (chosen_one == 2'b01)
						begin
							x <= x_spriteCounter;                    
							y <= y_spriteCounter + 46;
							data_x <= x_spriteCounter;
							data_y <= y_spriteCounter + 46; 
							data_c <= colour_sprite_bulb;
						end
					if (chosen_one == 2'b10)
						begin
							x <= x_spriteCounter;                     
							y <= y_spriteCounter + 46;
							data_x <= x_spriteCounter;
							data_y <= y_spriteCounter + 46; 
							data_c <= colour_sprite_squir;
						end
					if (chosen_one == 2'b11)
						begin
							x <= x_spriteCounter;
							y <= y_spriteCounter + 46;
							data_x <= x_spriteCounter;
							data_y <= y_spriteCounter + 46; 
							data_c <= colour_sprite_char;
						end
					end
				if (draw_poke_2)                                          //draws second sprite
					begin
					if (chosen_two == 2'b01)
						begin
							x <= x_spriteCounter + 96;
							y <= y_spriteCounter + 16;
							data_x <= x_spriteCounter + 96;
							data_y <= y_spriteCounter + 16; 
							data_c <= colour_sprite_bulb;
						end
					
					if (chosen_two == 2'b10)
						begin
							x <= x_spriteCounter + 96;
							y <= y_spriteCounter + 16;
							data_x <= x_spriteCounter + 96;
							data_y <= y_spriteCounter + 16; 
							data_c <= colour_sprite_squir;
						end
					if (chosen_two == 2'b11)
						begin
							x <= x_spriteCounter + 96;
							y <= y_spriteCounter + 16;
							data_x <= x_spriteCounter + 96;
							data_y <= y_spriteCounter + 16; 
							data_c <= colour_sprite_char;
						end
					end	
				end
				
				if (p1_move)                         //shows moves available to P1 depending on pokemon
					begin 
					if (chosen_one == 2'b01)
						begin
							x <= x_messageCounter;
							y <= y_messageCounter + 90;
							data_x <= x_messageCounter;
							data_y <= y_messageCounter + 90; 
							data_c <= colour_bulb_moves;
						end
					if (chosen_one == 2'b10)
						begin
							x <= x_messageCounter;
							y <= y_messageCounter + 90;
							data_x <= x_messageCounter;
							data_y <= y_messageCounter + 90; 
							data_c <= colour_squir_moves;
						end
					if (chosen_one == 2'b11)
						begin
							x <= x_messageCounter;
							y <= y_messageCounter + 90;
							data_x <= x_messageCounter;
							data_y <= y_messageCounter + 90; 
							data_c <= colour_char_moves;
						end
					end
					
					
				if (p2_move)                         //shows moves available to P2 depending on pokemon
					begin 
					if (chosen_two == 2'b01)
						begin
							x <= x_messageCounter;
							y <= y_messageCounter + 90;
							data_x <= x_messageCounter;
							data_y <= y_messageCounter + 90; 
							data_c <= colour_bulb_moves;
						end
					if (chosen_two == 2'b10)
						begin
							x <= x_messageCounter;
							y <= y_messageCounter + 90;
							data_x <= x_messageCounter;
							data_y <= y_messageCounter + 90; 
							data_c <= colour_squir_moves;
						end
					if (chosen_two == 2'b11)
						begin
							x <= x_messageCounter;
							y <= y_messageCounter + 90;
							data_x <= x_messageCounter;
							data_y <= y_messageCounter + 90; 
							data_c <= colour_char_moves;
						end
					end
					
				   if (basic1)                                 //player1 did basic move, inflict damage
					   begin
							normal_move_1 <= 1'b01;
							healthP2 <= healthP2 - 2'b10;
						end

						
						
					if (sp1)                                    //player1 did special move, inflict damage + randomness
						begin
							normal_move_1 <= 0;
							healthP2 <= healthP2 - addDamage; // 0 - miss, 1 - not very effective, 2 - normal, 3 - effective
							addDamageReg <= addDamage;
							effective3 <= effective1;

							
							if (counter > 5'b11100) 
								 counter <= 5'b00000;
							else
								 counter <= counter + 2'b01;
								 
								 
						end	
						
					if (draw_anim)	                       //draws basic moves animation
						begin
							
							x <= x_animCounter + 65;
							y <= y_animCounter + 38;
							data_x <= x_animCounter + 65;
							data_y <= y_animCounter + 38; 
							data_c <= colour_tackle;
						end
						
					if (draw_message)                     //displays message depending on damage inflicted
						begin
						
							if (normal_move_1 == 1'b01)
								begin
									x <= x_messageCounter;
									y <= y_messageCounter + 90;
									data_x <= x_messageCounter;
									data_y <= y_messageCounter + 90; 
									data_c <= colour_directhit;
								end
								
							else if (addDamageReg == 2)
								begin
									x <= x_messageCounter;
									y <= y_messageCounter + 90;
									data_x <= x_messageCounter;
									data_y <= y_messageCounter + 90; 
									data_c <= colour_directhit;
								end
								
							else if (addDamageReg == 1)
								begin
									x <= x_messageCounter;
									y <= y_messageCounter + 90;
									data_x <= x_messageCounter;
									data_y <= y_messageCounter + 90; 
									data_c <= colour_notveryeffective;
								end	
								
							else if ((addDamageReg == 3 && effective3 == 1))
								begin
									x <= x_messageCounter;
									y <= y_messageCounter + 90;
									data_x <= x_messageCounter;
									data_y <= y_messageCounter + 90; 
									data_c <= colour_supereffective;
								end
								
							else if ((addDamageReg == 3 && effective3 == 0))
								begin
									x <= x_messageCounter;
									y <= y_messageCounter + 90;
									data_x <= x_messageCounter;
									data_y <= y_messageCounter + 90; 
									data_c <= colour_criticalhit;
								end
							else if (addDamageReg == 0)
								begin
									x <= x_messageCounter;
									y <= y_messageCounter + 90;
									data_x <= x_messageCounter;
									data_y <= y_messageCounter + 90; 
									data_c <= colour_miss;
								end	
   
							
						end
						
						
					if (draw_background_back)                 //draws the background back after move animation
						begin
							x <= x_animCounter + 65;
							y <= y_animCounter + 38;
							data_x <= x_animCounter + 65;
							data_y <= y_animCounter + 38; 
							data_c <= colour_battling_screen;
						end
						
					if (basic2)                                 //player2 did basic move, inflict damage                                  
					   begin
							normal_move_2 <= 1;
							healthP1 <= healthP1 - 2'b10;
						end
					
					if (sp2)                                    //player2 did special move, inflict damage + randomness 
					  begin
							 normal_move_2 <= 0;
							 healthP1 <= healthP1 - addDamage2;
							 addDamageReg2 <= addDamage2;
							 effective4 <= effective2;
							
							 if (counter > 5'b11100) 
								counter <= 5'b00000;
							 else
								counter <= counter + 2'b01;
						end 		
						
					if (draw_message2)                     //displays message depending on damage inflicted
						begin
						if (normal_move_2 == 1)
								begin
									x <= x_messageCounter;
									y <= y_messageCounter + 90;
									data_x <= x_messageCounter;
									data_y <= y_messageCounter + 90; 
									data_c <= colour_directhit;
								end
								
							else if (addDamageReg2 == 2)
								begin
									x <= x_messageCounter;
									y <= y_messageCounter + 90;
									data_x <= x_messageCounter;
									data_y <= y_messageCounter + 90; 
									data_c <= colour_directhit;
								end
								
							else if ((addDamageReg2 == 3 && effective4 == 1))
								begin
									x <= x_messageCounter;
									y <= y_messageCounter + 90;
									data_x <= x_messageCounter;
									data_y <= y_messageCounter + 90; 
									data_c <= colour_supereffective;
								end
								
							else if (addDamageReg2 == 1)
								begin
									x <= x_messageCounter;
									y <= y_messageCounter + 90;
									data_x <= x_messageCounter;
									data_y <= y_messageCounter + 90; 
									data_c <= colour_notveryeffective;
								end
								
							else if ((addDamageReg2 == 3 && effective4 == 0))
								begin
									x <= x_messageCounter;
									y <= y_messageCounter + 90;
									data_x <= x_messageCounter;
									data_y <= y_messageCounter + 90; 
									data_c <= colour_criticalhit;
								end
							else if (addDamageReg2 == 0)
								begin
									x <= x_messageCounter;
									y <= y_messageCounter + 90;
									data_x <= x_messageCounter;
									data_y <= y_messageCounter + 90; 
									data_c <= colour_miss;
								end	
						
						end
					
											
					if (draw_anim2)                        //draws P1 special move animation	
						begin
						if (chosen_one == 2'b01)
							begin
								x <= x_animCounter + 65;
								y <= y_animCounter + 38;
								data_x <= x_animCounter + 65;
								data_y <= y_animCounter + 38; 
								data_c <= colour_razorleaf;
							end
						if (chosen_one == 2'b10)
							begin
								x <= x_animCounter + 65;
								y <= y_animCounter + 38;
								data_x <= x_animCounter + 65;
								data_y <= y_animCounter + 38; 
								data_c <= colour_watergun;
							end
						if (chosen_one == 2'b11)
							begin
								x <= x_animCounter + 65;
								y <= y_animCounter + 38;
								data_x <= x_animCounter + 65;
								data_y <= y_animCounter + 38; 
								data_c <= colour_ember;
							end
							
							
						end 
						
						
					if (draw_anim3)                        //draws P2 special move animation	
						begin
						if (chosen_two == 2'b01)
							begin
								x <= x_animCounter + 65;
								y <= y_animCounter + 38;
								data_x <= x_animCounter + 65;
								data_y <= y_animCounter + 38; 
								data_c <= colour_razorleaf;
							end
						if (chosen_two == 2'b10)
							begin
								x <= x_animCounter + 65;
								y <= y_animCounter + 38;
								data_x <= x_animCounter + 65;
								data_y <= y_animCounter + 38; 
								data_c <= colour_watergun;
							end
						if (chosen_two == 2'b11)
							begin
								x <= x_animCounter + 65;
								y <= y_animCounter + 38;
								data_x <= x_animCounter + 65;
								data_y <= y_animCounter + 38; 
								data_c <= colour_ember;
							end
							
							
						end 	
						
					
						
				if (healthP2 == 4'b0000)      //checks if health is 0, which means opposite player has won
					begin
						p1_win <= 1'b1;
						
						
					end
				 else if (healthP2 >= 4'b1100)
					begin
						p1_win <= 1'b1;
						
						
					end
				 else if (healthP1 == 4'b0000) 
					begin
						p2_win <= 1'b1;
						
						
					end
				 else if (healthP1 >= 4'b1100)
					begin
						p2_win <= 1'b1;
						
						
					end
				 else begin
					p1_win <= 1'b0;
					p2_win <= 1'b0;
				 end
				 
				 if (player_1_wins)                       //display win screen
					begin
						data_x <= x_fullScreenCounter;
						data_y <= y_fullScreenCounter; 
						x <= x_fullScreenCounter;
						y <= y_fullScreenCounter;
						data_c <= colour_player1wins;
					end
					
				if (player_2_wins)
					begin
						data_x <= x_fullScreenCounter;
						data_y <= y_fullScreenCounter; 
						x <= x_fullScreenCounter;
						y <= y_fullScreenCounter;
						data_c <= colour_player2wins;
					end
				 
				 
				
				case (chosen_one)                         //output hexes for pokemon chosen
					2'b01: pokemon1 <= 7'b1111001;
					2'b10: pokemon1 <= 7'b0100100;
					2'b11: pokemon1 <= 7'b0110000;
					default: pokemon1 <= 7'b1000000; 
				endcase
				
				case (chosen_two)
					2'b01: pokemon2 <= 7'b1111001;
					2'b10: pokemon2 <= 7'b0100100;
					2'b11: pokemon2 <= 7'b0110000;
					default: pokemon2 <= 7'b1000000; 
				endcase	
				 
				 
				
						
				if (healthP1 <= 4'b1100)
					health_output_p1 <= healthP1;
				else
					health_output_p1 <= 4'b0000;
				if (healthP2 <= 4'b1100)
					health_output_p2 <= healthP2;
				else
					health_output_p2 <= 4'b0000;	
						
						
							
			end
	 
endmodule

//counter to go through each pixel of mif file
module fullScreenCounter (X, Y, clk);
	input clk;
	output reg [7:0] X;
	output reg [6:0] Y;
	
	parameter X_limit = 160;
	parameter Y_limit = 120;
	
	always @(posedge clk)
		begin
			
			if (X < X_limit)
				begin
					X <= X + 1;
					Y <= Y;
				end
			
			else if (X == X_limit) 
				begin 
					X <= 0;
					Y <= Y + 1;
						
				if (Y == Y_limit)	
					begin
						Y <= 0;
						X <= 0;
					end	
				end		
		end
endmodule

//Rate devider, allows draw states to happen long enough to draw the whole picture
module RateDivider (D, Q, clk, Enable);
	input [25:0] D;
	input clk;
	input Enable;
	output reg [25:0] Q ;
	
	always @(posedge clk)
		begin
		
			if (Enable == 1'b1)
				begin
					if (Q==0)
						begin
							if (D == 0)
								Q <= 0;
							else
								Q <= D;
						end
						
					else
						Q <= Q - 1;	
				end
				
			else
				Q <= D;
			
		end

endmodule	

//HEX Decoder
module seg7(input c3, c2, c1, c0, output led0,led1,led2,led3,led4,led5,led6);
	 assign led0 = (~c3&~c2&~c1&c0)|(~c3&c2&~c1&~c0)|(c3&~c2&c1&c0)|(c3&c2&~c1&c0);
	 assign led1 = (~c3&c2&~c1&c0)|(~c3&c2&c1&~c0)|(c3&~c2&c1&c0)|(c3&c2&~c1&~c0)|(c3&c2&c1&~c0)|(c3&c2&c1&c0);
	 assign led2 = (~c3&~c2&c1&~c0)|(c3&c2&~c1&~c0)|(c3&c2&c1&~c0)|(c3&c2&c1&c0);
	 assign led3 = (~c3&~c2&~c1&c0)|(~c3&c2&~c1&~c0)|(~c3&c2&c1&c0)|(c3&~c2&c1&~c0)|(c3&c2&c1&c0);
	 assign led4 = (~c3&~c2&~c1&c0)|(~c3&~c2&c1&c0)|(~c3&c2&~c1&~c0)|(~c3&c2&~c1&c0)|(~c3&c2&c1&c0)|(c3&~c2&~c1&c0);
	 assign led5 = (~c3&~c2&~c1&c0)|(~c3&~c2&c1&~c0)|(~c3&~c2&c1&c0)|(~c3&c2&c1&c0)|(c3&c2&~c1&c0);
	 assign led6 = (~c3&~c2&~c1&~c0)|(~c3&~c2&~c1&c0)|(~c3&c2&c1&c0)|(c3&c2&~c1&~c0);
endmodule 

//Pseudo-randomyl decides whether a move will be a miss, critical, or normal damage
module specialMoveDamageP1(input clk, input [1:0] p1_select, input [1:0] p2_select, input [4:0] count, output reg [1:0] damageAdd, output reg effective);

	reg [29:0] random1 = 30'b001100111010100101110010010101; // 1 in 2 odds of miss 
	reg [29:0] random2 = 30'b010001010010011001001001010011; // 1 in 3 odds of critical
	
	
		
	always@(*) begin                                                                                                                                                               
		if (p1_select == 2'b01) begin //bulbasaur
           
          if (p2_select == 2'b11)  // charmander, does less damage
           begin
			  
				effective <= 1'b0;
				if (random2[count]==1'b1)
             damageAdd <=  2'b11;
            else
             damageAdd <=  2'b01;
            
           end   
           
          else if (p2_select == 2'b10)   // squirtle, does more damage
           begin
			  
            effective <= 1'b1;
				
				if (random1[count]==1'b1)
             damageAdd <=  2'b11;
            else
             damageAdd <=  2'b00;
           end
           
          else if (p2_select == 2'b01) begin
             effective <= 1'b0;
				 damageAdd <=  2'b10;
			  end
			 else 
				damageAdd <=  2'b00;
      end 
          
          
		else if (p1_select == 2'b10) begin // squirtle
          
			 if (p2_select == 2'b01)  // bulbasaur, does less damage
          begin
				effective <= 1'b0;
            if (random2[count]==1'b1)
				 damageAdd <=  2'b11;
            else
             damageAdd <=  2'b01;
				 
          end  
           
          else if (p2_select == 2'b11)  // charmander, does more damage
          begin
            effective <= 1'b1;
				if (random1[count]==1'b1)
             damageAdd <=  2'b11;
            else
             damageAdd <=  2'b00;
           
          end
           
          else if (p2_select == 2'b10) begin
             effective <= 1'b0;
				 damageAdd <=  2'b10;
			  end
			 else
				damageAdd <=  2'b00;
      end 
          
		else if (p1_select == 2'b11) begin // charmander

			if (p2_select == 2'b10)  // squirtle, does less damage
          begin
				effective <= 1'b0;
            if (random2[count]==1'b1)
             damageAdd <=  2'b11;
            else
             damageAdd <=  2'b01;

          end  
           
          else if (p2_select == 2'b01)  // bulbasaur, does more damage
          begin
            effective <= 1'b1;
				if (random1[count]==1'b1)
             damageAdd <=  2'b11;
            else
             damageAdd <=  2'b00;
				
          end
           
          else if (p2_select == 2'b11) begin
             effective <= 1'b0;
				 damageAdd <=  2'b10;
			 end
			 else
				damageAdd <=  2'b00;
      end 
		else 
			damageAdd <=  2'b00;
	end
		
endmodule 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 



