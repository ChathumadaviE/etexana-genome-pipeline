import sys
from collections import defaultdict

paf = sys.argv[1]
thr = float(sys.argv[2])

def load_paf(fname):
    with open(fname) as f:
        for line in f:
            if not line.strip() or line.startswith("#"):
                continue
            fields = line.rstrip().split("\t")
            tname, tlen, tstart, tend = fields[5], int(fields[6]), int(fields[7]), int(fields[8])
            nmatch, alen = int(fields[9]), int(fields[10])
            extra = "\t".join(fields[12:])
            yield tname, tlen, tstart, tend, nmatch, alen, extra

def merged_length(intervals):
    if not intervals:
        return 0
    intervals = sorted(intervals)
    merged = [list(intervals[0])]
    for s, e in intervals[1:]:
        if s > merged[-1][1]:
            merged.append([s, e])
        else:
            merged[-1][1] = max(merged[-1][1], e)
    return sum(e - s for s, e in merged)

scaf_len = {}
scaf_int = defaultdict(list)

for tname, tlen, tstart, tend, nmatch, alen, extra in load_paf(paf):
    if "tp:A:P" not in extra:
        continue
    ident = nmatch / alen
    if ident < thr:
        continue
    scaf_len[tname] = tlen
    scaf_int[tname].append((tstart, tend))

print("scaffold\tlength_bp\tcovered_bp\tpercent_covered")
for t in sorted(scaf_len):
    cov = merged_length(scaf_int[t])
    pct = 100.0 * cov / scaf_len[t]
    print(f"{t}\t{scaf_len[t]}\t{cov}\t{pct:.2f}")
