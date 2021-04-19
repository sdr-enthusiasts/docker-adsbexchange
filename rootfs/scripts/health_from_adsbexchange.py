#!/usr/bin/env python3

import subprocess
import json
import os
import sys

stats_raw = subprocess.check_output(['curl','--silent','https://www.adsbexchange.com/myip/'])
stats_json = json.loads(stats_raw.decode('utf-8'))

mlat_ok = False
beast_ok = False

if 'ERR' in stats_json.keys():
    print(stats_json['ERR'])
else:
    print("")
    
    if 'stats-uuid' in stats_json.keys():
        jsonkey = 'stats-uuid'
    elif 'stats-uuid1' in stats_json.keys():
        jsonkey = 'stats-uuid1'
    else:
        print("Could not determine UUID")
        sys.exit(1)
    
    if stats_json[jsonkey].lower() == 'not found':
        print("Feeder '%s':" % (os.environ['SITENAME']))
    else:
        print("Feeder '%s', UUID '%s':" % (os.environ['SITENAME'], stats_json['stats-uuid']))
        print("Online statistics at: https://www.adsbexchange.com/api/feeders/?feed=%s" % (stats_json['stats-uuid']))
    print("")
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
        if k.lower().count('mlat') >= 1:
            print("MLAT data feeding OK")
            print("  - Data Incoming From: %s" % (ks[0]))
            print("  - Route:Port: %s" % (ks[1]))
            print("  - Backend: %s" % (ks[2]))
            print("  - Connected: %s" % (ks[3]))
            print("  - Age: %s" % (datadict[k]['age']))
            print("")
            mlat_ok = True
        if k.lower().count('beast') >= 1:
            print("Beast data feeding OK")
            print("  - Data Incoming From: %s" % (ks[0]))
            print("  - Route:Port: %s" % (ks[1]))
            print("  - Backend: %s" % (ks[2]))
            print("  - Connected: %s" % (ks[3]))
            print("  - Age: %s" % (datadict[k]['age']))
            print("")
            beast_ok = True
        if not (beast_ok or mlat_ok):
            print("No Mode-S data being received by adsbexchange, check https://adsbexchange.com/myip/")

