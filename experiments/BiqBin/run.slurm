#!/bin/bash
#SBATCH --job-name=BiqBin

#SBATCH --nodes=1-1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=40
#SBATCH --ntasks=1 
#SBATCH --mail-type=end
#SBATCH --mail-user=yue.zhang@lipn.univ-paris13.fr
#SBATCH --partition=COMPUTE-SHORT
#SBATCH --output=BiqBin_Out.txt
#SBATCH --error=BiqBin_Err.txt


for file in ./instances_neg/*.txt; do
    echo "$file ... "
    srun julia run.jl "$file"
done


