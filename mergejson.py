#!/usr/bin/env python

import json
import os
import sys

if __name__ == '__main__':
  out = []
  for fname in sys.argv[2:]:
    with open(fname) as fd:
      out.append(json.load(fd))
  out.sort(key=lambda x:x['date'], reverse=True)
  with open(sys.argv[1] + '.tmp', 'w') as outfd:
    json.dump(out, outfd, indent=4)
  os.rename(sys.argv[1] + '.tmp', sys.argv[1])
