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

default result = {"decision": "Denied", "reason": "Could not determine Azure Region from environment inputs."}

# Approved: location is in the approved list
result = {"decision": "Approved", "reason": concat("", ["Location '", region, "' is approved."])} if {
    some i
    input.inputs[i].name == "Azure Region"
    region := input.inputs[i].value_v2.value
    region in data.approved_locations
}

# Manual: location requires manual approval
result = {"decision": "Manual", "reason": concat("", ["Location '", region, "' requires manual approval."])} if {
    some i
    input.inputs[i].name == "Azure Region"
    region := input.inputs[i].value_v2.value
    not region in data.approved_locations
    region in data.manual_locations
}

# Denied: location is not in any allowed list
result = {"decision": "Denied", "reason": concat("", ["Location '", region, "' is not allowed. Approved: ", sprintf("%v", [data.approved_locations]), ". Manual: ", sprintf("%v", [data.manual_locations]), "."])} if {
    some i
    input.inputs[i].name == "Azure Region"
    region := input.inputs[i].value_v2.value
    not region in data.approved_locations
    not region in data.manual_locations
}

# Auto-approve Execution actions (e.g. Day 2 operations)
result = {"decision": "Approved", "reason": "Execution actions are automatically approved."} if {
    input.action_identifier.entity_type == "Execution"
}