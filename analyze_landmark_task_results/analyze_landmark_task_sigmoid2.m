function [] = analyze_landmark_task_sigmoid2(log_fname)

% [] = ANALYZE_LANDMARK_TASK_SIGMOID2(LOG_FNAME)
%
% based in part on analyze_landmark_task. we're reading in the behav log
% file which contains all the info about subjects' responses. we want to
% plot the shiftiness against the proportion of rightward bias. we expect
% to get a sigmoid, which we're going to fit, and then use that to
% determine a single value for overall bias (based on the intercept with 
% the sigmoid where the person is saying rightward 50% of the time, aka 
% the 'indifference-intercept').
%
% we could either fit the sigmoid for each run, and then average the
% indifference-intercepts for each run-sigmoid, or we could lump all the
% runs together, and fit just a single sigmoid. we're going to try the
% latter.
%
% we're not sure what to do with the neutral trials: a) ignore them
% completely b) treat them as 50%s, to fill in the gap in the middle
%
% LOG_FNAME = the name of the file, e.g. 'kw012308_r*_log.txt' will load
% in all 4 runs.
%
% USAGE: analyze_landmark_task_sigmoid('kw012308_r*_log.txt')
%
% so we can use fitFunc and all the sigmoid fitting tools from Seth
%
% 8/10/09: removed neutral trials from analysis. made sure that our plot
% function was not plotting bins with less than 2 trials/bin
% 10/9/09: added some code to manipulate the axes

addpath /Users/saraszczepanski/Desktop/Pseudoneglect_study/seths_dataAnalysisTools/

% get a list of filenames that match the LOG_FNAME wildcard
filens = dir(log_fname);
% NTRIALS x 8
all_logs = [];

all_bin_midpoints = [];
all_prop_rights = [];
all_trials_per_bin = [];

for f=1:length(filens)
    cur_fname = filens(f).name;
    
    % nCurTrials x 8. the current log
    log = load(cur_fname);
    
    % all the hard work for a single log happens in this function. then, we
    % just amalgamate the results from each log together. we have to
    % analyze each log separately, otherwise it's harder to deal with the
    % fact that INSTRUCT has both kinds of values
    [cur_bin_midpoints cur_prop_rights cur_trials_per_bin] = analyze_single_log(log);

    % 1 x nRuns*nBins vector
    all_bin_midpoints  = [all_bin_midpoints  cur_bin_midpoints];
    all_prop_rights    = [all_prop_rights    cur_prop_rights];
    all_trials_per_bin = [all_trials_per_bin cur_trials_per_bin];

    % if you want to take the mean, you'll want to store an nRuns x nBins
    % matrix, and take the mean over rows
    % all_bin_midpoints = [all_bin_midpoints; cur_bin_midpoints];
    % all_prop_rights   = [all_prop_rights;   cur_prop_rights];

    all_logs = [all_logs; log];
    clear log
end % f filens

% this requires you to change the way you append the points to
% ALL_BIN_MIDPOINTS etc. above
% mean_bin_midpoints = nanmean(all_bin_midpoints);
% mean_prop_rights   = nanmean(all_prop_rights);

% try and fit a sigmoid to our data. see fitFunc.m and
% analyzeStaircase_surf.m (from seths_dataAnalysisTools) for more
% information

notnans = ~isnan(all_prop_rights);
%keyboard
all_prop_rights    = all_prop_rights(notnans);
%keyboard
all_bin_midpoints  = all_bin_midpoints(notnans);
%keyboard
all_trials_per_bin = all_trials_per_bin(notnans);
%keyboard

% the data have to be 2 x nObservations, with row 1 = x, row 2 = y

data = [all_bin_midpoints; all_prop_rights];

% i'm not too sure whether these startParams are right. we stole them from
% the example in fitFunc for sigmoidLikelihood
% semiSat = mean(all_bin_midpoints);
% slope = 2;
% max = 1;
% sig_startParams = [semiSat slope max];
% sig_free = [1 2 3]; % we want to try and fit all 3 of the startParams

% thresh    = 0.5;%
% slope     = 1;
% guess     = 0;%what you would expect if someone is at chance (where left-most curve begins)
% flake     = 1;%highest performance
% maxThresh = 20;
% weib_startParams = [thresh slope guess flake maxThresh];
% weib_free = [1 2 3 4 5];

