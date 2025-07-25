#!/usr/bin/env nextflow

/*
================================================================================
    Validate inputs and print help message
================================================================================
*/
if (params.help) {
    log.info """
    Usage:
    nextflow run UnityHPC/alphafold3-batch --json_dir <path> --model_dir <path> --output_dir <path>
    
    Required parameters:
    --json_dir    Path to directory containing JSON files
    --model_dir   Path to directory containing model files  
    --output_dir  Path to output directory
    """
    exit 0
}

// Check required parameters are provided
def checkRequiredParams() {
    def missing = []
    if (!params.json_dir) missing.add('--json_dir')
    if (!params.model_dir) missing.add('--model_dir') 
    if (!params.output_dir) missing.add('--output_dir')
    
    if (missing.size() > 0) {
        log.error "Missing required parameters: ${missing.join(', ')}"
        log.info "Use --help for usage information"
        exit 1
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { AF3_MSA               } from './modules/af3_msa.nf'
include { AF3_FOLD              } from './modules/af3_fold.nf'
include { validateJsonStructure } from './lib/jsonvalidation.groovy'

/*
================================================================================
    Workflow
================================================================================
*/
workflow {
    main:

    // Validate params
    checkRequiredParams()

    // Validate JSON structure
    nameMapping = validateJsonStructure(params.json_dir)
    
    log.info "All validations passed! Found ${nameMapping.size()} JSON files with unique names"

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
        .collate( params.inf_batch )
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