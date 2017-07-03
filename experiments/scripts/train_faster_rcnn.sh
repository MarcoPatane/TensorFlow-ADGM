#!/bin/bash

set -x
set -e

export PYTHONUNBUFFERED="True"

GPU_ID=$1
DATASET=$2
NET=$3

array=( $@ )
len=${#array[@]}
EXTRA_ARGS=${array[@]:3:$len}
EXTRA_ARGS_SLUG=${EXTRA_ARGS// /_}

case ${DATASET} in
  mnist)
    STEPSIZE=50000
    ITERS=54900
    ;;
  *)
    echo "No dataset given"
    exit
    ;;
esac

LOG="experiments/logs/${NET}_${DATASET}_${EXTRA_ARGS_SLUG}.txt.`date +'%Y-%m-%d_%H-%M-%S'`"
exec &> >(tee -a "$LOG")
echo Logging output to "$LOG"

set +x
if [[ ! -z  ${EXTRA_ARGS_SLUG}  ]]; then
    NET_FINAL=output/${NET}/${DATASET}/${EXTRA_ARGS_SLUG}/${NET}_faster_rcnn_iter_${ITERS}.ckpt
else
    NET_FINAL=output/${NET}/${DATASET}/default/${NET}_faster_rcnn_iter_${ITERS}.ckpt
fi
set -x

if [ ! -f ${NET_FINAL}.index ]; then
    if [[ ! -z  ${EXTRA_ARGS_SLUG}  ]]; then
        CUDA_VISIBLE_DEVICES=${GPU_ID} time python ./tools/trainval_net.py \
            --iters ${ITERS} \
            --dataset ${DATASET} \
            --cfg experiments/cfgs/${NET}.yml \
            --tag ${EXTRA_ARGS_SLUG} \
            --net ${NET} \
            --set ${EXTRA_ARGS}
    else
        CUDA_VISIBLE_DEVICES=${GPU_ID} time python ./tools/trainval_net.py \
            --iters ${ITERS} \
            --cfg experiments/cfgs/${NET}.yml \
            --net ${NET} \
            --set ${EXTRA_ARGS}
    fi
fi

./experiments/scripts/test_faster_rcnn.sh $@