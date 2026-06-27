set shell := ["bash", "-euo", "pipefail", "-c"]

contracts_dir := "contracts"
templates_dir := "templates"
basic_contract := contracts_dir / "basic.template.v1.org"
orgize := "cargo run --quiet --manifest-path ../orgize/Cargo.toml --"

default:
    @just --list

check: check-flat-templates trace-generated-templates

template-map:
    @for template in {{templates_dir}}/*.org; do \
      name="${template##*/}"; \
      case "$name" in \
        README.org|ASP_ORG_SKILL.org) continue ;; \
        basic.template.v1.org) \
          printf '%s -> %s\n' "{{basic_contract}}" "$template"; \
          ;; \
        basic.template.v1.with-task.org) \
          printf '%s -> %s\n' "{{contracts_dir}}/agent.task.v1.org" "$template"; \
          ;; \
        *) \
          contract="{{contracts_dir}}/$name"; \
          if [[ -f "$contract" ]]; then \
            printf '%s -> %s\n' "$contract" "$template"; \
          fi; \
          ;; \
      esac; \
    done

check-flat-templates:
    @test ! -e "{{templates_dir}}/output" || { echo "{{templates_dir}}/output is retired; keep generated templates directly under {{templates_dir}}/."; exit 1; }
    @test ! -e "{{contracts_dir}}/examples" || { echo "{{contracts_dir}}/examples is retired; keep audited templates directly under {{templates_dir}}/."; exit 1; }
    @! grep -R -n -F '#+CONTRACT_ORG:' "{{templates_dir}}" "{{contracts_dir}}"
    @! grep -R -n 'templates/output' "{{templates_dir}}" "{{contracts_dir}}"

trace-generated-templates:
    @for template in {{templates_dir}}/*.org; do \
      name="${template##*/}"; \
      case "$name" in \
        README.org|ASP_ORG_SKILL.org) continue ;; \
        basic.template.v1.org) \
          registries=("--org-contract-registry" "{{basic_contract}}") \
          ;; \
        basic.template.v1.with-task.org) \
          registries=("--org-contract-registry" "{{contracts_dir}}/agent.task.v1.org") \
          ;; \
        *) \
          contract="{{contracts_dir}}/$name"; \
          [[ -f "$contract" ]] || continue; \
          registries=("--org-contract-registry" "$contract") \
          ;; \
      esac; \
      printf 'trace %s\n' "$template"; \
      {{orgize}} contract trace "${registries[@]}" "$template" >/dev/null; \
    done
