#!/bin/bash



for file in ./rudy_all/*; do
    echo "$file ... "
    julia run.jl "$file"
done

