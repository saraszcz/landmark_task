function [] = ptb(funcname)

try
    oldclut=Screen('LoadClut',0);
    eval(funcname)
catch
    Screen('CloseAll');
    ShowCursor;
    ListenChar(0);
    Priority(0);
    Screen('LoadClut',0,oldclut);
    %rethrow(lasterror);
end