% fit the sigmoid to the data, and get the parameters that it decides on
% (fitParams)
%
% sigmoid
%[fitParams, q, chisq, df] = fitFunc(sig_startParams, data, sig_free, 'sigmoidLikelihood');
% weibull
%[fitParams, q, chisq, df] = fitFunc(weib_startParams, data, weib_free, 'WeibullLikelihood');
% fitParams
% now ask the model what the y values should be (using the parameters you
% just fit to the data), for the x values you have
% fitted_y = sigmoid(fitParams, all_bin_midpoints);


% plot the amalgamated sigmoid (with multiple points at the same x values)
% figure, hold on
% plot(all_bin_midpoints, all_prop_rights, 'kx')
% % plot the fitted model
% plot(all_bin_midpoints, fitted_y, 'r-');
% xlabel('Shiftiness (deg) bin midpoint')
% ylabel('Proportion of "right is longer" in each bin')

%%%%% uses Seth's function (analyzeStaircase_surf.m)in order to fit the
%%%%% Weibull function
d.stimLevels=all_bin_midpoints+2; % so that they're all positive-- 
%function can't deal with negative number.because we have negative numbers, 
%the square root comes out to be an imaginary number.  so we are adding 2 
%points to each value, so that they are all positive.  
%will subject this 2 points off of each value when we
%calculate the threshold. 
d.numCorrect=all_prop_rights.*all_trials_per_bin; % number right in each bin
d.numTrials=all_trials_per_bin; % number in each bin (both right and left)

% runs the analysis to find the best sigmoid, and returns the parameters in
% ANALYSIS
%plots out the sigmoid
[analysis large_bin_idx] = analyzeStaircase_surf(d); % ,'doPlot');


%%Returns the X value (in degrees of visual angle) that corresponds to some Y
%%threshold value (for example, the point where 50% of the time subjects
%%are reporting right, and 50% of the time they are reporting left)

target_y = .5;%this  is what we want to find %XXX
x_min = min(analysis.x);
x_max = max(analysis.x);
x_samples = x_min:.0001:x_max; % create lots and lots of fine-grained x values
predicted_y_from_samples = weib(x_samples,analysis.thresh,analysis.slope,analysis.guess,analysis.flake);% get the model to predict y values for each of x samples
y_min = min(predicted_y_from_samples);
% closest_y_idx = find(target_y - predicted_y_from_samples==min(abs(target_y-predicted_y_from_samples))); % pick closest to target_y
[closest_y_val closest_y_idx] = min(abs(target_y-predicted_y_from_samples)); % pick closest to target_y
closest_x_val = x_samples(closest_y_idx); %should return an x location that evaluates closest to behav_level

figure, hold on
% plot the binned data points. Note: ALL_BIN_MIDPOINTS doesn't have the +2
% added to make the x-values positive so the sigmoid fitting would work
plot(all_bin_midpoints(large_bin_idx), all_prop_rights(large_bin_idx), 'kx');

% plot the sigmoid model in red. we have to subtract 2 to plot this on the
% right x scale
plot(x_samples-2, predicted_y_from_samples, 'r-');

%%plot the target_y and closest_x_val
plot([x_min-2 closest_x_val-2], [target_y target_y], 'g-'); % plot a horizontal line from the y-axis to the closest x val
plot([closest_x_val-2 closest_x_val-2], [y_min target_y], 'g-'); % plot a vertical line from the x-axis to the closest y xval

%%%added this bit of code to make SFN figures%%%
% axis(axis(gca).*[0 0 0 0] + [-1 1 -.1 1.1]);%sets x axis so that it doesn't got past -1 or 1 %xxx
% set(gca,'YTick',[0:.25:1]);%sets Y axis %xxx
% set(gca,'XTick',[-1:.5:1]);%sets X axis %xxx
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

closest_x_val = closest_x_val - 2 %we need to subtract the two that we added above.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [bin_midpoints prop_rights trials_per_bin] = analyze_single_log(log)

nTrials = size(log,1); % total for all logs

run       = log(:,1);
trial     = log(:,2);
instruct  = log(:,3); % 1= which is longer, 2 = which is shorter
shift_pix = log(:,4);
width_pix = log(:,5);
response  = log(:,6);
correct   = log(:,7);
rt        = log(:,8);

% all the INSTRUCT values should be the same
assert(length(unique(instruct))==1);
instruct = unique(instruct); % boil it down to a single value

%%%%%User parameters%%%%%
res_x = 1280;%resolution of monitor in x direction. Powerbook.
%res_x = 800;%resolution of monitor in x direction. TMS room.
res_y = 854;%resolution of monitor in y direction. Powerbook.
%res_y = 600;%resolution of monitor in y direction. TMS room.
sz = [32 21.5];%sz of sreen in cm. PowerBook screen.
%sz = [40 30];%sz of sreen in cm. TMS room screen.
vdist = 32;%distance from screen in cm. Powerbook. 
 
