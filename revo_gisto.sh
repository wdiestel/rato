#!/bin/bash

# Github API, Auth
# https://developer.github.com/apps/building-github-apps/authenticating-with-github-apps/
# https://developer.github.com/changes/2020-02-14-deprecating-password-auth/

# JQ en bash-skriptoj
# https://stackoverflow.com/questions/43192556/using-jq-with-bash-to-run-command-for-each-object-in-array

# HMAC, JWT w. OpenSSL / bash
# https://stackoverflow.com/questions/7285059/hmac-sha1-in-bash
# https://willhaley.com/blog/generate-jwt-with-bash/

api=https://api.github.com
owner=reta-vortaro
gists=gists
xml=xml

getartid () {
    local file="${xml}/$1"
    local idline=$(grep "[$]Id" ${file})
    local id1=${idline#*\"$}
    local id=${id1%$\"*}
    echo "$id"
}

mkdir -p ${gists}
mkdir -p ${xml}
rm ${gists}/*
#curl -H "Authorization: token $tk" -X GET ${api}/gists | jq '.[] | { description, files: [ (.files[]|values) ][0]} '

# ekstraktu la unuan dosieron el ĉiuj gistoj...
echo "## preni ${api}/gists..."
curl -H "Authorization: token ${REVO_TOKEN}" -X GET ${api}/gists | \
    jq -c '.[] | { id, description, updated_at } + [ (.files[]|values) ][0]' | \
while IFS=$"\n" read -r line; do
    id=$(echo $line | jq -r '.id')
    fn=$(echo $line | jq -r '.filename')
    echo "# gisto \"${fn}\" -> ${gists}/${id}"
    echo $line | jq '.' > ${gists}/${id}
done

# elŝutu ĉiujn dosierojn laŭ la gisto-listo
for gist in ${gists}/*; do
  id=$(cat ${gist} | jq -r '.id')
  sz=$(cat ${gist} | jq -r '.size')
  tp=$(cat ${gist} | jq -r '.type')
  if [[ "${tp}" == "application/xml" && "${sz}" -lt 1000000 ]]; then
    url=$(cat ${gist} | jq -r '.raw_url')
    echo "## preni ${url}..."
    curl -o "${xml}/${id}.xml" -H "Authorization: token ${REVO_TOKEN}" "${url}"
    art_id=$(getartid "${id}.xml") && echo "Id: ${art_id}"
  else
    echo "ERARO: gisto ${id} havas malĝustan tipon aŭ estas tro granda:"
    cat ${gist}
  fi
done
