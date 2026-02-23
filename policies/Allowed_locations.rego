package torque.environment

import future.keywords.if
import future.keywords.in

# DEBUG: Dump the actual input structure to see what Torque sends
# Remove this rule and uncomment the real rules below once we know the structure

result = {"decision": "Denied", "reason": concat("", [
    "DEBUG - Full input: ",
    sprintf("%v", [input])
])} if {
    input
}

# # Data object example:
# # {
# #   "approved_locations": ["westus2", "northeurope"],
# #   "manual_locations": ["swedencentral", "francecentral"]
# # }
#
# default result = {"decision": "Denied", "reason": "Could not determine Azure Region from environment inputs."}
#
# result = {"decision": "Approved", "reason": concat("", ["Location '", region, "' is approved."])} if {
#     some i
#     input.inputs[i].name == "Azure Region"
#     region := input.inputs[i].value
#     region in data.approved_locations
# }
#
# result = {"decision": "Manual", "reason": concat("", ["Location '", region, "' requires manual approval."])} if {
#     some i
#     input.inputs[i].name == "Azure Region"
#     region := input.inputs[i].value
#     not region in data.approved_locations
#     region in data.manual_locations
# }
#
# result = {"decision": "Denied", "reason": concat("", ["Location '", region, "' is not allowed. Approved: ", sprintf("%v", [data.approved_locations]), ". Manual: ", sprintf("%v", [data.manual_locations]), "."])} if {
#     some i
#     input.inputs[i].name == "Azure Region"
#     region := input.inputs[i].value
#     not region in data.approved_locations
#     not region in data.manual_locations
# }