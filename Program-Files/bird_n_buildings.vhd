-- This is game logic and display code for the Flappy Attila Game. 

--pulling in the libraries needed for our game logic 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;


--creating the entity of the file  and also initializing all of the ports 
ENTITY bird_n_buildings IS
	PORT (
		v_sync : IN STD_LOGIC;
		pixel_row : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
		pixel_col : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
		-- port to take in the hits and used to display score on FPGA
		hits: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		
		 -- current bird x position
		bird_x : in  STD_LOGIC_VECTOR (10 DOWNTO 0);
		
		-- initiates serve
		serve : IN STD_LOGIC; 
		
		--ports for the colors to appear on the screen 
		red : OUT STD_LOGIC;
		green : OUT STD_LOGIC;
		blue : OUT STD_LOGIC
	);
END bird_n_buildings;

ARCHITECTURE Behavioral OF bird_n_buildings IS
	--Signals 
		--
	SIGNAL gapsize : INTEGER := 120; -- gap size in pixels
	SIGNAL score : integer :=0; -- score;+1for each bound passed
	SIGNAL gap_speed : STD_LOGIC_VECTOR (9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR (5, 10);-- distance gap moves each frame
    -- game objects 
	SIGNAL bound_on : STD_LOGIC; -- Indicates whether bound is at current pixel position
	SIGNAL bird_on : STD_LOGIC; -- Indicates whether bird at current pixel position
	SIGNAL building_on : std_logic; -- Indicates whether building at current pixel position
	SIGNAL background_on: STD_LOGIC; -- Indicates whether background at current pixel position
	SIGNAL game_on : STD_LOGIC := '0'; -- Indicates whether gap is in play

	-- Current gap position - intitialized to center of screen ~ This is how we controlled the size of the game on the screen 
	SIGNAL gap_pos : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(640, 10);

	SIGNAL bound_y : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(5, 10);
	SIGNAL bound_y_motion : STD_LOGIC_VECTOR(9 DOWNTO 0) := gap_speed;
	SIGNAL x : integer :=400;
	SIGNAL flag : integer :=0; -- variable to determine what type of game is happening 
	SIGNAL hitcount : STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal duck_top, duck_bottom, duck_left, duck_right : integer := 0; 
	signal duck_y : integer := 500; --initial duck y position
	--Constants 
	--Bird
	CONSTANT bird_w : INTEGER := 56; -- bird width in pixels
	CONSTANT bird_h : INTEGER := 71; -- bird height in pixels
	CONSTANT bird_y : STD_LOGIC_VECTOR(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(400, 10); --
	--Boundary
	CONSTANT bound_h : INTEGER := 50; -- thickness of the bound
    
BEGIN
    duck_left <= conv_integer(signed(bird_x))-23;--duck doesnt move in x direction, only up and down
    duck_right <=  conv_integer(signed(bird_x)) + 23;            
    duck_top <= duck_y;
    duck_bottom <=  duck_y + 71;    
	--Logic to determine where certain colors appear where on the screen. (Yellow gap & background, Green Buildings, White bird) 
	red <=  NOT building_on OR bound_on ;   	
	green <= NOT building_on OR bound_on  OR building_on;
	blue <=   background_on AND bird_on;
	
	--Process to draw a large rectangle in the background to achieve the background & gap to be the same color 
	backgrounddraw: PROCESS (pixel_row, pixel_col) IS
	VARIABLE vx, vy : STD_LOGIC_VECTOR (9 DOWNTO 0);
    BEGIN
		IF (pixel_row >= 0) AND pixel_row <= 800 AND pixel_col >= 0 AND pixel_col <= 800 THEN
			background_on <= '1';
		ELSE
			background_on <= '0';
		END IF;
	END PROCESS;

	--Process to draw gapset gap_on if current pixel address is covered by gap position
	gapdraw : PROCESS (bound_y, gap_pos, pixel_row, pixel_col) IS
	VARIABLE vx, vy : STD_LOGIC_VECTOR (9 DOWNTO 0);
    BEGIN	
		IF ((pixel_row >= gap_pos - gapsize/2) OR (gap_pos <= gapsize/2)) AND
			pixel_row <= gap_pos + gapsize/2 AND
			pixel_col >= bound_y - bound_h AND
			pixel_col <= bound_y + bound_h THEN
			bound_on <= '1';
		ELSE
			bound_on <= '0';
		END IF;
	END PROCESS;
	
	--Process to draw the buildings above and below the gap to the top and bottom of the screen 
	buldingdraw: PROCESS (bound_y, gap_pos, pixel_row, pixel_col) IS
	VARIABLE vx, vy : STD_LOGIC_VECTOR (9 DOWNTO 0);
	BEGIN
		IF ((pixel_row < gap_pos-gapsize/2) OR (gap_pos > gapsize/2)) AND
			( pixel_row > gap_pos + gapsize/2 OR 
			pixel_row < gap_pos + gapsize/2)  AND
			pixel_col >= bound_y - bound_h AND
			pixel_col <= bound_y + bound_h THEN
			building_on <= '1';
		ELSE
			building_on <= '0';
		END IF;
	END PROCESS;

	-- Process to draw the attila duck on the screen as the main character that is able to be controlled with the potentiometer 
	duckdraw : PROCESS (bird_x, pixel_row, pixel_col)
	type duck_sprite is array (0 to 55) of std_logic_vector(0 to 70);
	 
	    variable duck_data : duck_sprite := (     
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111100000000111111111111111111111111111111100000000111111111111",
		"11111111111100000000111111111111111111111111111111100000000111111111111",
		"11111111111100000000111111111111111111111111111111100000000111111111111",
		"11111111111100000000111111111111111111111111111111100000000111111111111",
		"11111111111100000000111111111111111111111111111111100000000111111111111",
		"11111111111100000000111111111111111111111111111111100000000111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111100000000000000000000000000000000000000000000000111111111111",
		"11111111111100000000000000000000000000000000000000000000000111111111111",
		"11111111111110000011111111111111111111111111111111111000001111111111111",
		"11111111111111000011111111111111111111111111111111111000011111111111111",
		"11111111111111100001111111111111111111111111111111110000111111111111111",
		"11111111111111110000111111111111111111111111111111100001111111111111111",
		"11111111111111111000011111111111111111111111111111000011111111111111111",
		"11111111111111111100001111111111111111111111111110000111111111111111111",
		"11111111111111111110000111111111111111111111111100001111111111111111111",
		"11111111111111111111100000111111111111111111100000111111111111111111111",
		"11111111111111111111111100001111111111111110000111111111111111111111111",
		"11111111111111111111111111000000111111100000011111111111111111111111111",
		"11111111111111111111111111110000000000000001111111111111111111111111111",
		"11111111111111111111111111111111110000111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111",
		"11111111111111111111111111111111111111111111111111111111111111111111111"
	    );
	    variable pos_in_duck_x: integer := conv_integer(signed(pixel_col)) - duck_top;
	    variable pos_in_duck_y: integer := conv_integer(signed(pixel_row)) - duck_left;
	    variable draw_pixel: std_logic := '0';
		begin
		 draw_pixel := '0';
		if (unsigned(pixel_row) >= duck_left) and (unsigned(pixel_row) < duck_right) and
		(unsigned(pixel_col) >= duck_top) and (unsigned(pixel_col) < (duck_bottom)) and
		(duck_data(pos_in_duck_y)(pos_in_duck_x) = '1') then
				bird_on <= '1';
		ELSE
				bird_on <= '0';
			end if;
        
	end process;
        
-- GAME LOGIC (Score, Points, End game, Start) 	
		   
	-- process to move gap once every frame (i.e. once every vsync pulse)
	mgap : PROCESS
		VARIABLE temp : STD_LOGIC_VECTOR (10 DOWNTO 0);
	BEGIN
		WAIT UNTIL rising_edge(v_sync);
		
		--This is checking if this is the first serve of the game because it resets everything 
		IF serve = '1' AND game_on = '0' THEN -- test for new serve
		    score<=0;
		    hitcount <= hitcount-hitcount;
		    hits <= hitcount;
		    gapsize<=120;
		    gap_speed<=CONV_STD_LOGIC_VECTOR (5, 10);
			game_on <= '1';
			bound_y_motion <= (gap_speed); -- set vspeed to (- gap_speed) pixels
		ELSIF 
		      -- if gap meets bottom bound
		      bound_y + bound_h/2 >= 900 THEN 
			    IF flag=0 THEN
				    score <= score+1;
				    flag <=1;
		END IF;  
		 
		    -- This controls the initial random spawn of the gap on the screen
		    x <=((123*(score**2)) mod 500) + 120;
		    IF x<120 THEN
			    x <=120;
			    ELSIF x>600 THEN
			    	x <=600;
		    END IF;
		   	 gap_pos <= CONV_STD_LOGIC_VECTOR(x, 10);
			 bound_y <= CONV_STD_LOGIC_VECTOR(5, 10);
		   	 flag <=0;
		END IF;
			
		-- This checkes if you landed within the gap and allows you to add to the score until you win @ 15 points and the score resets
		IF bound_y <= bird_y + bird_h/2 AND
		bound_y >= bird_y - bird_h/2 THEN
			IF (bird_x + bird_w/2) <= (gap_pos + gapsize/2) AND
			 (bird_x - bird_w/2) >= (gap_pos - gapsize/2) Then
				    hitcount <= hitcount+1;
				    hits <= hitcount; 
		ELSE
		-- hit the bound you lose
			game_on <= '0';
			score <= 0;
			hitcount <= hitcount-hitcount;
			gap_pos <= CONV_STD_LOGIC_VECTOR(x, 10);
			gapsize<=120;
			gap_speed<=CONV_STD_LOGIC_VECTOR (5, 10);
			bound_y_motion<=gap_speed;

		END IF;
    END IF;

		-- compute next gap vertical position
		-- variable temp adds one more bit to calculation to fix unsigned underflow problems
		-- when gap_y is close to zero and gap_y_motion is negative(This is not needed)
		temp := ('0' & bound_y) + (bound_y_motion(9) & bound_y_motion);
		IF game_on = '0' THEN
			bound_y <= CONV_STD_LOGIC_VECTOR(5, 10);
			ELSIF temp(10) = '1' THEN
				bound_y <= (OTHERS => '0');
		ELSE bound_y <= temp(9 DOWNTO 0);
		END IF;

	END PROCESS;
END Behavioral;
