#!/usr/bin/env python3
"""
Find common circRNA entries across multiple BED files.

Usage:
    cat *.bed | python common.py -t 2 -d 0
    python common.py merged.bed -t 2 -d 3

Arguments:
    -t, --count-threshold: Minimum number of methods (default: 2)
    -d, --deviation: Position deviation tolerance in bp (default: 0)
"""

import argparse
import sys
from collections import defaultdict


def parse_bed_entry(line):
    """Parse BED entry to extract chromosome, start, end."""
    parts = line.strip().split('\t')
    if len(parts) < 3:
        return None
    chromosome = parts[0]
    try:
        start = int(parts[1])
        end = int(parts[2])
    except ValueError:
        return None
    return (chromosome, start, end)


def find_common_entries(bed_entries, deviation=0, count_threshold=2):
    """
    Find circRNA entries detected by at least count_threshold methods.

    Args:
        bed_entries: List of (chr, start, end) tuples
        deviation: Allowed position deviation in bp
        count_threshold: Minimum number of detections

    Returns:
        List of common (chr, start, end) tuples
    """
    bed_entries_dict = defaultdict(int)
    common_entries = []

    for entry in bed_entries:
        if entry is None:
            continue

        if len(bed_entries_dict) == 0:
            bed_entries_dict[entry] += 1
        else:
            matched = False
            for other_entry in list(bed_entries_dict.keys()):
                if entry[0] == other_entry[0] and \
                    abs(entry[1] - other_entry[1]) <= deviation and \
                    abs(entry[2] - other_entry[2]) <= deviation:
                    bed_entries_dict[other_entry] += 1
                    matched = True
                    break
            if not matched:
                bed_entries_dict[entry] += 1

    for entry, count in bed_entries_dict.items():
        if count >= count_threshold:
            common_entries.append(entry)

    return common_entries


def main():
    parser = argparse.ArgumentParser(
        description='Find common circRNA entries across multiple BED files.'
    )
    parser.add_argument('bed_file', nargs='?',
                        help='Input BED file. If not provided, read from stdin.')
    parser.add_argument('-d', '--deviation', type=int, default=0,
                        help='Position deviation tolerance in bp (default: 0)')
    parser.add_argument('-t', '--count-threshold', type=int, default=2,
                        help='Minimum number of methods detecting circRNA (default: 2)')
    args = parser.parse_args()

    bed_entries = []

    if args.bed_file:
        with open(args.bed_file, 'r') as f:
            for line in f:
                entry = parse_bed_entry(line)
                if entry:
                    bed_entries.append(entry)
    else:
        for line in sys.stdin:
            entry = parse_bed_entry(line)
            if entry:
                bed_entries.append(entry)

    common_entries = find_common_entries(
        bed_entries,
        args.deviation,
        args.count_threshold
    )

    for entry in common_entries:
        print('\t'.join(map(str, entry)))


if __name__ == '__main__':
    main()