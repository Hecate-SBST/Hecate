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

% Success boolean variable
success = false;

% Remove the 'benchmarks' and 'demos' folders. This is not necessary, but
% they can interfere with normal running of the software if they are added
% to the active path by mistake.
if exist(staliroPath + filesep + "benchmarks","dir") == 7
    rmdir(staliroPath + filesep + "benchmarks","s");
    success = true;
else
    warning(sprintf("The folder '%s%sbenchmarks' was not found. Either it has already\n" + ...
        "been removed or the path to the S-Taliro folder is incorrect.",staliroPath,filesep));
    success = false;
end

if exist(staliroPath + filesep + "demos","dir") == 7
    rmdir(staliroPath + filesep + "demos","s");
    success = success & true;
else
    warning(sprintf("The folder '%s%sdemos' was not found. Either it has already\n" + ...
        "been removed or the path to the S-Taliro folder is incorrect.",staliroPath,filesep));
    success = false;
end

% Remove the original function 'staliro/auxiliary/Compute_Robustness.m'.
% This is necessary, as this function must be replaced by a version
% customized for Hecate.
if exist(staliroPath + filesep + "auxiliary" + filesep + "Compute_Robustness.m","file") == 2
    delete(staliroPath + filesep + "auxiliary" + filesep + "Compute_Robustness.m");
    success = success & true;
else
    warning(sprintf("The file '%s%sauxiliary%sCompute_Robustness.m' was not found.\n" + ...
        "Either it has already been removed or the path to the S-Taliro folder is incorrect.",staliroPath,filesep,filesep));
    success = false;
end

% Print success message
if success
    fprintf("All the relevant files have been replaced inside S-Taliro. Hecate can be now used.\n" + ...
        "Please check 'help hecate' for instructions on the syntax of the function.\n\n")
else
    fprintf("One or more files have already been removed or were not found.\n" + ...
        "If the update process was already performed before, there is no need to run it again.\n" + ...
        "Otherwise, check that the S-Taliro path was correct.\n\n")
end

end