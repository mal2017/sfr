# sex-from-reads

Estimation of Y/X read counts for quick and dirty sex determination.

## dependencies

- nextflow
- conda
- a bt2 index

If multiple fastqs are associated with one sample, they will only be aligned
together if they share a basename. Otherwise, the X/Y counts in the result files
can be processed after separately.

## quickstart

```
nextflow run \
	--ref path/to/{bt2_idx_prefix} \
	--fq 'some/pattern*.fastq.gz' \
	sfr.nf
```

If running `--fq` with a pattern, should be quoted. For single files a
plain path is fine.

## results

a `.csv` file with the following format:

```
sample, X reads,Y reads, Y/X ratio
```

PE reads are aligned as SE. Sample name is pulled from fastq names.

## other options

```
--Y [name for male-specific chrom]
--X [name for female-specific chrom]
--dev [if flagged, only run {n_reads_for dev} reads]
--n_reads_for_dev [default: 1000]
--outfile [default: ./results.csv]
```
