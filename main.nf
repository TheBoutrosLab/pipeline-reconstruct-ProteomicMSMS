#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { reconstruct_msms_diaTracer } from './module/reconstruct_msms_diaTracer.nf'
include { calculate_SHA512 } from './module/calculate_SHA512.nf'

/** Read one Bruker dia-PASEF .d directory per acquisition run. */
def readInputRuns(String input_csv) {
    def csv = file(input_csv)
    return Channel.fromPath(csv)
        .splitCsv(header: true)
        .toList()
        .map { rows ->
            if (!rows) throw new IllegalArgumentException("Input CSV has no runs: ${csv}")
            def pairs = [] as Set
            def paths = [] as Set
            def output_names = [] as Set
            rows.collect { row ->
                if (!row.keySet().containsAll(['sample_name', 'fraction_id', 'path'])) {
                    throw new IllegalArgumentException('Input CSV must contain sample_name,fraction_id,path columns')
                }
                def sample = row.sample_name?.trim()
                def fraction = row.fraction_id?.trim()
                if (!(sample ==~ /[A-Za-z0-9][A-Za-z0-9_-]*/)) {
                    throw new IllegalArgumentException("Invalid sample_name: ${row.sample_name}")
                }
                if (!(fraction ==~ /[A-Za-z0-9][A-Za-z0-9_-]*/)) {
                    throw new IllegalArgumentException("Invalid fraction_id: ${row.fraction_id}")
                }
                if (!pairs.add([sample, fraction])) {
                    throw new IllegalArgumentException("Duplicate sample_name/fraction_id: ${sample}/${fraction}")
                }
                if (!output_names.add("${sample}_${fraction}")) {
                    throw new IllegalArgumentException("Output basename collision: ${sample}_${fraction}")
                }
                def raw = row.path?.trim()
                if (!raw) throw new IllegalArgumentException("Missing .d path for ${sample}/${fraction}")
                def d = file(raw.startsWith('/') ? raw : "${csv.parent}/${raw}")
                if (!d.exists() || !d.isDirectory() || !d.name.toLowerCase().endsWith('.d')) {
                    throw new IllegalArgumentException("Missing or invalid .d directory: ${d}")
                }
                if (!paths.add(d.toRealPath().toString())) {
                    throw new IllegalArgumentException(".d directory listed more than once: ${d}")
                }
                tuple(sample, fraction, d)
            }
        }
}

log.info """\
        =====================================================================
        P I P E L I N E   R E C O N S T R U C T   P R O T E O M I C   M S M S
        =====================================================================
        Boutros Lab

        - pipeline: ${workflow.manifest.name} ${workflow.manifest.version}
        - dataset ID: ${params.dataset_id}
        - input CSV: ${params.input_csv}
        - diaTracer JAR: ${params.diatracer_executable}
        - Bruker libraries: ${params.bruker_lib_dir}
        - FragPipe image: ${params.docker_image_fragpipe}
        - output: ${params.output_dir_base}
        - work directory: ${params.work_dir}
        - resource profile: ${params.resource_allocation_profile_tag}
        - diaTracer options:
            writeInter: ${params.diatracer_write_inter}
            deltaApexIM: ${params.diatracer_delta_apex_im}
            deltaApexRT: ${params.diatracer_delta_apex_rt}
            ms1MS2Corr: ${params.diatracer_ms1_ms2_corr}
            massDefectFilter: ${params.diatracer_mass_defect_filter}
            massDefectOffset: ${params.diatracer_mass_defect_offset}
            RFMax: ${params.diatracer_rf_max}
        """.stripIndent()

workflow {
    runs = readInputRuns(params.input_csv)
    reconstruct_msms_diaTracer(runs.flatMap { it }, file(params.diatracer_executable), file(params.bruker_lib_dir))
    calculate_SHA512(reconstruct_msms_diaTracer.out.mzml)
}
