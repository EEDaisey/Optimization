%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   15th of September, 2025
%     Title:   Module 3 Assignment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optimal Production Plan:
%     Alpha Chips: 10.00
%     Beta Chips:  0.00
%     Gamma Chips: 10.00
% ------------------------
% Maximum Revenue: $6900.00
%
% Mathematical Analysis:
% The problem is a standard linear program.  The 'linprog' function from
% MATLAB's Optimization Toolbox is used to find the optimal solution.
% The solver is configured to use the dual-simplex algorithm, which is
% efficient for this type of problem.
%
% Reproducibility:
% (0) Open MATLAB.
% (1) Save this script as a .m file.
% (2) Execute the script. The numerical solution will be printed to the
%     console, and a 3D plot will be generated.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolveMegaChipsProblem()
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Objective Function %%%%%%%%%%%%%%%%%%%%%%%%
    % The objective is to maximize revenue. Since linprog performs
    % minimization by default (min c'x), we negate the revenue
    % coefficients to achieve maximization.
    revenuePerChip = [415; 300; 275]; % Revenue for xAlpha, xBeta, xGamma
    costVector = -revenuePerChip;     % Negated vector for solver
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Constraints %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % The constraints are of the form A*x <= b. Each row in the matrix A
    % corresponds to a resource constraint.
    constraintsMatrix = [7  3  3;  % Labor constraint
                         6  5  4;  % Material constraint
                         6  4  4]; % Energy constraint

    % The vector b represents the maximum availability of each resource.
    rhsVector = [100; 100; 120];

    % All decision variables must be non-negative.
    lowerBounds = zeros(3, 1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solver %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % The problem is structured for the linprog solver using the 'problem'
    % struct for clarity and best practices.
    problem.f        =   costVector;
    problem.Aineq    =   constraintsMatrix;
    problem.bineq    =   rhsVector;
    problem.lb       =   lowerBounds;
    problem.solver   =   'linprog';
    problem.options  =   optimoptions('linprog', 'Algorithm', ...
                                      'dual-simplex', 'Display', 'none');

    % Execute the solver to find the optimal production plan.
    [optimalPlan, negRevenue] = linprog(problem);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solution %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Display the final numerical results to the console.
    chipTypes = {'Alpha', 'Beta', 'Gamma'};
    fprintf('Optimal Production Plan:\n');
    fprintf('------------------------\n');
    for i = 1:numel(chipTypes)
        fprintf('    %s Chips: %.2f\n', chipTypes{i}, optimalPlan(i));
    end
    revenue = -negRevenue;
    fprintf('------------------------\n');
    fprintf('Maximum Revenue: $%.2f\n', revenue);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end