#!/usr/bin/env bash

if [ -f "FAILED" ]; then
  cat run-tests.log
  exit 1
else
  exit 0
fi
