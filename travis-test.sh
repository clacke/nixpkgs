#! /usr/bin/env bash

derivation=racket

echo -en 'travis_fold:start:deps\r'

nix-shell -A $derivation --run true

echo -en 'travis_fold:end:deps\r'

nix-build -A $derivation
