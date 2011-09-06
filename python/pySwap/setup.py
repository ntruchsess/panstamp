__author__="Daniel Berenguer"
__date__ ="$Aug 20, 2011 12:44:09 PM$"

from setuptools import setup,find_packages

setup (
  name = 'pySwap',
  version = '0.1',
  packages = find_packages(),

  # Declare your packages' dependencies here, for eg:
  install_requires=['foo>=3'],

  # Fill in these to make your Egg ready for upload to
  # PyPI
  author = 'Daniel Berenguer',
  author_email = 'dberenguer@usapiens.com',

  summary = 'SWAP Python packege',
  url = 'http://www.panstamp.com',
  license = 'GPL v.2',
  long_description= 'This package provides the necessary classes and functions to interact with wireless SWAP networks via a serial panStamp modem',

  # could also include long_description, download_url, classifiers, etc.
)