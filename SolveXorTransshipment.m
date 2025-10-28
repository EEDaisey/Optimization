%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Author:   Edward E. Daisey
%     Class:   Introduction to Optimization (625.615)
% Professor:   Dr. David Schug
%      Date:   27th of October, 2025
%     Title:   Xor Computing Transshipment Problem (Question 3)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    SUMMARY    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Network:
%   Plants (supply nodes):
%       01 : Production cost $1750 per unit, Max 500 units
%       10 : Production cost $1550 per unit, Max 600 units
%
%   Distribution hubs (transshipment nodes):
%       A, B, C
%
%   Retailers (demand nodes):
%       CA (California)  demand 350
%       OR (Oregon)      demand 300
%       NY (New York)    demand 250
%       MD (Maryland)    demand 200
%
% Shipping Cost (Plant -> Hub), dollars per unit:
%                A    B    C
%       01 :     4    4    8
%       10 :     5    5    6
%
% Shipping Cost (Hub -> Retailer), dollars per unit:
%                CA   OR   NY   MD
%       A :      13   14   11   10
%       B :      13   11   14    8
%       C :       7    9   14    9
%
% Decision Variables:
%   x(p,h)  = units shipped from plant p in {01,10} to hub h in {A,B,C}
%   y(h,r)  = units shipped from hub h in {A,B,C} to retailer r in {CA,OR,NY,MD}
%
% Cost Structure:
%   Each unit produced at plant p and sent to hub h costs:
%       productionCost(p) + shipPlantHubCost(p,h)
%   Each unit sent from hub h to retailer r costs:
%       shipHubRetailCost(h,r)
%
% Linear Program:
%   Minimize total cost
%       = sum over (plant p, hub h) of [ prodCost(p)+shipPlantHub(p,h) ] * x(p,h)
%       + sum over (hub h, retailer r) of shipHubRetail(h,r) * y(h,r)
%
%   Subject to:
%     (1) Plant capacity:
%         x01A + x01B + x01C <= 500        (Plant 01 capacity)
%         x10A + x10B + x10C <= 600        (Plant 10 capacity)
%
%     (2) Hub flow balance (conservation at hubs):
%         For each hub h:
%             inbound from plants = outbound to retailers
%         Example for Hub A:
%             x01A + x10A = A->CA + A->OR + A->NY + A->MD
%
%     (3) Retailer demand (must be met exactly):
%             A->CA + B->CA + C->CA = 350   (CA)
%             A->OR + B->OR + C->OR = 300   (OR)
%             A->NY + B->NY + C->NY = 250   (NY)
%             A->MD + B->MD + C->MD = 200   (MD)
%
%     (4) Nonnegativity:
%         x(p,h) >= 0, y(h,r) >= 0
%
% Balance check:
%   Total supply available  = 500 + 600 = 1100
%   Total demand required   = 350 + 300 + 250 + 200 = 1100
%   This is a balanced network.
%
% Implementation notes:
%   We solve this cost-minimizing transshipment model with linprog.
%
% Reproducibility:
%   1. Save this file as SolveXorTransshipment.m
%   2. In MATLAB, run:
%          SolveXorTransshipment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SolveXorTransshipment()

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Sets:
    %   Plants: 01, 10
    %   Hubs:   A, B, C
    %   Stores: CA, OR, NY, MD

    % Production cost per unit (dollars per unit)
    % Row order: [01; 10]
    prodCost = [1750; 1550];

    % Plant capacity (units)
    % Row order: [01; 10]
    plantCap = [500; 600];

    % Store demand (units)
    % Row order: [CA; OR; NY; MD]
    demandVec = [350; 300; 250; 200];

    % Shipping cost plant -> hub (dollars per unit)
    % Rows (plants): 01,10
    % Cols (hubs):   A,B,C
    shipPlantHub = [4 4 8;
                    5 5 6];

    % Shipping cost hub -> store (dollars per unit)
    % Rows (hubs):   A,B,C
    % Cols (stores): CA,OR,NY,MD
    shipHubRetail = [13 14 11 10;
                     13 11 14  8;
                      7  9 14  9];

    % Dimensions
    numPlants = 2;     % {01,10}
    numHubs   = 3;     % {A,B,C}
    numStores = 4;     % {CA,OR,NY,MD}

    numX      = numPlants * numHubs;      % 6   (plant -> hub flows)
    numY      = numHubs   * numStores;    % 12  (hub -> store flows)
    numVar    = numX + numY;              % 18  total decision variables

    %%%%%%%%%%%%%%%%%%%%%%%%%% COST VECTOR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % For each plant p and hub h:
    %   totalUnitCost(p,h) = prodCost(p) + shipPlantHub(p,h)
    %
    totalCostPH = zeros(numPlants, numHubs);
    for p = 1:numPlants
        for h = 1:numHubs
            totalCostPH(p,h) = prodCost(p) + shipPlantHub(p,h);
        end
    end

    % costX packs x01A,x01B,x01C,x10A,x10B,x10C in that order
    % costY packs flows from A,B,C to CA,OR,NY,MD in that order
    %
    % We flatten by hub within each plant for costX,
    % and by store within each hub for costY.
    costX = reshape(totalCostPH.', [], 1);     % 6x1
    costY = reshape(shipHubRetail.', [], 1);   % 12x1

    % Final objective cost vector for z = [x variables; y variables]
    costVec = [costX; costY];                  % 18x1

    %%%%%%%%%%%%%%%%%%%%%% CAPACITY (A * z <= b) %%%%%%%%%%%%%%%%%%%%%%%%%
    % Plant 01: x01A + x01B + x01C <= 500
    % Plant 10: x10A + x10B + x10C <= 600
    %
    aMat = zeros(numPlants, numVar);     % 2 x 18
    aMat(1,1:3) = 1;                     % x01A,x01B,x01C
    aMat(2,4:6) = 1;                     % x10A,x10B,x10C
    bVec = plantCap;                     % [500; 600]

    %%%%%%%%%%%%%%%% FLOW BALANCE AT HUBS (aEqHub) %%%%%%%%%%%%%%%%%%%%%%%
    % For each hub h:
    %   inbound from plants = outbound to all stores
    %
    % Variable ordering for z:
    %
    %   z(1)  = x01A    z(2)  = x01B    z(3)  = x01C
    %   z(4)  = x10A    z(5)  = x10B    z(6)  = x10C
    %
    %   z(7)  = aCa     z(8)  = aOr     z(9)  = aNy     z(10) = aMd
    %   z(11) = bCa     z(12) = bOr     z(13) = bNy     z(14) = bMd
    %   z(15) = cCa     z(16) = cOr     z(17) = cNy     z(18) = cMd
    %
    % Hub A:
    %   x01A + x10A - (A->CA + A->OR + A->NY + A->MD) = 0
    %
    % Hub B:
    %   x01B + x10B - (B->CA + B->OR + B->NY + B->MD) = 0
    %
    % Hub C:
    %   x01C + x10C - (C->CA + C->OR + C->NY + C->MD) = 0
    %
    aEqHub = zeros(numHubs, numVar);    % 3 x 18

    % Hub A equation
    % x01A=z(1), x10A=z(4), aCa..aMd=z(7..10)
    aEqHub(1,1)      =  1;
    aEqHub(1,4)      =  1;
    aEqHub(1,7:10)   = -1;

    % Hub B equation
    % x01B=z(2), x10B=z(5), bCa..bMd=z(11..14)
    aEqHub(2,2)      =  1;
    aEqHub(2,5)      =  1;
    aEqHub(2,11:14)  = -1;

    % Hub C equation
    % x01C=z(3), x10C=z(6), cCa..cMd=z(15..18)
    aEqHub(3,3)      =  1;
    aEqHub(3,6)      =  1;
    aEqHub(3,15:18)  = -1;

    bEqHub = zeros(numHubs,1);          % each hub net flow = 0

    %%%%%%%%%%%%%%%% DEMAND SATISFACTION (aEqDem) %%%%%%%%%%%%%%%%%%%%%%%%
    % Retailer CA: A->CA + B->CA + C->CA = 350
    % Retailer OR: A->OR + B->OR + C->OR = 300
    % Retailer NY: A->NY + B->NY + C->NY = 250
    % Retailer MD: A->MD + B->MD + C->MD = 200
    %
    aEqDem = zeros(numStores, numVar);  % 4 x 18

    % CA demand uses aCa=z(7), bCa=z(11), cCa=z(15)
    aEqDem(1,[7 11 15])   = 1;          % CA
    % OR demand uses aOr=z(8), bOr=z(12), cOr=z(16)
    aEqDem(2,[8 12 16])   = 1;          % OR
    % NY demand uses aNy=z(9), bNy=z(13), cNy=z(17)
    aEqDem(3,[9 13 17])   = 1;          % NY
    % MD demand uses aMd=z(10), bMd=z(14), cMd=z(18)
    aEqDem(4,[10 14 18])  = 1;          % MD

    bEqDem = demandVec;                % [350;300;250;200]

    % Stack equality constraints (hub balance + retailer demand)
    aEq = [aEqHub;
           aEqDem];                    % 7 x 18

    bEq = [bEqHub;
           bEqDem];                    % 7 x 1

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% SOLVE LP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Lower bounds: flows >= 0
    lb = zeros(numVar,1);

    % No explicit upper bounds on shipping variables other than plant
    % capacity and demand balance, so we leave ub empty.
    ub = [];

    opts = optimoptions('linprog','Display','none');
    [zSol, zVal] = linprog(costVec, aMat, bVec, aEq, bEq, lb, ub, [], opts);

    % Clean tiny numerical noise for reporting
    zPrint = zSol;
    zPrint(abs(zPrint) < 1e-6) = 0;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REPORT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Unpack plant -> hub flows
    x01A = zPrint(1);
    x01B = zPrint(2);
    x01C = zPrint(3);
    x10A = zPrint(4);
    x10B = zPrint(5);
    x10C = zPrint(6);

    % Unpack hub -> store flows
    aCa  = zPrint(7);   aOr  = zPrint(8);   aNy  = zPrint(9);   aMd  = zPrint(10);
    bCa  = zPrint(11);  bOr  = zPrint(12);  bNy  = zPrint(13);  bMd  = zPrint(14);
    cCa  = zPrint(15);  cOr  = zPrint(16);  cNy  = zPrint(17);  cMd  = zPrint(18);

    % Round total cost to nearest dollar for display
    totalCostRounded = round(zVal);

    fprintf('================ XOR TRANSSHIPMENT REPORT ================\n\n');
    fprintf('Plant -> Hub Flows (Units):\n');
    fprintf('  x01A = %g\n', x01A);
    fprintf('  x01B = %g\n', x01B);
    fprintf('  x01C = %g\n', x01C);
    fprintf('  x10A = %g\n', x10A);
    fprintf('  x10B = %g\n', x10B);
    fprintf('  x10C = %g\n', x10C);
    fprintf('\n');
    fprintf('Hub -> Retailer Flows (Units):\n');
    fprintf('  A->CA = %g,  A->OR = %g,  A->NY = %g,  A->MD = %g\n', aCa, aOr, aNy, aMd);
    fprintf('  B->CA = %g,  B->OR = %g,  B->NY = %g,  B->MD = %g\n', bCa, bOr, bNy, bMd);
    fprintf('  C->CA = %g,  C->OR = %g,  C->NY = %g,  C->MD = %g\n', cCa, cOr, cNy, cMd);
    fprintf('\n');
    fprintf('Total Cost = $%.0f\n\n', totalCostRounded);
    fprintf('==========================================================\n');

end

