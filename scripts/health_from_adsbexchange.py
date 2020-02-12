#!/usr/bin/env python3

import subprocess
import json
import os

stats_raw = subprocess.check_output(['curl','--silent','https://www.adsbexchange.com/myip/'])
stats_json = json.loads(stats_raw.decode('utf-8'))

if 'ERR' in stats_json.keys():
    print(stats_json['ERR'])
else:
    if stats_json['stats-uuid'].lower() == 'not found':
        print("Statistics for feeder '%s':" % (os.environ['SITENAME']))
    else:
        print("Statistics for feeder '%s', UUID '%s':" % (os.environ['SITENAME'], stats_json['stats-uuid']))
        print("Live stats available at: https://www.adsbexchange.com/api/feeders/?feed=%s" % (stats_json['stats-uuid']))
    print("")
    print("  - Lines output: %s" % (stats_json['outlines']))
    datadict = dict()
    for k in stats_json.keys():
        if len(k) >= 3:
            if k[:2] == 'rt':
                n = k[2:]
                if k not in datadict.keys():
                    datadict[stats_json[k]] = dict()
                datadict[stats_json[k]]['age'] = stats_json['age%s' % (n)]
    for k in datadict.keys():
        ks = k.split()
        print("")
        print("  - Data Incoming From: %s" % (ks[0])) 
        print("  - Route:Port: %s" % (ks[1]))
        print("  - Backend: %s" % (ks[2]))
        print("  - Connected: %s" % (ks[3]))
        print("  - Age: %s" % (datadict[k]['age']))

