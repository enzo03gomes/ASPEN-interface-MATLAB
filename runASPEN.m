%% OBJECTIVE:
    %Run an ASPEN PLUS simulation (.bkp) with modified node values


%% INPUT:
    %ASPEN:   handle to ASPEN simulation
    %node:    1xn vector with nodes to modify
    %nodeVal: 1xn vector with values to assign to nodes
    %nodeOut: 1xm vector with nodes to output
    %maxTime: 1x1 numeric of maximum time (in seconds) that simulation is allowed to run
    
%% OUTPUT:
    %nodeOutVal: value of output nodes
    %conv:       convergence of simulation (0 - converged w/o warnings, 1 - fail to converge, 2 - converged w/ warnings)


%% FUNCTION:    
function [nodeOutVal, conv] = runASPEN(ASPEN, node, nodeVal, nodeOut, maxTime)
        %modify nodes
        for i = 1:length(node)
            ASPEN.Tree.FindNode(node(i)).Value = nodeVal(i);
        end
        
        %wait for ASPEN to load the new values
        while ASPEN.Engine.IsRunning
            pause(0.1)
        end


        %re-run simulation
        ASPEN.Engine.Run2(0);                                               %Re-run simulation syncronously to avoid race conditions
        
        time = 0;
        while ASPEN.Engine.IsRunning == 1                                   %Continue to run simulation until max run time is reached - may not be needed anymore (aspen is synchronous now)
            pause(0.5);
            time = time+1;
            if time==maxTime 
                ASPEN.Engine.Stop;
            end
        end

        nodeOutVal = inf([1 length(nodeOut)]);                              %Object to store output (initialized here because it is used if convergence == 0 or == 1)


        %check convergence
        conv = checkConvergence(ASPEN);

        %extract output node values
        for i = 1:length(nodeOut)
            nodeOutVal(i) = ASPEN.Tree.FindNode(nodeOut(i)).Value;
        end

end


%ASPEN.Export('HAPEXP_REPORT', "report.txt") (SUMMARY, INPUT also work)