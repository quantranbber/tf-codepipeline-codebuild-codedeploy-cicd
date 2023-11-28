#!/bin/bash
set -e
pm2 delete my-nodejs-app || true
pm2 start /nodejs/index.js --name my-nodejs-app