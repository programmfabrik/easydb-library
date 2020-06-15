#!/usr/bin/python
# coding=utf8

import sys
import csv
import re
import argparse

argparser = argparse.ArgumentParser()

argparser.add_argument('target', metavar='target', type=str,
                       nargs='+', help='target l10n csv file')
argparser.add_argument('source', metavar='source', type=str,
                       nargs='+', help='source l10n csv file')
argparser.add_argument('-k', '--key', default='key',
                       help='key column for merging (default: "key"')
argparser.add_argument('-f', '--set-key-fallback',
                       help='fallback column for missing entries')

if __name__ == "__main__":

    args = None
    try:
        args = argparser.parse_args()
    except Exception as e:
        print 'Invalid arguments:', e
        exit(1)

    _merged_csv_data = {}
    _cultures = []
    _keys_order = []

    for csvfilename in [args.target[0], args.source[0]]:

        with open(csvfilename, 'rb') as csvfile:
            reader = csv.DictReader(csvfile, delimiter=',', quotechar='"')

            for row in reader:

                # check if the 'key' column exists
                if not args.key in row:
                    print 'key column \'%s\' is missing in %s' % (
                        args.key, csvfilename)
                    exit(1)

                _loca_key = row[args.key].strip()
                if _loca_key == None or _loca_key == '':
                    continue

                if not _loca_key in _merged_csv_data:
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

                    if len(row[culture]) > 0:
                        _merged_csv_data[_loca_key][culture] = row[culture]

    header = [args.key] + _cultures

    # use 'key' column as fallback
    fallback_column = args.key

    if args.set_key_fallback is not None:
        if not args.set_key_fallback in header:
            print 'fallback key column \'%s\' is missing in header' % args.set_key_fallback
            exit(1)
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
                # translation from source csv
                row.append(_merged_csv_data[key][culture])
            else:
                # fallback
                if fallback_column == args.key:
                    # use key as fallback
                    row.append(key)
                else:
                    # use value from callback column
                    row.append(_merged_csv_data[key][fallback_column])

        writer.writerow(row)
