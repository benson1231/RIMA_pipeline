#!/usr/bin/env python

#-------------------------------Immune Repertoire Cohort -----------------------------#
###############-------------Module to draw cohort plot--------------------##############

metadata = pd.read_csv(config["metasheet"], index_col=0, sep=',')
options = [config["Treatment"],config["Control"]]
design = config["design"]
treatment = config["Treatment"]
control = config["Control"] 

def immune_repertoire_cohort_targets(wildcards):
    ls = []
    
    ls.append("analysis/trust4/%s_%s_vs_%s_TRUST4_BCR_light.txt" % (design,treatment,control))
    ls.append("analysis/trust4/%s_%s_vs_%s_TRUST4_BCR_heavy.txt" % (design,treatment,control))
    ls.append("analysis/trust4/%s_%s_vs_%s_TRUST4_TCR.txt" % (design,treatment,control))
    
    ls.append("analysis/trust4/%s_%s_vs_%s_TRUST4_BCR_clonality.txt" % (design,treatment,control))
    ls.append("analysis/trust4/%s_%s_vs_%s_TRUST4_BCR_SHMRatio.txt" % (design,treatment,control))
    ls.append("analysis/trust4/%s_%s_vs_%s_TRUST4_BCR_Infil.txt" % (design,treatment,control))
    ls.append("analysis/trust4/%s_%s_vs_%s_TRUST4_TCR_clonality.txt" % (design,treatment,control))
    ls.append("analysis/trust4/%s_%s_vs_%s_TRUST4_TCR_Infil.txt" % (design,treatment,control))
    
    ls.append("analysis/trust4/%s_%s_vs_%s_TRUST4-BCR_mqc.pdf" % (design,treatment,control))
    ls.append("analysis/trust4/%s_%s_vs_%s_TRUST4-TCR_mqc.pdf" % (design,treatment,control))
    ls.append("analysis/trust4/%s_%s_vs_%s_TRUST4_Ig.txt" % (design,treatment,control))
    
    
    return ls
    
def getsampleIDs(meta):
	return meta[meta[design].isin(options)].index


rule immune_repertoire_cohort_all:
    input:
      immune_repertoire_cohort_targets
      


rule merge_bcr_process:
    input:
      bcr_light=expand("analysis/trust4/{sample}/{sample}_TRUST4_BCR_light.txt", sample=getsampleIDs(metadata)),
      bcr_heavy=expand("analysis/trust4/{sample}/{sample}_TRUST4_BCR_heavy.txt", sample=getsampleIDs(metadata))
    output:
      "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_BCR_light.txt",
      "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_BCR_heavy.txt"
    benchmark:
      "benchmarks/trust4/{design}_{treatment}_vs_{control}_trust4_merge_bcr.benchmark"
    log:
      "logs/trust4/{design}_{treatment}_vs_{control}_trust4_merge_bcr.log"
    conda: "../../envs/stat_perl_r.yml"
    params:
      meta= config["metasheet"],
      outdir="analysis/trust4/",
      bcr_light_input=lambda wildcards, input: ','.join(str(i) for i in list({input.bcr_light})[0]),
      bcr_heavy_input=lambda wildcards, input: ','.join(str(i) for i in list({input.bcr_heavy})[0]),
      Condition = design,
      Treatment = treatment,
      Control = control,
      path="set +eu;source activate %s" % config['stat_root']
    shell:
      "{params.path}; Rscript src/immune_repertoire/trust4_merge_bcr.R --bcr_light {params.bcr_light_input} --bcr_heavy {params.bcr_heavy_input}\
      --condition {params.Condition} --meta {params.meta} --treatment {params.Treatment} --control {params.Control} \
      --outdir {params.outdir}"
      
