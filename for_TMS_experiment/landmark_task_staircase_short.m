function[] = landmark_task_1(subj_id, run, instruct, side)
%function[] = landmark_task_1(subj_id, run, instruct, side)
% instruct = longer vs. shorter judgments. Which is longer? = 1; Which is shorter? =2
% side = side of all the staircase trials. 1= right; 2 = left
% todo
% - think about priority/rush
% - viewing distance in TMS room: 75 cm

%ss- changed the length of the offset of each stimulus.  rather than being 1 and 2 degrees off,
%changed to .5 and 1 degree off. changed backround to gray. changed number of neutrals
%to 20 and the number of offset stimuli to 16 (8 to right, 8 to left).

rand_init = sum(100*clock);
rand('state',rand_init); %randomize the seed

log_fname = sprintf('%s_r%i_log.txt', subj_id, run);%ss_073008_r1.txt
mat_fname = sprintf('%s_r%i.mat', subj_id, run);%ss_073008_r1.mat
%debug_fname = sprintf('%s_debug_r%i',subj_id, run); % append trial # and .mat later
tm_fname = sprintf('%s_r%i_timing.txt', subj_id, run);%ss_073008_r1_timing.txt

%run #, trial #, instruct, cur_shift_pix, stim_width_pix, response, 
%correct, RT. 
%instruct = 1, "Which is longer?"; instruct =2, "Which is shorter?"
%cur_shift_pix < 0, shift to left. cur_shift_pix > 0, shift to the right. cur_shift_pix = 0, symmetrical
%response = 1, pressed the right button. response = 2, pressed the left button. response = -1, did not respond.
%correct =1, correct response. correct = 0, incorrect response. correct = -1, no right/wrong answer
%RT = 0 when subjects do not respond to stimulus
behav = zeros(0,8); %initializes the behavioral matrix
%timing = GetSecs, trial #, trial start time, trigger reset time, fix start time,
%stim start time, zap time, mask start time, response time, trial end time
timing = zeros(0,10);%initializes a time matrix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%stimulus parameters
num_trials = 42;%needs to be divisible by 6
fix_dur = 1.5; % amount of time (in sec) that the fixation point is on at beginning of trial
stim_dur = .20; % amount of time (in sec) that the transected stimulus is on
iti_dur = 5; % amount of time (in sec) between offset of transected stimulus and beginning of trial
button_right = kbname('l'); %this is the "l" (xx) button on the keyboard
button_neutral = kbname('k'); %this is the "k" (44) button on the keyboard
button_left = kbname('j'); %this is the "j" (66) button on the keyboard
res_x = 800;%resolution of monitor in x direction
res_y = 600;%resolution of monitor in y direction
%res_x = 1280;%resolution of monitor in x direction %ss
%res_y = 854;%resolution of monitor in y direction %ss
%sz = [32 21.5];%sz of sreen in cm. PowerBook screen. %ss
sz = [40 30];%sz of sreen in cm. TMS room screen.
vdist = 70; %62;%distance from screen in cm. %ss
%vdist = 32;%distance from screen in cm.
TMS_on = 0;% 0= not running TMS study. 1= running TMS study
zap_interval = 0.20;% set to 150 ms
starting_dist = .75;%from 1-.75 % in degrees, same for both sides. higher = the first trial is easier
% starting_dist * power(step_proportion,0:10)
% for 2 and .75 = [2  1.5  1.13  .84  .63  .48  .36  .27  .20  .15  .11]
%note: if you make step_proportion any larger than .80, then once you get around .16 degrees
%of offset, this translates into pixels that round to the same number, so it takes a longer
%number of trials to move towards the actual center.
%deg_jumps = 1 * power(.82,0:20);
%cur_shift_pix_temp = round((deg_jumps * ppd(1)))
step_proportion = 0.70;%.75 or .70 % how much to change the DIST if you get twice in a row. making this higher makes the changes more gradual

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%VisAng takes the screen resolution, screen size, and viewing distance and calculates
%the pixels per degree or degrees per pixel. returns two values per variable: pixels per
%degree in the x direction and pixels per degree in the y direction (or the same for
%degrees per pixel)
[ppd dpp] = VisAng([res_x res_y],sz,vdist);%ppd = pixels per degree, dpp = degrees per pixel

