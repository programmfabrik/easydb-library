#!/usr/bin/python
# coding=utf8

import sys
import csv
import re
import argparse
import json

argparser = argparse.ArgumentParser()

argparser.add_argument('master', metavar='master',
                       type=str, help='master l10n csv file')
argparser.add_argument('merge', metavar='merge',
                       type=str, help='merge l10n csv file')

required = argparser.add_argument_group('required arguments')
required.add_argument('-k', '--key', type=str, required=True, metavar='key',
                      help='[Example: -k key] key column name for merging')
required.add_argument('-m', '--merge-columns', nargs='+', type=str, required=True, metavar='merge_columns',
                      help='[Example: -m=ru-RU,pl-PL] columns from merge that should be merged into master. must be in both master and merge.')

argparser.add_argument('-f', '--set-key-fallback',
                       help='fallback column for missing entries, must be in master csv')


def to_stderr(line, _exit=True):
    sys.stderr.write(str(line) + "\n")
    if _exit:
        exit(1)


if __name__ == "__main__":

    args = argparser.parse_args()

    _merge_columns = set()
    for a in args.merge_columns:
        for b in a.split(','):
            b = b.strip()
            if len(b) > 0:
                _merge_columns.add(b)

    _merge_columns = list(_merge_columns)

    if len(_merge_columns) < 1:
        to_stderr("'--merge-columns' must be list of valid column names")

    _master_csv_data = []
    _merge_csv_data = {}

    _master_columns = []
    _master_keys = set()

    is_master_file = True
    for csvfilename in [args.master, args.merge]:

        with open(csvfilename, 'rb') as csvfile:
            reader = csv.DictReader(csvfile, delimiter=',', quotechar='"')
            if reader.fieldnames is None:
                to_stderr("no columns in csv file %s" % csvfilename)

            # check if the --key column is present in master and merge csv
            if not args.key in reader.fieldnames:
                to_stderr("key column '%s' is missing in %s" %
                          (args.key, csvfilename))

            # check if the --merge-columns are present in master and merge csv
            for column in _merge_columns:
                if not column in reader.fieldnames:
                    to_stderr("merge-column %s is not in csv file %s" %
                              (column, csvfilename))

            for fieldname in reader.fieldnames:
                if is_master_file:
                    _master_columns.append(fieldname)

            for row in reader:
                _row_data = []

                _loca_key = row[args.key].strip()
                if _loca_key == None:
                    continue
                if _loca_key == '' and not is_master_file:
                    continue

                if is_master_file:
                    _master_keys.add(_loca_key)

                for fieldname in reader.fieldnames:
                    if is_master_file:
                        _row_data.append(row[fieldname])
                    elif fieldname in _merge_columns:
                        if _loca_key not in _merge_csv_data:
                            if _loca_key not in _master_keys:
                                continue
                            _merge_csv_data[_loca_key] = {}
                        _merge_csv_data[_loca_key][fieldname] = row[fieldname]

                if is_master_file:
                    _master_csv_data.append({
                        '_key': _loca_key,
                        '_row': _row_data
                    })

        is_master_file = False

    fallback_column = None
    if args.set_key_fallback is not None:
        if not args.set_key_fallback in _master_columns:
            to_stderr("fallback key column '%s' is missing in master csv %s" %
                      (args.set_key_fallback, args.master))
        else:
            # use 'set-key-fallback' column as fallback
            fallback_column = args.set_key_fallback

    # merge all key values from merge csv into master csv
    for d in _master_csv_data:
        if not '_key' in d or not '_row' in d:
            continue
        if len(d['_key']) < 1:
            continue

        _loca_key = d['_key']
        if not _loca_key in _merge_csv_data:
            continue

        _key_data = _merge_csv_data[_loca_key]

        for i in range(len(_master_columns)):
            if i >= len(d['_row']):
                continue
            _col = _master_columns[i]
            if not _col in _key_data:
                continue

            _merge_value = _key_data[_col]
            _master_value = d['_row'][i]

            # value neither in master nor in merge -> key fallback
            if (_master_value is None or len(_master_value) < 1) and (_merge_value is None or len(_merge_value) < 1):
                if fallback_column == args.key:
                    # use key as fallback
                    d['_row'][i] = _loca_key
                elif fallback_column is not None:
                    # use value from callback column
                    d['_row'][i] = _master_value if _master_value is not None else ''

            # value is in master and in merge -> merge value
            else:
                d['_row'][i] = _merge_value

    writer = csv.writer(sys.stdout, delimiter=',', quotechar='"')
    writer.writerow(_master_columns)

    for row in _master_csv_data:
        if not '_row' in row:
            continue
        writer.writerow(row['_row'])