rule merge_tcr_process:
    input:
      tcr=expand("analysis/trust4/{sample}/{sample}_TRUST4_TCR.txt", sample=getsampleIDs(metadata)),
    output:
      "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_TCR.txt",
    benchmark:
      "benchmarks/trust4/{design}_{treatment}_vs_{control}_trust4_merge_tcr.benchmark"
    log:
      "logs/trust4/{design}_{treatment}_vs_{control}_trust4_merge_tcr.log"
    conda: "../../envs/stat_perl_r.yml"
    params:
      meta= config["metasheet"],
      outdir="analysis/trust4/",
      tcr_input=lambda wildcards, input: ','.join(str(i) for i in list({input.tcr})[0]),
      Condition = design,
      Treatment = treatment,
      Control = control,
      path="set +eu;source activate %s" % config['stat_root']
    shell:
      "{params.path}; Rscript src/immune_repertoire/trust4_merge_tcr.R --tcr {params.tcr_input} \
      --condition {params.Condition} --meta {params.meta} --treatment {params.Treatment} --control {params.Control} \
      --outdir {params.outdir}"
      


rule merge_bcr_clonality:
    input:
      clonality=expand("analysis/trust4/{sample}/{sample}_TRUST4_BCR_heavy_clonality.txt", sample=getsampleIDs(metadata)),
    output:
      "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_BCR_clonality.txt",
    benchmark:
      "benchmarks/trust4/{design}_{treatment}_vs_{control}_trust4_merge_bcr_clonality.benchmark"
    log:
      "logs/trust4/{design}_{treatment}_vs_{control}_trust4_merge_bcr_clonality.log"
    conda: "../../envs/stat_perl_r.yml"
    params:
      meta= config["metasheet"],
      outdir="analysis/trust4/",
      clonality_input=lambda wildcards, input: ','.join(str(i) for i in list({input.clonality})[0]),
      Condition = design,
      Treatment = treatment,
      Control = control,
      path="set +eu;source activate %s" % config['stat_root']
    shell:
      "{params.path}; Rscript src/immune_repertoire/trust4_merge_bcr_clonality.R --clonality {params.clonality_input} \
      --condition {params.Condition} --meta {params.meta} --treatment {params.Treatment} --control {params.Control} \
      --outdir {params.outdir}"

rule merge_tcr_clonality:
    input:
      clonality=expand("analysis/trust4/{sample}/{sample}_TRUST4_TCR_clonality.txt", sample=getsampleIDs(metadata)),
    output:
      "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_TCR_clonality.txt",
    benchmark:
      "benchmarks/trust4/{design}_{treatment}_vs_{control}_trust4_merge_tcr_clonality.benchmark"
    log:
      "logs/trust4/{design}_{treatment}_vs_{control}_trust4_merge_tcr_clonality.log"
    conda: "../../envs/stat_perl_r.yml"
    params:
      meta= config["metasheet"],
      outdir="analysis/trust4/",
      clonality_input=lambda wildcards, input: ','.join(str(i) for i in list({input.clonality})[0]),
      Condition = design,
      Treatment = treatment,
      Control = control,
      path="set +eu;source activate %s" % config['stat_root']
    shell:
      "{params.path}; Rscript src/immune_repertoire/trust4_merge_tcr_clonality.R --clonality {params.clonality_input} \
      --condition {params.Condition} --meta {params.meta} --treatment {params.Treatment} --control {params.Control} \
      --outdir {params.outdir}"


rule merge_bcr_shm:
    input:
      shm=expand("analysis/trust4/{sample}/{sample}_TRUST4_BCR_heavy_SHMRatio.txt", sample=getsampleIDs(metadata)),
    output:
      "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_BCR_SHMRatio.txt",
    benchmark:
      "benchmarks/trust4/{design}_{treatment}_vs_{control}_trust4_merge_bcr_shm.benchmark"
    log:
      "logs/trust4/{design}_{treatment}_vs_{control}_trust4_merge_bcr_shm.log"
    conda: "../../envs/stat_perl_r.yml"
    params:
      meta= config["metasheet"],
      outdir="analysis/trust4/",
      shm_input=lambda wildcards, input: ','.join(str(i) for i in list({input.shm})[0]),
      Condition = design,
      Treatment = treatment,
      Control = control,
      path="set +eu;source activate %s" % config['stat_root']
    shell:
      "{params.path}; Rscript src/immune_repertoire/trust4_merge_SHM.R --shm {params.shm_input} \
      --condition {params.Condition} --meta {params.meta} --treatment {params.Treatment} --control {params.Control} \
      --outdir {params.outdir}"
      
      
