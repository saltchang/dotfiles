#!/bin/bash

# 0 = none, 1 = English (Inactive), 2 = Bopomofo (Active)
STATUS=$(fcitx5-remote)

if [[ "$STATUS" == "2" ]]; then
    echo "{ \"alt\": \"bopomofo\" }"
else
    echo "{ \"alt\": \"english\" }"
fi
