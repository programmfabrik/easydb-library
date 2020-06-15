#!/usr/bin/python
# coding=utf8

import sys
import csv
import re
import argparse

argparser = argparse.ArgumentParser()

argparser.add_argument('master', metavar='master',
                       type=str, help='master l10n csv file')
argparser.add_argument('merge', metavar='merge',
                       type=str, help='merge l10n csv file')
argparser.add_argument(
    '-k', '--key', help='key column for merging, must be set')
argparser.add_argument('-f', '--set-key-fallback',
                       help='fallback column for missing entries, must be in master csv')


def to_stderr(line, _exit=True):
    sys.stderr.write(line + "\n")
    if _exit:
        exit(1)


if __name__ == "__main__":

    args = argparser.parse_args()

    if args.key is None or len(args.key) < 1:
        to_stderr("'--key' must be non-empty string")

    _merged_csv_data = {}
    _cultures = []
    _master_cultures = []
    _keys_order = []

    is_master_file = True
    for csvfilename in [args.master, args.merge]:

        with open(csvfilename, 'rb') as csvfile:
            reader = csv.DictReader(csvfile, delimiter=',', quotechar='"')
            if reader.fieldnames is None:
                to_stderr("no columns in csv file %s" % csvfilename)

            for row in reader:

                # check if the 'key' column exists
                if not args.key in row:
                    to_stderr("key column '%s' is missing in %s" %
                              (args.key, csvfilename))

                _loca_key = row[args.key].strip()
                if _loca_key == None or _loca_key == '':
                    continue

                if not _loca_key in _merged_csv_data:
                    # a key from the merge csv does not exist in master, skip this row
                    if not is_master_file:
                        to_stderr("unknown key '%s' in '%s': skip row" %
                                  (_loca_key, csvfilename), False)
                        continue

                    _merged_csv_data[_loca_key] = {}
                    _keys_order.append(_loca_key)

                for culture in reader.fieldnames:
                    if culture == args.key:
                        continue
                    elif re.match(r"[a-z]{2}\-[A-Z]{2}", culture) == None:
                        continue
                    else:
                        if not culture in _cultures:
                            _cultures.append(culture)
                            if is_master_file:
                                _master_cultures.append(culture)

                    if len(row[culture]) > 0:
                        _merged_csv_data[_loca_key][culture] = row[culture]

        is_master_file = False

    header = [args.key] + _cultures
    _master_cultures += [args.key]

    fallback_column = None
    if args.set_key_fallback is not None:
        if not args.set_key_fallback in _master_cultures:
            to_stderr("fallback key column '%s' is missing in master csv %s" %
                      (args.set_key_fallback, args.master))
        else:
            # use 'set-key-fallback' column as fallback
            fallback_column = args.set_key_fallback

    writer = csv.writer(sys.stdout, delimiter=',', quotechar='"')
    writer.writerow(header)

    for key in _keys_order:

        if not key in _merged_csv_data:
            continue

        row = [key]

        for culture in _cultures:
            if culture in _merged_csv_data[key]:
                # translation from master csv
                row.append(_merged_csv_data[key][culture])
            else:
                # fallback
                if fallback_column == args.key:
                    # use key as fallback
                    row.append(key)
                else:
                    if fallback_column is None:
                        row.append('')
                    else:
                        # use value from callback column
                        row.append(_merged_csv_data[key][fallback_column])

        writer.writerow(row)
