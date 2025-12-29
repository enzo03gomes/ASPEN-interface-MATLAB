# ASPEN-interface-MATLAB
Simple Aspen Plus interface with MATLAB for process optimization.

This repo is meant to be used to optimize processes with respect to temperatures, pressures, stream compositions, etc., and not optimize layouts or perform heat integration. If that is something that interests you, feel free to contact me, and we can have a look at that together.


## How to Set Up a MATLAB Interface with Aspen Plus
The program `loadASPEN.m` takes in a directory to an Aspen Plus `.apwz` file, and automatically activates a COM server with Aspen Plus through `Apwn.Document` and initializes the simulation. This function also outputs a handle to the COM server.

Since MATLAB only supports late-binding, the simulation details (such as parameter values or plant structure) are not cached until it is run for the first time using the interface. For this reason, `loadASPEN.m` also runs the simulation once. Although this makes loading the simulation interface slower (taking a few minutes), it allows for variable values to be found and modified later on without trouble.

## Modifying and Running an Aspen Plus Simulation Through MATLAB
Once the COM interface has been loaded using `loadASPEN`, you can use `runASPEN.m` to select the variables you want to change, their respective values, and any variables you may want to read.
For example, the Aspen Plus file `Rankine-2Stage-Cycle.apwz` contains a simple simulation of a 2-stage Rankine Cycle for power generation. It includes a thermodynamic efficiency calculator module (`EFFCALC`), as well as a calculator module (`PRESSEQ`) that automatically sets the heater and condenser offload pressures to match the offload pressures of the turbines and pumps upstream (i.e., the pressure drop across these units is zero).

Let's say you want to observe how the process efficiency changes with different offload pressures of the turbines. You can find the path to the pressures using the Variable Explorer in Aspen Plus:
<img width="1929" height="1029" alt="FindPRES1" src="https://github.com/user-attachments/assets/b53b4e8b-c2fa-480b-ad9b-5f49f4620a39" />
<img width="1929" height="1029" alt="FindPRES2" src="https://github.com/user-attachments/assets/deef5eab-c137-4a7e-a660-0975522323ee" />


Then, copy the path to the offload pressure parameter:
<img width="1929" height="1029" alt="FindEFF" src="https://github.com/user-attachments/assets/a7fa64f1-4e07-4165-ac60-cf3453ab88e3" />


In MATLAB, we can set the `node` variable to be `node = ["/Data/Blocks/TURB-1/Input/PRES", "/Data/Blocks/TURB-2/Input/PRES"]`, and then select a node value: `nodeVal = [90, 20]`.
Since we only care about how this affects the overall efficiency of the process, we can search for the output of `EFFCALC` using the variable finder again:
*figure here*

And set `nodeOut = "/Data/Flowsheeting Options/Calculator/EFFCALC/Output/WRITE_VAL/6"`. Overall, the MATLAB program would look like:

```{MATLAB}
%% Define path to simulation
[stat,mess] = fileattrib; file = [mess.Name '\Rankine-2Stage-Cycle.apwz'];

%% Load the ASPEN interface
ASPEN = loadASPEN(file);

%% Define simulation parameters
node    = ["/Data/Blocks/TURB-1/Input/PRES", "/Data/Blocks/TURB-2/Input/PRES"];
nodeVal = [90, 20];
nodeOut = "/Data/Flowsheeting Options/Calculator/EFFCALC/Output/WRITE_VAL/6";
maxTime = 40 %this option is deprecated

%% Run simulation with modified offload pressures
[eff, conv] = runASPEN(ASPEN, node, nodeVal, nodeOut, maxTime);
fprintf("THermodynamic efficiency: %0.2f\n\n", eff)
```

Note how `runASPEN` also outputs `conv`. This object is the same output by `checkConvergence`, and is equal to `0` if the simulation converged with no warnings, `1` if it failed to converge, and `2` if it converged with warnings. These values are in line with what Aspen Plus itself uses. It is important to keep an eye on this, since Aspen Plus can be rather volatile.



## Example of a Grid Search Using MATLAB and R
Now that we have looked at a simple example of modifying and running a simulation, let's try to actually optimize the offload pressure of the turbines. This repo includes an R file (`GridSearchGen.R`) that helps you set up a grid search. In this file, you can set the explanatory variables and respective values, as well as the variable you want to read (i.e., the response variables).

In this case, we want the offload pressure of the first turbine to be between 90 bar and 200 bar, while the second turbine pressure varies between 2 bar and 30 bar. The desired response variable is still the efficiency; therefore, we set:

```{R}
#node names and values of explanatory variables
nodes    = list("/Data/Blocks/TURB-1/Input/PRES" = seq(90, 200, length.out = 5),
                "/Data/Blocks/TURB-2/Input/PRES" = seq(2, 30, length.out = 5))

#node names of response variables
output   = c("/Data/Flowsheeting Options/Calculator/EFFCALC/Output/WRITE_VAL/6")

```

