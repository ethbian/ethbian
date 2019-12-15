#!/bin/bash

echo ""
echo "*****************************************"
echo "*    ETHBIAN MONITORING CONFIG v0.1     *"
echo "*****************************************"
echo ""

INFLUX_SERVICE='influxdb'
COLLECTD_SERVICE='collectd'
GRAFANA_SERVICE='grafana-server'
PEERSGEO_USER='eth'
PEERSGEO_SCRIPT='geth_peers_geo2influx.py'
PEERSGEO_LOG='/var/log/geo2influx.log'

# --------------------------- helpers -------------------
function get_status () {
   systemctl $1 --quiet $2
   if [ $? -ne 0 ]; then
      STATUS=false
   else
      STATUS=true
   fi
}

function enable_services () {
   for SERVICE in $INFLUX_SERVICE $COLLECTD_SERVICE $GRAFANA_SERVICE; do
      sudo systemctl enable $SERVICE
   done
}

function disable_services () {
   for SERVICE in $INFLUX_SERVICE $COLLECTD_SERVICE $GRAFANA_SERVICE; do
      sudo systemctl disable $SERVICE
   done
}

function start_services () {
   for SERVICE in $INFLUX_SERVICE $COLLECTD_SERVICE $GRAFANA_SERVICE; do
      sudo systemctl restart $SERVICE
   done
}

function stop_services () {
   for SERVICE in $GRAFANA_SERVICE $COLLECTD_SERVICE $INFLUX_SERVICE; do
      sudo systemctl stop $SERVICE
   done
}

function enable_cron () {
   CMD=`sudo grep $PEERSGEO_SCRIPT /var/spool/cron/crontabs/$PEERSGEO_USER |grep -c -v '^ *#'`
   if [ $CMD -eq 0 ]; then
      sudo /bin/bash -c "echo '*/30 * * * * /usr/local/bin/$PEERSGEO_SCRIPT >> $PEERSGEO_LOG 2>&1' >> /var/spool/cron/crontabs/$PEERSGEO_USER"
   fi
}

function disable_cron () {
   CMD=`sudo grep $PEERSGEO_SCRIPT /var/spool/cron/crontabs/$PEERSGEO_USER |grep -c -v '^ *#'`
   if [ $CMD -ne 0 ]; then
      sudo sed -i "/$PEERSGEO_SCRIPT/d" /var/spool/cron/crontabs/$PEERSGEO_USER
   fi
}

# --------------------------- functions -------------------
function main_info () {
    whiptail --title ' monitoring info ' --backtitle 'Ethbian monitoring configuration' \
    --msgbox "Ethbian monitoring:\n\n\
    - collectd (collects system/geth data)\n\
    - geth_peers... script (geolocation, eth's crontab)\n\
    - influx database (data storage)\n\
    - grafana (data visualization)\n\n\
        Here you can switch all of them on or off"\
    14 60
}

function check_status () {
    echo 'Checking status...'
    get_status 'is-active' $INFLUX_SERVICE
    INFLUX_RUN=$STATUS
    get_status 'is-enabled' $INFLUX_SERVICE
    INFLUX_ENABLED=$STATUS

    get_status 'is-active' $COLLECTD_SERVICE
    COLLECTD_RUN=$STATUS
    get_status 'is-enabled' $COLLECTD_SERVICE
    COLLECTD_ENABLED=$STATUS

    get_status 'is-active' $GRAFANA_SERVICE
    GRAFANA_RUN=$STATUS
    get_status 'is-enabled' $GRAFANA_SERVICE
    GRAFANA_ENABLED=$STATUS

    PEERSGEO_STATUS=`sudo grep $PEERSGEO_SCRIPT /var/spool/cron/crontabs/$PEERSGEO_USER |grep -c -v '^ *#'`
    if [ $PEERSGEO_STATUS -eq 0 ]; then
        PEERSGEO_STATUS=false
    else
        PEERSGEO_STATUS=true
    fi

    if [ "$INFLUX_RUN" = true ] && [ "$INFLUX_ENABLED" = true ] && [ "$COLLECTD_RUN" = true ] && [ "$COLLECTD_ENABLED" = true ] && [ "$GRAFANA_RUN" = true ] && [ "$GRAFANA_ENABLED" = true ] && [ "$PEERSGEO_STATUS" = true ]; then
        ALL_SERVICES='running'
    elif [ "$INFLUX_RUN" = false ] && [ "$INFLUX_ENABLED" = false ] && [ "$COLLECTD_RUN" = false ] && [ "$COLLECTD_ENABLED" = false ] && [ "$GRAFANA_RUN" = false ] && [ "$GRAFANA_ENABLED" = false ] && [ "$PEERSGEO_STATUS" = false ]; then
        ALL_SERVICES='stopped'
    else
        ALL_SERVICES='mixed'
    fi
}

