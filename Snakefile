#
# use with --use-conda for maximal froodiness.
#

# override this with --configfile on command line
configfile: 'test-data/conf.yml'

outputdir = config['outputdir'].rstrip('/') + '/'
scaled = config['scaled']
ksize = config['ksize']
fragment_size = config['fragment_size']

rule all:
    input:
        outputdir + 'matching-fragments.fa',
        outputdir + 'matching-contigs.fa',
        outputdir + 'nomatch-contigs.fa'

rule gather_all:
    input:
        query = outputdir + 'contigs.sig',
        database = config['database']
    output:
        csv = outputdir + 'gather.csv',
        matches = outputdir + 'matches.sig'
    conda: 'conf/env-sourmash.yml'
    params:
        scaled = scaled
    shell: """
        sourmash gather {input.query} {input.database} -o {output.csv} \
            --save-matches {output.matches} --scaled={params.scaled}
    """

rule extract_fragments:
    input:
        matches = outputdir + 'matches.sig',
        assembly = config['assembly']
    output:
        fragments = outputdir + 'matching-fragments.fa',
        matching = outputdir + 'matching-contigs.fa',
        nomatch = outputdir + 'nomatch-contigs.fa'
    params:
        fragment_size=int(fragment_size)
    conda: 'conf/env-sourmash.yml'
    shell: """
        ./scripts/extract-matching-fragments.py \
              {input.matches} {input.assembly} \
              --output-fragments {output.fragments} \
              --matching-contigs {output.matching} \
              --nomatch-contigs {output.nomatch} \
              -F {params.fragment_size}
    """

rule contigs_sig:
    input:
        config['assembly']
    output:
        outputdir + 'contigs.sig'
    conda: 'conf/env-sourmash.yml'
    params:
        scaled = scaled,
        ksize = ksize
    shell: """
        sourmash compute -k {params.ksize} --scaled {params.scaled} \
            {input} -o {output}
    """
