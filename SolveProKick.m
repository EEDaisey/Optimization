%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   27th of October, 2025
%     Title:   Transportation Problem (Question 1, Parts b, c, d)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    SUMMARY    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Decision Variables:
%
%   For each factory F in {A,B,C} (part b) or {A,B,C,D} (parts c,d)
%   and each store S in {CA,AZ,NM,TX}, define:
%
%       x(F,S) = number of soccer balls shipped from factory F
%                to store S.
%
% Variable Stacking Convention in the Solver:
%
%   We order flows factory-by-factory. For example, in part (b)
%   with factories A,B,C, the decision vector is:
%
%       [ AtoCA AtoAZ AtoNM AtoTX ...
%         BtoCA BtoAZ BtoNM BtoTX ...
%         CtoCA CtoAZ CtoNM CtoTX ]'
%
%   In parts (c) and (d), we include factory D at the end:
%
%       [ AtoCA AtoAZ AtoNM AtoTX ...
%         BtoCA BtoAZ BtoNM BtoTX ...
%         CtoCA CtoAZ CtoNM CtoTX ...
%         DtoCA DtoAZ DtoNM DtoTX ]'
%
% Store Demands (must be fully satisfied for each destination S):
%
%   CA (California)
%   AZ (Arizona)
%   NM (New Mexico)
%   TX (Texas)
%
%   For each store S:
%       sum over factories F of x(F,S) = demand(S)
%
% Factory Capacities (outbound limit for each origin F):
%
%   A, B, C in part (b)
%   A, B, C, D in parts (c) and (d)
%
%   For each factory F:
%       sum over stores S of x(F,S) <= capacity(F)
%
% Objective:
%
% Part (b):
%   Use factories A,B,C only.
%   Minimize total shipping cost.
%
% Part (c):
%   Use factories A,B,C,D.
%   Minimize total shipping cost.
%   (Factory D becomes available. Structure of constraints is the
%    same as part (b), but with an additional factory.)
%
% Part (d):
%   Use factories A,B,C,D.
%   Minimize total (production cost + shipping cost).
%   That is: for each unit shipped, cost = production cost at the
%   factory that made it + the shipping cost to its assigned store.
%
% Model Form:
%
%   Minimize   sum_F sum_S [ unitCost(F,S) * x(F,S) ]
%
%   Subject to
%       (1) For each store S:
%               sum_F x(F,S) = demand(S)
%           (meet every store's demand exactly)
%
%       (2) For each factory F:
%               sum_S x(F,S) <= capacity(F)
%           (do not exceed available supply at any factory)
%
%       (3) x(F,S) >= 0 for all F,S
%
% Implementation Notes:
%
%   - We solve three LPs:
%       Part (b):  factories A,B,C with shipping cost only.
%       Part (c):  factories A,B,C,D with shipping cost only.
%       Part (d):  factories A,B,C,D with (production + shipping) cost.
%
%   - Each LP is solved using linprog.
%
% Reproducibility Steps:
%   1. Save this file as SolveProKick.m
%   2. In MATLAB, run:
%          SolveProKick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolveProKick()

    % ---------------------------------------------------------------------
    % Core problem data (shared across parts (b), (c), and (d)).
    % ---------------------------------------------------------------------

    % Store names (for reporting).
    storeNames = {'CA','AZ','NM','TX'};

    % Factory names for each case.
    factoryNamesABC  = {'A','B','C'};
    factoryNamesABCD = {'A','B','C','D'};

    % Demand at each store: [CA; AZ; NM; TX].
    demandVec = [5000; 4000; 1000; 2000];

    % Factory capacities.
    % A = 4000, B = 7000, C = 3000, D = 3000.
    capacityABC  = [4000; 7000; 3000];        % factories A,B,C
    capacityABCD = [4000; 7000; 3000; 3000];  % factories A,B,C,D

    % Shipping cost matrix (dollars per unit shipped).
    % Rows correspond to factories A,B,C,D.
    % Columns correspond to stores CA,AZ,NM,TX.
    %
    % shipCostMatABCD(i,j) = cost to ship one unit
    % from factory i to store j.
    shipCostMatABCD = [ 0.83  0.59  0.77  0.78 ; ...
                        0.78  0.50  0.93  0.67 ; ...
                        0.73  0.93  0.78  0.58 ; ...
                        0.81  0.76  0.54  0.58 ];

    % Production cost per unit at each factory (dollars per unit).
    % prodCostABCD(i) = cost to make one unit at factory i.
    % i = A,B,C,D.
    prodCostABCD = [3.59; 2.85; 4.76; 4.52];

    % =====================================================================
    % Part (b): Factories A,B,C only. Objective = shipping cost only.
    % =====================================================================

    % Extract shipping cost rows for factories A,B,C.
    shipCostMatB = shipCostMatABCD(1:3, :);    % 3 x 4

    % Build the cost vector for part (b) in the required order:
    % [AtoCA AtoAZ AtoNM AtoTX  BtoCA ... CtoTX]'
    costVecB = BuildCostVector(shipCostMatB);

    % Solve the LP for part (b).
    [xB, zB] = SolveTransportation(costVecB, demandVec, capacityABC);

    % Report solution for part (b).
    fprintf('\n================ PART (b) ================\n');
    fprintf('Factories used: A, B, C.\n');
    fprintf('Objective: Minimize total shipping cost.\n\n');
    ReportSolution( ...
        xB, zB, demandVec, capacityABC, ...
        factoryNamesABC, storeNames, ...
        'Part (b) Results');


    % =====================================================================
    % Part (c): Factories A,B,C,D. Objective = shipping cost only.
    % =====================================================================

    shipCostMatC = shipCostMatABCD(1:4, :);    % 4 x 4

    % Build the cost vector for part (c):
    % [A-block, then B-block, then C-block, then D-block].
    costVecC = BuildCostVector(shipCostMatC);

    % Solve the LP for part (c).
    [xC, zC] = SolveTransportation(costVecC, demandVec, capacityABCD);

    % Report solution for part (c).
    fprintf('\n================ PART (c) ================\n');
    fprintf('Factories used: A, B, C, D.\n');
    fprintf('Objective: Minimize total shipping cost.\n');
    fprintf('Factory D is now available.\n\n');
    ReportSolution( ...
        xC, zC, demandVec, capacityABCD, ...
        factoryNamesABCD, storeNames, ...
        'Part (c) Results');


    % =====================================================================
    % Part (d): Factories A,B,C,D.
    % Objective = production cost + shipping cost.
    % =====================================================================

    % Compute total cost per shipped unit:
    % totalCostMatD(i,j) = prodCostABCD(i) + shipCostMatABCD(i,j).
    totalCostMatD = shipCostMatABCD(1:4,:) + repmat(prodCostABCD(1:4),1,4);

    % Build the combined production+shipping cost vector
    % using the same ordering convention.
    costVecD = BuildCostVector(totalCostMatD);

    % Solve the LP for part (d).
    [xD, zD] = SolveTransportation(costVecD, demandVec, capacityABCD);

    % Report solution for part (d).
    fprintf('\n================ PART (d) ================\n');
    fprintf('Factories used: A, B, C, D.\n');
    fprintf('Objective: Minimize total (production + shipping) cost.\n');
    fprintf('High production cost factories may shut down.\n\n');
    ReportSolution( ...
        xD, zD, demandVec, capacityABCD, ...
        factoryNamesABCD, storeNames, ...
        'Part (d) Results');

    fprintf('\n======================================\n\n');


    % =====================================================================
    % BuildCostVector
    %
    % Purpose:
    %   Convert a cost matrix (numFactories x numStores) into a single
    %   column cost vector in "factory block" order.
    %
    %   If costMat = [rowA ; rowB ; rowC ; rowD],
    %   then costVec = [rowA  rowB  rowC  rowD] stacked vertically.
    %
    % Inputs:
    %   costMat    Matrix of size (numFactories x numStores).
    %
    % Output:
    %   costVec    Column vector of length (numFactories * numStores),
    %              ordered by factory A block, then B block, etc.
    % =====================================================================
    function costVec = BuildCostVector(costMat)
        % costMat.' is (numStores x numFactories).
        % reshape(costMat.',[],1) grabs factory A row across stores first,
        % then factory B row across stores, etc.
        costVec = reshape(costMat.', [], 1);
    end


    % =====================================================================
    % SolveTransportation
    %
    % Purpose:
    %   Build and solve the linear program
    %
    %       Minimize    costVec' * x
    %
    %       Subject to:
    %         1. For each store j:
    %               sum over factories i of x(i,j) = demand(j)
    %         2. For each factory i:
    %               sum over stores j of x(i,j) <= capacity(i)
    %         3. x >= 0
    %
    % Decision Variable Layout:
    %   x = [
    %         Factory1toStore1 ... Factory1toStoreS ...
    %         Factory2toStore1 ... Factory2toStoreS ...
    %         ...
    %         FactoryMtoStore1 ... FactoryMtoStoreS
    %       ]'
    %
    % Inputs:
    %   costVec         Column vector of per-unit costs (length M*S)
    %   demandVecLocal  Column vector of store demands (length S)
    %   capacityVec     Column vector of factory capacities (length M)
    %
    % Outputs:
    %   xSol            Optimal shipment plan (vector)
    %   zVal            Minimum total cost
    % =====================================================================
    function [xSol, zVal] = SolveTransportation(costVec, demandVecLocal, capacityVec)

        numStores    = length(demandVecLocal);   % number of stores
        numFactories = length(capacityVec);      % number of factories

        % Demand constraints: AeqLocal * x = bEqLocal.
        % For each store j, incoming shipments from all factories
        % must meet that store's demand exactly.
        aEqLocal = zeros(numStores, numFactories * numStores);
        for j = 1:numStores
            for i = 1:numFactories
                varIndex = (i-1)*numStores + j;
                aEqLocal(j, varIndex) = 1;
            end
        end
        bEqLocal = demandVecLocal(:);

        % Capacity constraints: aMat * x <= bVecLocal.
        % For each factory i, total outbound shipments cannot exceed
        % available capacity at that factory.
        aMat = zeros(numFactories, numFactories * numStores);
        for i = 1:numFactories
            colsForFactoryI = (i-1)*numStores + (1:numStores);
            aMat(i, colsForFactoryI) = 1;
        end
        bVecLocal = capacityVec(:);

        % Lower bounds: x >= 0.
        lbLocal = zeros(numFactories * numStores, 1);
        ubLocal = [];   % no explicit upper bounds beyond capacity

        solverOptions = optimoptions('linprog','Display','none');

        [xSol, zVal] = linprog( ...
            costVec, ...
            aMat, bVecLocal, ...
            aEqLocal, bEqLocal, ...
            lbLocal, ubLocal, [], solverOptions);

        % Clean tiny numerical noise.
        xSol(abs(xSol) < 1e-9) = 0;
    end


    % =====================================================================
    % ReportSolution
    %
    % Purpose:
    %   Display the optimal shipment plan, including:
    %     - Full shipment matrix (all factories x all stores)
    %     - Each route's shipped amount
    %     - Total objective cost
    %     - Capacity usage per factory
    %     - Demand satisfaction per store
    %
    % Inputs:
    %   xSol                Optimal shipment vector from SolveTransportation
    %   zVal                Objective value (total cost)
    %   demandVecLocal      Demand at each store
    %   capacityVec         Capacity available at each factory
    %   factoryNamesLocal   Cell array of factory labels
    %   storeNamesLocal     Cell array of store labels
    %   headerString        Title printed above this report block
    % =====================================================================
    function ReportSolution( ...
        xSol, zVal, demandVecLocal, capacityVec, ...
        factoryNamesLocal, storeNamesLocal, headerString)

        fprintf('%s\n\n', headerString);

        numStores    = length(storeNamesLocal);
        numFactories = length(factoryNamesLocal);

        % Reshape xSol into (numFactories x numStores).
        % Row i = shipments from factory i to each of the stores
        % in order [CA AZ NM TX].
        flowMat = reshape(xSol, numStores, numFactories).';

        % Suppress tiny noise.
        tolPrint = 1e-6;
        flowMat(abs(flowMat) < tolPrint) = 0;

        % Print table of shipments (factories as rows, stores as columns).
        fprintf('Optimal shipment plan (units shipped):\n');
        fprintf('            ');
        for j = 1:numStores
            fprintf('%8s', storeNamesLocal{j});
        end
        fprintf('\n');
        for i = 1:numFactories
            fprintf('  Factory %s', factoryNamesLocal{i});
            for j = 1:numStores
                fprintf('%8.0f', flowMat(i,j));
            end
            fprintf('\n');
        end
        fprintf('\n');

        % Print per-route breakdown.
        fprintf('Route breakdown:\n');
        for i = 1:numFactories
            for j = 1:numStores
                fprintf('  %s->%s : %6.0f\n', ...
                    factoryNamesLocal{i}, storeNamesLocal{j}, flowMat(i,j));
            end
        end
        fprintf('\n');

        % Total cost for this scenario.
        fprintf('Objective value:\n');
        fprintf('  Total cost = $%0.0f\n', zVal);

        % Capacity usage.
        factoryTotals = sum(flowMat,2);
        fprintf('\nFactory capacity check:\n');
        for i = 1:numFactories
            fprintf('  %s ships %g (cap %g)\n', ...
                factoryNamesLocal{i}, factoryTotals(i), capacityVec(i));
        end

        % Demand satisfaction.
        storeTotals = sum(flowMat,1);
        fprintf('\nStore demand check:\n');
        for j = 1:numStores
            fprintf('  %s gets %g (need %g)\n', ...
                storeNamesLocal{j}, storeTotals(j), demandVecLocal(j));
        end
        fprintf('\n');
    end
end

