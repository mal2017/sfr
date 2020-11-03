#!/usr/bin/env nextflow

nextflow.enable.dsl=1

version = '1.0'

params.x = 'chrX'
params.y = 'chrY'
params.ref = ''
params.fq = ''
params.n_reads_for_dev = 1000
params.dev = false
params.outfile = './results.csv'

log.info """\
         S E X - F R O M - R E A D S
         =============================
         female-specific contig: ${params.x}
         male-specific contig: ${params.y}
         fastq/pattern : ${params.fq}
         outfile: ${params.outfile}
         """
         .stripIndent()


bt2_idx = params.ref
male_chrom = params.y
female_chrom = params.x
n_reads_for_dev = params.n_reads_for_dev
fq_ch = Channel.fromFilePairs( params.fq ).ifEmpty({ error 'Provide path or pattern.' })

process alignment {
		conda 'bowtie2'

		cpus 2

		input:
		tuple val(sample), path(reads) from fq_ch
		val(idx) from bt2_idx

    output:
    tuple sample,file('aln.sam') into x_aln_ch, y_aln_ch

		script:
		if(params.dev)
    	"""
    	bowtie2 -x ${bt2_idx} -u ${n_reads_for_dev} -U ${reads} -k 1 -p ${task.cpus} > aln.sam
    	"""
		else
			"""
			bowtie2 -x ${bt2_idx} -U ${reads} -k 1 -p ${task.cpus} > aln.sam
			"""
}

process y_reads {
		conda 'samtools'

		input:
		tuple val(sample), path(sam_file) from y_aln_ch

		output:
		tuple val(sample),stdout into y_result_ch

		"""
		samtools view ${sam_file} | awk '(\$3=="${male_chrom}")' | wc -l | tr -d '\n'
		"""

}

process x_reads {
		conda 'samtools'

		input:
		tuple val(sample), path(sam_file) from x_aln_ch

		output:
		tuple val(sample),stdout into x_result_ch

		"""
		samtools view ${sam_file} | awk '(\$3=="${female_chrom}")' | wc -l | tr -d '\n'
		"""
}

x_result_ch
	.join(y_result_ch)
	.map {it.flatten()}
	.map {it[3] = (it[2] as Double).div([it[1] as Double ]); it}
	.map { "${it[0]},${it[1]},${it[2]}" }
	.collectFile(name:params.outfile, newLine: true, sort:true)


workflow.onComplete {
    println "sex-from-reads completed!"
    println "Time elapsed: $workflow.duration"
}
