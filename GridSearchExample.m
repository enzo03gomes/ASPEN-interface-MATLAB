%% SETUP
    clc; clear();
    [stat,mess] = fileattrib; file = [mess.Name '\Rankine-2Stage-Cycle.apwz'];
    

%% DEFINE PARAMETERS    
    maxTime  = 40;                                                          %maximum simulation time
    gridFile = "C:\Users\enzo0\Documents\AAU\OllieThesis\ASPEN MATLAB COM INTERFACE\Clean Files\gridSearchParameters.CSV";


%% RUN GRID SEARCH
    %load ASPEN file
    wb = waitbar(0, "Loading ASPEN+ file...", "Name", "Grid Search ASPEN+");
    
    ASPEN = loadASPEN(file);
    
    waitbar(0, wb, "ASPEN PLUS file loaded. Loading grid search parameters...")

    %retrieve grid parameters
    grid = readtable(gridFile, 'VariableNamingRule', 'preserve');  % Load grid parameters from the CSV file
    grid(:, 1) = [];

    %separate into input, status and output
    colNames = string(grid.Properties.VariableNames);
    
    statusID = find(colNames == "status");                                  %status column is used as a separator between input and output. Knowing its position means we can separate the two sub-tables
    outputID = (statusID+1):length(colNames);
    nodeID   = 1:(statusID-1);
    runID    = find(grid{:, statusID} == -1);                               %find which combinations haven't been run yet

    node     = colNames(nodeID);
    nodeOut  = colNames(outputID);
    
    waitbar(0, wb, "Running Grid Search...")


    %loop over each not-yet-run combination
    for i = 1:length(runID)

        %redo simulation
        runPos = runID(i);
        currNodeVal = grid{runPos,nodeID};
        [outp, conv] = runASPEN(ASPEN, node, currNodeVal, nodeOut, maxTime);
        
        %update wait bar
        waitbar(i/length(runID), wb, sprintf("Running Grid Search...\nRun %i completed with status %i", runPos, conv))

        %reconstruct the grid
        grid(runPos, statusID) = array2table(conv);                                           %update status
        grid(runPos, outputID) = array2table(outp);                                           %save output values
        
        %save CSV file
        writetable(grid, gridFile)
    end

    %close wait bar
    close(wb)


%% PLOT RESULTS:    
    %re-order results
    eff = grid; eff(:,"status") = [];
    
    eff.Properties.VariableNames = ["Turbine 1 Offload Pressure (bar)" "Turbine 2 Offload Pressure (bar)" "Efficiency"];

    %plot results
    figure(1)
    heatmap(eff, "Turbine 1 Offload Pressure (bar)", "Turbine 2 Offload Pressure (bar)", 'ColorVariable', "Efficiency")
    