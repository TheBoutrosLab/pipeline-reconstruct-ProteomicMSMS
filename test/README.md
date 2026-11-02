# diaTracer nf-test integration case

The single case runs one representative Bruker dia-PASEF `.d` acquisition through diaTracer. The `.d` directory, licensed JAR, and MSFragger Bruker native library are supplied locally; neither is distributed with this repository.

On the machine that will run the test, initialize the repository dependencies with `git submodule update --init --recursive`. Copy `.env-template` to the Git-ignored `.env`, set `TEST_DATA_DIR`, place the compatible MSFragger `ext/bruker` directory at `${TEST_DATA_DIR}/MSFragger-4.4.1/ext/bruker` (or adjust `bruker_lib_dir` in the test config), and edit `test/test-integration-diaTracer/input.csv` to point to a representative `.d` directory beneath `TEST_DATA_DIR`. The CSV has one row. From a Slurm job with nf-test, Nextflow, and the container runtime available, run:

```bash
bash test/run-nftest.sh test-integration-diaTracer
```

The runner keeps output and work files under `/scratch/$SLURM_JOB_ID/test-integration-diaTracer`. Check that it publishes one nonempty `_diatracer.mzML` and a matching `.sha512` file, and verify the checksum with `sha512sum -c`. The repository's `input/input.csv` is a header-only template and is not the test fixture.
