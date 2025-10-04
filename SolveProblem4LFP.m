%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   28-Sep-2025
%     Title:   Module 5 - Problem 4B
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Original Formulation:
%   max (4 x1 + 6 x2 + 12) / (3 x1 + 7 x2 + 50)
%   s.t.  x1 + 3 x2 <= 50
%         5 x1 + 2 x2 <= 70
%         x1, x2 >= 0
%
% New Formulation:
%   Let z = 1 / (3 x1 + 7 x2 + 50),  y = z * x, 3 y1 + 7 y2 + 50 z = 1.
%   LP in (y1, y2, z):
%       max  4 y1 + 6 y2 + 12 z
%       s.t. y1 + 3 y2 - 50 z <= 0
%            5 y1 + 2 y2 - 70 z <= 0
%            3 y1 + 7 y2 + 50 z  = 1
%            y1, y2, z >= 0
%
% Note: Matlab 2015a Used.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolveProblem4LFP()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Setup LP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Decision variables: v = [y1; y2; z]:
    objectiveVector = -[4; 6; 12];     % maximize -> minimize negative (double)

    % A * v <= b:
    constraintsMatrix = [ 1, 3, -50;
                          5, 2, -70 ]; % double
    rhsVector = [0; 0];                % double

    % Aeq * v = beq:
    equalityMatrix = [3, 7, 50];       % double
    equalityRhs    = 1;                % double

    % Bounds:
    lowerBounds = zeros(3,1);          % y1,y2,z >= 0
    upperBounds = [];                  % no upper bounds

    % Starting point (R2015 API expects x0 positionally before options):
    x0 = [];                           % let linprog choose

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solve %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Use 'simplex' or 'interior-point'. Set Display 'off'.
    options = optimoptions('linprog', 'Algorithm', 'simplex', 'Display', 'off');

    % [x,fval,exitflag,output] = linprog(f,A,b,Aeq,beq,lb,ub,x0,options):
    [solutionVec, negObjective, exitflag, output] = linprog( ...
        objectiveVector, constraintsMatrix,   rhsVector, ...
         equalityMatrix,       equalityRhs, lowerBounds, ...
            upperBounds,                x0,     options);
        
    if exitflag <= 0
        warning('linprog did not report success. exitflag=%d\n%s', exitflag, output.message);
    end

    y1 = solutionVec(1);
    y2 = solutionVec(2);
    z  = solutionVec(3);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Map back x %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % x = y / z   (z > 0 at optimum):
    x1 = y1 / z;
    x2 = y2 / z;

    % Fractional objective value at x*:
    numerator   = 4*x1 + 6*x2 + 12;
    denominator = 3*x1 + 7*x2 + 50;
    fracValue   = numerator / denominator;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Print %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('================= Module 5 - Problem 4 =================\n');
    fprintf('Status (linprog exitflag): %d\n', exitflag);
    fprintf('y* = [y1, y2] = [%.10f, %.10f],  z* = %.10f\n', y1, y2, z);
    fprintf('x* = [x1, x2] = [%.10f, %.10f]\n', x1, x2);
    fprintf('Fractional objective at x*: %.10f\n', fracValue);

    % Feasibility checks (original constraints):
    check1 = x1 + 3*x2;
    check2 = 5*x1 + 2*x2;
    fprintf('Check: x1 + 3 x2 = %.2f (<= 50)\n', check1);
    fprintf('Check: 5 x1 + 2 x2 = %.2f (<= 70)\n', check2);
end

