#!/bin/bash
#SBATCH --job-name=BiqBin_GDomQCRQP

#SBATCH --nodes=1-1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=40
#SBATCH --ntasks=1 
#SBATCH --mail-type=end
#SBATCH --mail-user=yue.zhang@lipn.univ-paris13.fr
#SBATCH --partition=COMPUTE-SHORT
#SBATCH --output=BiqBin_GDomQCRQP.txt
#SBATCH --error=BiqBin_GDomQCRQP.txt

module load /softs/modules/gurobi/1200


for file in ./instances_neg/*.txt; do
    echo "$file ... "
    srun julia Gurobi_Dom_QCR_QP.jl "$file"
done

for file in ./instances_uni/*.txt; do
    echo "$file ... "
    srun julia Gurobi_Dom_QCR_QP.jl "$file"
done


for file in ./instances_neqfloat/*.txt; do
    echo "$file ... "
    srun julia Gurobi_Dom_QCR_QP.jl "$file"
done



