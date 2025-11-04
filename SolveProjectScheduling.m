%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Edward E. Daisey
% Class: Introduction to Optimization (625.615)
% Professor: Dr. David Schug
% Date: 3rd of November, 2025
% Title: Project Scheduling LP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Summary %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Minimize makespan T for activities 1,2,3,...,15.
% LP:
%   minimize T
%   subject to t_j - t_i >= d_i (for each precedence i->j)
%   T >= t_i + d_i (for all i)
%   t_i >= 0, T >= 0
%
% Output: Early Start / Early Finish (ES/EF) table from a two-pass solve:
% Pass 1: minimize T to get T*.
% Pass 2: fix T = T* and minimize sum(t_i) to obtain earliest starts.
%
% Reproducibility:
% 1. Save as SolveCityFreewayShortestPath.m
% 2. In MATLAB: SolveCityFreewayShortestPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function SolveProjectScheduling()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    numActivities = 15;
    durations = [1 3 1 4 1 1 5 5 4 2 1 4 1 2 1]';
    precedence = [ 1 2; 2 3; 2 4; 3 5; 4 6; 5 6; 4 7; 5 8; 8 9; 6 10; 10 11; ...
                  7 12; 11 12; 12 13; 9 14; 13 14; 14 15 ];
    numArcs = size(precedence,1);
    tIndex  = numActivities + 1;
    numVars = numActivities + 1;   % [t_1..t_15, T]
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%% Constraints %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % (A*x <= b):
    %  (1) t_j - t_i >= d_i  ->  -t_j + t_i <= -d_i
    aMat = zeros(numArcs, numVars); bVec = zeros(numArcs,1);
    for k = 1:numArcs
        i = precedence(k,1); j = precedence(k,2);
        aMat(k,i) =  1; aMat(k,j) = -1; bVec(k) = -durations(i);
    end
    %  (2) T >= t_i + d_i  ->  t_i - T <= -d_i
    aMat2 = zeros(numActivities, numVars); bVec2 = zeros(numActivities,1);
    for i = 1:numActivities
        aMat2(i,i) = 1; aMat2(i,tIndex) = -1; bVec2(i) = -durations(i);
    end
    A = [aMat; aMat2];  b = [bVec; bVec2];
 
    lb = zeros(numVars,1); ub = [];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Pass 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Minimize T to get optimal makespan T*
    objectiveT = zeros(numVars,1); objectiveT(tIndex) = 1;
    x0 = []; options = optimset('Display','off');
    [sol1, optimalT] = linprog(objectiveT, A, b, [], [], lb, ub, x0, options);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Pass 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Fix T = T* and minimize sum(t_i) to get true ES values. Choose the earliest
    % feasible start at that makespan.
    eqA = zeros(1,numVars); eqA(tIndex) = 1; eqb = optimalT;
    objectiveSumT = zeros(numVars,1); objectiveSumT(1:numActivities) = 1;
    [sol2, ~] = linprog(objectiveSumT, A, b, eqA, eqb, lb, ub, x0, options);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tol = 1e-9;
    startTimes = sol2(1:numActivities);
    startTimes(abs(startTimes) < tol) = 0;
    startTimesDisp = round(startTimes,4);
    efDisp = round(startTimes + durations,4);
 
    % Identify a critical path (zero slack arcs):
    isCritical = false(numArcs,1);
    for k = 1:numArcs
        i = precedence(k,1); j = precedence(k,2);
        isCritical(k) = abs(startTimes(j) - (startTimes(i) + durations(i))) <= 1e-8;
    end
    criticalPath = 15; current = 15;
    while true
        preds = precedence(isCritical & precedence(:,2)==current, 1);
        if isempty(preds), break; end
        [~, idx] = max(startTimes(preds));
        current = preds(idx);
        criticalPath = [current criticalPath];
        if isempty(precedence(precedence(:,2)==current,1)), break; end
    end
 
    fprintf('================ PROJECT SCHEDULING ================\n');
    fprintf('Optimal Makespan T* = %g Weeks\n\n', optimalT);
    fprintf('Critical Path: ');
    fprintf('%d', criticalPath(1));
    for k = 2:numel(criticalPath), fprintf(' -> %d', criticalPath(k)); end
    fprintf('\n\n i |    ES      EF\n');
    for i = 1:numActivities
        fprintf('%2d | %7.4f  %7.4f\n', i, startTimesDisp(i), efDisp(i));
    end
    fprintf('\n====================================================\n');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end