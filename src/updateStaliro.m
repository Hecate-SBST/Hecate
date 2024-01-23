% This function removes some files from S-Taliro to use it in Hecate. This
% function must be run once for each new installation of S-Taliro, but
% it is unnecessary after S-Taliro has been installed correctly.
%
%           updateStaliro(staliroPath);
%
%   E.g.:   updateStaliro("./staliro");
%
% Inputs:
%   staliroPath: Absolute or relative path to the folder containing the
%   S-Taliro installation.
%
% A fresh version of S-Taliro can be downloaded from here:
% https://app.assembla.com/spaces/s-taliro_public/subversion/source/HEAD/trunk
%
% (C) 2024, Federico Formica, McMaster University

function updateStaliro(staliroPath)

% Convert to string
if isa(staliroPath,"char")
    staliroPath = string(staliroPath);
end

% Remove the 'benchmarks' and 'demos' folders. This is not necessary, but
% they can interfere with normal running of the software if they are added
% to the active path by mistake.
if exist(staliroPath + "/benchmarks","dir") == 7
    rmdir(staliroPath + "/benchmarks");
else
    warning(sprintf("The folder 'staliro/benchmarks' was not found. Either it has already\n" + ...
        "been removed or the path to the S-Taliro folder is incorrect."));
end

if exist(staliroPath + "/demos","dir") == 7
    rmdir(staliroPath + "/demos");
else
    warning(sprintf("The folder 'staliro/demos' was not found. Either it has already\n" + ...
        "been removed or the path to the S-Taliro folder is incorrect."));
end

% Remove the original function 'staliro/auxiliary/Compute_Robustness.m'.
% This is necessary, as this function must be replaced by a version
% customized for Hecate.
if exist(staliroPath + "/auxiliary/Compute_Robustness.m","file") == 2
    delete(staliroPath + "/auxiliary/Compute_Robustness.m");
else
    warning(sprintf("The file 'staliro/auxiliary/Compute_Robustness.m' was not found.\n" + ...
        "Either it has already been removed or the path to the S-Taliro folder is incorrect."));
end
end