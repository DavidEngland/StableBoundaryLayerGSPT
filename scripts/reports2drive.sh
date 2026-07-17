#!/bin/bash
set -euo pipefail
cp compile_reports.pdf ~/Documents/drive/scm
find results/ -type f -name "*.pdf" -exec cp -v {} ~/Documents/drive/scm/ \;