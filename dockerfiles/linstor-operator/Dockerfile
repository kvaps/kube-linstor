FROM quay.io/operator-framework/ansible-operator:v0.8.1
ARG VERSION=

USER root
RUN pip install --upgrade setuptools Jinja2
RUN pip install ansible ansible-runner openshift kubernetes ansible-runner-http idna==2.7

COPY watches.yaml ${HOME}/watches.yaml

COPY roles/ ${HOME}/roles/
