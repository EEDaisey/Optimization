%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   9 December 2025
%     Title:   Question 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolvePowerPicklesNetwork()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Problem Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Cost matrix (c_ij) and capacity matrix (u_ij) taken directly from the
    % provided CSVs. NaN = no arc is between nodes i and j.

    costMatrix = [
      NaN NaN NaN 9 6 3 5 NaN NaN NaN NaN;
      NaN NaN NaN 2 1 7 1 NaN NaN NaN NaN;
      NaN NaN NaN 10 6 2 9 NaN NaN NaN NaN;
      9 2 10 NaN 9 4 3 1 2 4 3;
      6 1 6 9 NaN 4 8 3 10 10 2;
      3 7 2 4 4 NaN 1 9 7 7 4;
      5 1 9 3 8 1 NaN 10 2 6 2;
      NaN NaN NaN 1 3 9 10 NaN NaN NaN NaN;
      NaN NaN NaN 2 10 7 2 NaN NaN NaN NaN;
      NaN NaN NaN 4 10 7 6 NaN NaN NaN NaN;
      NaN NaN NaN 3 2 4 2 NaN NaN NaN NaN
    ];

    capacityMatrix = [
      NaN NaN NaN 31 29 36 29 NaN NaN NaN NaN;
      NaN NaN NaN 32 38 27 45 NaN NaN NaN NaN;
      NaN NaN NaN 26 34 29 32 NaN NaN NaN NaN;
      29 29 39 NaN 42 44 26 39 31 37 25;
      27 40 34 44 NaN 37 27 38 27 26 26;
      25 25 30 36 31 NaN 42 43 26 42 38;
      29 44 41 27 45 27 NaN 27 44 42 43;
      NaN NaN NaN 41 41 25 37 NaN NaN NaN NaN;
      NaN NaN NaN 27 44 27 43 NaN NaN NaN NaN;
      NaN NaN NaN 42 25 38 31 NaN NaN NaN NaN;
      NaN NaN NaN 31 38 42 38 NaN NaN NaN NaN
    ];

    [numNodes, numColsCosts] = size(costMatrix);
    [numNodesCap, numColsCaps] = size(capacityMatrix);

    if numNodes ~= numNodesCap || numColsCosts ~= numColsCaps
        error('Cost and capacity matrices need to have the same size.');
    end

    % Net supplies b_i (negative = demand, 0 = transshipment, positive = supply)
    netSupply = [ ...
         100;   % Node 1 (Plant)
         120;   % Node 2 (Plant)
          80;   % Node 3 (Plant)
           0;   % Node 4 (Transshipment)
           0;   % Node 5 (Transshipment)
           0;   % Node 6 (Transshipment)
           0;   % Node 7 (Transshipment)
         -75;   % Node 8 (Store)
         -95;   % Node 9 (Store)
         -50;   % Node 10 (Store)
         -80];  % Node 11 (Store)

    if length(netSupply) ~= numNodes
        error('netSupply length (%d) must match number of nodes (%d).', ...
            length(netSupply), numNodes);
    end

    %%%%%%%%%%%%%%%%%%%%%%%% Build Arc List & LP Data %%%%%%%%%%%%%%%%%%%%%
    % We define arcs:
    arcMask = (~isnan(capacityMatrix)) & (capacityMatrix > 0);
    [fromNodes, toNodes] = find(arcMask);
    numArcs = length(fromNodes);

    if numArcs == 0
        error('No arcs found with positive capacity.');
    end

    % Cost and capacity vectors for each arc k:
    costVector     = zeros(numArcs, 1);
    capacityVector = zeros(numArcs, 1);
    for k = 1:numArcs
        i = fromNodes(k);
        j = toNodes(k);
        costVector(k)     = costMatrix(i, j);
        capacityVector(k) = capacityMatrix(i, j);
    end

    % Bounds: 0 <= x_ij <= capacity_ij:
    lowerBounds = zeros(numArcs, 1);
    upperBounds = capacityVector;

    %%%%%%%%%%%%%%%%%%%%%%%%%% Flow Balance (Aeq, beq) %%%%%%%%%%%%%%%%%%%%
    % For each node i:
    %   sum_j x_ij - sum_k x_ki = netSupply(i)
    %
    % Aeq is numNodes x numArcs.
    % For arc k with fromNodes(k) = i, toNodes(k) = j:
    %   Aeq(i, k) = +1  (outflow from i)
    %   Aeq(j, k) = -1  (inflow into j)

    Aeq = zeros(numNodes, numArcs);
    for k = 1:numArcs
        i = fromNodes(k);
        j = toNodes(k);
        Aeq(i, k) = Aeq(i, k) + 1;
        Aeq(j, k) = Aeq(j, k) - 1;
    end
    beq = netSupply;

    % No additional inequality constraints besides bounds:
    A = [];
    b = [];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solve with linprog %%%%%%%%%%%%%%%%%%%%%%
    % Matlab 2015 linprog syntax:
    %   [x,fval,exitflag,output] = linprog(f,A,b,Aeq,beq,lb,ub,x0,options)
    % We do NOT provide an initial point x0, so we pass [] for that variable.

    options = optimoptions('linprog', 'Display', 'off');

    [arcFlows, fVal, exitFlag, output] = linprog( ...
        costVector, A, b, Aeq, beq, lowerBounds, upperBounds, [], options);

    if exitFlag ~= 1
        fprintf('Warning: linprog did not report full optimality.\n');
        disp(output);
    end

    totalCost = fVal;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('======================= Optimal Solution for Problem 3 ======================\n');
    fprintf('Minimum Total Shipping Cost: %g\n\n', totalCost);

    % Build a full flow matrix for readability:
    flowMatrix = zeros(numNodes, numColsCosts);
    for k = 1:numArcs
        i = fromNodes(k);
        j = toNodes(k);
        flowMatrix(i, j) = arcFlows(k);
    end

    % Print nonzero flows:
    tol = 1e-6;
    fprintf('Nonzero Flows x_ij (i -> j, in packages):\n');
    for k = 1:numArcs
        if arcFlows(k) > tol
            i = fromNodes(k);
            j = toNodes(k);
            fprintf('  %2d -> %2d : %7.2f  (Cost per Unit = %g)\n', ...
                i, j, arcFlows(k), costVector(k));
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Node Balance Check %%%%%%%%%%%%%%%%%%%%%%
    fprintf('\nNode Balance Check (Outflow - Inflow vs netSupply):\n');
    for i = 1:numNodes
        outFlow = sum(flowMatrix(i, :));
        inFlow  = sum(flowMatrix(:, i));
        netFlow = outFlow - inFlow;
        if abs(netFlow - netSupply(i)) < 1e-6
            status = '[Satisfied]';
        else
            status = '[Not Satisfied]';
        end
        fprintf('  Node %2d: netFlow = %8.2f, netSupply = %8.2f  %s\n', ...
            i, netFlow, netSupply(i), status);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Capacity Check %%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('\nCapacity Check for Nonzero Flows (x_ij <= u_ij):\n');
    for k = 1:numArcs
        x = arcFlows(k);
        if x > tol
            i = fromNodes(k);
            j = toNodes(k);
            u = capacityVector(k);
            if x <= u + 1e-6
                status = '[Satisfied]';
            else
                status = '[Not Satisfied]';
            end
            fprintf('  Arc %2d -> %2d: x = %7.2f, u = %7.2f  %s\n', ...
                i, j, x, u, status);
        end
    end
    fprintf('=============================================================================\n');
end