binwidth = .1; %%% arbitrary

%%%%%%%%%%%%%%%%%%%%%%%%%
% we want to deal with everything in terms of visual angle
[ppd dpp] = VisAng([res_x res_y],sz,vdist);
% dpp(1) = horizontal
%
% line stimulus shiftiness and width values, in degrees
shift_deg = shift_pix * dpp(1);
width_deg = width_pix * dpp(1);

% creates a histogram (i.e. bins the various SHIFT_DEG values)
% 
% we decided not to use this, because we want the bin boundaries to be 
% hardcoded for all subjects, whereas this will come up with different 
% bin boundaries each time.
%
 %hist(shift_deg,20)

% define the bin boundaries
%
% the starting points are +/-2 degrees of visual angle
upper =  2; %1.1; %XXX
lower = -2; %-1.1; %XXX
% linspace(-1,1,21) % decided this was overkill
bin_boundaries = lower:binwidth:upper;
% for each bin, average together its upper and lower boundaries
bin_midpoints = mean([bin_boundaries(1:end-1); bin_boundaries(2:end)],1);
 
% HISTC is like HIST, except that you specify the bin boundaries to use for
% the counts per bin. better still, BIN_IDX labels which bin each point
% falls into
[counts_per_bin bin_labels] = histc(shift_deg,bin_boundaries);
% when you assert that something is true, matlab will give you an error if
% you're wrong. since we're about to get rid of the nth bin, i just want to
% check that nothing actually fell into that bin. if this were ever to be
% true, then we should probably not remove the last bin. i don't think it
% makes much difference either way.
assert(length(find(bin_labels==length(bin_boundaries)))==0);
% it returns as many counts as you fed it boundaries, because the last bin
% consists of just those that match boundaries(end). so we're just going to
% ignore that last bin.
counts_per_bin = counts_per_bin(1:end-1);
nBins = length(counts_per_bin);

% rough-and-ready display of the histogram of bin counts. but the X axis 
% doesn't display the bin boundaries correctly
% bar(counts_per_bin);

% the BIN_LABELS labels each trial according to the bin boundaries within 
% which it falls (in terms of its SHIFTINESS_PIX). then, using that
% label vector, we're going to index into the RESPONSEs to determine the
% proportion of rights in each bin
%
% PROP_RIGHTS = a 1 x nBins vector containing the proportion of rightward
% values in each bin
prop_rights = [];
% TRIALS_PER_BIN = count of total number of trials in each bin 
% (this gets used to calculated PROP_RIGHTS)
trials_per_bin = [];
for b=1:nBins
    % find all the trials that fell into this bin
    trial_idx = find(bin_labels==b);
    % now pull out all the responses for this bin. cur_resps can either be
    % a bunch of 1's, 2's, or -1's
    cur_resps = response(trial_idx);
    % disp('before')
    % cur_resps
    % whittle down CUR_RESPS to just include lefts and rights (i.e. exclude
    % neutrals and no-responses)
    cur_resps(cur_resps==0) = [];
    cur_resps(cur_resps==-1) = [];
    
    nTrialsThisBin = length(cur_resps);
    % disp('after')
    % cur_resps
    % now calculate the proportion of the responses for this bin that are
    % rightward. 1 = right, 2 = left
    switch(instruct)
        % if they're being asked 'which is longer', then a 'right' response
        % means 'right is longer'. if they're being asked 'which is
        % shorter', then a 'left' response means 'right is longer'
        case 1 % longer
            cur_prop_right = length(find(cur_resps==1)) / nTrialsThisBin;
        case 2 % shorter
            cur_prop_right = length(find(cur_resps==2)) / nTrialsThisBin;
        otherwise
            error('Instruct must be either 1 or 2');
    end % switch instruct
    % store the proportion of rightwards for this bin in our main vector of
    % counts
    trials_per_bin(b) = nTrialsThisBin;
    prop_rights(b) = cur_prop_right;
end % b nBins

% plot the individual run
% figure
% plot(bin_midpoints, prop_rights, 'kx')
% xlabel('Shiftiness (deg) bin midpoint')
% ylabel('Proportion of "right is longer" in each bin')

%save

%TO DO:      
%1. Find and return 50% point. 2. Save out graphs 

% TODO FOR SIGMOID FIT:
% - What to do with the outliers? [Some solutions: 1. increase 
% the bin size, so there are more trials per bin or 2. exclude bins with 3 
% or less values inside; right now it's at 2].
% - Should we be using the Weibull or Sigmoid likelihood functions???  



