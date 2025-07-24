process AF3_FOLD {
    tag "$id"
    label "gpu"
    publishDir "${params.output_dir}/fold", mode: 'copy', pattern: "folds/*"

    input:
    tuple val(id), path("input_a3m/*")
    path af3_db
    path af3_model

    output:
    path "folds/*"

    script:
    """
    module load alphafold3/latest
    mkdir folds
    run_alphafold.py --norun_data_pipeline --input_dir input_a3m --output_dir folds --db_dir $af3_db --model_dir $af3_model
    """
}
