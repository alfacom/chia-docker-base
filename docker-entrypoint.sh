#!/usr/bin/env bash

# shellcheck disable=SC2154
if [[ -n "${TZ}" ]]; then
  echo "Setting timezone to ${TZ}"
  ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone
fi

${MINER_NAME} init --fix-ssl-permissions

if [[ ${testnet} == 'true' ]]; then
  echo "configure testnet"
  ${MINER_NAME} configure --testnet true
fi

if [[ ${keys} == "persistent" ]]; then
  echo "Not touching key directories"
elif [[ ${keys} == "generate" ]]; then
  echo "to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  ${MINER_NAME} keys generate
elif [[ ${keys} == "copy" ]]; then
  if [[ -z ${ca} ]]; then
    echo "A path to a copy of the farmer peer's ssl/ca required."
    exit
  else
  ${MINER_NAME} init -c "${ca}"
  fi
else
  ${MINER_NAME} keys add -f "${keys}"
fi

for p in ${plots_dir//:/ }; do
  mkdir -p "${p}"
  if [[ ! $(ls -A "$p") ]]; then
    echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
  fi
  ${MINER_NAME} plots add -d "${p}"
done

${MINER_NAME} configure --upnp "${upnp}"

if [[ -n "${log_level}" ]]; then
  ${MINER_NAME} configure --log-level "${log_level}"
fi

if [[ -n ${farmer_address} && -n ${farmer_port} ]]; then
  ${MINER_NAME} configure --set-farmer-peer "${farmer_address}:${farmer_port}"
fi

sed -i 's/localhost/127.0.0.1/g' "$MINER_ROOT/config/config.yaml"

if [[ ${log_to_file} != 'true' ]]; then
  sed -i 's/log_stdout: false/log_stdout: true/g' "$MINER_ROOT/config/config.yaml"
else
  sed -i 's/log_stdout: true/log_stdout: false/g' "$MINER_ROOT/config/config.yaml"
fi

exec "$@"
