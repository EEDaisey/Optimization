%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   9 December 2025
%     Title:   Question 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolveHouseOptionProblem()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Problem Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Utilities (u_i) for options 1, 2, 3, ..., 9:
    utility = [9 10 5 9 6 4 6 5 8]'; 
    
    % Costs (in thousands of dollars) for options 1, 2, 3, ..., 9:
    pricesK = [25 30 42 32 27 12 15 25 45]'; 
    
    % Budget in thousands of dollars:
    budgetK = 120;         % $120,000
    
    % Number of decision variables:
    numVars = length(utility);  % 9
    
    %%%%%%%%%%%%%%%%%%%%%%%%% Objective for intlinprog %%%%%%%%%%%%%%%%%%%%
    % intlinprog minimizes; we want to maximize utility.
    % We minimize the negative of total utility: f^T x = -(utility^T x).
    objCoeffs = -utility;
    
    %%%%%%%%%%%%%%%%%%%%%%%%% Inequality Constraints %%%%%%%%%%%%%%%%%%%%%%
    % A*x <= b.
    
    % (1) Budget Constraint: pricesK' * x <= budgetK:
    aBudget = pricesK';
    bBudget = budgetK;
    
    % (2) Additional Constraints:
    %     x4 + x7 <= 1
    aSunDeck = [0 0 0 1 0 0 1 0 0];
    bSunDeck = 1;
    
    %     x4 + x2 <= 1
    aSunKitchen = [0 1 0 1 0 0 0 0 0];
    bSunKitchen = 1;
    
    %     x8 + x6 <= 1
    aGaragePorch = [0 0 0 0 0 1 0 1 0];
    bGaragePorch = 1;
    
    %     x7 + x9 <= 1
    aDeckPool = [0 0 0 0 0 0 1 0 1];
    bDeckPool = 1;
    
    %     x1 <= x5   -->   x1 - x5 <= 0
    aBedroomBasement = [1 0 0 0 -1 0 0 0 0];
    bBedroomBasement = 0;
    
    % Stack all inequality rows:
    A = [
        aBudget;
        aSunDeck;
        aSunKitchen;
        aGaragePorch;
        aDeckPool;
        aBedroomBasement
    ];
    
    b = [
        bBudget;
        bSunDeck;
        bSunKitchen;
        bGaragePorch;
        bDeckPool;
        bBedroomBasement
    ];
    
    %%%%%%%%%%%%%%%%%%%%%%%%% Variable Bounds & Integrality %%%%%%%%%%%%%%%
    % x_i element of {0,1}.
    lowerBounds = zeros(numVars, 1);   % x_i >= 0
    upperBounds = ones(numVars, 1);    % x_i <= 1
    intCon = 1:numVars;                % All Variables Integers
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solve ILP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    options = optimoptions('intlinprog','Display','off');
    
    [xOpt, fVal, exitFlag, output] = intlinprog( ...
        objCoeffs, intCon, A, b, [], [], lowerBounds, upperBounds, options);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Check Exit Flag %%%%%%%%%%%%%%%%%%%%%%%%%
    if exitFlag ~= 1
        fprintf('Warning: intlinprog did not report full optimality.\n');
        disp(output);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Optimal utility (fVal = min f^T x = -max utility^T x):
    totalUtility = -fVal;
    
    % Total cost in thousands:
    totalCostK = pricesK' * xOpt;
    
    % Total cost in dollars:
    totalCostDollars = 1000 * totalCostK;
    
    % Option names:
    optionNames = {
        'Extra Bedroom'
        'Upgraded Kitchen'
        'Hardwood Floors'
        'Sunroom'
        'Finished Basement'
        'Front Porch'
        'Deck'
        'Three-car Garage'
        'Pool'
    };
    
    fprintf('==================== Optimal Solution for Problem 1 ====================\n');
    fprintf('Total Cost:    $%g\n', totalCostDollars);
    fprintf('Total Utility: %g\n', totalUtility);
    
    % Print each x_i:
    fprintf('\nDecision Variables (x_i):\n');
    for i = 1:numVars
        fprintf('  x_%d = %d  (%s)\n', i, round(xOpt(i)), optionNames{i});
    end
    
    fprintf('\nSelected Options To Maximize Utility:\n');
    for i = 1:numVars
        if round(xOpt(i)) == 1
            fprintf('  * %s\n', optionNames{i});
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint Check %%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('\nCheck Constraints:\n');
    
    % Budget:
    lhsBudget = pricesK' * xOpt;
    if lhsBudget <= budgetK
        statusBudget = '[Satisfied]';
    else
        statusBudget = '[Not Satisfied]';
    end
    fprintf('  * Budget Constraint: Cost = %g <= %g  \n    %s\n', ...
        lhsBudget, budgetK, statusBudget);
    
    % Sunroom + Deck:
    lhsSunDeck = xOpt(4) + xOpt(7);
    if lhsSunDeck <= 1
        statusSunDeck = '[Satisfied]';
    else
        statusSunDeck = '[Not Satisfied]';
    end
    fprintf('  * Sunroom & Deck Constraint: x4 + x7 = %g <= 1  \n    %s\n', ...
        lhsSunDeck, statusSunDeck);
    
    % Sunroom + Kitchen:
    lhsSunKitchen = xOpt(4) + xOpt(2);
    if lhsSunKitchen <= 1
        statusSunKitchen = '[Satisfied]';
    else
        statusSunKitchen = '[Not Satisfied]';
    end
    fprintf('  * Sunroom & Kitchen Constraint: x4 + x2 = %g <= 1  \n    %s\n', ...
        lhsSunKitchen, statusSunKitchen);
    
    % Garage + Porch:
    lhsGaragePorch = xOpt(8) + xOpt(6);
    if lhsGaragePorch <= 1
        statusGaragePorch = '[Satisfied]';
    else
        statusGaragePorch = '[Not Satisfied]';
    end
    fprintf('  * Garage & Porch Constraint: x8 + x6 = %g <= 1  \n    %s\n', ...
        lhsGaragePorch, statusGaragePorch);
    
    % Deck + Pool:
    lhsDeckPool = xOpt(7) + xOpt(9);
    if lhsDeckPool <= 1
        statusDeckPool = '[Satisfied]';
    else
        statusDeckPool = '[Not Satisfied]';
    end
    fprintf('  * Deck & Pool Constraint: x7 + x9 = %g <= 1  \n    %s\n', ...
        lhsDeckPool, statusDeckPool);
    
    % Bedroom + Basement Conditional Logic:
    lhsBedroomBasement = xOpt(1) - xOpt(5);
    if lhsBedroomBasement <= 0
        statusBedroomBasement = '[Satisfied]';
    else
        statusBedroomBasement = '[Not Satisfied]';
    end
    fprintf('  * Bedroom & Basement Conditional Logic Constraint: x1 - x5 = %g <= 0  \n    %s\n', ...
        lhsBedroomBasement, statusBedroomBasement);
    fprintf('========================================================================\n');
end