rule merge_bcr_infil:
    input:
      infil=expand("analysis/trust4/{sample}/{sample}_TRUST4_BCR_heavy_lib_reads_Infil.txt", sample=getsampleIDs(metadata)),
    output:
      "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_BCR_Infil.txt",
    benchmark:
      "benchmarks/trust4/{design}_{treatment}_vs_{control}_trust4_merge_bcr_shm.benchmark"
    log:
      "logs/trust4/{design}_{treatment}_vs_{control}_trust4_merge_bcr_shm.log"
    conda: "../../envs/stat_perl_r.yml"
    params:
      meta= config["metasheet"],
      outdir="analysis/trust4/",
      infil_input=lambda wildcards, input: ','.join(str(i) for i in list({input.infil})[0]),
      Condition = design,
      Treatment = treatment,
      Control = control,
      path="set +eu;source activate %s" % config['stat_root']
    shell:
      "{params.path}; Rscript src/immune_repertoire/trust4_merge_bcr_Infil.R --infil {params.infil_input} \
      --condition {params.Condition} --meta {params.meta} --treatment {params.Treatment} --control {params.Control} \
      --outdir {params.outdir}"


rule merge_tcr_infil:
    input:
      infil=expand("analysis/trust4/{sample}/{sample}_TRUST4_TCR_lib_reads_Infil.txt", sample=getsampleIDs(metadata)),
    output:
      "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_TCR_Infil.txt",
    benchmark:
      "benchmarks/trust4/{design}_{treatment}_vs_{control}_trust4_merge_bcr_lib_reads_Infil.benchmark"
    log:
      "logs/trust4/{design}_{treatment}_vs_{control}_trust4_merge_bcr_lib_reads_Infil.log"
    conda: "../../envs/stat_perl_r.yml"
    params:
      meta= config["metasheet"],
      outdir="analysis/trust4/",
      infil_input=lambda wildcards, input: ','.join(str(i) for i in list({input.infil})[0]),
      Condition = design,
      Treatment = treatment,
      Control = control,
      path="set +eu;source activate %s" % config['stat_root']
    shell:
      "{params.path}; Rscript src/immune_repertoire/trust4_merge_tcr_Infil.R --infil {params.infil_input} \
      --condition {params.Condition} --meta {params.meta} --treatment {params.Treatment} --control {params.Control} \
      --outdir {params.outdir}"


rule trust4_cohort_plot:
   input:
      bcr_heavy = "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_BCR_heavy.txt",
      bcr_infil = "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_BCR_Infil.txt",
      bcr_clone = "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_BCR_clonality.txt",
      bcr_shm = "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_BCR_SHMRatio.txt",
      tcr = "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_TCR.txt",
      tcr_infil = "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_TCR_Infil.txt",
      tcr_clone = "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_TCR_clonality.txt",
   output:
      "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4-BCR_mqc.pdf",
      "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4-TCR_mqc.pdf",
      "analysis/trust4/{design}_{treatment}_vs_{control}_TRUST4_Ig.txt"
   log:
      "logs/trust4/{design}_{treatment}_vs_{control}_trust4_plot.log"
   benchmark:
      "benchmarks/trust4/{design}_{treatment}_vs_{control}_trust4_plot.benchmark"
   conda: "../../envs/stat_perl_r.yml"
   params:
      Condition = design,
      Treatment = treatment,
      Control = control,
      plot_dir="analysis/trust4/",
      path="set +eu;source activate %s" % config['stat_root'],
   shell:
      "{params.path}; Rscript src/immune_repertoire/trust4_plot.R \
      --infil_bcr {input.bcr_infil} \
      --heavy_bcr {input.bcr_heavy} \
      --shm {input.bcr_shm} \
      --clone_bcr {input.bcr_clone} \
      --infil_tcr {input.tcr_infil} \
      --tcr {input.tcr} \
      --clone_tcr {input.tcr_clone} \
      --outdir {params.plot_dir} --condition {params.Condition} --treatment {params.Treatment} --control {params.Control}"


