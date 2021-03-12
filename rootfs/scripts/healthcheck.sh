#!/usr/bin/env bash
# shellcheck disable=SC1091
set -e

# source healthcheck functions
source /opt/healthchecks-framework/healthchecks.sh

EXITCODE=0

if [ -f "/run/adsbexchange-feed/aircraft.json" ]; then

    # get latest timestamp of readsb json update
    TIMESTAMP_LAST_READSB_UPDATE=$(jq '.now' < /run/adsbexchange-feed/aircraft.json)

    # get current timestamp
    TIMESTAMP_NOW=$(date +"%s.%N")

    # makse sure readsb has updated json in past 60 seconds
    TIMEDELTA=$(echo "$TIMESTAMP_NOW - $TIMESTAMP_LAST_READSB_UPDATE" | bc)
    if [ "$(echo "$TIMEDELTA" \< 60 | bc)" -ne 1 ]; then
        echo "adsbexchange-feed last updated: ${TIMESTAMP_LAST_READSB_UPDATE}, now: ${TIMESTAMP_NOW}, delta: ${TIMEDELTA}. UNHEALTHY"
        EXITCODE=1
    else
        echo "adsbexchange-feed last updated: ${TIMESTAMP_LAST_READSB_UPDATE}, now: ${TIMESTAMP_NOW}, delta: ${TIMEDELTA}. HEALTHY"
    fi

    # get number of aircraft
    NUM_AIRCRAFT=$(jq '.aircraft | length' < /run/adsbexchange-feed/aircraft.json)
    if [ "$NUM_AIRCRAFT" -lt 1 ]; then
        echo "total aircraft: $NUM_AIRCRAFT. UNHEALTHY"
        EXITCODE=1
    else
        echo "total aircraft: $NUM_AIRCRAFT. HEALTHY"
    fi

else

    echo "WARNING: Cannot find /run/adsbexchange-feed/aircraft.json, so skipping some checks."

fi

# make sure we're feeding beast/beastreduce & mlat data to adsbexchange
MYIP_JSON_OUTPUT=$(curl --silent -o - https://www.adsbexchange.com/myip/)
if echo "$MYIP_JSON_OUTPUT" | grep -i beast "$TEMPFILE" > /dev/null 2>&1; then
    echo "ADSBx reports beast connection: HEALTHY"
else
    echo "ADSBx reports beast connection: UNHEALTHY"
    EXITCODE=1
fi
if echo "$MYIP_JSON_OUTPUT" | grep -i mlat "$TEMPFILE" > /dev/null 2>&1; then
    echo "ADSBx reports MLAT connection: HEALTHY"
else
    echo "ADSBx reports MLAT connection: UNHEALTHY"
    EXITCODE=1
fi

# make sure we're listening for beast 
if check_tcp4_socket_listening ANY 30005; then
    echo "listening for beast connections on port 30005. HEALTHY"
else
    echo "not listening for beast connections on port 30005. UNHEALTHY"
    EXITCODE=1
fi

# make sure we're listening for mlat 
if check_tcp4_socket_listening ANY 30105; then
    echo "listening for mlat connections on port 30105. HEALTHY"
else
    echo "not listening for mlat connections on port 30105. UNHEALTHY"
    EXITCODE=1
fi

# death count for adsbexchange-feed
SERVICEDIR=/run/s6/services/adsbexchange-feed
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

# death count for adsbexchange-stats
SERVICEDIR=/run/s6/services/adsbexchange-stats
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

# death count for healthcheck
SERVICEDIR=/run/s6/services/healthcheck
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
