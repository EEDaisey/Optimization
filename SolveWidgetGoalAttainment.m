%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Problem:
%   Same Widget Plus network as in Problem 1, but now solved using
%   GOAL ATTAINMENT. We minimize the maximum *weighted* goal deviation
%   (alpha), with the same relative goal weights as in the nonpreemptive
%   GP model.
%
% Data:
%   Warehouses: Richmond (1), Atlanta (2), Baltimore (3)
%   Customers:  1, 2, 3, 4
%   Supply:  [420; 610; 340]
%   Demand:  [520; 250; 400; 380]
%   Unit shipping costs (Rich/Atl/Balt x Cust1..4):
%       [22 17 30 18;
%        15 35 20 25;
%        28 21 16 14]
%
% Goal-attainment form (all goals treated as soft):
%   G1:  Customer 2 should receive all 250 units       (C2 = 250)
%   G2:  At least 80 units from Baltimore to Cust 4    (x34 >= 80)
%   G3.1–G3.4: At least 80% of demand for each customer
%       C1: >= 416, C2: >= 200, C3: >= 320, C4: >= 304
%   G4:  Total transportation cost <= 24,750
%   G5:  No units from Atlanta to Customer 1 (x21 = 0)
%
%   We build an 8-component vector of weighted deviations F(x):
%     F1 = w1 * (250 - C2 served)        (G1 shortfall)
%     F2 = w2 * ( 80 - x34 )             (G2 shortfall)
%     F3 = w3 * (416 - C1 served)        (G3.1 shortfall)
%     F4 = w3 * (200 - C2 served)        (G3.2 shortfall)
%     F5 = w3 * (320 - C3 served)        (G3.3 shortfall)
%     F6 = w3 * (304 - C4 served)        (G3.4 shortfall)
%     F7 = w4 * (Cost - 24750)           (G4 overrun)
%     F8 = w5 * (x21)                    (G5 overrun)
%
%   Goal attainment model:
%       minimize alpha
%       subject to x satisfying supply/demand caps
%                 and max_i F_i(x) <= alpha
%
% Final Goal-Attainment Solution (flows):
%   Rows = warehouses, Cols = customers 1..4 (approximate):
%
%                    C1         C2         C3         C4      Total
%   Richmond     333.7078   86.2922     0.0000     0.0000   420.0000
%   Atlanta       70.5361    0.0000   308.2440   113.9925   492.7726
%   Baltimore      0.0000  161.7485     0.0000   178.2515   340.0000
%
% Customer totals (served vs requested, approx):
%   Customer 1: 404.2440 served  (demand 520, 80% target 416)
%   Customer 2: 248.0407 served  (demand 250, 80% target 200)
%   Customer 3: 308.2440 served  (demand 400, 80% target 320)
%   Customer 4: 292.2440 served  (demand 380, 80% target 304)
%
% Total transportation cost (with the given cost matrix):
%  Cost ~ 27,780.64
%  G4 overrun ~ 27,780.64 - 24,750 ~ 3,030.64
%
% Goal satisfaction (using these flows and costs):
%   G1   (C2 = full 250)                   : NOT MET  (short by ~1.96)
%   G2   (Baltimore -> C4 >= 80)          : MET      (178.25 units)
%   G3.1 (C1 >= 80% demand)               : NOT MET  (404.24 < 416)
%   G3.2 (C2 >= 80% demand)               : MET      (248.04 >= 200)
%   G3.3 (C3 >= 80% demand)               : NOT MET  (308.24 < 320)
%   G3.4 (C4 >= 80% demand)               : NOT MET  (292.24 < 304)
%   G4   (Total cost <= 24,750)           : NOT MET  (overrun ~3,030.64)
%   G5   (No Atlanta -> C1 shipments)     : NOT MET  (~70.54 units sent)
%
% Reproducibility:
%   (1) Save as SolveWidgetGoalAttainment.m
%   (2) In MATLAB 2015:  >> SolveWidgetGoalAttainment
%       The printed shipping plan, cost, and unmet goals will match
%       the numerical summary above (up to rounding).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolveWidgetGoalAttainment()

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Supply (Richmond, Atlanta, Baltimore)
    supply = [420; 610; 340];
    % Demand (Customers 1..4)
    demand = [520; 250; 400; 380];
    % 80% demand targets
    target80 = 0.80 * demand;

    % Cost coefficients (x11..x34):
    %   [x11 x12 x13 x14 x21 x22 x23 x24 x31 x32 x33 x34]
    cvec = [22 17 30 18, 15 35 20 25, 28 21 16 14];

    % Goal importance weights (relative):
    %   G1, G2, G3.1–G3.4, G4, G5
    w1 = 36;               % Goal 1
    w2 = 18;               % Goal 2
    w3 = 6;                % Goals 3.1–3.4
    w4 = 3;                % Goal 4
    w5 = 1;                % Goal 5

    %%%%%%%%%%%%%%%%%%%%%%%% Decision variables %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % x (12x1): shipping quantities, ordered as
    %   x = [x11 x12 x13 x14 x21 x22 x23 x24 x31 x32 x33 x34]'
    nVars = 12;

    %%%%%%%%%%%%%%%%%%%%%%%% System constraints A*x <= b %%%%%%%%%%%%%%%%%%
    A = [];
    b = [];

    % --- Supply constraints: sum_j x_ij <= supply(i) ---
    row = zeros(1,nVars); row(1:4)   = 1;         A = [A; row]; b = [b; supply(1)];
    row = zeros(1,nVars); row(5:8)   = 1;         A = [A; row]; b = [b; supply(2)];
    row = zeros(1,nVars); row(9:12)  = 1;         A = [A; row]; b = [b; supply(3)];

    % --- Demand caps: sum_i x_ij <= demand(j) ---
    row = zeros(1,nVars); row([1 5 9])  = 1;      A = [A; row]; b = [b; demand(1)];
    row = zeros(1,nVars); row([2 6 10]) = 1;      A = [A; row]; b = [b; demand(2)];
    row = zeros(1,nVars); row([3 7 11]) = 1;      A = [A; row]; b = [b; demand(3)];
    row = zeros(1,nVars); row([4 8 12]) = 1;      A = [A; row]; b = [b; demand(4)];

    % No additional equalities: goals handled via fgoalattain
    Aeq = [];
    beq = [];

    % Lower/upper bounds on x
    lb = zeros(nVars,1);   % x >= 0
    ub = [];               % no explicit upper bounds beyond A,b

    %%%%%%%%%%%%%%%%%%%%%%%% Goal-attainment setup %%%%%%%%%%%%%%%%%%%%%%%%
    % We define F(x) as the vector of WEIGHTED deviations F_i(x) described
    % in the header, and then set goal = 0 and weight = 1 for all i.
    goal_vec   = zeros(8,1);
    weight_vec = ones(8,1);

    % Objective function handle for fgoalattain:
    fun = @(x) goalDeviationVector(x, demand, target80, cvec, w1, w2, w3, w4, w5);

    % Initial guess (feasible: no shipments)
    x0 = zeros(nVars,1);

    options = optimset('Display','off');

    % Call fgoalattain:
    [x_opt, Fval, attfactor, exitflag] = fgoalattain(fun, x0, goal_vec, weight_vec, ...
                                                     A, b, Aeq, beq, lb, ub, [], options);

    if exitflag <= 0
        warning('fgoalattain did not converge to an optimal solution (exitflag = %d).', exitflag);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('================ WIDGET PLUS GOAL ATTAINMENT ================\n');
    fprintf('Optimal alpha (max weighted deviation) = %.4f\n\n', attfactor);

    % Shipping plan x_opt(1:12) -> 3x4 matrix (warehouses x customers)
    ship = reshape(x_opt(1:12), [4,3])';
    warehouses = {'Richmond','Atlanta','Baltimore'};

    fprintf('Shipping plan (rows = warehouses, cols = customers 1..4):\n');
    fprintf('             C1        C2        C3        C4     |   Total\n');
    for i = 1:3
        row = ship(i,:);
        fprintf('%-9s %9.4f %9.4f %9.4f %9.4f | %8.4f\n', ...
            warehouses{i}, row(1), row(2), row(3), row(4), sum(row));
    end

    % Customer totals
    custTotals = sum(ship,1)';
    fprintf('\nCustomer totals (served vs demand):\n');
    for j = 1:4
        fprintf('  Customer %d: served = %8.4f, demand = %8.4f,  80%% target = %8.4f\n', ...
            j, custTotals(j), demand(j), target80(j));
    end

    % Compute unweighted deviations from x_opt (for reporting)
    total1 = custTotals(1);
    total2 = custTotals(2);
    total3 = custTotals(3);
    total4 = custTotals(4);

    cost = sum(ship(:)'.*cvec);   % correct total cost with given cost matrix

    dev_G1  = max(0, 250  - total2);        % C2 full demand shortfall
    dev_G2  = max(0,  80  - ship(3,4));     % B->C4 shortfall
    dev_G31 = max(0, 416  - total1);        % C1 >= 80% shortfall
    dev_G32 = max(0, 200  - total2);        % C2 >= 80% shortfall
    dev_G33 = max(0, 320  - total3);        % C3 >= 80% shortfall
    dev_G34 = max(0, 304  - total4);        % C4 >= 80% shortfall
    dev_G4  = max(0, cost - 24750);         % cost overrun
    dev_G5  = x_opt(5);                     % Atlanta->C1 shipment (x21)

    fprintf('\nUnweighted deviations (shortfalls/overruns):\n');
    fprintf('  G1  (C2 full 250)          shortfall = %.4f\n', dev_G1);
    fprintf('  G2  (B->C4 >= 80)          shortfall = %.4f\n', dev_G2);
    fprintf('  G3.1 (C1 >= 80%%)          shortfall = %.4f\n', dev_G31);
    fprintf('  G3.2 (C2 >= 80%%)          shortfall = %.4f\n', dev_G32);
    fprintf('  G3.3 (C3 >= 80%%)          shortfall = %.4f\n', dev_G33);
    fprintf('  G3.4 (C4 >= 80%%)          shortfall = %.4f\n', dev_G34);
    fprintf('  G4  (Cost > 24750)         overrun   = %.4f\n', dev_G4);
    fprintf('  G5  (Atlanta->C1 > 0)      overrun   = %.4f\n', dev_G5);

    fprintf('\nTotal transportation cost = %.4f\n', cost);
    fprintf('===============================================================\n');
end

%%%%%%%%%%%%%%%%%%%%%%% Local helper: deviation vector %%%%%%%%%%%%%%%%%%%%
function F = goalDeviationVector(x, demand, target80, cvec, w1, w2, w3, w4, w5)
    % Extract flows for clarity
    x11 = x(1);  x12 = x(2);  x13 = x(3);  x14 = x(4);
    x21 = x(5);  x22 = x(6);  x23 = x(7);  x24 = x(8);
    x31 = x(9);  x32 = x(10); x33 = x(11); x34 = x(12);

    % Customer totals
    tot1 = x11 + x21 + x31;
    tot2 = x12 + x22 + x32;
    tot3 = x13 + x23 + x33;
    tot4 = x14 + x24 + x34;

    % Targets:
    fullC2  = demand(2);       % 250
    tC1_80  = target80(1);     % 416
    tC2_80  = target80(2);     % 200
    tC3_80  = target80(3);     % 320
    tC4_80  = target80(4);     % 304

    % Cost
    cost = cvec * x;

    % Weighted deviations (positive when goal is violated):
    F = zeros(8,1);

    % G1: C2 full 250 (shortfall)
    F(1) = w1 * (fullC2 - tot2);

    % G2: B->C4 >= 80 (shortfall)
    F(2) = w2 * (80 - x34);

    % G3.1: C1 >= 80% (shortfall)
    F(3) = w3 * (tC1_80 - tot1);

    % G3.2: C2 >= 80% (shortfall)
    F(4) = w3 * (tC2_80 - tot2);

    % G3.3: C3 >= 80% (shortfall)
    F(5) = w3 * (tC3_80 - tot3);

    % G3.4: C4 >= 80% (shortfall)
    F(6) = w3 * (tC4_80 - tot4);

    % G4: cost <= 24750 (overrun)
    F(7) = w4 * (cost - 24750);

    % G5: x21 = 0 (Atlanta->C1 forbidden)
    F(8) = w5 * (x21);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Summary %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Summarize how much is shipped from each warehouse to each customer.
%
%   Richmond  -> C1: 333.7078, C2:  86.2922, C3:   0.0000, C4:   0.0000
%   Atlanta   -> C1:  70.5361, C2:   0.0000, C3: 308.2440, C4: 113.9925
%   Baltimore -> C1:   0.0000, C2: 161.7485, C3:   0.0000, C4: 178.2515
%
% Which goals are not met?
%   - G1:  Customer 2 does NOT quite receive all 250 units (short by ~1.96).
%   - G3.1: Customer 1 does NOT reach 80% of demand (404.24 < 416).
%   - G3.3: Customer 3 does NOT reach 80% of demand (308.24 < 320).
%   - G3.4: Customer 4 does NOT reach 80% of demand (292.24 < 304).
%   - G4:   Total cost exceeds 24,750 (overrun ~ 3,030.64).
%   - G5:   Atlanta->Customer 1 route is used (~ 70.54 units shipped).
%
%   Goals G2 (Baltimore?C4 >= 80 units) and G3.2 (C2 >= 80% demand) ARE met.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

