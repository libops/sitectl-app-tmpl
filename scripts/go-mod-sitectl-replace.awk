$1 == "replace" && $2 == "(" {
  in_replace = 1
  next
}

in_replace && $1 == ")" {
  in_replace = 0
  next
}

$1 == "replace" && $2 == "github.com/libops/sitectl" {
  found = 1
}

in_replace && $1 == "github.com/libops/sitectl" {
  found = 1
}

END {
  exit !found
}
