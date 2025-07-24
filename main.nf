#!/usr/bin/env nextflow

include { AF3_MSA   } from './modules/af3_msa.nf'
include { AF3_FOLD  } from './modules/af3_fold.nf'

workflow {
    main:

    // Validate inputs
    ch_json_raw = Channel.fromPath("${params.json_dir}/*.json")
        .map { file -> [file.baseName, file] }
    
    ch_af3_db = file(params.af3_db, checkIfExists: true)
    ch_model_dir = file(params.model_dir, checkIfExists: true)
    
    AF3_MSA (
        ch_json_raw,
        ch_af3_db
    )
    msa_json = AF3_MSA.out.af3_json_processed

    ch_msa_json = msa_json
        .collate( 5 )
        .map { v ->
            def ids = v.collect { it[0] }
            def json_paths = v.collect { it[1] }
            [ids, json_paths]
        }

    AF3_FOLD (
        ch_msa_json,
        ch_af3_db,
        ch_model_dir
    )
}