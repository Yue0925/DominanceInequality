#!/bin/bash


# for file in ./instances/*; do
#     echo "$file ... "
#     julia inst_generator.jl "$file"
# done


# for file in ./PolyMaxCut/*.ieq; do
#     echo "$file ... "
#     vint "$file"
# done

# for file in ./PolyMaxCUt/*.poi; do
#     echo "$file ... "
#     dim "$file"
# done


# for file in ./PolyMaxCut/*.poi; do
#     echo "$file ... "
#     julia dominanceFilter.jl "$file"
# done


for file in ./ALLswap/*.poi; do
    echo "$file ... "
    julia dominanceFilter.jl "$file"
done


# for file in ./swap/*.poi; do
#     echo "$file ... "
#     julia dominanceFilter.jl "$file"
# done



# for file in ./leftright/*.poi; do
#     echo "$file ... "
#     julia dominanceFilter.jl "$file"
# done



# for file in ./insertionleft/*.poi; do
#     echo "$file ... "
#     julia dominanceFilter.jl "$file"
# done


# for file in ./insertionright/*.poi; do
#     echo "$file ... "
#     julia dominanceFilter.jl "$file"
# done



# for file in ./ALLinsertionleft/*.poi; do
#     echo "$file ... "
#     julia dominanceFilter.jl "$file"
# done



# for file in ./ALLinsertionright/*.poi; do
#     echo "$file ... "
#     julia dominanceFilter.jl "$file"
# done


# for file in ./completeOneSwap/*.poi; do
#     echo "$file ... "
#     traf "$file"
# done



