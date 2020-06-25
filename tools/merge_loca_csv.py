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
required.add_argument('-m', '--merge-columns', type=str, required=True, metavar='merge_columns',
                      help='[Example: -m=ru-RU,pl-PL] string with comma separated columns from merge csv that should be merged into master. must be in both master and merge csv files.')

argparser.add_argument('-f', '--set-key-fallback',
                       help='fallback column for missing entries, must be in master csv')
argparser.add_argument('-s', '--sort', action='store_true',
                       help='sort keys alphabetically in output csv')

KEY_INTERNAL = '_key'
ROW_INTERNAL = '_row'


def to_stderr(line, _exit=True):
    sys.stderr.write(str(line) + "\n")
    if _exit:
        exit(1)


def sort_keys(x, y):
    if KEY_INTERNAL not in x:
        return 0
    if KEY_INTERNAL not in y:
        return 0
    if x[KEY_INTERNAL] == y[KEY_INTERNAL]:
        return 0
    if x[KEY_INTERNAL] > y[KEY_INTERNAL]:
        return 1
    return -1


if __name__ == "__main__":

    args = argparser.parse_args()

    _merge_columns = set()
    for a in args.merge_columns.split(','):
        a = a.strip()
        if len(a) > 0:
            _merge_columns.add(a)

    _merge_columns = list(_merge_columns)

    if len(_merge_columns) < 1:
        to_stderr("'--merge-columns' must be list of valid column names")

    _master_csv_data = []
    _merge_csv_data = {}

    _master_columns = []
    _master_keys = set()
    _merge_keys = set()

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
                else:
                    _merge_keys.add(_loca_key)

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
                        KEY_INTERNAL: _loca_key,
                        ROW_INTERNAL: _row_data
                    })

        is_master_file = False

    for _loca_key in _merge_keys:
        if not _loca_key in _master_keys:
            to_stderr('missing in master: %s' % _loca_key, False)

    for _loca_key in _master_keys:
        if not _loca_key in _merge_keys:
            to_stderr('missing in merge: %s' % _loca_key, False)

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
        if not KEY_INTERNAL in d or not ROW_INTERNAL in d:
            continue
        if len(d[KEY_INTERNAL]) < 1:
            continue

        _loca_key = d[KEY_INTERNAL]
        if not _loca_key in _merge_csv_data:
            continue

        _key_data = _merge_csv_data[_loca_key]

        for i in range(len(_master_columns)):
            if i >= len(d[ROW_INTERNAL]):
                continue
            _col = _master_columns[i]
            if not _col in _key_data:
                continue

            _merge_value = _key_data[_col]
            _master_value = d[ROW_INTERNAL][i]

            # value neither in master nor in merge -> key fallback
            if (_master_value is None or len(_master_value) < 1) and (_merge_value is None or len(_merge_value) < 1):
                if fallback_column == args.key:
                    # use key as fallback
                    d[ROW_INTERNAL][i] = _loca_key
                elif fallback_column is not None:
                    # use value from callback column
                    d[ROW_INTERNAL][i] = _master_value if _master_value is not None else ''

            # value is in master and in merge -> merge value
            else:
                d[ROW_INTERNAL][i] = _merge_value

    if args.sort:
        _master_csv_data.sort(cmp=sort_keys)

    writer = csv.writer(sys.stdout, delimiter=',', quotechar='"')
    writer.writerow(_master_columns)

    for row in _master_csv_data:
        if not ROW_INTERNAL in row:
            continue
        writer.writerow(row[ROW_INTERNAL])
