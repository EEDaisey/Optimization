%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   22nd of September, 2025
%     Title:   Module 4 Assignment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Critical Points and Classification:
% Critical points of the function:
%                      f(x1, x2, x3) = 3*x1^2 + 4*x2^2 + x3^2 - 9*x1*x2*x3
%     Critical Point 1: (0, 0, 0) - Local Minimum
%     Critical Point 2: (Nonzero Points) - Saddle Points
%
% Mathematical Analysis:
% The function is analyzed by solving Grad[f(x)] = 0 (i.e., finding the critical points).
% The Hessian matrix at each critical point is then computed to classify the points
% based on the eigenvalues of the Hessian matrix:
%     - Local Minimum: All eigenvalues of the Hessian are positive.
%     - Local Maximum: All eigenvalues of the Hessian are negative.
%     - Saddle Point: The eigenvalues have mixed signs.
%
% Reproducibility:
% (0) Open MATLAB.
% (1) Save this script as a .m file.
% (2) Execute the script.  The numerical solution will be printed to the
%     console, and eigenvalues will be computed for the classification.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function SolveOptimizationProblem()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Hessian (Grad²[f]) %%%%%%%%%%%%%%%%%%%%%%%%%%
    % Compute the second-order partial derivatives (Hessian of f):
    hessianF = @(x1, x2, x3) [    6,  -9*x3,  -9*x2;
                              -9*x3,      8,  -9*x1;
                              -9*x2,  -9*x1,     2];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Analysis %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Solve for critical points by solving Grad[f] = 0:
    syms x1 x2 x3;
    sol = solve([6*x1 - 9*x2*x3 == 0, ...
                 8*x2 - 9*x1*x3 == 0, ...
                 2*x3 - 9*x1*x2 == 0], ...
                         [x1, x2, x3]);
 
    % Initialize matrix to store unique critical points:
    uniquePoints = [];  % To store already seen critical points.
    tolerance = 1e-5;   % Tolerance to consider points as duplicates.
 
    % Iterate over all solutions and consider all sign combinations:
    for i = 1:length(sol.x1)
        % Extract values from the solution:
        x1Val = double(sol.x1(i));
        x2Val = double(sol.x2(i));
        x3Val = double(sol.x3(i));
 
        % Generate all sign combinations (+/- for each variable):
        signCombinations = [1, -1];
        for s1 = signCombinations
            for s2 = signCombinations
                for s3 = signCombinations
                    % Apply the sign combinations to the critical point:
                    x1Modified = s1 * x1Val;
                    x2Modified = s2 * x2Val;
                    x3Modified = s3 * x3Val;
 
                    % Check if this critical point has already been processed:
                    isDuplicate = false;
                    for j = 1:size(uniquePoints, 1)
                        if all(abs(uniquePoints(j,:) - ...
                            [x1Modified, x2Modified, x3Modified]) < tolerance)
                            isDuplicate = true; 
                            break;
                        end
                    end
 
                    % If the point is not a duplicate, process it:
                    if ~isDuplicate
                        % Add the point to the list of unique points:
                        uniquePoints = [uniquePoints; ...
                                          x1Modified, ...
                                          x2Modified, ...
                                          x3Modified];
 
                        % Compute the Hessian at the modified critical point:
                        H = hessianF(x1Modified, x2Modified, x3Modified);
 
                        % Compute eigenvalues of the Hessian:
                        eigvals = eig(H);
 
                        % Insert some print statements:
                        disp('Eigenvalues of the Hessian:');
                        disp(eigvals);
 
                        % Check if there are any small negative eigenvalues:
                        if any(eigvals < 0 & eigvals > -1e-5)
                            disp('Small negative eigenvalue detected:');
                            disp(eigvals(eigvals < 0 & eigvals > -1e-5));
                        end
 
                        % Classify the critical point based on the eigenvalues:
                        if all(eigvals > 0)
                            disp('This point is a minimum.');
                        elseif all(eigvals < 0)
                            disp('This point is a maximum.');
                        else
                            disp('This point is a saddle point.');
                        end
                        disp('==================================================');
                    end
                end
            end
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


