#!/usr/bin/python
# coding=utf8

import sys
import csv
import re

# languages where the key is used as the fallback
FALLBACK_KEY = ['ru-RU', 'pl-PL', 'cs-CZ']

if __name__ == "__main__":

    _merged_csv_data = {}
    _cultures = []

    if len(sys.argv) < 3:
        print "Usage: merge_l10n_csv.py <csv-files> <target-csv-file>"

    for idx in range(1, len(sys.argv) - 1):
        source_csv = sys.argv[idx]

        print "source csv #%d: %s" % (idx, source_csv)

        with open(source_csv, 'rb') as csvfile:
            reader = csv.DictReader(csvfile, delimiter=',', quotechar='"')

            for row in reader:
                loca_key = row["key"].strip()
                if loca_key == None or loca_key == '':
                    continue

                if not loca_key in _merged_csv_data:
                    _merged_csv_data[loca_key] = {}

                for culture in reader.fieldnames:
                    if culture == "key":
                        continue
                    elif re.match(r"[a-z]{2}\-[A-Z]{2}", culture) == None:
                        continue
                    else:
                        if not culture in _cultures:
                            _cultures.append(culture)
                            print "  new culture", culture

                    _merged_csv_data[loca_key][culture] = row[culture]

    target_csv = sys.argv[len(sys.argv) - 1]
    print "target:", target_csv

    _cultures.sort()
    header = ['key'] + _cultures

    with open(target_csv, 'wb') as csvfile:
        writer = csv.writer(csvfile, delimiter=',', quotechar='"')

        writer.writerow(header)

        for key in _merged_csv_data:

            row = [key]

            for culture in _cultures:
                if culture in _merged_csv_data[key]:
                    # translation from source csv
                    row.append(_merged_csv_data[key][culture])
                else:
                    # fallback
                    if culture in FALLBACK_KEY:
                        row.append(key)
                    else:
                        row.append('')

            writer.writerow(row)

    print "wrote %d keys for %d cultures" % (len(_merged_csv_data), len(_cultures))