if mod(num_trials,2) ~= 0; error('num_trials must be even'); end

shuf_idx = randperm(num_trials);%stores the new random ordering of the trials

% preallocate the sides randomly, so that we have an equal number 
% of lefts and rights, but randomize when they occur
sides_ordered = [ones(1,num_trials/2) ones(1,num_trials/2)*2]; % INTERMINGLE_SIDES
sides = sides_ordered(shuf_idx); % apply the shuffling % INTERMINGLE_SIDES
% instead of randomly pre-allocating the sides, we are going to make all of the trials come from one side only.
% sides = [ones(1,num_trials)*side]; %1's = right; 2's = left  % SINGLE_SIDE

% this will store the position (i.e. distance from neutral) after 
% it's been shown on each trial. we don't know what these values are yet
% 0 = neutral. negative = left. positive = right.
dists_deg = zeros(num_trials,1);

% initialize the dists_deg for the first trial for each side to STARTING_DIST, 
% i.e. find the first timepoint for a given side, and set its value to STARTING_DIST
% response = 1, pressed the right button. response = 2, pressed the left button. 
	% response = -1, did not respond.
first_left_t = min(find(sides==2));
first_right_t = min(find(sides==1)); 
dists_deg(first_left_t) = starting_dist;
dists_deg(first_right_t) = starting_dist;

% this will keep track of which responses they've made.
% either 0, 1 or 2. -1 = not recorded
responses = ones(num_trials,1)*-1;

% this will store which trials were correct 
% and which were incorrect (either neutral or the wrong side)
corrects  = ones(num_trials,1)*-1;

% we can't pre-calculate the SHIFTINESS in pixels, because each trial's 
% SHIFTINESS depends on the subject's responses up to that point

% 1 x num_trials vector, with each value being the length
% (in degrees of visual angle) of the transected line
% for a given trial
%
% we want to apply the same shuffling here as we applied to SIDES to make sure that 
% each side has the same number of each length
%
% the lengths are 20, 21, 22, 23, divided evenly, and split equally for left and right. 
% e.g. there will be num_trials/8 trials with length 20...
nTperC = num_trials / 6; % the number of trials per condition (e.g. left, length 21)
stim_width_deg_ordered = [...
   ones(1,nTperC)*21 ones(1,nTperC)*22 ones(1,nTperC)*23 ... % right
   ones(1,nTperC)*21 ones(1,nTperC)*22 ones(1,nTperC)*23 ... % left
  ];  
			  
stim_width_deg = stim_width_deg_ordered(shuf_idx);
stim_width_pix = round(stim_width_deg * ppd(1));

stim_bar_height = round(2*ppd(2));%height of the transecting bar (2 degrees of visual angle)
mask_bar_height = round(10*ppd(2));
stimThickness = round(0.1*ppd(2)); % pen thickness of the transected stimulus line
maskThickness = round(0.2*ppd(2)); % pen thickness of the mask
mask_width_pix = round(50*ppd(1));%length of mask line
fix_width = 10;
fix_height = 10;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BLACK_INDEX		= 0;
WHITE_INDEX = 5;
GRAY_INDEX = 10;
clut = zeros(256, 3);
clut(BLACK_INDEX	+ 1, :) = [0 0 0];
clut(WHITE_INDEX	+ 1, :) = [255 255 255];
%clut (GRAY_INDEX    + 1, :) = [128 128 128];
clut (GRAY_INDEX    + 1, :) = [110 110 110];
Bkcolor	= GRAY_INDEX;	% background color %ss

p.res = SCREEN(0,'Resolution');%from stephanie's code
p.res.pixelSize = 8;

%p.res = NearestResolution(0,res_x,res_y,85,8);%this is from keith's code. sets screen resolution.
[w, rect] = SCREEN(0, 'OpenWindow', Bkcolor, [], p.res);	% open main screen
w2 = SCREEN(0, 'OpenOffscreenWindow',[],rect);

Screen(w, 'SetClut', clut);	% Set the CLUT (color look-up table) with the clut that was created up above
HideCursor;	% Hide the mouse cursor
center = [rect(3) rect(4)]/2;	% center of screen (pixel coordinates)
p.frame_rate=SCREEN(w,'FrameRate');	% frames per second
fix_cord = [center(1) center(2)];

