#!/bin/bash


for file in ./instances/*; do
    echo "$file ... "
    julia parser.jl "$file"
done