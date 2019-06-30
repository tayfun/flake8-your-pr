#!/bin/bash
# if a command fails, exit
set -e
# treat unset variables as error
set -u
# if any command in a pipe fails, fail
set -o pipefail
# print all debug information
set -x


# This is populated by our secret from the Workflow file.
if [[ -z "$GITHUB_TOKEN" ]]; then
	echo "Set the GITHUB_TOKEN env variable."
	exit 1
fi


cat "$GITHUB_EVENT_PATH"


BASE_COMMIT=$(
    jq \
        --raw-output \
        .pull_request.base.sha \
        "$GITHUB_EVENT_PATH"
)
ACTION=$(
    jq --raw-output .action "$GITHUB_EVENT_PATH"
)


main() {
    # The only 2 actions in pull-request we are interested in
    if [ "$ACTION" != 'synchronize' ] && [ "$ACTION" != 'opened' ]; then
        echo "Not interested in this event: $ACTION. Exiting..."
        exit
    fi
    # Get files Added or Modified wrt base commit, filter for Python,
    # replace new lines with space.
    new_files_in_branch=$(
        git diff \
            --name-only \
            --diff-filter=AM \
            "$BASE_COMMIT" | grep '\.py$' | tr '\n' ' '
    )
    echo "New files in branch: $new_files_in_branch"
    # Feed to flake8 which will return the output in json format.
    # shellcheck disable=SC2086
    flake8 --format=json $new_files_in_branch | jq '.' > flake8_output.json || true # NOQA
    python /src/main.py
}

main "$@"
