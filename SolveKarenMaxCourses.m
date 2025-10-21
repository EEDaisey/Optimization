%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   18th of October, 2025
%     Title:   Module 8 Assignment — Q4(d) Solve Max #Courses (<=30h)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optimal Course Set (maximize count, time <= 30h):
%   Take {Intro OR, Linear Opt, Modeling & Simulation, Prob & Stats, Data Mining}
%   Index set {1, 2, 5, 6, 7}
% ------------------------
% Count = 5, Hours = 26, Credits = 16, GPA = 53/16 = 3.3125  (>= 2.5)
%
% Mathematical Model:
% Maximize  sum(y_j)
% s.t.      sum(g_j*c_j*y_j) >= 2.5 * sum(c_j*y_j),        (GPA)
%           sum(c_j*y_j)     >= 12,                        (Full-time)
%           sum(h_j*y_j)     <= 30,                        (Time cap)
%           y_1 = 1,                                       (Intro required)
%           y_3 <= y_2,  y_4 <= y_2,  y_7 <= y_6,          (Prereqs)
%           y_2 + y_5 + y_7 >= 2,                          (At least two of {LO,MS,DM})
%           y in {0,1}^8.
%
% Reproducibility:
% (0) Open MATLAB.
% (1) Save as SolveKarenMaxCourses.m
% (2) Run:  SolveKarenMaxCourses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolveKarenMaxCourses()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Course order: [1] Intro OR, [2] Linear Opt, [3] Integer Opt, [4] Nonlinear Opt,
    %               [5] Modeling & Simulation, [6] Prob & Stats,
    %               [7] Data Mining, [8] Scientific Computing
    hours    = [3 6 8 10 6 5 6 10]';   % h_j
    credits  = [2 3 3  3  4 3 4  4 ]'; % c_j
    gradePts = [4 4 3  2  4 3 2  4 ]'; % g_j
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% A*y <= b %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % GPA >= 2.5  ->  sum((g-2.5).*c .* y) >= 0  ->  -sum(...) <= 0
    gpaRow  = -((gradePts - 2.5).*credits)';          % <= 0
    % Full-time: sum(c.*y) >= 12  ->  -sum(c.*y) <= -12
    fullRow = -credits';                               % <= -12
    % Prereqs: y3 <= y2, y4 <= y2, y7 <= y6
    rIO_LO  = zeros(1,8); rIO_LO([3 2]) = [1 -1];      % y3 - y2 <= 0
    rNLO_LO = zeros(1,8); rNLO_LO([4 2]) = [1 -1];     % y4 - y2 <= 0
    rDM_PS  = zeros(1,8); rDM_PS([7 6]) = [1 -1];      % y7 - y6 <= 0
    % At least two of {LO,MS,DM}: y2 + y5 + y7 >= 2  ->  -(...) <= -2
    rSet    = zeros(1,8); rSet([2 5 7]) = -1;          % -(y2+y5+y7) <= -2
    % Time cap: sum(h.*y) <= 30
    timeRow = hours';                                   % <= 30

    A = [gpaRow; fullRow; rIO_LO; rNLO_LO; rDM_PS; rSet; timeRow];
    b = [0; -12; 0; 0; 0; -2; 30];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Aeq*y = beq %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Must take Intro OR: y1 = 1
    Aeq = [1 0 0 0 0 0 0 0];
    beq = 1;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Solve ILP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Maximize sum(y)  <=>  minimize -sum(y)
    f = -ones(8,1);
    intcon = 1:8; lb = zeros(8,1); ub = ones(8,1);
    opts = optimoptions('intlinprog','Display','none');
    [yOpt,fval] = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub,opts);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Report %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    names = {'Intro OR','Linear Opt','Integer Opt','Nonlinear Opt', ...
             'Modeling & Simulation','Prob & Stats','Data Mining','Scientific Comp'};
    idx = find(yOpt > 0.5);
    fprintf('Classes: '); fprintf('%s   ', names{idx}); fprintf('\n');
    H = sum(hours(idx)); C = sum(credits(idx)); G = sum(gradePts(idx).*credits(idx));
    fprintf('Count = %d, Hours = %g, Credits = %g, GPA = %g\n', numel(idx), H, C, G/C);
    fprintf('Objective = %g\n', fval);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
