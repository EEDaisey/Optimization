%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   20th of October, 2025
%     Title:   Convex Combination Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Feasibility:   Feasible
%
% Exact convex weights:
%   lambda1 = 20/51  = ~0.3921568627
%   lambda2 = 11/34  = ~0.3235294118
%   lambda3 =  4/51  = ~0.0784313725
%   lambda4 =  7/34  = ~0.2058823529
% Check: lambda >= 0, sum = 1,  [9 1 -6 3; 6 -7 9 1; -1 3 5 5]*lambda = [4;1;2].
%
% Mathematical Analysis:
% Test v = (4,1,2) for membership in conv(S), S={s1..s4}, by LP feasibility:
%   minimize 0
%   subject to [s1 s2 s3 s4]*lambda = v,  sum(lambda)=1,  lambda >= 0.
%
% Reproducibility:
% (0) Open MATLAB (R2015+).
% (1) Save this file as SolveConvexCombination.m
% (2) Run:   SolveConvexCombination
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function SolveConvexCombination()
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Objective (min 0) %%%%%%%%%%%%%%%%%%%%%%%%%
    objectiveF = zeros(4,1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Constraints %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    equalityA = [ 9  1 -6  3;
                  6 -7  9  1;
                 -1  3  5  5;
                  1  1  1  1 ];
    equalityB = [4; 1; 2; 1];
 
    A = []; b = [];
    lb = zeros(4,1);
    ub = [];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solver %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MATLAB 2015 linprog signature requires x0 before options.
    x0 = [];
    options = optimset('Display','off');
    [lambda, ~] = linprog(objectiveF, A, b, equalityA, equalityB, ...
                                    lb, ub, x0, options);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('Weights (Lambda):\n');
    fprintf('  lambda1 = %.2f\n', lambda(1));
    fprintf('  lambda2 = %.2f\n', lambda(2));
    fprintf('  lambda3 = %.2f\n', lambda(3));
    fprintf('  lambda4 = %.2f\n', lambda(4));
 


    S = [ 9  1 -6  3;
          6 -7  9  1;
         -1  3  5  5 ];
    t = S*lambda;
    fprintf('t = [%.2f; %.2f; %.2f]\n', t(1), t(2), t(3));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
