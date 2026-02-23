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
azure_region := value if {
    some i
    input.inputs[i].name == "Azure Region"
    value := input.inputs[i].value
}

# Deny if no Azure Region input is found
result = {"decision": "Denied", "reason": "No 'Azure Region' input found in the environment."} if {
    not azure_region
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