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
cultures_fallback = []

EN_US_CULTURE = "en-US"
FALLBACK_SUFFIX = "-key-fallback"

def getCultureValue(_row, _culture, i = 0):
    _value = _row[_culture]
    if _value == None or _value == '':
        if i >= len(cultures_plain):
            return ""
        nextCulture = cultures_plain[i]
        i += 1
        return getCultureValue(_row, nextCulture, i)
    return _value.strip()


def getCultureValueWithFallback(_row, _culture, _key, i = 0):
    _value = _row[_culture]
    if _value == None or _value == '':
        return _key
    return _value.strip()


for idx in range(1, len(sys.argv)-1):
    print "#"+str(idx), sys.argv[idx]

    with open(sys.argv[idx], 'rb') as csvfile:
        reader = csv.DictReader(csvfile, delimiter=',', quotechar='"')

        for culture in reader.fieldnames:
            if culture == "key":
                continue
            elif re.match(r"[a-z]{2}\-[A-Z]{2}", culture) == None:
                print "Omitting column \""+culture+"\", culture format \"az-AZ\" not matching."
            else:
                cultures.append({"code": culture})
                cultures_plain.append(culture)

        cultures_plain = sorted(cultures_plain, key=lambda item: 0 if item == EN_US_CULTURE else 1)
        for culture in cultures_plain:
            key_fallback_culture = "%s%s" % (culture, FALLBACK_SUFFIX)
            cultures.append({"code": key_fallback_culture})
            cultures_fallback.append(key_fallback_culture)

        line = 1 # the first line was skipped as it is contains the keys for the dict
        for row in reader:

            loca_key = row["key"].strip()
            if loca_key == None or loca_key == '':
                continue

            for culture in row.keys():
                if culture not in cultures_plain and culture not in cultures_fallback:
                    continue

                key_fallback_culture = "%s%s" % (culture, FALLBACK_SUFFIX)

                if not culture in target_dict:
                    if culture == None:
                        print
                        print "WARNING: Line %s: Ignoring extra value: %s. Row:" % ((line+1), row[culture]), repr(row)
                        continue

                    target_dict[culture] = {}
                    target_dict[key_fallback_culture] = {}

                target_dict[culture][loca_key] = getCultureValue(row, culture)
                target_dict[key_fallback_culture][loca_key] = getCultureValueWithFallback(row, culture, loca_key)

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
    print "Wrote", filename, "with", repr(cultures_plain + cultures_fallback)
