%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Problem:
%   Widget Plus ships widgets from 3 warehouses (Richmond, Atlanta,
%   Baltimore) to 4 customers with limited supply and capped demands.
%   Multiple service, cost, and routing goals are modeled via
%   NONPREEMPTIVE GOAL PROGRAMMING using a weighted sum of deviations.
%
% Optimal Shipping Plan (from the GP model below):
%   Quantities are in units of widgets; rows = warehouses, cols = customers.
%
%                    C1         C2         C3         C4      Total
%   Richmond     297.7273   122.2727     0.0000     0.0000   420.0000
%   Atlanta      118.2727     0.0000   320.0000    91.7273   530.0000
%   Baltimore      0.0000   127.7273     0.0000   212.2727   340.0000
%
% Customer totals (served vs. requested):
%   Customer 1: 416.0000 served  (demand 520, 80% target 416)
%   Customer 2: 250.0000 served  (demand 250, 80% target 200)
%   Customer 3: 320.0000 served  (demand 400, 80% target 320)
%   Customer 4: 304.0000 served  (demand 380, 80% target 304)
%
% Goal Satisfaction (nonpreemptive, weighted-sum GP):
%   G1  (C2 gets full 250)               : MET
%   G2  (Baltimore -> C4 >= 80 units)    : MET (212.27 units)
%   G3.1 (C1 >= 80% demand)              : MET (416 units)
%   G3.2 (C2 >= 80% demand)              : MET (250 > 200)
%   G3.3 (C3 >= 80% demand)              : MET (320 units)
%   G3.4 (C4 >= 80% demand)              : MET (304 units)
%   G4  (Total cost <= 24,750)           : MET (cost = 24,750)
%   G5  (No Atlanta -> C1 shipments)     : NOT MET
%       (118.27 units shipped from Atlanta to Customer 1)
%
% Reproducibility:
%   (1) Save this script as SolveWidgetNonpreemptiveGP.m
%   (2) In MATLAB 2015:  >> SolveWidgetNonpreemptiveGP
%   The printed shipping plan and deviations will match the summary above.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolveWidgetNonpreemptiveGP()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Supply (Richmond, Atlanta, Baltimore)
    supply = [420; 610; 340];
    % Demand (Customers 1..4)
    demand = [520; 250; 400; 380];
    % 80% demand targets
    target80 = 0.80 * demand;
    
    % Cost coefficients c_ij in row-major order:
    %   [x11 x12 x13 x14 x21 x22 x23 x24 x31 x32 x33 x34]
    cvec = [22 17 30 18, 15 35 20 25, 28 21 16 14];
    
    % Goal weights (nonpreemptive GP)
    w1 = 36;   % G1: C2 full
    w2 = 18;   % G2: Balt->C4 >= 80
    w3 = 6;    % G3.1–G3.4: 80% demand
    w4 = 3;    % G4: cost <= 24,750
    w5 = 1;    % G5: no Atlanta->C1
    
    % Variables (28 total):
    %   x(1:12)  = shipping x_ij
    %   x(13:20) = U1, U2, U31, U32, U33, U34, U4, U5
    %   x(21:28) = E1, E2, E31, E32, E33, E34, E4, E5
    numVars = 28;
    
    % Indexing for clarity
    idx_U1  = 13; idx_U2  = 14; idx_U31 = 15; idx_U32 = 16;
    idx_U33 = 17; idx_U34 = 18; idx_U4  = 19; idx_U5  = 20;
    idx_E1  = 21; idx_E2  = 22; idx_E31 = 23; idx_E32 = 24;
    idx_E33 = 25; idx_E34 = 26; idx_E4  = 27; idx_E5  = 28;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Objective f %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Min Z = 36*U1 + 18*U2 + 6*(U31+U32+U33+U34) + 3*E4 + 1*E5
    % (Only detrimental deviations are penalized.)
    f = zeros(numVars, 1);
    f(idx_U1)          = w1;
    f(idx_U2)          = w2;
    f(idx_U31:idx_U34) = w3;   % G3.1–G3.4 under-achievement
    f(idx_E4)          = w4;   % Cost overrun
    f(idx_E5)          = w5;   % Atlanta->C1 violation
    
    %%%%%%%%%%%%%%%%%%%%%%%%% System constraints %%%%%%%%%%%%%%%%%%%%%%%%%%
    % A*x <= b  (Supply limits and demand caps)
    A = zeros(7, numVars);
    b = zeros(7, 1);
    
    % Supply: sum_j x_ij <= supply(i)
    % Richmond: x11+x12+x13+x14 <= 420
    A(1, 1:4) = 1;          b(1) = supply(1);
    % Atlanta:  x21+x22+x23+x24 <= 610
    A(2, 5:8) = 1;          b(2) = supply(2);
    % Baltimore:x31+x32+x33+x34 <= 340
    A(3, 9:12) = 1;         b(3) = supply(3);
    
    % Demand caps: sum_i x_ij <= demand(j)
    % C1: x11+x21+x31 <= 520
    A(4, [1 5 9]) = 1;      b(4) = demand(1);
    % C2: x12+x22+x32 <= 250
    A(5, [2 6 10]) = 1;     b(5) = demand(2);
    % C3: x13+x23+x33 <= 400
    A(6, [3 7 11]) = 1;     b(6) = demand(3);
    % C4: x14+x24+x34 <= 380
    A(7, [4 8 12]) = 1;     b(7) = demand(4);
    
    %%%%%%%%%%%%%%%%%%%%%%%%% Goal equations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Aeq*x = beq
    Aeq = zeros(8, numVars);
    beq = zeros(8, 1);
    
    % G1: C2 full demand: x12 + x22 + x32 + U1 - E1 = 250
    Aeq(1, [2 6 10 idx_U1 idx_E1]) = [1 1 1 1 -1];
    beq(1) = demand(2);
    
    % G2: Baltimore->C4 >= 80: x34 + U2 - E2 = 80
    Aeq(2, [12 idx_U2 idx_E2]) = [1 1 -1];
    beq(2) = 80;
    
    % G3.1: C1 >= 80% demand: x11+x21+x31 + U31 - E31 = 416
    Aeq(3, [1 5 9 idx_U31 idx_E31]) = [1 1 1 1 -1];
    beq(3) = target80(1);
    
    % G3.2: C2 >= 80% demand: x12+x22+x32 + U32 - E32 = 200
    Aeq(4, [2 6 10 idx_U32 idx_E32]) = [1 1 1 1 -1];
    beq(4) = target80(2);
    
    % G3.3: C3 >= 80% demand: x13+x23+x33 + U33 - E33 = 320
    Aeq(5, [3 7 11 idx_U33 idx_E33]) = [1 1 1 1 -1];
    beq(5) = target80(3);
    
    % G3.4: C4 >= 80% demand: x14+x24+x34 + U34 - E34 = 304
    Aeq(6, [4 8 12 idx_U34 idx_E34]) = [1 1 1 1 -1];
    beq(6) = target80(4);
    
    % G4: Total cost <= 24,750 (penalize overrun E4 only):
    %     (cvec * x) + U4 - E4 = 24750
    Aeq(7, 1:12)            = cvec;
    Aeq(7, [idx_U4 idx_E4]) = [1 -1];
    beq(7)                  = 24750;
    
    % G5: No Atlanta->C1 (x21 = 0 ideally, penalize E5):
    %     x21 + U5 - E5 = 0
    Aeq(8, [5 idx_U5 idx_E5]) = [1 1 -1];
    beq(8)                    = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Bounds & Solve %%%%%%%%%%%%%%%%%%%%%%%%%%
    lb = zeros(numVars, 1);
    ub = [];  % implicit upper bounds via A,b and Aeq,beq
    
    x0 = [];
    options = optimset('Display', 'off');
    
    [x_opt, fval, exitflag] = linprog(f, A, b, Aeq, beq, lb, ub, x0, options);
    
    if exitflag ~= 1
        warning('linprog did not converge to an optimal solution (exitflag = %d).', exitflag);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('================ WIDGET PLUS NONPREEMPTIVE GP ================\n');
    fprintf('Optimal objective value Z = %.4f\n\n', fval);
    
    % Shipping plan: reshape x(1:12) into 3x4 (warehouses x customers)
    ship = reshape(x_opt(1:12), [4, 3])';
    warehouses = {'Richmond','Atlanta','Baltimore'};
    
    fprintf('Shipping plan (rows = warehouses, cols = customers 1..4):\n');
    fprintf('             C1        C2        C3        C4     |   Total\n');
    for i = 1:3
        row = ship(i,:);
        fprintf('%-9s %9.4f %9.4f %9.4f %9.4f | %8.4f\n', ...
            warehouses{i}, row(1), row(2), row(3), row(4), sum(row));
    end
    
    % Customer totals
    custTotals = sum(ship, 1)';
    fprintf('\nCustomer totals (served vs demand):\n');
    for j = 1:4
        fprintf('  Customer %d: served = %8.4f, demand = %8.4f\n', ...
            j, custTotals(j), demand(j));
    end
    
    % Deviations
    U = x_opt(13:20);
    E = x_opt(21:28);
    
    fprintf('\nDetrimental deviations used in Z:\n');
    fprintf('  U1  (G1: C2 full demand shortfall)         = %.4f\n', U(1));
    fprintf('  U2  (G2: B->C4 >= 80 shortfall)            = %.4f\n', U(2));
    fprintf('  U31 (G3.1: C1 >= 80%% shortfall)           = %.4f\n', U(3));
    fprintf('  U32 (G3.2: C2 >= 80%% shortfall)           = %.4f\n', U(4));
    fprintf('  U33 (G3.3: C3 >= 80%% shortfall)           = %.4f\n', U(5));
    fprintf('  U34 (G3.4: C4 >= 80%% shortfall)           = %.4f\n', U(6));
    fprintf('  E4  (G4: cost overrun beyond 24,750)       = %.4f\n', E(7));
    fprintf('  E5  (G5: Atlanta->C1 forbidden shipment)   = %.4f\n', E(8));
    
    fprintf('\n===============================================================\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Summary %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Summarize how much is shipped from each warehouse to each customer.
%
%   Richmond  -> C1: 297.7273, C2: 122.2727, C3: 0.0000,  C4: 0.0000
%   Atlanta   -> C1: 118.2727, C2: 0.0000,   C3: 320.0000, C4: 91.7273
%   Baltimore -> C1: 0.0000,   C2: 127.7273, C3: 0.0000,  C4: 212.2727
%
% Customer totals:
%   C1: 416.0000  (>= 80% of 520)
%   C2: 250.0000  (full demand)
%   C3: 320.0000  (>= 80% of 400)
%   C4: 304.0000  (>= 80% of 380)
%
% Which goals are not met?
%   - All service goals G1, G2, G3.1–G3.4 and the cost goal G4 are met.
%   - The only goal not met is G5 (ship no units from Atlanta to Customer 1),
%     because 118.2727 units are shipped along that route.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%```
