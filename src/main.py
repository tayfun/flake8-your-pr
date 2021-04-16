import json
import os
import requests
from datetime import datetime, timezone



class CheckRun:
    GITHUB_TOKEN = os.environ['GITHUB_TOKEN']
    GITHUB_EVENT_PATH = os.environ['GITHUB_EVENT_PATH']

    URI = 'https://api.github.com'
    # We need preview version to access check run API
    API_VERSION = 'antiope-preview'
    ACCEPT_HEADER_VALUE = "application/vnd.github.{}+json".format(API_VERSION)
    AUTH_HEADER_VALUE = "token {}".format(GITHUB_TOKEN)
    # This is the max annotations Github API accepts in one go.
    MAX_ANNOTATIONS = 50

    def __init__(self):
        self.read_event_file()
        self.read_meta_data()
        self.read_flake8_output()
        self.files_with_errors_counter = 0
        self.annotations = []

    def read_event_file(self):
        with open(self.GITHUB_EVENT_PATH) as event_file:
            self.event = json.loads(event_file.read())

    def read_meta_data(self):
        self.repo_full_name = self.event['repository']['full_name']
        pull_request = self.event.get('pull_request')
        if pull_request:
            self.head_sha = pull_request['head']['sha']
        else:
            check_suite = self.event['check_suite']
            self.head_sha = check_suite['pull_requests'][0]['base']['sha']

    def read_flake8_output(self):
        if os.path.exists('flake8_output.json'):
            with open('flake8_output.json') as flake8_output_file:
                self.flake8_output = json.loads(flake8_output_file.read())
        else:
            self.flake8_output = {}

    def create_single_annotation(self, error, file_path):
        message = '{} ({})'.format(error['text'], error['code'])
        annotation = dict(
            path=file_path,
            start_line=error['line_number'],
            end_line=error['line_number'],
            annotation_level='notice',
            message=message,
            start_column=error['column_number'],
            end_column=error['column_number'],
        )
        return annotation

    def create_annotations(self):
        for file_path, error_list in self.flake8_output.items():
            if not error_list:
                continue
            self.files_with_errors_counter += 1
            for error in error_list:
                annotation = self.create_single_annotation(error, file_path)
                self.annotations.append(annotation)
                if len(self.annotations) == 50:
                    return

    def get_summary(self):
        number_of_annotations = len(self.annotations)
        summary = """
        Flake8 Run Summary:

        Total Errors: {}
        Files Checked: {}
        Files with Errors: {}
        """.format(
            number_of_annotations if number_of_annotations < 50 else '50+',
            len(self.flake8_output),
            (
                self.files_with_errors_counter
                if number_of_annotations < 50
                else '{}+'.format(self.files_with_errors_counter)
            ),
        )
        return summary

    def get_conclusion(self):
        if len(self.annotations) == 0:
            return 'success'
        return 'failure'

    def get_payload(self):
        summary = self.get_summary()
        conclusion = self.get_conclusion()

        payload = {
            'name': 'flake8-your-pr',
            'head_sha': self.head_sha,
            'status': 'completed',
            'conclusion': conclusion,
            'completed_at': datetime.now(timezone.utc).isoformat(),
            'output': {
                'title': 'Flake8 Result',
                'summary': summary,
                'text': 'Flake8 results',
                'annotations': self.annotations,
            },
        }
        return payload

    def create(self):
        self.create_annotations()
        payload = self.get_payload()
        print(payload)
        response = requests.post(
            f'{self.URI}/repos/{self.repo_full_name}/check-runs',
            headers={
                'Accept': self.ACCEPT_HEADER_VALUE,
                'Authorization': self.AUTH_HEADER_VALUE,
            },
            json=payload,
        )
        print(response.content)
        response.raise_for_status()


if __name__ == '__main__':
    check_run = CheckRun()
    check_run.create()
