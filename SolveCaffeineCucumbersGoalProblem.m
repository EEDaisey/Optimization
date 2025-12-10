%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   9 December 2025
%     Title:   Question 4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolveCaffeineCucumbersGoalProblem()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Problem Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Cost matrix c_ij (kiosks in columns, plants in rows):
    %       K1   K2   K3   K4
    % P1    $8   $7   $5  $13
    % P2   $14  $14  $13   $3
    % P3   $10   $4  $13   $8
    costMatrix = [ ...
         8   7   5  13; ...
        14  14  13   3; ...
        10   4  13   8];

    % Plant supplies (packages):
    supplyVector = [100; 120; 80];

    % Kiosk demands (packages):
    demandVector = [100; 75; 150; 175];

    % Targets for 80% service goals:
    targetService = 0.8 * demandVector;  % [80; 60; 120; 140]

    % Cost goal:
    targetCost = 3200;

    numPlants  = size(costMatrix, 1); % 3
    numKiosks  = size(costMatrix, 2); % 4
    numGoals   = 5;

    % Number of shipment variables x_ij:
    numShipVars = numPlants * numKiosks; % 12

    % For goals we use U_k, E_k, k = 1..5:
    numU = numGoals;
    numE = numGoals;

    totalVars = numShipVars + numU + numE;

    % Indices in the decision vector:
    % x(1:numShipVars)      : shipment variables x_ij
    % x(uStart:uStart+4)    : U_1,...,U_5
    % x(eStart:eStart+4)    : E_1,...,E_5
    uStart = numShipVars + 1;
    eStart = uStart + numU;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Objective %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Nonpreemptive goal programming objective:
    %   Minimize Z = E1 + 4 U2 + 2 U3 + 2 U4 + 2 U5
    %
    % The decision vector is:
    %   [x_11, x_12, ..., x_34, U1...U5, E1...E5]^T

    objCoeffs = zeros(totalVars, 1);

    % Weights: w1 = 1, w2 = 4, w3 = 2, w4 = 2, w5 = 2
    % Detrimental deviations: E1 (over budget), U2...U5 (shortfalls).
    objCoeffs(eStart + 0) = 1;  % E1 has weight 1

    objCoeffs(uStart + 1) = 4;  % U2 has weight 4
    objCoeffs(uStart + 2) = 2;  % U3 has weight 2
    objCoeffs(uStart + 3) = 2;  % U4 has weight 2
    objCoeffs(uStart + 4) = 2;  % U5 has weight 2

    %%%%%%%%%%%%%%%%%%%%%%%%% Goal Equalities (Aeq, beq) %%%%%%%%%%%%%%%%%%
    % We impose the 5 goal equations in Aeq * x = beq form.

    % There are 5 goal equations:
    numGoalEqs = 5;
    Aeq = zeros(numGoalEqs, totalVars);
    beq = zeros(numGoalEqs, 1);

    % Helper to index x_ij in the shipment block:
    % index(i,j) = (i-1)*numKiosks + j, 1-based for Matlab.
    indexX = @(i, j) (i - 1) * numKiosks + j;

    row = 1;

    % Goal 1: total cost + U1 - E1 = targetCost
    for i = 1:numPlants
        for j = 1:numKiosks
            Aeq(row, indexX(i, j)) = costMatrix(i, j);
        end
    end
    Aeq(row, uStart + 0) = 1;   % +U1
    Aeq(row, eStart + 0) = -1;  % -E1
    beq(row) = targetCost;
    row = row + 1;

    % Goals 2-5: service for kiosks
    % Goal 2: y1 + U2 - E2 = 80
    % Goal 3: y2 + U3 - E3 = 60
    % Goal 4: y3 + U4 - E4 = 120
    % Goal 5: y4 + U5 - E5 = 140
    for j = 1:numKiosks
        % Sum_i x_ij
        for i = 1:numPlants
            Aeq(row, indexX(i, j)) = 1;
        end

        % U_{j+1} - E_{j+1}
        % Goal 2 corresponds to U2,E2, etc.
        Aeq(row, uStart + j) = 1;    % +U_{j+1}
        Aeq(row, eStart + j) = -1;   % -E_{j+1}

        beq(row) = targetService(j);
        row = row + 1;
    end

    %%%%%%%%%%%%%%%%%%%%% System Inequalities (A, b) %%%%%%%%%%%%%%%%%%%%%%
    % 1) Plant Capacity: sum_j x_ij <= S_i
    % 2) Kiosk Caps:     sum_i x_ij <= D_j

    numIneq = numPlants + numKiosks;
    A = zeros(numIneq, totalVars);
    b = zeros(numIneq, 1);

    row = 1;

    % Plant supplies:
    for i = 1:numPlants
        for j = 1:numKiosks
            A(row, indexX(i, j)) = 1;
        end
        b(row) = supplyVector(i);
        row = row + 1;
    end

    % Kiosk demand caps:
    for j = 1:numKiosks
        for i = 1:numPlants
            A(row, indexX(i, j)) = 1;
        end
        b(row) = demandVector(j);
        row = row + 1;
    end

    %%%%%%%%%%%%%%%%%%%%%% Bounds and Integrality %%%%%%%%%%%%%%%%%%%%%%%%%
    lowerBounds = zeros(totalVars, 1);
    upperBounds = Inf(totalVars, 1);

    % Shipment variables x_ij are integer, deviations U,E are continuous:
    intCon = 1:numShipVars;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solve Model %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    options = optimoptions('intlinprog', 'Display', 'off');

    [xOpt, fVal, exitFlag, output] = intlinprog( ...
        objCoeffs, intCon, A, b, Aeq, beq, lowerBounds, upperBounds, options);

    if exitFlag ~= 1
        fprintf('Warning: intlinprog did not report full optimality.\n');
        disp(output);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('======================= Optimal Solution for Problem 4 ===================\n');
    fprintf('Minimum Z = %g\n', fVal);

    % Extract shipments:
    shipMatrix = reshape(xOpt(1:numShipVars), [numKiosks, numPlants])';
    % shipMatrix(i,j) = packages from Plant i to Kiosk j

    % Extract deviations:
    uVals = xOpt(uStart:uStart+numU-1);
    eVals = xOpt(eStart:eStart+numE-1);

    % Compute kiosk totals and cost:
    kioskTotals = sum(shipMatrix, 1)';   % 4x1
    plantTotals = sum(shipMatrix, 2);    % 3x1
    totalCost   = sum(sum(costMatrix .* shipMatrix));

    fprintf('\nShipment Plan (Packages Shipped From Each Plant To Each Kiosk):\n');
    fprintf('           K1      K2      K3      K4      (Row Sum)\n');
    for i = 1:numPlants
        fprintf('Plant %d:', i);
        for j = 1:numKiosks
            fprintf(' %7.2f', shipMatrix(i, j));
        end
        fprintf(' | %7.2f\n', plantTotals(i));
    end

    fprintf('\nKiosk Totals (y_j):\n');
    for j = 1:numKiosks
        fprintf('  Kiosk %d: %7.2f  (Demand = %g)\n', ...
            j, kioskTotals(j), demandVector(j));
    end

    fprintf('\nTotal Shipping Cost: $%g\n', totalCost);
    fprintf('Cost Goal Target:    $%g\n', targetCost);

    fprintf('\nGoal Deviations (U_k = Shortfall, E_k = Excess):\n');
    for k = 1:numGoals
        fprintf('  Goal %d: U_%d = %7.2f, E_%d = %7.2f\n', ...
            k, k, uVals(k), k, eVals(k));
    end

    fprintf('\nInterpretation of Goals:\n');
    fprintf('  Goal 1 (Cost <= 3200):     Penalize Over Budget E1 Only.\n');
    fprintf('  Goals 2-5 (>= 80%% Demand): Penalize Shortfalls U2...U5.\n');
    fprintf('==========================================================================\n');
end
