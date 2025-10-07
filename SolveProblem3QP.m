%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   6th of October, 2025
%     Title:   Module 3 Assignment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optimal x:
%     x1: 1.00
%     x2: 0.00
% ------------------------
% Minimum Objective: -4.0000
%
% Mathematical Analysis:
% The problem is a convex quadratic program. The objective is written as
% (1/2)x'Hx + c'x with a symmetric H. Constraints are Ax <= b with x >= 0.
% The solution also matches the hand calculation over the triangle
% {(0,0),(1,0),(0,1)} showing the minimum at (1,0).
%
% Reproducibility:
% (0) Open MATLAB.
% (1) Save this script as a .m file.
% (2) Execute the script. The numerical solution will be printed.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolveProblem3QP()
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Objective Function %%%%%%%%%%%%%%%%%%%%%%%%
    % f(x) = 1/2 x' H x + c' x  matches
    % 2 x1^2 + 3 x2^2 + 4 x1 x2 - 6 x1 - 3 x2
    H = [4 4; 4 6];        % symmetric Hessian
    c = [-6; -3];          % linear term
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Constraints %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Ax <= b with x >= 0
    A = [1 1;     % x1 + x2 <= 1
         2 3];    % 2 x1 + 3 x2 <= 4
    b = [1; 4];
    lb = [0; 0];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solver %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % quadprog solves min (1/2)x'Hx + c'x  s.t. A x <= b, x >= lb
    options = optimoptions('quadprog','Display','none');
    [xOpt, fval, exitflag] = quadprog(H, c, A, b, [], [], lb, [], [], options);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solution %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('Optimal x:\n');
    fprintf('  x1: %.4f\n', xOpt(1));
    fprintf('  x2: %.4f\n', xOpt(2));
    fprintf('------------------------\n');
    fprintf('Minimum Objective: %.4f\n', fval);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end