SCREEN(w,'TextSize',20);
%SCREEN(w,'DrawText','+', fix_cord(1),fix_cord(2), BLACK_INDEX);	% fixation cross
draw_pnline(w,center,fix_width,0,WHITE_INDEX,stimThickness, fix_height);
%describescreen(0)

% we have hardcoded this text since it only gets used for centering, and 
% since we don't expect the question to change. if it does, change this length. 
% we're ignoring the fact that there are two questions ('longer' and 'shorter') 
% and that their length is different by 1
% 
% pair of x,y coordinates for the text location (in the middle of the screen, 
% at the very beginning of the run)
SCREEN(w,'TextSize',16);
txtloc_mid = [center(1) - SCREEN(w,'TextWidth','Which side is shorter?')/2, ... % x
	          center(2) + 40]; % y

% the location of the question (e.g. 'which side is longer?') at the top 
% of the screen, displayed throughout the rest of the run
SCREEN(w,'TextSize',16);
txtloc_top = [center(1) - SCREEN(w,'TextWidth','Which side is shorter?')/2, ... % x
     	       center(2) - 200]; % y

% tell the subject what to do for the rest of this run
display_question(w,WHITE_INDEX,instruct,txtloc_mid); 

FlushEvents('keydown');
kbwait;
% just testing rectangles
% SCREEN(w,'FillRect',WHITE_INDEX,[0 0 500 500]);

% blank the screen
%SCREEN(w,'FillRect',Bkcolor);

% for each trial, a fixation point comes on for 1 s, followed by a stimulus for 200 ms, 
%followed by a mask that stays on until subjects respond. the response period is 
%built into the 3 sec intertrial interval.

if TMS_on
	IOCard_nidaq(1,0,0);%resets trigger1. resetting here because it takes some time the first time it is reset.
    IOCard_nidaq(1,1,0);%resets trigger2.
	%disp('resetting');
end 

