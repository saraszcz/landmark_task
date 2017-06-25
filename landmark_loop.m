%%landmark_loop.m
%%calls landmark_task_1 multiple times with different inputs (run, instruct)
% for TMS experiment, we have 4 runs of landmark_task_1
% subj_id = must change this for every subject
% run = run #
% instruct: 1 = "Which is longer?"; 2 = "Which is shorter?"
landmark_task_1('test', 1, 1);%run 1, Which is longer?
landmark_task_1('test', 2, 2);%run 2, Which is shorter?
landmark_task_1('test', 3, 2);%run 3, Which is shorter?
landmark_task_1('test', 4, 1);%run 4, Which is longer?

