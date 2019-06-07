# coding=utf8

import os
import sys
from time import sleep
from subprocess import Popen, PIPE, STDOUT
from tempfile import TemporaryFile


def call(node_runner_binary, node_env, parameters):

    # try:
    if True:
        p1 = Popen(
            node_runner_binary.split(' ') + parameters,
            shell=False,
            stdin=None,
            stdout=PIPE,
            stderr=STDOUT,
            env=node_env
        )

        out = u''
        while True:
            nextline = p1.stdout.readline()
            if nextline == '' and p1.poll() is not None:
                break
            out += unicode(nextline, encoding='utf-8')

        return out, p1.returncode

    # except Exception as e:
    #     return unicode(e), 1


def get_paths(config, plugin=None):

    if not 'system' in config or not 'nodejs' in config['system']:
        return None, None, None

    for k in ['node_runner_binary', 'node_runner_app', 'node_modules']:
        if k not in config['system']['nodejs']:
            return None, None, None

    node_runner_binary = config['system']['nodejs']['node_runner_binary']
    if node_runner_binary is None:
        return None, None, None

    node_runner_binary = os.path.abspath(node_runner_binary)

    node_runner_app = config['system']['nodejs']['node_runner_app']
    if node_runner_app is None:
        return None, None, None

    node_runner_app = os.path.abspath(node_runner_app)

    node_modules = config['system']['nodejs']['node_modules']
    if node_modules is None:
        node_path = set()
    else:
        node_path = set(node_modules.split(':'))

    if plugin is not None and 'base_path' in plugin:
        node_path.add(plugin['base_path'] + '/node_modules')

    return node_runner_binary, node_runner_app, {
        'NODE_PATH': ':'.join([os.path.abspath(n) for n in node_path])
    }
