module load minimap2-2.14-gcc-12.2.0-uetueyt

REF=/path/to/WW_cleaned.fasta          # cleaned WW reference
QUERY=/path/to/ZZ_RagTag_scaffolds.fasta   # scaffold-level ZZ assembly
OUT=/path/to/ZZ_on_WW.paf

minimap2 -x asm10 -t 24 "${REF}" "${QUERY}" > "${OUT}"
