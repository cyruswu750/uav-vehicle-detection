#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: [WEIGHTS=path/to/weights.pt] scripts/reproduce.sh <folder of UAV images>" >&2
  exit 1
fi

IMAGES="$(realpath "$1")"
YOLOV5_COMMIT="dd104811c2e0419529aa7177ce160321e9694837"
MODEL="${MODEL:-yolov5s.pt}"
EPOCHS="${EPOCHS:-100}"
BATCH="${BATCH:-16}"
WORKDIR="${WORKDIR:-third_party/yolov5}"
WEIGHTS="${WEIGHTS:-}"

if [ -n "$WEIGHTS" ]; then
  WEIGHTS="$(realpath "$WEIGHTS")"
fi

if [ ! -d "$WORKDIR" ]; then
  git clone https://github.com/ultralytics/yolov5 "$WORKDIR"
fi
git -C "$WORKDIR" checkout "$YOLOV5_COMMIT"
pip install -r "$WORKDIR/requirements.txt"

cd "$WORKDIR"

if [ -z "$WEIGHTS" ]; then
  python train.py \
    --data VisDrone.yaml \
    --weights "$MODEL" \
    --img 640 \
    --epochs "$EPOCHS" \
    --batch-size "$BATCH" \
    --name visdrone \
    --exist-ok

  WEIGHTS="runs/train/visdrone/weights/best.pt"

  python val.py \
    --data VisDrone.yaml \
    --weights "$WEIGHTS" \
    --img 640 \
    --task val
fi

python detect.py \
  --weights "$WEIGHTS" \
  --source "$IMAGES" \
  --img 640 \
  --name uav \
  --exist-ok

echo "Annotated images written to $WORKDIR/runs/detect/uav"
