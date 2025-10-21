%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   18th of October, 2025
%     Title:   Minimize Weekly Hours
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optimal Weekly Hours Plan:
%   Take {Intro OR, Modeling & Simulation, Prob & Stats, Data Mining}
%   Index set {1, 5, 6, 7}
% ------------------------
% Hours = 20, Credits = 13, GPA = 41/13 = 3.15385  (>= 2.5)
%
% Mathematical Analysis:
% Minimize  sum(h_j * y_j)
% s.t.      sum(g_j * c_j * y_j) >= 2.5 * sum(c_j * y_j),
%           sum(c_j * y_j) >= 12,
%           y_1 = 1,
%           y_3 <= y_2,  y_4 <= y_2,  y_7 <= y_6,
%           y_2 + y_5 + y_7 >= 2,
%           y in {0,1}^8.
%
% Reproducibility:
% (0) Open MATLAB.
% (1) Save as SolveKarenMinHours.m
% (2) Run:  SolveKarenMinHours
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolveKarenMinHours()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    hours    = [3 6 8 10 6 5 6 10]';
    credits  = [2 3 3  3  4 3 4  4 ]';
    gradePts = [4 4 3  2  4 3 2  4 ]';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% A*y <= b %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % GPA >= 2.5  <=>  sum((gradePts-2.5).*credits .* y) >= 0
    % Move to left and negate:  -sum((gradePts-2.5).*credits .* y) <= 0
    gpaRow  = -((gradePts - 2.5).*credits)';    % <= 0
    % Full-time: sum(credits .* y) >= 12  <=>  -sum(credits .* y) <= -12
    fullRow = -credits';                        % <= -12
    % Prereqs: y3 <= y2, y4 <= y2, y7 <= y6
    rIO_LO  = zeros(1,8); rIO_LO([3 2]) = [1 -1];   % y3 - y2 <= 0
    rNLO_LO = zeros(1,8); rNLO_LO([4 2]) = [1 -1];  % y4 - y2 <= 0
    rDM_PS  = zeros(1,8); rDM_PS([7 6]) = [1 -1];   % y7 - y6 <= 0
    % Set requirement: y2 + y5 + y7 >= 2  <=>  -(y2+y5+y7) <= -2
    rSet    = zeros(1,8); rSet([2 5 7]) = -1;

    A = [gpaRow; fullRow; rIO_LO; rNLO_LO; rDM_PS; rSet];
    b = [0; -12; 0; 0; 0; -2];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Aeq*y = beq %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Must take Intro to OR: y1 = 1
    Aeq = [1 0 0 0 0 0 0 0];
    beq = 1;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Solve ILP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    f = hours; intcon = 1:8; lb = zeros(8,1); ub = ones(8,1);
    opts = optimoptions('intlinprog','Display','none');
    [yOpt,fval] = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub,opts);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Report %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    names = {'Intro OR','Linear Opt','Integer Opt','Nonlinear Opt', ...
             'Modeling & Simulation','Prob & Stats','Data Mining','Scientific Comp'};
    idx = find(yOpt > 0.5);
    fprintf('Classes: '); fprintf('%s   ', names{idx}); fprintf('\n');
    H = sum(hours(idx)); C = sum(credits(idx)); G = sum(gradePts(idx).*credits(idx));
    fprintf('Hours = %g, Credits = %g, GPA = %g\n', H, C, G/C);
    fprintf('Objective (Hours) = %g\n', fval);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end