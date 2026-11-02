/** Write a SHA-512 sidecar for one reconstructed mzML. */
process calculate_SHA512 {
    container params.docker_image_fragpipe
    label 'process_low'
    ext log_dir: { "${sample_name}/${fraction_id}/${task.process.replace(':', '/')}/task-${task.index}-attempt-${task.attempt}" }
    publishDir path: "${params.output_dir_base}/output/diaTracer", mode: 'copy', pattern: '*.sha512'

    input:
        tuple val(sample_name), val(fraction_id), path(mzml_file)

    output:
        path "${mzml_file.name}.sha512", emit: checksum

    script:
        """
        set -euo pipefail
        sha512sum -- "${mzml_file}" > "${mzml_file.name}.sha512"
        """
}
