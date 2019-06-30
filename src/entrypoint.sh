#!/bin/bash
# if a command fails, exit
set -e
# treat unset variables as error
set -u
# if any command in a pipe fails, fail
set -o pipefail


# This is populated by our secret from the Workflow file.
if [[ -z "$GITHUB_TOKEN" ]]; then
	echo "Set the GITHUB_TOKEN env variable."
	exit 1
fi


BASE_COMMIT=$(
    jq \
        --raw-output \
        .check_suite.pull_requests[0].base.sha \
        "$GITHUB_EVENT_PATH"
)
REPO_NAME=$(
    jq --raw-output .repository.name "$GITHUB_EVENT_PATH"
)
ACTION=$(
    jq --raw-output .action "$GITHUB_EVENT_PATH"
)


main() {
    if [ "$ACTION" == 'completed' ]; then
        exit
    fi
    # Get files Added or Modified wrt base commit, filter for Python,
    # replace new lines with space.
    # cd "$REPO_NAME"
    ls
    echo 'checking git status'
    git status
    new_files_in_branch=$(
        git diff \
            --name-only \
            --diff-filter=AM \
            "$BASE_COMMIT" | grep '\.py$' | tr '\n' ' '
    )
    echo "New files in branch: $new_files_in_branch"
    # Feed to flake8 which will return the output in json format.
    # shellcheck disable=SC2086
    flake8 --format=json $new_files_in_branch | jq '.' > flake8_output.json  # NOQA
    cat flake8_output.json
}

main "$@"
