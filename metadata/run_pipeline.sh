#!/usr/bin/env bash
# The metadata pipeline, in the order that actually runs. This file is the run
# order; nothing else restates it (ARCHITECTURE.md §4).
#
#   metadata/run_pipeline.sh            # every stage, from the repo root
#   metadata/run_pipeline.sh 01 03      # just those stages
#
# 01 metadata.csv   per table, from __dataset.json summary + columns and the __units header
# 02 biblio.csv     dictionary_auto.csv joined to __dataset.json; drops rows with no __dataset.json
#
# Every stage reads tracked files only: tables are listed by
# output/<t>__dataset.json (metadata/tables.R), and stage 01 takes its counts
# from that file's summary, never from a core CSV. So any clone gives the same
# outputs, with or without the gitignored cores (#66).
# 03 tags.csv       tags_auto.csv with tags_human.csv cells winning; vocabulary enforced
# 11 status.json    counts and the appended history row; reads 01, 03 and validate/report.csv
# 12 table_locations.csv  homepage map points, --offline: keeps the points the
#                   uploader read from Redivis, places new tables from
#                   geographicCoverage or tags/locations_human.csv
#
# Nothing here uploads. metadata/upload_meta.py ships the three CSVs to the
# Redivis dataset eco_meta as a draft; publishing is a human click.
set -euo pipefail
cd "$(dirname "$0")/.."
DEFAULT_ORDER=(01 02 03 11 12)
# A case, not an associative array: macOS ships bash 3.2, which has no declare -A (#65).
stage_script() {
  case "$1" in
    01) echo 01_metadata.R ;;
    02) echo 02_biblio.R ;;
    03) echo 03_tags.R ;;
    11) echo 11_status.R ;;
    12) echo table_locations ;;
    *)  echo "" ;;
  esac
}
if [[ $# -gt 0 ]]; then stages=("$@"); else stages=("${DEFAULT_ORDER[@]}"); fi
for s in "${stages[@]}"; do
  f="$(stage_script "$s")"
  if [[ -z "$f" ]]; then echo "run_pipeline.sh: unknown stage $s" >&2; exit 2; fi
  if [[ "$f" == table_locations ]]; then
    python3 tools/table_locations.py --offline
  else
    Rscript "metadata/$f"
  fi
done
