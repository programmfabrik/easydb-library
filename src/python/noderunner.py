# coding=utf8

import os
import sys
from subprocess import Popen, PIPE


def call(config, script, parameters='', additional_nodepaths=[], logger=None):

    node_runner_binary, node_runner_app, node_paths = get_paths(config)
    if node_runner_binary is None:
        raise Exception('node_runner_binary_not_found')
    if node_runner_app is None:
        raise Exception('node_runner_app_not_found')

    command = node_runner_binary.split(' ') + [node_runner_app, script, '-']

    node_paths += additional_nodepaths
    node_env = {
        'NODE_PATH': ':'.join([os.path.abspath(n) for n in node_paths])
    }

    if logger is not None:
        logger.debug('noderunner call: %s' % ' '.join(command))
        logger.debug('noderunner stdin: %s' % parameters)
        logger.debug('noderunner environment: %s' % node_env)

    p1 = Popen(
        command,
        shell=False,
        stdin=PIPE,
        stdout=PIPE,
        stderr=PIPE,
        env=node_env
    )

    out, err = p1.communicate(input=parameters.encode('utf-8'))
    exit_code = p1.returncode

    if logger is not None:
        logger.debug('noderunner call: %s bytes from stdout, %s bytes from stderr, exit code: %s ==> %s'
            % (len(out), len(err), exit_code, 'OK' if exit_code == 0 else 'ERROR'))
        if (exit_code != 0):
            logger.error('noderunner call: exit code: %s, error: %s, out: %s' % (exit_code, err, out))

    return out.decode('utf-8'), err.decode('utf-8'), exit_code


def get_paths(config):

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

    return node_runner_binary, node_runner_app, list(node_path)
