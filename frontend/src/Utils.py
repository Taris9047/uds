#!/usr/bin/env python3

# Contains some useful misc stuffs. Such as terminal running methods and Version comparators.

import os
import sys
import re
import subprocess as sbp

### Run Console (Bash.. currently...) ###


class RunCmd(object):
    def __init__(self, shell_type="bash", verbose=False):
        # At this moment, just bash is supported! Let's see if it works out!
        self.shell_type = shell_type
        self.verbose = verbose
        self.exit_code = None

    def Run(self, cmd=None, env=None):
        logs = []
        if isinstance(cmd, str):
            return self.RunACmd(cmd, env)

        elif isinstance(cmd, list) and (not env or isinstance(env, str)):
            for cm in cmd:
                log, self.exit_code = self.RunACmd(cm, env)
                logs.append(log)

            return logs, self.exit_code

        elif isinstance(cmd, list) and isinstance(env, list):
            for cm, ev in zip(cmd, env):
                log, self.exit_code = self.RunACmd(cm, ev)
                logs.append(log)

            return logs, self.exit_code

    def RunACmd(self, cmd=None, env=None):
        if not cmd:
            return 0

        if not env:
            self.cmd_to_run = cmd
        else:
            self.cmd_to_run = "{} {}".format(env, cmd)

        if self.verbose:
            result_log, exit_code = self.RunVerbose()
        else:
            result_log, exit_code = self.RunSilent()

        return result_log, exit_code

    def RunVerbose(self, cmd=None):
        if cmd:
            cmd_to_run = cmd
        else:
            cmd_to_run = self.cmd_to_run

        log = ""
        p = sbp.Popen(cmd_to_run, shell=True, stdout=sbp.PIPE)
        for line in iter(p.stdout.readline, b""):
            ln = line.decode("utf-8").strip()
            sys.stdout.buffer.write(line)
            sys.stdout.flush()
            log += "{}{}".format(ln, os.linesep)
        p.stdout.close()
        exit_code = p.wait()
        return log, exit_code

    def RunSilent(self, cmd=None):
        if cmd:
            cmd_to_run = cmd
        else:
            cmd_to_run = self.cmd_to_run

        log = ""
        p = sbp.Popen(cmd_to_run, shell=True, stdout=sbp.PIPE)
        for line in iter(p.stdout.readline, b""):
            ln = line.decode("utf-8").strip()
            log += "{}{}".format(ln, os.linesep)
        p.stdout.close()
        exit_code = p.wait()
        return log, exit_code


### Version Parsor ###
class Version(object):
    def __init__(self, ver_info):
        self.ver_info = [0]
        if isinstance(ver_info, str):
            self.init_str(ver_info)
        elif isinstance(ver_info, list):
            self.init_list(ver_info)

    def init_str(self, ver_info):
        self.ver_info = self.split_num_alpha(ver_info.split("."))

    def init_list(self, ver_info):
        self.ver_info = self.split_num_alpha(ver_info)

    # Stupid but needed since some programmers use version number with
    # alphabets such as 23b, 1.11.3a, etc.
    @staticmethod
    def split_num_alpha(ary):
        insert_list = []
        for i, _ in enumerate(ary):
            # knocking out v12.13 case
            if isinstance(_, str) and _[0].lower() == "v":
                ary[i] = _[1:]

            try:
                ary[i] = int(_)
            except ValueError:
                splitted = re.findall(r"[^\W\d_]+|\d+", _)
                for s_i, s in enumerate(splitted):
                    if s.isnumeric():
                        splitted[s_i] = int(s)
                insert_list.append((i, splitted))

        offset = 0
        while insert_list:
            sp = insert_list.pop(0)
            ary[sp[0] + offset] = sp[1][0]
            ary = ary[: sp[0] + 1 + offset] + sp[1][1:] + ary[sp[0] + 1 + offset:]
            offset += len(sp) - 1
        return ary

    def __eq__(self, other):
        return self.ver_info == other.ver_info

    def __ne__(self, other):
        return self.ver_info != other.ver_info

    def __lt__(self, other):
        return self.ver_info < other.ver_info

    def __le__(self, other):
        return self.ver_info <= other.ver_info

    def __gt__(self, other):
        return self.ver_info > other.ver_info

    def __ge__(self, other):
        return self.ver_info >= other.ver_info

    def to_str(self):
        return ".".join([str(_) for _ in self.ver_info])

    def to_list_str(self):
        return [str(_) for _ in self.ver_info]

    def to_list(self):
        return self.ver_info


# Checks up whether a command line program exists or not.
def program_exists(program=None):
    def is_exe(prog):
        print(prog)
        return os.path.isfile(prog) and os.access(prog, os.X_OK)

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return True
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return True

    return False
