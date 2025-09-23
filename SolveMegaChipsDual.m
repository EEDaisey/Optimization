%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   15th of September, 2025
%     Title:   Module 3 Assignment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optimal Dual Solution (Shadow Prices):
%     y_Labor:    $1.00
%     y_Material: $68.00
%     y_Energy:   $0.00
% ------------------------------------
% Minimum Resource Value: $6900.00
%
% Mathematical Analysis:
% The problem is a standard linear program. The 'linprog' function from
% MATLAB's Optimization Toolbox is used to find the optimal solution.
% This solution can also be derived using complementary slackness. Since
% the optimal primal solution uses all Labor and Material (binding
% constraints) but has leftover Energy (slack), the shadow price for
% Energy (y_Energy) must be zero. The remaining dual variables are solved
% from the binding constraints. The optimal objective value of the
% dual ($6900.00) equals the optimal objective value of the primal,
% as guaranteed by the Strong Duality Theorem.
%
% Reproducibility:
% (0) Open MATLAB.
% (1) Save this script as a .m file.
% (2) Execute the script. The numerical solution will be printed to the
%     console.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SolveMegaChipsDual()
   %%%%%%%%%%%%%%%%%%%%%%%%%%% Objective Function %%%%%%%%%%%%%%%%%%%%%%%%%
   % The objective is to minimize the total imputed value of the resources.
   dualObjective = [100; 100; 120]; % Cost for Labor, Material, Energy

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Constraints %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % The constraints are of the form A_T*y >= c. To use linprog's default
   % A*x <= b form, we multiply the constraints by -1.
   dualConstraintA = -[7  6  6;  % Alpha constraint
                       3  5  4;  % Beta constraint
                       3  4  4]; % Gamma constraint

   % The RHS vector (primal objective coefficients) is also negated.
   dualRhsB = -[415; 300; 275];

   % All dual variables must be non-negative.
   lowerBounds = zeros(3, 1);
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solver %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % The problem is structured for the linprog solver using the 'problem'
   % struct for clarity and best practices.
   problem.f        =   dualObjective;
   problem.Aineq    =   dualConstraintA;
   problem.bineq    =   dualRhsB;
   problem.lb       =   lowerBounds;
   problem.solver   =   'linprog';
   problem.options  =   optimoptions('linprog','Algorithm',...
                                     'dual-simplex','Display','none');

   % Execute the solver to find the optimal dual variables.
   [shadowPrices, minCost] = linprog(problem);
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solution %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % Display the final numerical results to the console.
   resourceTypes = {'Labor', 'Material', 'Energy'};
   fprintf('Optimal Dual Solution (Shadow Prices):\n');
   fprintf('------------------------------------\n');
   for i = 1:numel(resourceTypes)
       fprintf('    y_%s: $%.2f\n', resourceTypes{i}, shadowPrices(i));
   end
   fprintf('------------------------------------\n');
   fprintf('Minimum Resource Value: $%.2f\n', minCost);
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
