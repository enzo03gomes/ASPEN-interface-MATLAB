%% OBJECTIVE:
    %Check if a ASPEN simulation has converged by checking all flags.

%% INPUTS:
    %ASPEN: COM interface with ASPEN+

%% OUTPUTS:
    %conv: convergence value. When the flags have different values, conv
    %returns the worst case scenario (i.e., if there are warnings but no errors, it returns warning (2); if there are warnings and errors, it returns error (1))


%% FUNCTION:

function [conv] = checkConvergence(ASPEN)
    %load output node
    convNode = "/Data/Results Summary/Run-Status/Output";
    convLeaf = ["CSSTAT" "CVSTAT" "PCESSTAT" "PPSTAT" "PROPSTAT" "RSTAT" "SENSSTAT" "PCESSTAT"];
    convVals = inf([1 length(convLeaf)]);

    %loop over all leafs and check value
    for i = 1:length(convLeaf)
        convVals(i) = ASPEN.Tree.FindNode(sprintf("%s/%s", convNode, convLeaf(i))).Value;
    end
    
    %if there's any convergence flag that triggers a warning or error, make the worst the output
    conv = 0;
    for i = 1:(length(convLeaf)-1)
        if convVals(i) ~= 0 && (conv > convVals(i) || conv == 0)            %if not successful (0) and if previous saved flag is a warning (2) and the current is an error (1), update output
            conv = convVals(i); 
        end
    end

    %last flag is different: if <10, behaves the same as before. if >10 and <999:
    %if multiple of 10, flags success; otherwise is warning
    %if >999, flags error

    lastFlag = convVals(length(convLeaf));
    if lastFlag >= 10
        if lastFlag >= 1000                                                 %garanteed error
            conv = 1;

        elseif mod(lastFlag, 10) ~= 0 && conv ~= 1                          %if flagged as warning but output is not an error, then update output
            conv = 2;
        end    
    
    elseif lastFlag ~= 0 && (conv > lastFlag || conv == 0)                  %same as all other flags
        conv = lastFlag;
    end
end