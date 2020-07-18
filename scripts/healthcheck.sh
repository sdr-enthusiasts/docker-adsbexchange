#!/usr/bin/env bash
set -e

EXITCODE=0

if [ -f "/run/adsbexchange-feed/aircraft.json" ]; then

    # get latest timestamp of readsb json update
    TIMESTAMP_LAST_READSB_UPDATE=$(cat /run/adsbexchange-feed/aircraft.json | jq '.now')

    # get current timestamp
    TIMESTAMP_NOW=$(date +"%s.%N")

    # makse sure readsb has updated json in past 60 seconds
    TIMEDELTA=$(echo "$TIMESTAMP_NOW - $TIMESTAMP_LAST_READSB_UPDATE" | bc)
    if [ $(echo $TIMEDELTA \< 60 | bc) -ne 1 ]; then
        echo "adsbexchange-feed last updated: ${TIMESTAMP_LAST_READSB_UPDATE}, now: ${TIMESTAMP_NOW}, delta: ${TIMEDELTA}. UNHEALTHY"
        EXITCODE=1
    else
        echo "adsbexchange-feed last updated: ${TIMESTAMP_LAST_READSB_UPDATE}, now: ${TIMESTAMP_NOW}, delta: ${TIMEDELTA}. HEALTHY"
    fi

    # get number of aircraft
    NUM_AIRCRAFT=$(cat /run/adsbexchange-feed/aircraft.json | jq '.aircraft | length')
    if [ $NUM_AIRCRAFT -lt 1 ]; then
        echo "total aircraft: $NUM_AIRCRAFT. UNHEALTHY"
        EXITCODE=1
    else
        echo "total aircraft: $NUM_AIRCRAFT. HEALTHY"
    fi

else

    echo "WARNING: Cannot find /run/adsbexchange-feed/aircraft.json, so skipping some checks."

fi

# make sure we're feeding beast/beastreduce data to adsbexchange
netstat -an | grep ESTABLISHED | grep 30005 | grep $(dig +short feed.adsbexchange.com) > /dev/null
if [ $? -eq 0 ]; then
    echo "established beast connection to feed.adsbexchange.com:30005. HEALTHY"
else
    echo "no established beast connection to feed.adsbexchange.com:30005. UNHEALTHY"
    EXITCODE=1
fi

# make sure we're feeding MLAT data to adsbexchange
netstat -an | grep ESTABLISHED | grep 31090 | grep $(dig +short feed.adsbexchange.com) > /dev/null
if [ $? -eq 0 ]; then
    echo "established mlat connection to feed.adsbexchange.com:31090. HEALTHY"
else
    echo "no established mlat connection to feed.adsbexchange.com:31090. UNHEALTHY"
    EXITCODE=1
fi

# make sure we're listening for beast 
netstat -an | grep LISTEN | grep 30005 > /dev/null
if [ $? -eq 0 ]; then
    echo "listening for beast connections on port 30005. HEALTHY"
else
    echo "not listening for beast connections on port 30005. UNHEALTHY"
    EXITCODE=1
fi

# make sure we're listening for mlat 
netstat -an | grep LISTEN | grep 30105 > /dev/null
if [ $? -eq 0 ]; then
    echo "listening for mlat connections on port 30105. HEALTHY"
else
    echo "not listening for mlat connections on port 30105. UNHEALTHY"
    EXITCODE=1
fi

# death count for adsbexchange-feed
SERVICEDIR=/run/s6/services/adsbexchange-feed
SERVICENAME=$(basename "${SERVICEDIR}")
SERVICE_DEATHS=$(s6-svdt "${SERVICEDIR}" | grep -v "exitcode 0" | wc -l)
if [ $SERVICE_DEATHS -ge 1 ]; then
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. UNHEALTHY"
    EXITCODE=1
else
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. HEALTHY"
fi
s6-svdt-clear "${SERVICEDIR}"

# death count for adsbexchange-stats
SERVICEDIR=/run/s6/services/adsbexchange-stats
SERVICENAME=$(basename "${SERVICEDIR}")
SERVICE_DEATHS=$(s6-svdt "${SERVICEDIR}" | grep -v "exitcode 0" | wc -l)
if [ $SERVICE_DEATHS -ge 1 ]; then
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. UNHEALTHY"
    EXITCODE=1
else
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. HEALTHY"
fi
s6-svdt-clear "${SERVICEDIR}"

# death count for healthcheck
SERVICEDIR=/run/s6/services/healthcheck
SERVICENAME=$(basename "${SERVICEDIR}")
SERVICE_DEATHS=$(s6-svdt "${SERVICEDIR}" | grep -v "exitcode 0" | wc -l)
if [ $SERVICE_DEATHS -ge 1 ]; then
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. UNHEALTHY"
    EXITCODE=1
else
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. HEALTHY"
fi
s6-svdt-clear "${SERVICEDIR}"

# death count for mlat-client
SERVICEDIR=/run/s6/services/mlat-client
SERVICENAME=$(basename "${SERVICEDIR}")
# shellcheck disable=SC2126
SERVICE_DEATHS=$(s6-svdt "${SERVICEDIR}" | grep -v "exitcode 0" | wc -l)
if [ "$SERVICE_DEATHS" -ge 1 ]; then
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. UNHEALTHY"
    EXITCODE=1
else
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. HEALTHY"
fi
s6-svdt-clear "${SERVICEDIR}"

exit $EXITCODE
