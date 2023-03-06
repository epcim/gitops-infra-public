#!/bin/sh

# replaces only upper case variables found in manifests (ie, to protect CRDs onse, ie PrometheusRules
perl -pe 's/\$(\{)?([A-Z_]\w*)(?(1)\})/$ENV{$2}/g'


