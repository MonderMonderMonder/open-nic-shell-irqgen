#!/bin/bash

module load xilinx/vivado/2022.2 
module load mentor/questasim/2023.4 

if ! test -d lib/; then
  mkdir lib/
  ln -s ../../../../cocotb/{axis,tb}.py lib/
  touch lib/__init__.py
fi

make
