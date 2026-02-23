package torque.environment

import future.keywords.if
import future.keywords.in

# This policy enforces location-based governance for Azure environments.
# It checks the "Azure Region" input and returns one of three decisions:
#   - "Approved"  : location is in the approved list (auto-approved)
#   - "Manual"    : location is in the manual list (requires approval)
#   - "Denied"    : location is not in any allowed list
#
# Data object example:
# {
#   "approved_locations": ["westus2", "northeurope"],
#   "manual_locations": ["swedencentral", "francecentral"]
# }
#
# Any location not in either list will be denied.

# Helper: extract the "Azure Region" input value
# Format 1: inputs is an array of {name, value} objects
azure_region := value if {
    some i
    input.inputs[i].name == "Azure Region"
    value := input.inputs[i].value
}

# Format 2: inputs is a map with key "Azure Region"
azure_region := value if {
    value := input.inputs["Azure Region"]
}

# Format 3: inputs is a map with key "azure_region" (snake_case)
azure_region := value if {
    value := input.inputs.azure_region
}

# Format 4: inputs is a map with key "Azure_Region"
azure_region := value if {
    value := input.inputs.Azure_Region
}

# Deny if no Azure Region input is found — include debug info
result = {"decision": "Denied", "reason": concat("", [
    "No 'Azure Region' input found. Available input keys: ",
    sprintf("%v", [input_keys])
])} if {
    not azure_region
    input_keys := {k | input.inputs[k]}
}

# Fallback deny if we can't even read input keys
result = {"decision": "Denied", "reason": "No 'Azure Region' input found and could not read input structure."} if {
    not azure_region
    not input.inputs
}

# Deny if data variables are not arrays
result = {"decision": "Denied", "reason": "The data variables 'approved_locations' and 'manual_locations' must be arrays."} if {
    azure_region
    not is_array(data.approved_locations)
}

result = {"decision": "Denied", "reason": "The data variables 'approved_locations' and 'manual_locations' must be arrays."} if {
    azure_region
    not is_array(data.manual_locations)
}

# Approved: location is in the approved list
result = {"decision": "Approved", "reason": concat("", ["Location '", azure_region, "' is approved."])} if {
    is_array(data.approved_locations)
    is_array(data.manual_locations)
    azure_region in data.approved_locations
}

# Manual: location is in the manual approval list
result = {"decision": "Manual", "reason": concat("", ["Location '", azure_region, "' requires manual approval."])} if {
    is_array(data.approved_locations)
    is_array(data.manual_locations)
    not azure_region in data.approved_locations
    azure_region in data.manual_locations
}

# Denied: location is not in any allowed list
result = {"decision": "Denied", "reason": concat("", ["Location '", azure_region, "' is not allowed. Approved: ", sprintf("%v", [data.approved_locations]), ". Manual approval: ", sprintf("%v", [data.manual_locations]), "."])} if {
    is_array(data.approved_locations)
    is_array(data.manual_locations)
    not azure_region in data.approved_locations
    not azure_region in data.manual_locations
}