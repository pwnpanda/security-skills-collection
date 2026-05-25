#!/usr/bin/env bash
# Link every skill in this repo into ~/.claude/skills so Claude Code
# can load them. Idempotent: re-running is safe and reports skips
# instead of clobbering. Conflicts (existing real dirs or foreign
# symlinks at the target path) are warned about and left untouched.
set -euo pipefail

LOG_LEVEL="${LOG_LEVEL:-INFO}"
if [[ "${LOG_LEVEL}" == "DEBUG" ]]; then
  set -x
fi

repo_root="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
skills_src="${repo_root}/skills"
refs_src="${repo_root}/references"

target_dir="${HOME}/.claude/skills"
refs_target="${HOME}/.claude/references"

if [[ ! -d "${skills_src}" ]]; then
  echo "ERROR: ${skills_src} does not exist" >&2
  exit 1
fi
if [[ ! -d "${refs_src}" ]]; then
  echo "ERROR: ${refs_src} does not exist" >&2
  exit 1
fi

mkdir -p "${target_dir}"

linked=0
skipped=0
conflicts=0

link_one() {
  local src="$1"
  local dst="$2"
  local label="$3"

  if [[ -L "${dst}" ]]; then
    local current
    current="$(readlink "${dst}")"
    if [[ "${current}" == "${src}" ]]; then
      echo "skipped (already linked): ${label}"
      skipped=$((skipped + 1))
      return
    fi
    echo "WARN (conflict — left alone): ${label} -> ${current}"
    conflicts=$((conflicts + 1))
    return
  fi

  if [[ -e "${dst}" ]]; then
    echo "WARN (conflict — left alone): ${label} (real file or dir at target)"
    conflicts=$((conflicts + 1))
    return
  fi

  ln -s "${src}" "${dst}"
  echo "linked: ${label}"
  linked=$((linked + 1))
}

shopt -s nullglob
for skill_path in "${skills_src}"/*/; do
  skill_name="$(basename "${skill_path}")"
  link_one "${skills_src}/${skill_name}" "${target_dir}/${skill_name}" "${skill_name}"
done
shopt -u nullglob

link_one "${refs_src}" "${refs_target}" "references"

echo ""
echo "${linked} linked, ${skipped} skipped, ${conflicts} conflicts"
