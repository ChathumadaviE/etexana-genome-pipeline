import sys
from collections import defaultdict

paf = sys.argv[1]

def load_paf(fname):
    with open(fname) as f:
        for line in f:
            if not line.strip() or line.startswith("#"):
                continue
            fields = line.rstrip().split("\t")
            qname, qlen, qstart, qend = fields[0], int(fields[1]), int(fields[2]), int(fields[3])
            tname, tlen, tstart, tend = fields[5], int(fields[6]), int(fields[7]), int(fields[8])
            nmatch, alen = int(fields[9]), int(fields[10])
            extra = "\t".join(fields[12:])
            yield qname, qlen, qstart, qend, tname, tlen, tstart, tend, nmatch, alen, extra

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

def compute_pct(thresh_ident):
    q_len = {}
    q_int = defaultdict(list)

    for (qname, qlen, qstart, qend,
         tname, tlen, tstart, tend,
         nmatch, alen, extra) in load_paf(paf):

        if "tp:A:P" not in extra:
            continue  # primary alignments only

        ident = nmatch / alen
        if ident < thresh_ident:
            continue

        q_len[qname] = qlen
        q_int[qname].append((qstart, qend))

    total_zz = sum(q_len.values())
    aligned = sum(merged_length(iv) for iv in q_int.values())
    pct = 100.0 * aligned / total_zz if total_zz > 0 else 0.0
    return total_zz, aligned, pct

for thr in (0.90, 0.80):
    total, aligned, pct = compute_pct(thr)
    print(f"Identity ≥{int(thr*100)}%: aligned {aligned} bp of {total} bp "
          f"({pct:.1f}% of ZZ assembly)")
