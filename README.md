# dcind (Docker-Compose-in-Docker)

Forked from [meAmidos/dcind](https://github.com/meAmidos/dcind).

## Changes from Upstream

- Add `jq` and `git`, since we need to run [ansible-role-tester](https://github.com/fubarhouse/ansible-role-tester) and parse the report.
- Create `systemd` cgroup for ubuntu1804 support in images.

## Sample Pipeline

```yaml
resources:
  - name: issmirnov.compile_zsh
    type: git
    source:
      uri: https://github.com/issmirnov/ansible-role-compile-zsh.git
      branch: master

jobs:
  - name: issmirnov.compile_zsh
    plan:
      - aggregate:
        - get: ansible-role-compile-zsh
          resource: issmirnov.compile_zsh
          params: {depth: 1}
          trigger: true
      - task: compile ansible-role-test binary
        config:
          <<: *compile_art
      - task: run ansible-role-tester
        privileged: true
        params:
          ROLE: ansible-role-compile-zsh
        config:
          <<: *ansible_role_tester
          inputs:
            - name: art_bin
            - name: ansible-role-compile-zsh
          outputs:
            - name: report

# Compile ansible-role-tester
compile_art: &compile_art
  platform: linux
  image_resource:
    type: docker-image
    source:
      repository: golang
      tag:  1.9.3
  outputs:
    - name: art_bin
  run:
    path: sh
    args:
      - -exc
      - |
        export ROOT=$PWD
        export GOPATH=$PWD
        go get github.com/fubarhouse/ansible-role-tester
        cd src/github.com/fubarhouse/ansible-role-tester
        CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build  -ldflags '-w -extldflags "-static"'
        cp ansible-role-tester $ROOT/art_bin/

# Define job to run ansible-role-tester        
ansible_role_tester: &ansible_role_tester
  platform: linux
  image_resource:
    type: docker-image
    source:
      repository: issmirnov/dcind
  run:
    path: sh
    args:
      - -exc
      - |
        source /docker-lib.sh > /dev/null 2>&1
        start_docker > /dev/null 2>&1

        mkdir -p report # output
        export ROOT=$PWD
        cp art_bin/ansible-role-tester $ROLE
        cd $ROLE

        ./ansible-role-tester full -t ubuntu1804 --extra-roles $ROOT --library "$(pwd)/tests/library" --report --report-output ../report/report.json

        if [[ "$(jq '.Ansible.Run.Result' ../report/report.json)" != "true" ]]; then
            echo "Run failed";
            exit 1;
        fi
        if [[ "$(jq '.Ansible.Idempotence.Result' ../report/report.json)" != "true" ]]; then
            echo "Idempotence failed";
            exit 2;
        fi
```
