%% OBJECTIVE:
    %open an ASPEN PLUS simulation (.apwz)


%% INPUT:
    %file:  full path to ASPEN .apwz file
    

%% OUTPUT:
    %ASPEN: handle for simulation


%% FUNCTION:    
    function [ASPEN] = loadASPEN(file)
        wb = waitbar(0, "Loading ActiveX COM interface...", "Name", "Loading ASPEN+");
        ASPEN = actxserver('Apwn.Document');                                %Load COM interface
        
        waitbar(0, wb, "Initializing ASPEN+ file...")
        ASPEN.InitFromFile2(file);                                          %Load simulation
        
        waitbar(0, wb, "Updating Settings...")
        ASPEN.Visible = 1;                                                  %Don't open ASPEN on screen
        ASPEN.SuppressDialogs = 1;                                          %Don't let  ASPEN output popup dialog boxes
    
        while ASPEN.Engine.IsRunning                                        %Ensure that ASPEN engine is done running before reinitiating
            pause(0.1)
        end

        waitbar(0, wb, "Initializing the Simulation...")
        ASPEN.Engine.Run2(0);                                               %Simulation is run syncronously to avoid race conditions

        while ASPEN.Engine.IsRunning                                        %Ensure that ASPEN engine is done running before moving on
            pause(0.1)
        end

        close(wb)
    end