%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   6th of October, 2025
%     Title:   Module 3 Assignment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optimal Chemical Plan (liters):
%     x1: ~200.00
%     x2: ~435.08
%     x3: ~200.00
% ------------------------
% Minimum Cost: ~$30698.12
%
% Mathematical Analysis:
% Minimize 25*x1 + 37*x2 + 48*x3 subject to
%   q(x) = x3 - 0.25*x1^2 + 0.1*x2^2 + 0.01*x1*x2 >= 10000,
%   x2 - 2*x3 >= 0,
%   x1, x2, x3 >= 200.
% Since x1 hurts yield and x3 is very expensive per unit of yield, the
% optimizer sets x1 and x3 at their lower bounds and meets the yield
% primarily with x2.
%
% Reproducibility:
% (0) Open MATLAB.
% (1) Save this file as SolvePegamentoProblem.m
% (2) Run:  SolvePegamentoProblem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolvePegamentoProblem()
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Objective Function %%%%%%%%%%%%%%%%%%%%%%%%
    cost = @(x) 25*x(1) + 37*x(2) + 48*x(3);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Constraints %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Linear inequality:  x2 - 2*x3 >= 0  <=>  -x2 + 2*x3 <= 0
    A = [0 -1 2];
    b = 0;

    % Bounds: x1, x2, x3 >= 200
    lb = [200; 200; 200];
    ub = [];

    % Nonlinear inequality c(x) <= 0 implements q(x) >= 10000
    % c(x) = 10000 - (x3 - 0.25*x1^2 + 0.1*x2^2 + 0.01*x1*x2)
    nonlin = @(x) deal( 10000 - ( x(3) - 0.25*x(1)^2 + 0.1*x(2)^2 + 0.01*x(1)*x(2) ), [] );
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solver %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    x0 = [200; 400; 200]; % feasible for the linear parts
    opts = optimoptions('fmincon','Algorithm','sqp','Display','none');
    [xOpt, fval] = fmincon(cost, x0, A, b, [], [], lb, ub, nonlin, opts);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solution %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('Optimal Chemical Plan (liters):\n');
    fprintf('  x1: %.2f\n', xOpt(1));
    fprintf('  x2: %.2f\n', xOpt(2));
    fprintf('  x3: %.2f\n', xOpt(3));
    fprintf('------------------------\n');
    fprintf('Minimum Cost: $%.2f\n', fval);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
