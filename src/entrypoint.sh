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

find_base_commit() {
    BASE_COMMIT=$(
        jq \
            --raw-output \
            .pull_request.base.sha \
            "$GITHUB_EVENT_PATH"
    )
    # If this is not a pull request action it can be a check suite re-requested
    if [ "$BASE_COMMIT" == null ]; then
        BASE_COMMIT=$(
            jq \
                --raw-output \
                .check_suite.pull_requests[0].base.sha \
                "$GITHUB_EVENT_PATH"
        )
    fi
}

ACTION=$(
    jq --raw-output .action "$GITHUB_EVENT_PATH"
)
# First 2 actions are for pull requests, last 2 are for check suites.
ENABLED_ACTIONS='synchronize opened requested rerequested'


main() {
    if [[ $ENABLED_ACTIONS != *"$ACTION"* ]]; then
        echo -e "Not interested in this event: $ACTION.\nExiting..."
        exit
    fi
    find_base_commit
    # Get files Added or Modified wrt base commit, filter for Python,
    # replace new lines with space.
    new_files_in_branch=$(
        git diff \
            --name-only \
            --diff-filter=AM \
            "$BASE_COMMIT"
    )
    new_files_in_branch1=$(echo $new_files_in_branch | tr '\n' ' ')

    echo "New files in PR: $new_files_in_branch1"
    # Feed to flake8 which will return the output in json format.
    # shellcheck disable=SC2086
    # only run flake8 if there are python files changed
    if [[ $new_files_in_branch =~ .*".py".* ]]; then
        new_python_files_in_branch=$(
            git diff \
                --name-only \
                --diff-filter=AM \
                "$BASE_COMMIT" | grep '\.py$' | tr '\n' ' '
        )
        echo "New python files in PR: $new_python_files_in_branch"
        flake8 --format=json $new_python_files_in_branch | jq '.' > flake8_output.json || true # NOQA
    else
        echo "No new python files in PR"
    fi
    python /src/main.py
}

main "$@"
