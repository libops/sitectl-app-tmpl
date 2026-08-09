$1 == "repository:" && $2 == expected_repository {
  repository_count++
}

$1 == "commit:" && $2 == expected_commit {
  commit_count++
}

$1 == "path:" && $2 == ".libops/template-contract.yaml" {
  contract_path_count++
}

$1 == "digest:" && $2 == expected_digest {
  digest_count++
}

$1 == "revision:" && $2 == "app-tmpl-v1" {
  revision_count++
}

$1 == "sitectl:" {
  in_sitectl = 1
  next
}

in_sitectl && /^[^[:space:]]/ {
  in_sitectl = 0
}

in_sitectl && $1 == "version:" && $2 == expected_sitectl_version {
  sitectl_version_count++
}

$1 == "-" && $2 == "package:" && $3 == "sitectl-app-tmpl" {
  plugin_count++
}

END {
  valid = repository_count == 1 \
    && commit_count == 1 \
    && contract_path_count == 1 \
    && digest_count == 1 \
    && revision_count == 1 \
    && sitectl_version_count == 1 \
    && plugin_count == 1
  exit !valid
}
