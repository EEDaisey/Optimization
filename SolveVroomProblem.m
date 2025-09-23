%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optimal Mix:
%     Product A: 172.00 units
%     Product B: 137.00 units
%     Product C: 0.00 units
% ------------------------
% Minimum Cost: $2679.00
%
% Mathematical Analysis:
% The problem is a standard minimization linear program. The 'linprog'
% function is used to find the optimal solution. The '?' inequality
% constraints are converted to the '<=' form required by linprog by
% multiplying the constraint matrix (A) and the RHS vector (b) by -1.
%
% Reproducibility:
% (0) Open MATLAB.
% (1) Save this script as a .m file.
% (2) Execute the script. The numerical solution will be printed to the
%     console.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SolveVroomProblem()
   %%%%%%%%%%%%%%%%%%%%%%%%%%% Objective Function %%%%%%%%%%%%%%%%%%%%%%%%%%%
   % The objective is to minimize the total cost of the additive mix.
   objectiveCoefficients = [10; 7; 11]; % Cost for Product A, B, C

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Constraints %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % The constraints are of the form A*x >= b. To use linprog's default
   % A*x <= b form, we multiply the constraint matrix and RHS by -1.
   constraintMatrixA = -[4  5  7;  % Methanol constraint
                         3  2  3;  % Ethanol constraint
                         7  8  6]; % Amines constraint

   % The RHS vector is also negated.
   rhsVectorB = -[1200; 790; 2300];

   % All decision variables must be non-negative.
   lowerBounds = zeros(3, 1);
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solver %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % The problem is structured for the linprog solver using the 'problem'
   % struct for clarity and best practices.
   problem.f        =   objectiveCoefficients;
   problem.Aineq    =   constraintMatrixA;
   problem.bineq    =   rhsVectorB;
   problem.lb       =   lowerBounds;
   problem.solver   =   'linprog';
   problem.options  =   optimoptions('linprog','Algorithm',...
                                     'dual-simplex','Display','none');

   % Execute the solver to find the optimal mix and its cost.
   [optimalMix, minCost] = linprog(problem);
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solution %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % Display the final numerical results to the console.
   productTypes = {'Product A', 'Product B', 'Product C'};
   fprintf('Optimal Mix:\n');
   fprintf('------------\n');
   for i = 1:numel(productTypes)
       fprintf('    %s: %.2f units\n', productTypes{i}, optimalMix(i));
   end
   fprintf('------------\n');
   fprintf('Minimum Cost: $%.2f\n', minCost);
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end