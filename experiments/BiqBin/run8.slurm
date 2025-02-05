#!/bin/bash
#SBATCH --job-name=BiqBin_CQCRQP

#SBATCH --nodes=1-1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=40
#SBATCH --ntasks=1 
#SBATCH --mail-type=end
#SBATCH --mail-user=yue.zhang@lipn.univ-paris13.fr
#SBATCH --partition=COMPUTE-SHORT
#SBATCH --output=BiqBin_CQCRQP.txt
#SBATCH --error=BiqBin_CQCRQP.txt

module load /softs/modules/gurobi/1200


for file in ./instances_neg/*.txt; do
    echo "$file ... "
    srun julia Cplex_QCR_QP.jl "$file"
done

for file in ./instances_uni/*.txt; do
    echo "$file ... "
    srun julia Cplex_QCR_QP.jl "$file"
done


for file in ./instances_neqfloat/*.txt; do
    echo "$file ... "
    srun julia Cplex_QCR_QP.jl "$file"
done



