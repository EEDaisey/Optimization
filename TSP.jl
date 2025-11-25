#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#    Author:   Edward E. Daisey
#     Class:   Introduction to Optimization (625.615)
# Professor:   Dr. David Schug
#      Date:   23rd of November, 2025
#     Title:   Module 13 – Traveling Salesperson Problem Heuristic (Simulated
#              Annealing) Using Julia
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Description %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This script implements a solution for the Traveling Salesperson Problem
# (TSP) using Simulated Annealing (SA).
#
# Mathematical Model:
#   • Cities: N = {1, 2, ..., 12}
#   • Distances: d_ij given by a 12×12 matrix D
#   • Tour: a permutation π of {1, ..., 12}
#   • Objective: minimize f(π)
#
# Rather than solving the integer program exactly, we apply Simulated
# Annealing to explore the space of tours and (hopefully) find a near-optimal
# solution.
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

using Random

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Distance Matrix %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# BuildDistanceMatrix()
#   Returns the 12×12 distance matrix for the given TSP instance.
#
#   distMatrix[ i, j ] = distance from city i to city j.

function BuildDistanceMatrix()
    distMatrix = [
        0   7   6   8   3   7   5   5   7  12   4   9;
        7   0   4   8   8   9  11  12   9  12   7   8;
        6   4   0   4   5   9   4  10   8   4   4   3;
        8   8   4   0   7  11  10   2   5  11   9   4;
        3   8   5   7   0  11   7   7  11   5  11  11;
        7   9   9  11  11   0   6   2  10  11   7  10;
        5  11   4  10   7   6   0   2   8   6   6   7;
        5  12  10   2   7   2   2   0  12  11   8  10;
        7   9   8   5  11  10   8  12   0  10   8   9;
        12 12   4  11   5  11   6  11  10   0  11  11;
        4   7   4   9  11   7   6   8   8  11   0   2;
        9   8   3   4  11  10   7  10   9  11   2   0
    ]
    return distMatrix
end

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Objective Function %%%%%%%%%%%%%%%%%%%%%%%%%%%
# ComputeTourLength( route, distMatrix )
#   Input:
#     • route      : Vector of city indices, e.g., [1, 2, 3, 4, ..., 11, 12]
#     • distMatrix : 12×12 distance matrix
#   Output:
#     • Total tour length including the return edge to the start city.

function ComputeTourLength( route::Vector{Int}, distMatrix::Matrix{Int} )
    totalDistance = 0
    numCities = length( route )

    # Sum distances between consecutive cities.
    for k in 1:( numCities - 1 )
        totalDistance += distMatrix[ route[k], route[k + 1] ]
    end

    # Add distance to return to city that one starts at.
    totalDistance += distMatrix[ route[end], route[1] ]

    return totalDistance
end

#%%%%%%%%%%%%%%%%%%%%%%%%%%%% Neighborhood Operator %%%%%%%%%%%%%%%%%%%%%%%%%
# GenerateNeighbor(currentRoute, rng)
#   Produces a neighbor tour using a 2-opt style move:
#     • Choose two positions i < j in {2, 3, ..., numCities}
#       (city 1 is chosen as the starting point for this problem).
#     • Reverse the subsequence from i to j (inclusive).
#
#   This preserves feasibility (a valid Hamiltonian cycle) but changes the
#   structure of the tour.

function GenerateNeighbor( currentRoute::Vector{Int}, rng::AbstractRNG )
    numCities = length( currentRoute )

    # Choose two distinct positions among {2, ..., numCities}.
    i = rand( rng, 2:numCities )
    j = rand( rng, 2:numCities )
    while i == j
        j = rand( rng, 2:numCities )
    end
    if i > j
        i, j = j, i
    end

    neighborRoute = copy( currentRoute )

    # Use the (vector, start, stop) signature.
    reverse!( neighborRoute, i, j )

    return neighborRoute
end

#%%%%%%%%%%%%%%%%%%%%%%%%%%%% Simulated Annealing %%%%%%%%%%%%%%%%%%%%%%%%%%%
# SimulatedAnnealingTsp(distMatrix; ...)
#   Implements the SA metaheuristic for the TSP.
#
#   Keyword parameters:
#     • maxIter     : total SA iterations
#     • initialTemp : starting temperature
#     • finalTemp   : minimum temperature (lower bound)
#     • alpha       : cooling rate (0 < alpha < 1)
#     • rng         : pseudo-random number generator (deterministic for reproducibility)
#
#   Returns:
#     • bestRoute   : best tour found (vector of Int)
#     • bestCost    : total distance of that tour

function SimulatedAnnealingTsp(
    distMatrix::Matrix{Int};
    maxIter::Int = 1_000_000,
    initialTemp::Float64 = 10.0,
    finalTemp::Float64 = 1.0e-3,
    alpha::Float64 = 0.995,
    rng::AbstractRNG = Random.GLOBAL_RNG
)
    numCities = size( distMatrix, 1 )

    #------------------------- Initial Solution -----------------------------#
    # Fix city 1 as the start to remove rotational symmetry.
    remainingCities = collect( 2:numCities )
    shuffle!( rng, remainingCities )
    currentRoute = vcat( 1, remainingCities )

    currentCost = ComputeTourLength( currentRoute, distMatrix )

    bestRoute = copy( currentRoute )
    bestCost = currentCost

    temperature = initialTemp

    #------------------------- Main SA Loop --------------------------------#
    for iteration in 1:maxIter
        # Geometric cooling schedule with a hard lower bound.
        temperature = max( finalTemp, temperature * alpha )

        # Generate neighbor and evaluate.
        neighborRoute = GenerateNeighbor( currentRoute, rng )
        neighborCost = ComputeTourLength( neighborRoute, distMatrix )

        delta = neighborCost - currentCost

        if delta <= 0
            # Always accept an improving move.
            currentRoute = neighborRoute
            currentCost = neighborCost
        else
            # Accept a worse move with Metropolis probability.
            acceptanceProbability = exp( -delta / temperature )
            if rand( rng ) < acceptanceProbability
                currentRoute = neighborRoute
                currentCost = neighborCost
            end
        end

        # Track the best solution seen so far.
        if currentCost < bestCost
            bestCost = currentCost
            bestRoute = copy( currentRoute )
        end
    end

    return bestRoute, bestCost
end

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Driver Function %%%%%%%%%%%%%%%%%%%%%%%%%%%%
# SolveTspWithSimulatedAnnealing()
#   Builds the instance, runs SA, and prints the best tour and its cost.

function SolveTspWithSimulatedAnnealing()
    distMatrix = BuildDistanceMatrix()

    # The PRNG seed for reproducibility.
    rng = MersenneTwister(20000000)
    # Source: https://dl.acm.org/doi/10.1145/272991.272995
    # A bit old, but overall still a solid choice.

    bestRoute, bestCost = SimulatedAnnealingTsp( distMatrix; rng = rng )

    println("%%%%%%%%%%%%%%%%%%%%%%%%% TSP SA Results %%%%%%%%%%%%%%%%%%%%%%%%%")
    println( "Best Tour:" )
    print( "    " )
    for k in 1:length( bestRoute )
        print( bestRoute[k], " -> " )
    end
    println( bestRoute[1] )  # Close the cycle.

    println( "Total Tour Length: ", bestCost )
    println( "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%" )

    return bestRoute, bestCost
end

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Script Entry %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# When run this code as a script, execute the driver. When
# included from the REPL, call SolveTspWithSimulatedAnnealing() manually.

if abspath( PROGRAM_FILE ) == @__FILE__
    SolveTspWithSimulatedAnnealing()
end