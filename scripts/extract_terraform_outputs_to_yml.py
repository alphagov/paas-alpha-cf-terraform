#!/usr/bin/env python

import json
import yaml
import sys

outputs=json.load(sys.stdin)
terraform_outputs = {
        'terraform_outputs': outputs['modules'][0]['outputs']
}

print yaml.safe_dump(terraform_outputs, default_flow_style=False, explicit_start=True)

