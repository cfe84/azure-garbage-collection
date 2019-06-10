#!/bin/bash

for LOGICAPP in `ls logicapps/logicapp-*.json`; do
    node logicapps/parameterize-logicapp.js $LOGICAPP
done