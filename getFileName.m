function [fileName] = getFileName(tool)
%GETFILENAME Returns the fileName for test results, depending on the tool
%   Inputs:
%       tool: the name of the tool
%
%   Outputs:
%       fileName: char array containing file name

fileName = datestr(now,'dd_mm_yy_HHMM');
    if contains(settingName,'setting','IgnoreCase',true)
        nameStr = erase(settingName,{'Setting','setting'});
        fileName = strcat('./TestResults/', tool, '_', nameStr,'_',fileName,'.mat');
    else
        fileName = strcat('./TestResults/', tool, '_', model,'_',fileName,'.mat');
    end
end

