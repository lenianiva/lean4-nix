{ pkgs, ... }:
{
  fetchManifests = pkgs.writeShellApplication {
    name = "fetchManifest";
    text = /*Bash*/ ''
      rm manifests/*
      echo '{' > 'manifests/default.nix'

      curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        'https://api.github.com/repos/leanprover/lean4/releases' |
        jq '.[].tag_name' |
        tr -d '"' |
        while read -r tag; do
          rev="$(curl -L \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "https://api.github.com/repos/leanprover/lean4/git/ref/tags/$tag" |
            jq '.object.sha' |
            tr -d '"')"

          printf '{\n  tag = "%s";\n  rev = "%s";\n}' "$tag" "$rev" > "manifests/$tag.nix"
          printf '  "%s" = import ./%s.nix;\n' "$tag" "$tag" >> 'manifests/default.nix'
        done

      echo '}' >> 'manifests/default.nix'
    '';
  };
}
