#!/usr/bin/env bash

echo "tess torchBin"
for i in {1..10}
do
  nix shell -f pianotrans-tests.nix torchBin --command pianotrans test/cut_liszt.opus | grep 'Transcribe time:'
done

echo "test mklDnnOn, no Accelerate.framework"
for i in {1..10}
do
  nix shell github:nixos/nixpkgs/144ede9ee61ecfcc2d6b322398647e6908aa0db4#pianotrans --command pianotrans test/cut_liszt.opus | grep 'Transcribe time:'
done

echo "test mklDnnOff, has Accelerate.framework"
for i in {1..10}
do
  nix shell -f pianotrans-tests.nix mklDnnOff --command pianotrans test/cut_liszt.opus | grep 'Transcribe time:'
done

echo "test mklDnnOn, has Accelerate.framework"
for i in {1..10}
do
  nix shell -f pianotrans-tests.nix mklDnnOn --command pianotrans test/cut_liszt.opus | grep 'Transcribe time:'
done
