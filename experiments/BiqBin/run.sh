#!/bin/bash



for file in ./instances_neg/*.txt; do
    echo "$file ... "
    julia run.jl "$file"
done



for file in ./instances_uni/*.txt; do
    echo "$file ... "
    julia run.jl "$file"
done




for file in ./instances_neqfloat/*.txt; do
    echo "$file ... "
    julia run.jl "$file"
done