> [!Note]
> The search here is limited by the fact that the offload pressure of the second turbine has to be lower than the first (otherwise it'd be a compressor, not a turbine). You need to pay attention to these details, as the interface is not aware of the physics and engineering behind your simulation, and ASPEN may crash when given faulty information.

Running the program, you'll see a new file `gridSearchParameters.CSV`. This file contains all the combinations of pressures in the first two columns, as well as the desired response variable in the last column. You'll notice that separating these is a column named `status`, which is filled with `-1`. This column is where the MATLAB program `GridSearchExample.m` will save the convergence values output by `runASPEN`. It is preloaded with `-1` so that, in case Aspen Plus crashes halfway through the grid search, it can simply look for the earliest `-1` in the column and pick up from there again, without having to re-do the whole search. Similarly, the response variable column is populated with `0` so MATLAB can overwrite them with the obtained values after each simulation.

A more detailed view of how these files work can be found in the files themselves, as they have comments explaining (almost) every line.


## A Quick Note on Convergence 
Aspen Plus does not provide a single parameter confirming the successful convergence of the simulation. Instead, it provides a total of 8 values: `CSSTAT`, `CVSTAT`, `PCESSTAT`, `PPSTAT`, `PROPSTAT`, `RSTAT`, `SENSSTAT`, `PCESSTAT`. All of these variables, with the exception of `PCESSTAT`, follow the rule: `0` if convergence was successful, `1` if there are errors, and `2` if there are warnings. 

`PCESSTAT` follows a more complex rule: if the value has 2 digits only, then it behaves the same as all others; if it has 3 digits and the last digit is `0`, then the convergence was successful. If the last digit is anything but `0`, the simulation was completed with warnings. Finally, if `PCESSTAT` has 4 digits, then the simulation was completed with errors. You can check what each of these different codes mean in the Aspen Plus documentation (see below).


## Tips, Recommendations, and Useful Functions
Here are a couple of commands provided by the Aspen Plus COM interface that can be useful:

- `.Tree.FindPath()`: takes the path to a node and outputs a handle to said node. For example, `ASPEN.Tree.FindPath("/Data/Blocks/TURB-1)` outputs a handle to the first turbine's node.
- `.Elements`: outputs a handle to all children of a node. For example, `ASPEN.Tree.FindPath("/Data/Blocks/TURB-1).Elements` outputs a handle to the first turbine's children.
- `.Item()`: outputs a handle to a specific item given its ID. For example, `ASPEN.Tree.FindPath("/Data/Blocks/TURB-1).Elements.Item(0)` outputs a handle to the first child of the first turbine.
- `.Value`: outputs the value of the given node. For example, `ASPEN.Tree.FindPath("/Data/Blocks/TURB-1/Input/PRES).Value` outputs the set offload pressure of the first turbine.
- `.Visible()`: if `true`, the Aspen Plus GUI will open.
- `.SuppressDialogs()`: if `true`, Aspen Plus will not show the user any pop-up dialogs.
- `.reinit2`: reinitiates the simulation. 


Note that ASPEN tends to struggle with loops such as the one in our Rankine Cycle example. Typically, you handle this by running the simulation with an open loop once, and then run it again with the loop closed. This works because ASPEN now has a better initial estimate of the various stream parameters, and therefore, the solver is more likely to find a solution. This initial estimate is stored in the `.apwz` file, but not in the `.bkp` file, hence why this repo focuses on this file type specifically. Using the `.reinit2()` command will also delete the initial estimate, and therefore, I don't recommend using this command on simulations with loops, unless you also automate the rewiring.

When running a simulation through a COM interface, I recommend running ASPEN manually at least once (and verifying that it actually converges well) before loading it into MATLAB, independently of whether or not your simulation has loops. This is because the interface can be fragile at times, and may not be able to solve the system without an initial estimate.

As a general tip, it is important to remember that both MATLAB and R can overwrite files without warning. So, once you are done with a set of simulations, save or duplicate the produced CSV file in another directory. And although it is unlikely to happen, always keep a backup of your simulation (`.bkp` or not) in another folder, lest either program overwrite or delete your precious simulation.

You can find more information on how the COM interface works in the Aspen Plus documentation, which you can access through here:
<img width="1929" height="1029" alt="AspenCOMhelp" src="https://github.com/user-attachments/assets/28c9e188-c2e9-48bf-bff0-1eaf23aa986d" />


Finally, remember that the examples given here are just examples. Experiment with setups, design of experiments, file management options, etc. and find what best works for you!


## A Final Note
I want to thank --- for their repo on a similar task, which helped me get started on this project!

And to any interested in this repo, you can always feel free to contact me about any questions or suggestions you may have. This project was the first of its kind for me, so I might not be able to answer your questions immediately, but I'll try my best!
