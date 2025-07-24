# Introduction

This is a convinience [Alphafold3](https://github.com/google-deepmind/alphafold3) batch execution pipeline using [Nextflow](https://www.nextflow.io/). optimized for the Unity HPC cluster. The main optimizations are listed below;

- Splits MSA (CPU-heavy) and structure prediction (GPU-heavy) steps and submits jobs accordingly

- Parallel execution and checkpointing

- Smart resource usage. Failed jobs will be automatically submitted again with higher resources including better GPUs when neccessary.

- The pipeline will use GPUs with GPU compute capability > 8 to prevent problems. 

# Usage

**Mandatory arguments**

- `--json_dir`: Path to the directory that contains the input JSON files for Alphafold3. Make sure that the JSON files have the correct structure as described [here.](https://github.com/google-deepmind/alphafold3/blob/main/docs/input.md)

- `--output_dir`: Path to the output directory for the results.

- `--model_dir`: Path to the directory that contains the model paramaters for Alphafold3. Check [here](https://github.com/google-deepmind/alphafold3) to learn how to obtain the model paramaters.

**Optional arguments**

- `#SBATCH` paramaters can be adjusted as desired. The main one to adjust is the `--time` paramater. Increase or decrease as desired. Rest of the paramaters do not need adjusting.

## Example slurm script

Example script provided below. Assuming the name of the script is `main.sh`, it can be submitted with `sbatch main.sh` on the Unity cluster.

**main.sh**
```bash
#!/usr/bin/bash
#SBATCH --job-name=af3_batch                # Job name
#SBATCH --partition=workflow,cpu            # Partition (queue) name
#SBATCH -c 2                                # Number of CPUs
#SBATCH --nodes=1                           # Number of nodes
#SBATCH --mem=10gb                          # Job memory request
#SBATCH --time=1-00:00:00                   # Time limit days-hrs:min:sec
#SBATCH --output=logs/af3_batch_%j.log

module load nextflow/24.10.3

export NXF_OPTS="-Xms1G -Xmx8G"

nextflow run UnityHPC/alphafold3-batch \
    --json_dir /path/to/json_dir \
    --output_dir /path/to/results \
    --model_dir /path/to/model/dir \
    -profile unity \
    -resume
```
