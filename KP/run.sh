#!/bin/bash


# for file in ./instances/*; do
#     echo "$file ... "
#     julia parser.jl "$file"
# done


# for file in ./ieqOutput/*.ieq; do
#     echo "$file ... "
#     vint "$file"
# done


# for file in ./instances/*; do
#     echo "$file ... "
#     julia dominanceFilter.jl "$file"
# done


for file in ./dominanceFilter/*.poi; do
    echo "$file ... "
    traf "$file"
done