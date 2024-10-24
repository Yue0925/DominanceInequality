#!/bin/bash


# for file in ./instances/*; do
#     echo "$file ... "
#     julia inst_generator.jl "$file"
# done


# for file in ./PolyKP/*.ieq; do
#     echo "$file ... "
#     vint "$file"
# done

# for file in ./PolyKP/*.poi; do
#     echo "$file ... "
#     dim "$file"
# done


for file in ./PolyMaxCUt/*.poi; do
    echo "$file ... "
    julia dominanceFilter.jl "$file"
done


# for file in ./completeOneSwap/*.poi; do
#     echo "$file ... "
#     traf "$file"
# done



