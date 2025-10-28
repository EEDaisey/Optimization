%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   27th of October, 2025
%     Title:   Assignment Problem (Question 2, Parts a, b, c)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    SUMMARY    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Workers (row indices):
%   1  Annie
%   2  Blake
%   3  Carl
%   4  Devon
%   5  Eric
%   6  Fiona
%   7  Greg
%
% Jobs (column indices):
%   1  WashingMachine
%   2  Dishwasher
%   3  AC
%   4  Toilet
%   5  Fridge
%   6  Stove
%   7  Idle        (dummy job so that numJobs = numWorkers)
%
% Decision Variable:
%   x(i,j) = 1 if worker i is assigned to job j, and 0 otherwise.
%
% Model:
%   Minimize
%       sum_{i=1..7} sum_{j=1..7} costMat(i,j) * x(i,j)
%
%   Subject to:
%     For each worker i:
%         sum_{j=1..7} x(i,j) = 1
%         (each worker is assigned to exactly one job)
%
%     For each job j:
%         sum_{i=1..7} x(i,j) = 1
%         (each job - including Idle - has exactly one worker)
%
%     x(i,j) is binary (0 or 1).
%
% Construction of costMat:
%   - Take the given dollar costs.
%   - If a worker cannot do a job (table shows "not allowed"), assign
%     a very large penalty cost BigM = 1e6.
%   - Idle job has cost 0 for every worker.
%
% Implementation notes:
%   - We solve an integer linear program using intlinprog.
%   - The decision vector stacks x(i,j) row-by-row into one column vector.
%
% Reproducibility:
%   1. Save this file as SolveFinAssignment.m
%   2. In MATLAB, run:
%          SolveFinAssignment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolveFinAssignment()

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    workerNames = { ...
        'Annie', ...
        'Blake', ...
        'Carl', ...
        'Devon', ...
        'Eric', ...
        'Fiona', ...
        'Greg' ...
    };

    jobNames = { ...
        'WashingMachine', ...
        'Dishwasher', ...
        'AC', ...
        'Toilet', ...
        'Fridge', ...
        'Stove', ...
        'Idle' ...
    };

    % BigM cost for infeasible worker-job assignments
    bigM = 1e6;

    % Cost matrix: rows = workers, cols = jobs.
    % Column order: [WashingMachine Dishwasher AC Toilet Fridge Stove Idle]
    %
    % Annie: [40  40  250   NA   125    80   0]
    % Blake: [50  55  285   95   150   135   0]
    % Carl : [35  40   NA   NA    NA    NA   0]
    % Devon: [20  65  190   85   110    90   0]
    % Eric : [25  35  210   45   170   135   0]
    % Fiona: [45  25  170   85   140   125   0]
    % Greg : [50  40   NA   NA   125   115   0]
    %
    % Replace NA ("cannot do this job") with bigM.
    costMat = [ ...
        40    40    250   bigM  125   80    0 ;  % Annie
        50    55    285   95    150   135   0 ;  % Blake
        35    40    bigM  bigM  bigM  bigM  0 ;  % Carl
        20    65    190   85    110   90    0 ;  % Devon
        25    35    210   45    170   135   0 ;  % Eric
        45    25    170   85    140   125   0 ;  % Fiona
        50    40    bigM  bigM  125   115   0 ]; % Greg

    numWorkers = size(costMat,1);   % should be 7
    numJobs    = size(costMat,2);   % should be 7
    numVars    = numWorkers * numJobs;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Decision vector xVec stacks x(i,j) row-by-row:
    %
    %   x(1,1) x(1,2) ... x(1,7) x(2,1) ... x(7,7)
    %
    % The objective vector f matches that same ordering so that
    % f' * xVec = total assignment cost.
    %
    f = reshape(costMat.', [], 1);  % column vector of length numVars

    %%%%%%%%%%%%%%%%%%%%%%%% EQUALITY CONSTRAINTS %%%%%%%%%%%%%%%%%%%%%%%%
    % 1) Worker assignment constraints:
    %    For each worker i: sum_j x(i,j) = 1
    %
    aEqWorkers = zeros(numWorkers, numVars);
    for i = 1:numWorkers
        colsForI = (i-1)*numJobs + (1:numJobs);
        aEqWorkers(i, colsForI) = 1;
    end
    bEqWorkers = ones(numWorkers,1);

    % 2) Job coverage constraints:
    %    For each job j: sum_i x(i,j) = 1
    %
    aEqJobs = zeros(numJobs, numVars);
    for j = 1:numJobs
        for i = 1:numWorkers
            varIndex = (i-1)*numJobs + j;
            aEqJobs(j, varIndex) = 1;
        end
    end
    bEqJobs = ones(numJobs,1);

    % Stack the equalities into Aeq * xVec = beq
    aEq = [aEqWorkers;
           aEqJobs];

    bEq = [bEqWorkers;
           bEqJobs];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% BOUNDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % x(i,j) is binary, so:
    %   0 <= x(i,j) <= 1
    %
    lb = zeros(numVars,1);
    ub = ones(numVars,1);

    % Integer index set for intlinprog
    intcon = 1:numVars;

    %%%%%%%%%%%%%%%%%%%%%%%%% SOLVE INTEGER LP %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We solve:
    %   minimize f' * xVec
    %   subject to
    %       aEq * xVec = bEq
    %       lb <= xVec <= ub
    %       xVec(i) integer (binary)
    %
    opts = optimoptions('intlinprog','Display','none');

    [xOpt, fVal] = intlinprog(f, intcon, [], [], aEq, bEq, lb, ub, opts);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% REPORT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Convert xOpt (which is numeric approx) to a clean 0/1 assignment.
    xRounded = xOpt;
    xRounded(xRounded < 0.5)  = 0;
    xRounded(xRounded >= 0.5) = 1;

    % Reshape into worker-by-job matrix.
    % assignMat(i,j) = 1 means worker i is assigned to job j.
    assignMat = reshape(xRounded, numJobs, numWorkers).';
    assignMat(assignMat < 0.5)  = 0;
    assignMat(assignMat >= 0.5) = 1;

    fprintf('================ ASSIGNMENT REPORT ================\n\n');

    % Print assignment matrix (1 = assigned, 0 = not assigned)
    fprintf('Assignment Matrix (1 = assigned, 0 = not assigned):\n');
    fprintf('              ');
    for j = 1:numJobs
        fprintf('%15s', jobNames{j});
    end
    fprintf('\n');
    for i = 1:numWorkers
        fprintf('%12s', workerNames{i});
        for j = 1:numJobs
            fprintf('%15.0f', assignMat(i,j));
        end
        fprintf('\n');
    end
    fprintf('\n');

    % For each worker, print assigned job and its cost
    fprintf('Worker-to-Job Assignments:\n');
    totalCheck = 0;
    for i = 1:numWorkers
        jAssigned  = find(assignMat(i,:) == 1);
        jobName    = jobNames{jAssigned};
        jobCost    = costMat(i,jAssigned);
        totalCheck = totalCheck + jobCost;
        fprintf('  %-12s -> %-15s  Cost = $%g\n', ...
            workerNames{i}, jobName, jobCost);
    end
    fprintf('\n');

    % Show the solver objective and manual recompute for verification
    fprintf('Total Cost from Solver = $%g\n', fVal);
    fprintf('Recomputed Total Cost  = $%g\n', totalCheck);
    fprintf('\n===================================================\n\n');

end