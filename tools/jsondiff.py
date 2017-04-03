#!/usr/bin/python3

import sys
import json

if len(sys.argv) < 3:
    print ('wrong arguments')
    exit(1)

mappings = []
for i in [1,2]:
    with open(sys.argv[i]) as f:
        js = json.load(f)
        mappings.append(js[list(js.keys())[0]])

def jsonerror(path, error):
    print('[{}] {}'.format('.'.join(path), error))

def jsondiff(old, new, path=[]):
    if isinstance(old, dict):
        if not isinstance(new, dict):
            jsonerror(path, 'expecting object')
            return
        for k in old.keys():
            if k not in new:
                jsonerror(path + [k], 'not found')
                continue
            jsondiff(old[k], new[k], path + [k])
    elif isinstance(old, list):
        if not isinstance(new, list):
            jsonerror(path, 'expecting list')
            return
        if len(old) != len(new):
            jsonerror(path, 'list length {} != {}'.format(len(old), len(new)))
            return
        for i in range(len(new)):
            jsondiff(old[i], new[i], path + [str(i)])
    elif old != new:
        jsonerror(path, 'expecting {}, got {}'.format(old, new))

jsondiff(*mappings)
