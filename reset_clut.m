function [] = ptb(funcname)

load oldclut
Screen('CloseAll');
ShowCursor;
ListenChar(0);
Priority(0);
Screen('LoadClut',0,oldclut);
clear all
%rethrow(lasterror);
