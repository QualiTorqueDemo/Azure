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

# Default result: approve if no location input found
default result = {"decision": "Approved", "reason": "No location input found, defaulting to approved."}

# Approved: location is in the approved list
result = {"decision": "Approved", "reason": concat("", ["Location '", region, "' is approved."])} if {
    region := input.inputs["Azure Region"]
    region in data.approved_locations
}

# Manual: location requires manual approval
result = {"decision": "Manual", "reason": concat("", ["Location '", region, "' requires manual approval."])} if {
    region := input.inputs["Azure Region"]
    not region in data.approved_locations
    region in data.manual_locations
}

# Denied: location is not in any allowed list
result = {"decision": "Denied", "reason": concat("", ["Location '", region, "' is not allowed. Approved: ", sprintf("%v", [data.approved_locations]), ". Manual: ", sprintf("%v", [data.manual_locations]), "."])} if {
    region := input.inputs["Azure Region"]
    not region in data.approved_locations
    not region in data.manual_locations
}