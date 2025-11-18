%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Problem:
%   Widget Plus flagship store operates 7 days/week. Each of 50 full-time
%   employees works 5 CONSECUTIVE days and has 2 consecutive days off.
%   Daily staffing requirements:
%       Sun  Mon  Tue  Wed  Thu  Fri  Sat
%       47   22   28   35   34   43   53
%
%   Preemptive Goal Programming is used with 3 priority levels:
%     Level 1 (highest): G1.1 (Sat fully staffed), G1.2 (Sun fully staffed)
%     Level 2:          G2   (Fri fully staffed)
%     Level 3:          G3.1–G3.4 (Mon–Thu fully staffed)
%
% Final Preemptive GP Solution (after 3 sequential LPs, as printed by MATLAB):
%
%   Employees starting their 5-day work block on:
%       Start Sun (x1) =  0.00
%       Start Mon (x2) =  0.00
%       Start Tue (x3) =  3.00
%       Start Wed (x4) = 25.00
%       Start Thu (x5) =  3.88
%       Start Fri (x6) = 11.12
%       Start Sat (x7) =  7.00
%   Total employees used = 50 (capacity fully utilized).
%
%   Resulting staffing by DAY (Actual vs Required):
%       Day   Actual Staff   Required
%       Sun       47.00         47
%       Mon       22.00         22
%       Tue       21.12         28
%       Wed       35.00         35
%       Thu       31.88         34
%       Fri       43.00         43
%       Sat       50.00         53
%
% Goal Status (Preemptive, consistent with the output above):
%   Level 1:
%     - G1.1 (Saturday fully staffed, 53): NOT MET (short by 3.00).
%     - G1.2 (Sunday fully staffed, 47):  MET.
%   Level 2:
%     - G2 (Friday fully staffed, 43):    MET.
%   Level 3:
%     - G3.1 (Monday 22):                 MET.
%     - G3.2 (Tuesday 28):                NOT MET (short by 6.88).
%     - G3.3 (Wednesday 35):              MET.
%     - G3.4 (Thursday 34):               NOT MET (short by 2.12).
%
% Reproducibility:
%   (1) Save this script as SolveWidgetSchedulingPreemptiveGP.m
%   (2) In MATLAB 2015:  >> SolveWidgetSchedulingPreemptiveGP
%       The three-pass preemptive GP solution will reproduce the starter
%       pattern and daily staffing shown above.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolveWidgetSchedulingPreemptiveGP()

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Daily staffing requirements: [Sun Mon Tue Wed Thu Fri Sat]
    demands = [47; 22; 28; 35; 34; 43; 53];
    max_employees = 50;

    % Variable layout (21 total):
    %   x(1:7)   = starters x1..x7 (start Sun..Sat)
    %   x(8:14)  = U_Sun..U_Sat  (understaffing)
    %   x(15:21) = E_Sun..E_Sat  (overstaffing)
    numVars = 21;

    %%%%%%%%%%%%%%%%%%%%%%%% System constraint A*x <= b %%%%%%%%%%%%%%%%%%%
    % Total number of employees cannot exceed 50:
    A = zeros(1, numVars);
    A(1,1:7) = 1;          % sum of starters
    b = max_employees;

    %%%%%%%%%%%%%%%%%%%%%%%% Day balance Aeq*x = beq %%%%%%%%%%%%%%%%%%%%%%
    % For each day d:
    %   S_d (sum of appropriate x_j) + U_d - E_d = demand_d.
    Aeq = zeros(7, numVars);
    beq = demands;

    % Index mapping for clarity:
    % x1..x7: 1..7
    % U: 8..14  (Sun..Sat)
    % E: 15..21 (Sun..Sat)

    % Sun: works if start Sun, Wed, Thu, Fri, Sat => x1,x4,x5,x6,x7
    Aeq(1, [1 4 5 6 7  8 15]) = [1 1 1 1 1  1 -1];
    % Mon: start Sun, Mon, Thu, Fri, Sat => x1,x2,x5,x6,x7
    Aeq(2, [1 2 5 6 7  9 16]) = [1 1 1 1 1  1 -1];
    % Tue: start Sun, Mon, Tue, Fri, Sat => x1,x2,x3,x6,x7
    Aeq(3, [1 2 3 6 7 10 17]) = [1 1 1 1 1  1 -1];
    % Wed: start Sun, Mon, Tue, Wed, Sat => x1,x2,x3,x4,x7
    Aeq(4, [1 2 3 4 7 11 18]) = [1 1 1 1 1  1 -1];
    % Thu: start Sun, Mon, Tue, Wed, Thu => x1,x2,x3,x4,x5
    Aeq(5, [1 2 3 4 5 12 19]) = [1 1 1 1 1  1 -1];
    % Fri: start Mon, Tue, Wed, Thu, Fri => x2,x3,x4,x5,x6
    Aeq(6, [2 3 4 5 6 13 20]) = [1 1 1 1 1  1 -1];
    % Sat: start Tue, Wed, Thu, Fri, Sat => x3,x4,x5,x6,x7
    Aeq(7, [3 4 5 6 7 14 21]) = [1 1 1 1 1  1 -1];

    lb = zeros(numVars,1);
    ub = [];  % no upper bounds beyond A,b

    options = optimset('Display','off');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Pass 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Level 1: Minimize weekend understaffing U_Sat + U_Sun
    f1 = zeros(numVars,1);
    f1(8)  = 1;  % U_Sun
    f1(14) = 1;  % U_Sat

    [x1, P1_star, exitflag1] = linprog(f1, A, b, Aeq, beq, lb, ub, [], options);
    if exitflag1 ~= 1
        warning('Pass 1 did not converge to optimal solution.');
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Pass 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Level 2: Fix U_Sun + U_Sat = P1_star, then minimize U_Fri.
    Aeq_P2 = [Aeq; zeros(1,numVars)];
    Aeq_P2(8, [8 14]) = [1 1];     % U_Sun + U_Sat = P1_star
    beq_P2 = [beq; P1_star];

    f2 = zeros(numVars,1);
    f2(13) = 1;                     % U_Fri index = 13

    [x2, P2_star, exitflag2] = linprog(f2, A, b, Aeq_P2, beq_P2, lb, ub, [], options);
    if exitflag2 ~= 1
        warning('Pass 2 did not converge to optimal solution.');
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Pass 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Level 3: Fix P1*, P2*, then minimize weekday understaffing
    %          U_Mon + U_Tue + U_Wed + U_Thu.
    Aeq_P3 = [Aeq_P2; zeros(1,numVars)];
    Aeq_P3(9, 13) = 1;              % U_Fri = P2_star
    beq_P3 = [beq_P2; P2_star];

    f3 = zeros(numVars,1);
    f3(9:12) = 1;                   % U_Mon..U_Thu

    [x_final, P3_star, exitflag3] = linprog(f3, A, b, Aeq_P3, beq_P3, lb, ub, [], options);
    if exitflag3 ~= 1
        warning('Pass 3 did not converge to optimal solution.');
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('============ WIDGET PLUS SCHEDULING (PREEMPTIVE GP) ============\n');
    fprintf('P1* (U_Sun + U_Sat) = %.2f\n', P1_star);
    fprintf('P2* (U_Fri)         = %.2f\n', P2_star);
    fprintf('P3* (U_Mon+U_Tue+U_Wed+U_Thu) = %.2f\n\n', P3_star);

    starters    = x_final(1:7);
    understaff  = x_final(8:14);
    overstaff   = x_final(15:21);

    days = {'Sun','Mon','Tue','Wed','Thu','Fri','Sat'};

    % Compute actual staffing per day using the x-part of Aeq
    staffingMatrix = Aeq(:,1:7);
    actualStaff    = staffingMatrix * starters;

    fprintf('Starter pattern (employees starting on each day):\n');
    for j = 1:7
        fprintf('  Start %-3s: %6.2f\n', days{j}, starters(j));
    end
    fprintf('\nDaily staffing (Actual vs Required):\n');
    fprintf('Day   Required   Actual   Under(U)   Over(E)\n');
    fprintf('---------------------------------------------\n');
    for j = 1:7
        fprintf('%-4s %8.2f %8.2f %9.2f %9.2f\n', ...
            days{j}, demands(j), actualStaff(j), understaff(j), overstaff(j));
    end
    fprintf('===============================================================\n\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Summary %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% How many employees work each day of the week?
%
%   Using the preemptive GP solution (from the final pass):
%
%   Starters:
%     x1 (Sun) =  0.00,  x2 (Mon) =  0.00,  x3 (Tue) =  3.00,
%     x4 (Wed) = 25.00,  x5 (Thu) =  3.88,  x6 (Fri) = 11.12,
%     x7 (Sat) =  7.00
%     Total employees = 50
%
%   Resulting staffing by day:
%     Sun: 47.00 employees  (require 47)
%     Mon: 22.00 employees  (require 22)
%     Tue: 21.12 employees  (require 28)
%     Wed: 35.00 employees  (require 35)
%     Thu: 31.88 employees  (require 34)
%     Fri: 43.00 employees  (require 43)
%     Sat: 50.00 employees  (require 53)
%
% Which goals, if any, are not met?
%   - G1.1 (Saturday fully staffed at 53) is NOT met (short by 3.00).
%   - G3.2 (Tuesday fully staffed at 28) is NOT met (short by 6.88).
%   - G3.4 (Thursday fully staffed at 34) is NOT met (short by 2.12).
%   - All other goals (Sun, Mon, Wed, Fri) are met exactly.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%```
