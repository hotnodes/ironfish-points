#!/bin/bash

if [ $(id -u) != 0 ]; then
  echo "Run script from user root!"
  exit 1
fi

apt --no-install-recommends -y install bc &> /dev/null


SCRIPT_DIR=/opt/tmp/ironfish
SCRIPT_NAME=ironfish-points.sh
SCRIPT_PATH="$SCRIPT_DIR/${SCRIPT_NAME}"
SCRIPT_LOG_FILE="ironfish-points.log"
GRAFFITI_NAME=$(ironfish config:get blockGraffiti | tr -d \")
ACCOUNT_NAME=$(ironfish wallet:which | tr -d \")
IRON_BALANCE=$(ironfish wallet:balance | grep Balance | awk '{print $NF}')


function check_balance(){
  if (( $(echo "${IRON_BALANCE} >= 0.00000003" | bc -l) )); then
    echo "Not enough balanceof IRON: ${IRON_BALANCE} on Account: ${ACCOUNT_NAME}"
    exit 1
  fi
}

function script_autoupdater(){
    crontab -l | grep "${SCRIPT_NAME}" &> /dev/null
    if [[ $? != 0 ]]; then
        mkdir -p ${SCRIPT_DIR}
        curl -s "https://raw.githubusercontent.com/hotnodes/hotnodes-network-scripts/main/ironfish-points.sh" > ${SCRIPT_PATH}
        chmod 700 ${SCRIPT_PATH}
        crontab -l > tmp_cron
        echo " * 1 */2 * * sh -c ${SCRIPT_PATH} &> ${SCRIPT_DIR}/${SCRIPT_LOG_FILE}" &>> tmp_cron
        crontab tmp_cron
        rm tmp_cron
    fi
}

check_balance
script_autoupdater


echo "Mint asset started..."
ironfish wallet:mint --name=${GRAFFITI_NAME} --metadata=${GRAFFITI_NAME} --amount=3000 --fee=0.00000001 --confirm
echo "Waiting 10 min to complete mint operation..."

sleep 600

MINTED_ASSET_ID=$(ironfish wallet:balances | grep $GRAFFITI_NAME | grep -v Account | tail -1 | awk '{print $2}')
echo "Minted asset ID = ${MINTED_ASSET_ID}"

echo "Performing burn & send operations..."

ironfish wallet:burn --amount=1500 --fee=0.00000001 --assetId=$MINTED_ASSET_ID --confirm | grep Hash | awk '{print $NF}'
echo "Waiting 10 min to complete burn operation..."
sleep 600

ironfish wallet:send --to dfc2679369551e64e3950e06a88e68466e813c63b100283520045925adbe59ca --amount=1500 --fee=0.00000001 --assetId=$MINTED_ASSET_ID --confirm 
