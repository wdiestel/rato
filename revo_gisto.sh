#!/bin/bash

# https://developer.github.com/apps/building-github-apps/authenticating-with-github-apps/
# https://developer.github.com/changes/2020-02-14-deprecating-password-auth/

# https://stackoverflow.com/questions/43192556/using-jq-with-bash-to-run-command-for-each-object-in-array

api=https://api.github.com
owner=reta-vortaro
incoming=incoming
xml=xml

mkdir -p ${incoming}
mkdir -p ${xml}
rm ${incoming}/*
#curl -H "Authorization: token $tk" -X GET ${api}/gists | jq '.[] | { description, files: [ (.files[]|values) ][0]} '

# ekstraktu la unuan dosieron el ĉiuj gistoj...
curl -H "Authorization: token ${REVO_TOKEN}" -X GET ${api}/gists | \
    jq -c '.[] | { id, description, updated_at } + [ (.files[]|values) ][0]' | \
while IFS=$"\n" read -r line; do
    id=$(echo $line | jq -r '.id')
    fn=$(echo $line | jq -r '.filename')
    echo "skribas giston por \"${fn}\" al incoming/${id}"
    echo $line | jq '.' > ${incoming}/${id}
done

# elŝutu ĉiujn dosierojn laŭ la gisto-listo
for gist in ${incoming}/*; do
  id=$(cat ${gist} | jq -r '.id')
  sz=$(cat ${gist} | jq -r '.size')
  if [[ sz -lt 1000000 ]]; then
    url=$(cat ${gist} | jq -r '.raw_url')
    echo "elŝutante ${url}..."
    curl -o "${xml}/${id}.xml" -H "Authorization: token ${REVO_TOKEN}" "${url}"
  else
    echo "ERARO: gisto ${id} estas tro granda: ${sz}"
  fi
done
