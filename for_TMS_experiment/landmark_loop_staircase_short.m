%%landmark_loop.m
%%calls landmark_task_1 multiple times with different inputs (run, instruct)
% for TMS experiment, we have 4 runs of landmark_task_1
% subj_id = must change this for every subject
% run = run #
% instruct: 1 = "Which is longer?"; 2 = "Which is shorter?"
%behav
%landmark_task_staircase_short('rl_111308_behav', 1, 1, 1);%run 1, Which is longer? Right staircase
% landmark_task_staircase_short('rl_111308_behav', 2, 2, 2);%run 2, Which is shorter? Left staircase
% landmark_task_staircase_short('rl_111308_behav', 3, 2, 1);%run 3, Which is shorter? Right staircase
% landmark_task_staircase_short('rl_111308_behav', 4, 1, 2);%run 4, Which is longer? Left staircase
%TMS
landmark_task_staircase_short('rl_120208_behav', 1, 1, 1);%run 1, Which is longer? Right staircase
landmark_task_staircase_short('rl_120208_behav', 2, 2, 2);%run 2, Which is shorter? Left staircase
landmark_task_staircase_short('rl_120208_behav', 3, 2, 1);%run 3, Which is shorter? Right staircase
landmark_task_staircase_short('rl_120208_behav', 4, 1, 2);%run 4,


%don't need to do these other 4 because we are using intermingled blocks.
%landmark_task_staircase_2('test4', 5, 1, 2);%run 1, Which is longer? Left staircase
%landmark_task_staircase_2('test4', 6, 2, 1);%run 2, Which is shorter? Right staircase
%landmark_task_staircase_2('test4', 7, 2, 2);%run 3, Which is shorter? Left staircase
%landmark_task_staircase_2('test4', 8, 1, 1);%run 4, Which is longer? Right staircase


