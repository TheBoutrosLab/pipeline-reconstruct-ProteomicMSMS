/** Reconstruct pseudo-MS/MS from one dia-PASEF .d directory. */
process reconstruct_msms_diaTracer {
    container params.docker_image_fragpipe
    label 'process_high'
    stageInMode 'copy' // diaTracer writes its mzML beside the input .d directory.
    ext log_dir: { "${sample_name}/${fraction_id}/${task.process.replace(':', '/')}/task-${task.index}-attempt-${task.attempt}" }

    publishDir path: "${params.output_dir_base}/output/diaTracer", mode: 'copy', pattern: '*.mzML'

    input:
        tuple val(sample_name), val(fraction_id), path(d_dir, name: 'input.d')
        path executable, name: 'diaTracer.jar'
        path bruker_lib_dir, name: 'bruker_lib'

    output:
        tuple val(sample_name), val(fraction_id), path("${sample_name}_${fraction_id}_diatracer.mzML"), emit: mzml

    script:
        def heap_mb = Math.max(256, (task.memory.toMega() * 0.8) as int)
        """
        set -euo pipefail
        if [ ! -f bruker_lib/libtimsdata-2-21-0-4.so ]; then
            echo "diaTracer requires libtimsdata-2-21-0-4.so from the MSFragger ext/bruker directory" >&2
            exit 1
        fi
        java -Dlibs.bruker.dir=bruker_lib -Djna.library.path=bruker_lib -Xmx${heap_mb}m -XX:ActiveProcessorCount=${task.cpus} \
            -jar diaTracer.jar \
            --dFilePath "\${PWD}/input.d" --workDir "\${PWD}" --threadNum ${task.cpus} \
            --writeInter ${params.diatracer_write_inter} \
            --deltaApexIM ${params.diatracer_delta_apex_im} \
            --deltaApexRT ${params.diatracer_delta_apex_rt} \
            --ms1MS2Corr ${params.diatracer_ms1_ms2_corr} \
            --massDefectFilter ${params.diatracer_mass_defect_filter} \
            --massDefectOffset ${params.diatracer_mass_defect_offset} \
            --RFMax ${params.diatracer_rf_max}
        mapfile -t spectra < <(find . -maxdepth 2 -type f -iname '*diatracer.mzml' -print)
        if [ "\${#spectra[@]}" -ne 1 ]; then
            echo "Expected exactly one diaTracer mzML, found \${#spectra[@]}" >&2
            exit 1
        fi
        mv -- "\${spectra[0]}" "${sample_name}_${fraction_id}_diatracer.mzML"
        """
}
