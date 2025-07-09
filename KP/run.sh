#!/bin/bash


# for file in ./instances/*; do
#     echo "$file ... "
#     julia parser.jl "$file"
# done


# for file in ./PolyKP/*.ieq; do
#     echo "$file ... "
#     vint "$file"
# done

# for file in ./PolyKP/*.poi; do
#     echo "$file ... "
#     dim "$file"
# done


# for file in ./instances/*; do
#     echo "$file ... "
#     julia dominanceFilter.jl "$file"
# done


for file in ./completeOneSwap/kp16*; do
    echo "$file ... "
    julia analyse.jl "$file"
done



