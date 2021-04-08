#!/usr/bin/env python

from distutils.core import setup

setup(
    name="test_package",
    version="1.0.2",
    packages=[
        "Jinja2==2.7.2",
        "Django==1.6.1",
        "python-etcd==0.4.5",
    ],
)