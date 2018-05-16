#!/bin/bash

for i in *.sh; do
  if [[ "$i" != `basename "$0"` ]]; then
    ./$i
  fi
done

