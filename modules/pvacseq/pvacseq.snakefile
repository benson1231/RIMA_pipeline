#!/usr/bin/env python

#-------------------------------
import itertools
import pandas as pd
import re
import os

def pvacseq_targets(wildcards):
    """Generates the targets for this module"""
    ls = []
    for sample in config["VCF"]:
        ls.append("analysis/pvacseq/%s/%s.varscan.somatic.base.snp.Somatic.hc.filter.vep.gx.vcf" % (sample, sample))
        ls.append("analysis/pvacseq/%s/MHC_Class_I/%s.filtered.condensed.ranked.tsv" % (sample, sample))
        ls.append("analysis/pvacseq/%s/MHC_Class_I/%s.filtered.tsv" % (sample, sample))
        ls.append("analysis/pvacseq/%s/MHC_Class_I/%s.all_epitopes.tsv" % (sample, sample))
        ls.append("analysis/pvacseq/%s/MHC_Class_I/%s.tsv" % (sample, sample))
        ls.append("analysis/pvacseq/%s/%s.filtered.condensed.ranked.addSample.tsv" % (sample, sample))
        ls.append("files/pvacseq/Merged.filtered.condensed.ranked.addSample.tsv")
    return ls


def getTumorHLA(wildcards):
    """get the arcasHLA results file for the tumor sample"""
    sample_name = wildcards.sample
    arcasHLA_out_file = "analysis/neoantigen/merge/genotypes.p-group.tsv"
    if not os.path.exists(arcasHLA_out_file):
        print("WES ERROR: %s is not found!" % arcasHLA_out_file)
        return ""
    f = pd.read_csv(arcasHLA_out_file, index_col=0, sep='\t')
    tmp = f.loc[sample_name][0:12].values[0:12]
    hla = ",".join(["HLA-%s" % x for x in tmp if x])
    hla = re.sub('P','',hla)
    #print("HLA Class I for" + " " + sample_name + ":" + " " + hla)
    return hla

def pvacseq_extract(wildcards):
    ls=[]
    for sample in config["VCF"]:
        ls.append("analysis/pvacseq/%s/%s.filtered.condensed.ranked.addSample.tsv" % (sample, sample))
    return ls


rule pvacseq_all:
    input:
        pvacseq_targets

rule neoantigen_annotate_expression:
    input:
        vcf = lambda wildcards: config["VCF"][wildcards.sample],
        expression = "analysis/batchremoval/tpm_matrix.batch"
    output:
        "analysis/pvacseq/{sample}/{sample}.varscan.somatic.base.snp.Somatic.hc.filter.vep.gx.vcf"
    params:
        sample_name = lambda wildcards: [wildcards.sample],
        tmp = "analysis/pvacseq/{sample}/{sample}.tmp",
        path="set +eu;source activate %s" % config['pvacseq_root']
    benchmark:
        "benchmarks/pvacseq/{sample}.neoantigen_vep_annotate.benchmark"
    # conda: "../envs/pvacseq_env.yml"
    shell:
        """tr ',' '\t' < {input.expression} | awk '{{if($1 != "Gene_ID") gsub(/\.[0-9]+/,"",$1)}}1' OFS='\t' > {params.tmp} """
        """ && {params.path}; vcf-expression-annotator {input.vcf} {params.tmp} custom transcript --id-column Gene_ID --expression-column {params.sample_name} -s {params.sample_name} -o {output}"""
        """ && rm {params.tmp}"""

rule neoantigen_pvacseq:
    """NOTE: neoantigen's pvacseq is not available on CONDA
    MUST either be installed in base system/docker container"""
    input:
        vcf="analysis/pvacseq/{sample}/{sample}.varscan.somatic.base.snp.Somatic.hc.filter.vep.gx.vcf",
    output:
        main = "analysis/pvacseq/{sample}/MHC_Class_I/{sample}.filtered.condensed.ranked.tsv",
        #OTHERS:
        filtered = "analysis/pvacseq/{sample}/MHC_Class_I/{sample}.filtered.tsv",
        all_epitopes = "analysis/pvacseq/{sample}/MHC_Class_I/{sample}.all_epitopes.tsv",
        tsv = "analysis/pvacseq/{sample}/MHC_Class_I/{sample}.tsv",
        addSample = "analysis/pvacseq/{sample}/{sample}.filtered.condensed.ranked.addSample.tsv"
    params:
        ##normal = "CTTTP07N1",#lambda wildcards: config['runs'][wildcards.run][0],
        tumor = lambda wildcards: [wildcards.sample],
        iedb = config['neoantigen_iedb_mhcI'],
        HLA = getTumorHLA,
        callers=config['neoantigen_callers'] if config['neoantigen_callers'] else "MHCflurry NetMHCcons MHCnuggetsII",
        epitope_lengths=config['neoantigen_epitope_lengths'] if config['neoantigen_epitope_lengths'] else "8,9,10,11",
        output_dir = "analysis/pvacseq/{sample}",
        path="set +eu;source activate %s" % config['pvacseq_root']
    log:
        "logs/pvacseq/{sample}.neoantigen_pvacseq.log"
    benchmark:
        "benchmarks/pvacseq/{sample}.neoantigen_pvacseq.benchmark"
    # conda: "../envs/pvacseq_env.yml"
    shell:
        """{params.path}; pvacseq run {input.vcf} {params.tumor} {params.HLA} {params.callers} {params.output_dir} -e {params.epitope_lengths} -t {threads}  --iedb-install-directory {params.iedb} 2> {log} || true """
        """ && touch {output.main} """   ### to avoid there is no output from this run for some samples
        """ && touch {output.filtered} """
        """ && touch {output.all_epitopes} """
        """ && touch {output.tsv} """
        """ && awk '{{print ARGV[1]}}' {output.main} | awk  '{{print $3}}' -FS '\t' | paste - {output.main}| awk  'NR==1{{$1="Sample"}}1'-FS '\t'  OFS='\t' > {output.addSample}"""

rule pvacseq_plot:
    input:
        pvacseq_extract
    output:
        merged_filter = "files/pvacseq/Merged.filtered.condensed.ranked.addSample.tsv",
        pat_epitopes = "files/pvacseq/Patient_count_epitopes_plot.png",
        epitope_affinity = "files/pvacseq/epitopes_affinity_plot.png",
        hla_epitope = "files/pvacseq/HLA_epitopes_fraction_plot.png",
    log:
        "logs/pvacseq/immune_pvacseq_plot.log"
    message:
        "Processing pvacseq result"
    benchmark:
        "benchmarks/pvacseq/pvacseq_plot.benchmark"
    params:
        outpath = "files/pvacseq/",
        path="set +eu;source activate %s" % config['stat_root'],
        multiqc = " files/multiqc/neoantigen/",
        meta = config['metasheet'],
        condition = config['designs']
    conda: "../../envs/stat_perl_r.yml"
    shell:
        """cat {input} | sed '1 !{{/Sample/d;}}' > {output.merged_filter} """  
        """ && {params.path}; Rscript src/pvacseq/pvacseq_plot.R --input {output.merged_filter} --outdir {params.outpath} --meta {params.meta} --multiqc {params.multiqc} --condition {params.condition}"""     

        


  
