#!/usr/bin/python
# coding=utf8
import sys
import csv
import os
import re
import json

# print 'Number of arguments:', len(sys.argv), 'arguments.'
# print 'Argument List:', str(sys.argv)

if len(sys.argv) < 3:
    print "Usage: l10n2json.py <csv-files> <target-directory>"

directory = sys.argv[ len(sys.argv)-1 ]

target_dict = {}

if not os.path.exists(directory):
    print "Target-Directory does not exists:", directory
    exit(1)

cultures = []
cultures_plain = []

for idx in range(1, len(sys.argv)-1):
    print "#"+str(idx), sys.argv[idx]

    with open(sys.argv[idx], 'rb') as csvfile:
        reader = csv.DictReader(csvfile, delimiter=',', quotechar='"')

        for culture in reader.fieldnames:
            if culture == "key":
                continue
            elif re.match("[a-z]{2}\-[A-Z]{2}", culture) == None:
                print "Omitting column \""+culture+"\", culture format \"az-AZ\" not matching."
            else:
                cultures.append({"code": culture})
                cultures_plain.append(culture)

        line = 1 # the first line was skipped as it is contains the keys for the dict
        for row in reader:

            loca_key = row["key"]
            for culture in row.keys():
                if culture not in cultures_plain:
                    continue

                if not culture in target_dict:
                    if culture == None:
                        print
                        print "WARNING: Line %s: Ignoring extra value: %s. Row:" % ((line+1), row[culture]), repr(row)
                        continue

                    target_dict[culture] = {}

                if row[culture] == None:
                    target_dict[culture][loca_key] = ""
                else:
                    target_dict[culture][loca_key] = row[culture]
            line = line + 1

for culture, loca_keys in target_dict.iteritems():
    # we omit columns which don't look like "culture" columns

    filename = directory+"/"+culture+".json"
    with open(filename, 'w') as outfile:
        dump_dict = {}
        dump_dict[culture] = target_dict[culture]
        json.dump(dump_dict, outfile, ensure_ascii=False, sort_keys=True, indent=4)
    print "Wrote", filename, "with", len(target_dict[culture].keys()), "loca keys."

filename = directory+"/cultures.json"
with open(filename, 'w') as outfile:
    json.dump(cultures, outfile, ensure_ascii=False, sort_keys=True, indent=4)
    print "Wrote", filename, "with", repr(cultures_plain)
