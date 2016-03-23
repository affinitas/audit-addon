from setuptools import setup
from setuptools import find_packages
from codecs import open
from os import path

here = path.abspath(path.dirname(__file__))

with open(path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

setup(

VERSION = '0.0.0'

setup(
    name='auditdb',
    version=VERSION,
    description='allow to audit changes of data',
    url='https://github.com/affinitas/audit-addon',
    author='Claus Koch',
    author_email='claus.koch@affinitas.de',
    license='MIT',
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: Developers',
        'Intended Audience :: System Administrators',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3.4',
    ],
    keywords='postgresql audit addon',
    packages=find_packages(exclude=['contrib', 'docs', 'tests*']),
)
