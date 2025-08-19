#!/bin/bash
set -e

touch elm.json # touch to force re-run of generate.js
make build

cp -r ./dist/* /usr/share/nginx/html/ 

# remove node_modules to save space
find ./plugins -maxdepth 2 -name node_modules -exec rm -rf {} \; || true

chown -R $DOCKER_UID /usr/share/nginx/html/*

sed -i "s|http://localhost:9000|$REST_URL|g" /usr/share/nginx/html/assets/index*.js 

TRANSLATION_FILES_HASH=`sha256sum ./dist/.vite/manifest.json | awk '{print substr($1, 0, 8)}'`
sed -i "s|{{TRANSLATION_FILES_HASH}}|$TRANSLATION_FILES_HASH|g" /usr/share/nginx/html/assets/index*.js 

exec "$@"
