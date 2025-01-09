#!/bin/bash



for file in ./instances_neg/*.txt; do
    echo "$file ... "
    julia run.jl "$file"
done

