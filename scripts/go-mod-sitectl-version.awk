$1 == "require" && $2 == "(" {
  in_require = 1
  next
}

in_require && $1 == ")" {
  in_require = 0
  next
}

$1 == "require" && $2 == "github.com/libops/sitectl" {
  print $3
  exit
}

in_require && $1 == "github.com/libops/sitectl" {
  print $2
  exit
}
