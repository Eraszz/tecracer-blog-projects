
##########################################
# Imports
##########################################

package terraform.analysis

import input as tfplan
import future.keywords.in


##########################################
# Parameters
##########################################

blast_radius := 30

weights := {
    "aws_instance":{"delete":100, "create": 6, "modify": 1},
    "aws_s3_bucket":{"delete":100, "create": 20, "modify": 1}
}


##########################################
# Changed & Created Resources
##########################################

res_changes[resource_type] := all {
    some resource_type
    weights[resource_type]
    all := [name |
        name:= tfplan.resource_changes[_]
        name.type == resource_type
    ]
}

res_creations[resource_type] := num {
    some resource_type
    res_changes[resource_type]
    all := res_changes[resource_type]
    creates := [res |  res:= all[_]; res.change.actions[_] == "create"]
    num := count(creates)
}


##########################################
# Policies
##########################################

score := s {
    all := [ x |
            some resource_type
            crud := weights[resource_type];
            new := crud["create"] * res_creations[resource_type];
            x := new
    ]
    s := sum(all)
}

deny_iam_changes {
    some resource in tfplan.resource_changes
    violations := [address |
        address := resource.address
        contains(resource.type, "iam")
    ]
    count(violations) > 0
}

check_instance_type {
    some resource in tfplan.resource_changes
    violations := [address |
        address := resource.address
        resource.type == "aws_instance"
        not resource.change.after.instance_type == "t2.micro"
        ]

    count(violations) > 0
}

default authz := false
authz {
    score < blast_radius
    not deny_iam_changes
    not check_instance_type
}