function main_status () {
    COLLECTD_SUMMARY=' collectd:   '
    if [ "$COLLECTD_ENABLED" = true ]; then
        COLLECTD_SUMMARY+=' [ENABLED]   '
    else
        COLLECTD_SUMMARY+=' [DISABLED]  '
    fi
    if [ "$COLLECTD_RUN" = true ]; then
        COLLECTD_SUMMARY+=' [RUNNING] '
    else
        COLLECTD_SUMMARY+=' [STOPPED] '
    fi

    INFLUX_SUMMARY=' influxdb:   '
    if [ "$INFLUX_ENABLED" = true ]; then
        INFLUX_SUMMARY+=' [ENABLED]   '
    else
        INFLUX_SUMMARY+=' [DISABLED]  '
    fi
    if [ "$INFLUX_RUN" = true ]; then
        INFLUX_SUMMARY+=' [RUNNING] '
    else
        INFLUX_SUMMARY+=' [STOPPED] '
    fi

    GRAFANA_SUMMARY=' grafana:    '
    if [ "$GRAFANA_ENABLED" = true ]; then
        GRAFANA_SUMMARY+=' [ENABLED]   '
    else
        GRAFANA_SUMMARY+=' [DISABLED]  '
    fi
    if [ "$GRAFANA_RUN" = true ]; then
        GRAFANA_SUMMARY+=' [RUNNING] '
    else
        GRAFANA_SUMMARY+=' [STOPPED] '
    fi

    PEERSGEO_SUMMARY=' peers2geo:       -  '
    if [ "$PEERSGEO_STATUS" = true ]; then
        PEERSGEO_SUMMARY+='      [RUNNING] '
    else
        PEERSGEO_SUMMARY+='      [STOPPED] '
    fi

    whiptail --title ' monitoring info ' --backtitle 'Ethbian monitoring status' \
    --msgbox "Monitoring services:\n\n\
    service      autostart     status\n\
    -------------------------------------\n\
    $COLLECTD_SUMMARY\n\
    $INFLUX_SUMMARY\n\
    $GRAFANA_SUMMARY\n\
    $PEERSGEO_SUMMARY\n\n"\
    14 60
}

function main_menu () {
    check_status

    if [ "$ALL_SERVICES" == 'running' ]; then
        INFO="\nAll the services are enabled and running"
        MENU=('1)' 'stop and disable all the services' '2)' 'restart the services' '3)' 'stop the services'  '4)' 'disable geo2ip cronjob' '5)' 'show monitoring services status')
    elif [ "$ALL_SERVICES" == 'stopped' ]; then
        INFO="\nAll the services are disabled and stopped"
        MENU=('1)' 'start and enable all the services' '2)' 'start the services' '3)' 'enable the services'  '4)' 'enable geo2ip cronjob' '5)' 'show monitoring services status')
    else
        INFO="\nNot all of the services are enabled or running"
        MENU=('1)' 'restart and enable all the services' '2)' 'stop and disable all the services' '3)' 'enable geo2ip cronjob' '4)' 'disable geo2ip cronjob' '5)' 'show monitoring services status')
    fi

    ACTION=$(
        whiptail --title ' monitoring info ' --cancel-button 'Exit' --menu "$INFO" 16 60 5 "${MENU[@]}" \
        3>&2 2>&1 1>&3
    )
    _CANCELLED=$?
    exec 3>&-

    if [ $_CANCELLED -ne 0 ]; then
        echo ""
        echo "Bye bye..."
        exit 0
    fi

    if [ "$ALL_SERVICES" == 'running' ]; then
        case "$ACTION" in
            '1)')
                stop_services
                disable_cron
                disable_services
            ;;
            '2)')
                start_services
            ;;
            '3)')
                stop_services
            ;;
            '4)')
                disable_cron
            ;;
            '5)')
                check_status
                main_status
            ;;
        esac
    elif [ "$ALL_SERVICES" == 'stopped' ]; then
        case "$ACTION" in
            '1)')
                start_services
                enable_cron
                enable_services
            ;;
            '2)')
                start_services
            ;;
            '3)')
                enable_services
            ;;
            '4)')
                enable_cron
            ;;
            '5)')
                check_status
                main_status
            ;;
        esac
    else
        case "$ACTION" in
            '1)')
	            start_services
	            enable_cron
	            enable_services
            ;;
            '2)')
                stop_services
                disable_cron
                disable_services
            ;;
            '3)')
                enable_cron
            ;;
            '4)')
                disable_cron
            ;;
            '5)')
                check_status
                main_status
            ;;
        esac
    fi
}

# --------------------------- main -------------------
main_info
check_status
main_status
while :
do
    main_menu
done
