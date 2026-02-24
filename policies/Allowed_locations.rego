package torque.environment

import future.keywords.if
import future.keywords.in

# This policy enforces location-based governance for Azure environments.
# It checks the "Azure Location" input and returns one of three decisions:
#   - "Approved"  : location is in the approved list (auto-approved)
#   - "Manual"    : location is in the manual list (requires approval)
#   - "Denied"    : location is not in any allowed list
#
# Data object example:
# {
#   "approved_locations": ["westus2", "northeurope"],
#   "manual_locations": ["swedencentral", "francecentral"]
# }

default result = {"decision": "Denied", "reason": "Could not determine Azure location from environment inputs."}

# Approved: location is in the approved list
result = {"decision": "Approved", "reason": concat("", ["Location '", location, "' is approved."])} if {
    some i
    input.inputs[i].name == "Azure Location"
    location := input.inputs[i].value_v2.value
    location in data.approved_locations
}

# Manual: location requires manual approval
result = {"decision": "Manual", "reason": concat("", ["Location '", location, "' requires manual approval."])} if {
    some i
    input.inputs[i].name == "Azure Location"
    location := input.inputs[i].value_v2.value
    not location in data.approved_locations
    location in data.manual_locations
}

# Denied: location is not in any allowed list
result = {"decision": "Denied", "reason": concat("", ["Location '", location, "' is not allowed. Approved locations: ", sprintf("%v", [data.approved_locations]), ". Manual approval locations: ", sprintf("%v", [data.manual_locations]), "."])} if {
    some i
    input.inputs[i].name == "Azure Location"
    location := input.inputs[i].value_v2.value
    not location in data.approved_locations
    not location in data.manual_locations
}

# Auto-approve Execution actions (e.g. Day 2 operations)
result = {"decision": "Approved", "reason": "Execution actions are automatically approved."} if {
    input.action_identifier.entity_type == "Execution"
}