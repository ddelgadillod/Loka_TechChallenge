#!/bin/bash -euo pipefail
multiqc \
    --filename multiqc_report.html \
    --force \
    --interactive \
    .
