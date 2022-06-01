#!/usr/bin/python3

import os, sys, re

def import_file(filename, out, parse_import_re, container = '<main>', base_path = '.'):
    this_abs = os.path.abspath(os.path.join(base_path, filename))

    next_base_path = os.path.join(base_path, os.path.dirname(filename))
    try:
        with open(os.path.join(base_path, filename)) as f:
            for line in f.readlines():
                if line.startswith("@import"):
                    m = parse_import_re.match(line)
                    if not m:
                        if not line.startswith("@import url("):
                            sys.stderr.write("failed to parse import line: %s" % line)
                        out.write("/* failed to resolve import line, include : */\n")
                        out.write(line)
                    else:
                        next_abs = os.path.abspath(os.path.join(next_base_path, m.group(1)))

                        #print('  "%s" -> "%s";' % (this_abs, next_abs))

                        out.write("/* import %s */\n" % filename)
                        import_file(m.group(1), out, parse_import_re, filename, next_base_path)
                else:
                    out.write(line)
    except IOError as e:
        sys.stderr.write("failed to include %s (in %s): %s" % (
            os.path.join(base_path, filename), filename, e))
        out.write("/* failed to include %s (required in %s) */\n" % (filename, container))

if len(sys.argv) != 3:
    sys.stderr.write("usage: %s <infile.scss> <outfile.scss>\n" % sys.argv[0])
    sys.exit(1)

parse_import_re = re.compile('^@import\s+["\']([^"\']*)["\'];.*$')
with open(sys.argv[2], "w") as out:
    import_file(sys.argv[1], out, parse_import_re)
