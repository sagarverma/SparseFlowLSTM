#!/bin/bash

TOOLS=/home/quadro/lrcn-caffe/build/tools

export HDF5_DISABLE_VERSION_CHECK=1
export PYTHONPATH=.

GLOG_logtostderr=1  $TOOLS/caffe train -solver lstm_solver.prototxt   
echo "Done."