for t = 1:num_trials

	cur_side = sides(t); % side that we're presenting.
	cur_length = stim_width_deg(t);		
	cur_dist_deg = dists_deg(t);
	% disp(' ')
	% disp(sprintf('t = %i',t))
	% disp(sprintf('cur_side = %i',cur_side))
	% disp(sprintf('cur_dist_deg = %.2f',dists_deg(t)))
	% button_press = input('0 = neutral, 1= right, 2 = left: ');
	% index of the most recent timepoint ON THIS SIDE
	%
	% find the largest timepoint that is of the same side as CUR_SIDE, 
	% but smaller than T (current timepoint index).
	%because all of the trials are all on the same side, there is really no need to do this step.
	%but we decided to keep this code in case that we mix left and right trials together.

	prev_t = max(find(sides==cur_side & find(sides)<t));
	next_t = min(find(sides==cur_side & find(sides)>t));
	%	
	% translate from SIDES & dists_deg -> SHIFTINESS, before drawing the stimulus
	if cur_side==1 % rightwards
		cur_shift_deg = cur_dist_deg;
	else % leftwards
		cur_shift_deg = cur_dist_deg * -1;
	end
	% now convert CUR_SHIFT into CUR_SHIFT_PIX. see LANDMARK_TASK_3.M
	cur_shift_pix = round(cur_shift_deg * ppd(1));
	dists_pix(t) = cur_shift_pix; % store for good measure
	
	trial_start_time = GetSecs;
	
	fix_drawn = 0;
	fix_start_time = trial_start_time;
	fix_end_time   = fix_start_time + fix_dur;
	
	stim_drawn = 0;
	stim_start_time = fix_end_time;
	stim_end_time   = stim_start_time + stim_dur;
	
	zapped = 0;
	zap_start_time = stim_start_time + zap_interval;% define when the TMS pulse will occur
	
	mask_drawn = 0;
	mask_start_time = stim_end_time;
	trial_end_time = trial_start_time + fix_dur + stim_dur + iti_dur;
	
	check_resp = 0;
	button_press = 0;%this shouldn't be necessary, but we are resetting at the beginning
	%of every trial just in case. 
	% while loop for the duration of the trial
	SCREEN(w,'FillRect',Bkcolor);
	% display_question(w,WHITE_INDEX,instruct,txtloc_top);
	
	%create full screen of random noise for the mask (>= .5 causes 1's and 0's)
	mask_mat = (rand(rect(4), rect(3)) >= .50) * WHITE_INDEX;

	% mask_mat = ones(rect(3),rect(4))*.5;
	% size(mask_mat)
	SCREEN(w2, 'PutImage', mask_mat); %copy the random mask to the back buffer
	
	% set analog output (to trigger) to 0
	if TMS_on
		actual_trigger_reset_time = GetSecs;
		IOCard_nidaq(1,0,0);%resets trigger1
        IOCard_nidaq(1,1,0);%resets trigger2.
		%disp('resetting');
	else 
		actual_trigger_reset_time = -1;%if the TMS machine is not on, then we are setting 
		actual_zap_time = -1;%these to a negative number so we know that they are not being recorded.
	end
	
	while GetSecs < trial_end_time%%start of main while loop for one trial
		
		% draw fixation cross for 1000ms
		if GetSecs > fix_start_time & GetSecs < fix_end_time & fix_drawn==0
			actual_fix_start_time = GetSecs;
			SCREEN(w,'TextSize',20);
			%SCREEN(w,'DrawText','+', fix_cord(1),fix_cord(2), BLACK_INDEX);	% fixation cross 
			draw_pnline(w,center,fix_width,0,WHITE_INDEX,stimThickness, fix_height);
			fix_drawn = 1;
		end % fixation cross
	
		% draw stimulus for 200ms
		if GetSecs > stim_start_time & GetSecs < stim_end_time & stim_drawn==0
			SCREEN(w,'FillRect',Bkcolor);
			% display_question(w,WHITE_INDEX,instruct,txtloc_top);
			actual_stim_start_time = GetSecs;
			draw_pnline(w,center,stim_width_pix(t),cur_shift_pix,WHITE_INDEX,stimThickness, stim_bar_height);% draw a pseudoneglect stimulus 
			stim_drawn = 1;
			check_resp = 1;
		end % stimulus
	
		if TMS_on & GetSecs > zap_start_time & zapped == 0 
			actual_zap_time = GetSecs;
			IOCard_nidaq(1,0,2047);	% send trigger pulse1 [IOCard_nidaq(CardID,Port,Line)]
            IOCard_nidaq(1,1,2047);	% send trigger pulse2
			zapped = 1;
			%disp('triggering');
		end
		
		if GetSecs > mask_start_time & GetSecs < trial_end_time & mask_drawn==0
			%SCREEN(w,'FillRect',Bkcolor); %we may want to blank the screen before
			%presenting the mask, but this may not be necessary since the maks will
			%overright the stimulus anyway.
			% draw the mask
			actual_mask_start_time = GetSecs;
			%draw_pnline(w,center,mask_width_pix,0,BLACK_INDEX,maskThickness, mask_bar_height);
			SCREEN('CopyWindow',w2,w); %copy from back to front buffer, so mask is visible
			mask_drawn = 1;
			% wait for keyboard input and hide the mask
		end % mask and ITI
	
		%NOTE: some of the code in the next three response blocks is redundant and can be condensed.
		if GetSecs > mask_start_time & check_resp == 1
			[keyIsDown, actual_response_time, keycode] = kbcheck; %check response
			if find(keycode(button_right))%pressed the right button
				button_press = 1;
				check_resp=0;
				%SCREEN(w,'FillRect',Bkcolor);
				%draw_pnline(w,center,fix_width,0,WHITE_INDEX,stimThickness, fix_height);
				% display_question(w,WHITE_INDEX,instruct,txtloc_top)
				RT = actual_response_time - stim_start_time;
				if instruct == 1 & cur_shift_pix< 0, correct = 0;%what is longer & stimulus is to the left
				elseif instruct == 1 & cur_shift_pix > 0, correct = 1;%what is longer & stimulus is to the right
				elseif instruct == 2 & cur_shift_pix < 0, correct = 1;%what is shorter & stimulus is to the left
				elseif instruct == 2 & cur_shift_pix > 0, correct = 0;%what is shorter & stimulus is to the right
				elseif cur_shift_pix == 0, correct = -1; % no shift, no right or wrong answer
				else error('Unknown condition'); end
				% add a row to the BEHAV matrix:
				% run #, trial #, instruct, cur_shift_pix, stim_width_pix, response, 
				% correctness, RT.
				behav(end+1,:) = [run, t, instruct, cur_shift_pix, stim_width_pix(t) ...
								  button_press, correct, RT];
			elseif find(keycode(button_left))%pressed the left button
				button_press = 2;
				check_resp=0; %stop checking
				%SCREEN(w,'FillRect',Bkcolor);
				%draw_pnline(w,center,fix_width,0,WHITE_INDEX,stimThickness, fix_height);
				% display_question(w,WHITE_INDEX,instruct,txtloc_top);
				RT = actual_response_time - stim_start_time;
				if instruct == 1 & cur_shift_pix < 0, correct = 1;%what is longer & stimulus is to the left
				elseif instruct == 1 & cur_shift_pix > 0, correct = 0;%what is longer & stimulus is to the right
				elseif instruct == 2 & cur_shift_pix < 0, correct = 0;%what is shorter & stimulus is to the left
				elseif instruct == 2 & cur_shift_pix > 0, correct = 1;%what is shorter & stimulus is to the right
				elseif cur_shift_pix == 0, correct = -1; % no shift, no right or wrong answer
				else error('Unknown condition'); end
				% add a row to the BEHAV matrix:
				% run #, trial #, instruct, stim_shift_pix, stim_width_pix, response, 
				% correctness, RT.
				behav(end+1,:) = [run, t, instruct, cur_shift_pix, stim_width_pix(t) ...
								  button_press, correct, RT];
								  
			elseif find(keycode(button_neutral)) %pressed the neutral button
				button_press = 0;
				check_resp=0; %stop checking
				%SCREEN(w,'FillRect',Bkcolor);
				%draw_pnline(w,center,fix_width,0,WHITE_INDEX,stimThickness, fix_height);
				RT = actual_response_time - stim_start_time;
				correct = 0;
				behav(end+1,:) = [run, t, instruct, cur_shift_pix, stim_width_pix(t) ...
								  button_press, correct, RT];
			end
		end
		
	end%end while loop
	actual_trial_end_time = GetSecs;
	if check_resp == 1%during when we are looking for a response and subjects have not
		%yet pressed a button this trial
		button_press = -1;%they didn't respond (no press)
		correct = 0; % count no-press as wrong
		RT = -1;%count reaction time as negative
		actual_response_time = -1;
		% they didn't press either of the allowed keys
		%
		% add a row to the BEHAV matrix:
		% run #, trial #, instruct, stim_shift_pix, stim_width_pix, response, 
		% correctness, RT.
		behav(end+1,:) = [run, t, instruct, cur_shift_pix, stim_width_pix(t) ...
								  button_press, correct, RT];
	end
	timing(end+1,:) = [run, t, trial_start_time, actual_trigger_reset_time, actual_fix_start_time, ...
						actual_stim_start_time, actual_zap_time, actual_mask_start_time, actual_response_time, ...
						actual_trial_end_time];
						
	% this is all staircasing. 
	responses(t) = button_press;
	corrects(t) = correct;
	if correct == 1 % they said the correct side
		if t>1 & corrects(prev_t) & dists_deg(prev_t) == cur_dist_deg% 2nd correct in a row
			%in the future, the correct way to do this would be to have "n" corrects in a row
			dists_deg(next_t) = cur_dist_deg * step_proportion; % make it harder for next trial
		else % either first trial OR previous trial was incorrect
			dists_deg(next_t) = cur_dist_deg; % keep it the same difficulty for next trial
		end
	else % they said either neutral OR the incorrect side
		% we don't need to check whether it's the first trial, 
		% since if you get it wrong, we'll make it easier no matter what
		dists_deg(next_t) = cur_dist_deg / step_proportion; % make it easier
	end % cur_side
	% save the contents of the workspace for this trial, e.g. ss_debug_t37.mat
	% disp('Saving debug info for this trial')
	% save(sprintf('%s_t%i.mat',debug_fname,t));
end %end for loop

% save as ascii tab-delimited (i.e. tabs between each columns, 
% so you can open/paste it in excel
%
% BEHAVE = run #, trial #, instruct, stim_shift_pix, stim_width_pix, response, 
% correctness, RT.
save(log_fname,'behav','-ascii','-tabs');
%save(tm_fname,'timing','-ascii','-tabs');
save(mat_fname);

SCREEN('CloseAll');
showcursor;


