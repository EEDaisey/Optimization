%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   27th of October, 2025
%     Title:   Maximum Flow Problem (Question 4)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    SUMMARY    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Network:
%   Source node:
%       1  (supplies flow)
%
%   Sink node:
%       7  (receives flow)
%
%   Transshipment nodes:
%       2, 3, 4, 5, 6  (flow in = flow out)
%
% Directed arcs and capacities (units max):
%   1 -> 2 : 75
%   1 -> 3 : 50
%   2 -> 4 : 25
%   2 -> 5 : 20
%   2 -> 7 : 20
%   3 -> 4 : 25
%   3 -> 5 : 125
%   3 -> 6 : 25
%   4 -> 7 : 20
%   5 -> 4 : 25
%   5 -> 7 : 20
%   6 -> 5 : 15
%   6 -> 7 : 25
%
% Decision variables (all >= 0):
%   x12 = flow from node 1 to node 2
%   x13 = flow from node 1 to node 3
%   x24 = flow from node 2 to node 4
%   x25 = flow from node 2 to node 5
%   x27 = flow from node 2 to node 7
%   x34 = flow from node 3 to node 4
%   x35 = flow from node 3 to node 5
%   x36 = flow from node 3 to node 6
%   x54 = flow from node 5 to node 4
%   x47 = flow from node 4 to node 7
%   x57 = flow from node 5 to node 7
%   x65 = flow from node 6 to node 5
%   x67 = flow from node 6 to node 7
%
% Objective:
%   Maximize total flow into sink node 7:
%       Z = x27 + x47 + x57 + x67
%
% Flow conservation (transshipment nodes only):
%   Node 2:  x12 - x24 - x25 - x27 = 0
%   Node 3:  x13 - x34 - x35 - x36 = 0
%   Node 4:  x24 + x34 + x54 - x47 = 0
%   Node 5:  x25 + x35 + x65 - x54 - x57 = 0
%   Node 6:  x36 - x65 - x67 = 0
%
% Capacity bounds on each arc:
%   0 <= x12 <= 75
%   0 <= x13 <= 50
%   0 <= x24 <= 25
%   0 <= x25 <= 20
%   0 <= x27 <= 20
%   0 <= x34 <= 25
%   0 <= x35 <= 125
%   0 <= x36 <= 25
%   0 <= x47 <= 20
%   0 <= x54 <= 25
%   0 <= x57 <= 20
%   0 <= x65 <= 15
%   0 <= x67 <= 25
%
% Linear Program (in words):
%   Maximize Z
%   Subject to:
%       (1) Flow conservation at nodes 2, 3, 4, 5, 6
%       (2) Arc capacity bounds
%       (3) Nonnegativity on all flows
%
% Implementation notes:
%   We solve this maximum flow problem using linprog.
%   linprog minimizes, so we minimize -(x27 + x47 + x57 + x67).
%
% Reproducibility:
%   1. Save this file as SolveMaxFlow.m
%   2. In MATLAB, run:
%          SolveMaxFlow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolveMaxFlow()

    %%%%%%%%%%%%%%%%%%%%%%%%%%%% INDEXING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We collect all decision variables into one vector z in this order:
    %
    %   z = [ x12  x13  x24  x25  x27  x34  x35  x36  x54  x47  x57  x65  x67 ]'
    %
    % so:
    %   z(1)  = x12   (1 -> 2)
    %   z(2)  = x13   (1 -> 3)
    %   z(3)  = x24   (2 -> 4)
    %   z(4)  = x25   (2 -> 5)
    %   z(5)  = x27   (2 -> 7)
    %   z(6)  = x34   (3 -> 4)
    %   z(7)  = x35   (3 -> 5)
    %   z(8)  = x36   (3 -> 6)
    %   z(9)  = x54   (5 -> 4)
    %   z(10) = x47   (4 -> 7)
    %   z(11) = x57   (5 -> 7)
    %   z(12) = x65   (6 -> 5)
    %   z(13) = x67   (6 -> 7)
    %
    numVar = 13;

    %%%%%%%%%%%%%%%%%%%%%%%% OBJECTIVE VECTOR %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We want to MAXIMIZE:
    %     Z = x27 + x47 + x57 + x67
    %
    % linprog MINIMIZES f'z, so we minimize the NEGATIVE of the objective:
    %     f'z = -(x27 + x47 + x57 + x67)
    %
    % According to our z ordering:
    %     x27 = z(5)
    %     x47 = z(10)
    %     x57 = z(11)
    %     x67 = z(13)
    %
    f = zeros(numVar,1);
    f(5)  = -1;   % -x27
    f(10) = -1;   % -x47
    f(11) = -1;   % -x57
    f(13) = -1;   % -x67

    %%%%%%%%%%%%%%%%%%%%% EQUALITY CONSTRAINTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Flow conservation at nodes 2, 3, 4, 5, 6:
    %
    % Node 2:  x12 - x24 - x25 - x27 = 0
    %          z(1) - z(3) - z(4) - z(5) = 0
    rowNode2 = zeros(1,numVar);
    rowNode2([1 3 4 5]) = [ 1  -1  -1  -1 ];
    %
    % Node 3:  x13 - x34 - x35 - x36 = 0
    %          z(2) - z(6) - z(7) - z(8) = 0
    rowNode3 = zeros(1,numVar);
    rowNode3([2 6 7 8]) = [ 1  -1  -1  -1 ];
    %
    % Node 4:  x24 + x34 + x54 - x47 = 0
    %          z(3) + z(6) + z(9) - z(10) = 0
    rowNode4 = zeros(1,numVar);
    rowNode4([3 6 9 10]) = [ 1   1   1  -1 ];
    %
    % Node 5:  x25 + x35 + x65 - x54 - x57 = 0
    %          z(4) + z(7) + z(12) - z(9) - z(11) = 0
    rowNode5 = zeros(1,numVar);
    rowNode5([4 7 12 9 11]) = [ 1   1   1  -1  -1 ];
    %
    % Node 6:  x36 - x65 - x67 = 0
    %          z(8) - z(12) - z(13) = 0
    rowNode6 = zeros(1,numVar);
    rowNode6([8 12 13]) = [ 1  -1  -1 ];

    aEq = [ rowNode2 ;
            rowNode3 ;
            rowNode4 ;
            rowNode5 ;
            rowNode6 ];

    bEq = zeros(5,1);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% BOUNDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Capacity bounds 0 <= x_ij <= capacity_ij on each arc.
    %
    lb = zeros(numVar,1);
    ub = zeros(numVar,1);
    %
    % capacities in the same order as z
    ub(1)  = 75;    % x12  (1 -> 2)
    ub(2)  = 50;    % x13  (1 -> 3)
    ub(3)  = 25;    % x24  (2 -> 4)
    ub(4)  = 20;    % x25  (2 -> 5)
    ub(5)  = 20;    % x27  (2 -> 7)
    ub(6)  = 25;    % x34  (3 -> 4)
    ub(7)  = 125;   % x35  (3 -> 5)
    ub(8)  = 25;    % x36  (3 -> 6)
    ub(9)  = 25;    % x54  (5 -> 4)
    ub(10) = 20;    % x47  (4 -> 7)
    ub(11) = 20;    % x57  (5 -> 7)
    ub(12) = 15;    % x65  (6 -> 5)
    ub(13) = 25;    % x67  (6 -> 7)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% SOLVE LP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % No inequality constraints other than bounds, so A and b are empty.
    %
    opts = optimoptions('linprog','Display','none');
    [zSol, fVal] = linprog(f, [], [], aEq, bEq, lb, ub, [], opts);

    % Clean small numerical noise for readability in the report.
    tol = 1e-9;
    zSol(abs(zSol) < tol) = 0;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REPORT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Unpack solution into descriptive variable names.
    %
    x12 = zSol(1);    % 1 -> 2
    x13 = zSol(2);    % 1 -> 3
    x24 = zSol(3);    % 2 -> 4
    x25 = zSol(4);    % 2 -> 5
    x27 = zSol(5);    % 2 -> 7
    x34 = zSol(6);    % 3 -> 4
    x35 = zSol(7);    % 3 -> 5
    x36 = zSol(8);    % 3 -> 6
    x54 = zSol(9);    % 5 -> 4
    x47 = zSol(10);   % 4 -> 7
    x57 = zSol(11);   % 5 -> 7
    x65 = zSol(12);   % 6 -> 5
    x67 = zSol(13);   % 6 -> 7
    %
    % Compute the total maximum flow into node 7:
    %   Z = x27 + x47 + x57 + x67
    %
    maxFlow = x27 + x47 + x57 + x67;
    %
    % fVal should be equal to -(maxFlow), up to rounding error, because
    % linprog minimized the negative of the objective.

    fprintf('================ MAX FLOW REPORT ================\n\n');
    fprintf('Arc Flows (Units):\n');
    fprintf('  x12 (1->2) = %g\n',  x12);
    fprintf('  x13 (1->3) = %g\n',  x13);
    fprintf('  x24 (2->4) = %g\n',  x24);
    fprintf('  x25 (2->5) = %g\n',  x25);
    fprintf('  x27 (2->7) = %g\n',  x27);
    fprintf('  x34 (3->4) = %g\n',  x34);
    fprintf('  x35 (3->5) = %g\n',  x35);
    fprintf('  x36 (3->6) = %g\n',  x36);
    fprintf('  x54 (5->4) = %g\n',  x54);
    fprintf('  x47 (4->7) = %g\n',  x47);
    fprintf('  x57 (5->7) = %g\n',  x57);
    fprintf('  x65 (6->5) = %g\n',  x65);
    fprintf('  x67 (6->7) = %g\n',  x67);
    fprintf('\n');
    fprintf('Maximum Flow from Node 1 to Node 7 = %g\n', maxFlow);
    fprintf('\n=================================================\n\n');
end
