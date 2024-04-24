#!/usr/bin/env nextflow

// Define input parameters to be used.
params.data = "$baseDir" 

// Create a channel to read in the data file paths.
reads_ch = channel.fromFilePairs(params.data + '/*{1,2}.fastq.gz')

// Step 1: Creating a fasta assembly using skesa as our tool of choice
process assemble {
    // Define the inputs to the process - in this case, two paired trimmed fastq files.
    input:
    tuple val(pairId), file(read1)

    // Define the outputs of the process - in this case, an assembled fasta file.
    output:
    file("${pairId}_asm.fna")

    // The actual command to run the tool of choice - in this case, spades.
    script:
    """
    skesa --reads ${read1[0]} ${read1[1]} --contigs_out ${pairId}_asm.fna
    """
}

// Step 2: Quality assessment of the assembly using quast as our tool of choice; this is the first of our parallel operations
process quast {
    // Define the inputs to the process - in this case, one assembly fasta file.
    input:
    file assembly_fna

    // Define the outputs of the process - in this case, the text file from quast.
    output:
    file("quast_result/report.txt")

    // The actual command to run the tool of choice - in this case, quast.
    script:
    """
    quast.py ${assembly_fna} -o quast_result
    """
}

// Step 3: Genotyping using mlst as our tool of choice; this is the second of our parallel operations
process mlst {
    // Define the inputs to the process - in this case, one assembly fasta file.
    input:
    file assembly_fna

    // Define the outputs of the process - in this case, the tsv file from mlst.
    output:
    file("MLST_Summary.tsv")

    // The actual command to run the tool of choice - in this case, mlst.
    script:
    """
    mlst ${assembly_fna} > MLST_Summary.tsv
    """
}

// Define the workflow execution
workflow {
    // Execute the processes in the correct order.
    // By default, in nextflow, all processes are run in parallel, depending on the dependencies.
    // Because quast and mlst are taking the outputs from the first process assemble, those two processes will be run in parallel.    
    assemble(reads_ch)
    quast(assemble.out)
    mlst(assemble.out)
}