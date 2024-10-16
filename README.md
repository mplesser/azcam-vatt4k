# azcam-vatt4k

## Purpose

This repository contains the *azcam-vatt4k* *azcam* environment. It contains code and data files for the VATT Vatt4k camera system.

## Installation Example

Download the code (usually into the *azcam* root folder such as `c:\azcam`) and install.

```shell
cd /azcam
git clone https://github.com/mplesser/azcam-vatt4k
pip install -e ./alpyca-2.0.4
pip install -e ./azcam-vatt4ktarragon-noir
```

## Execution Example

```python
python -m azcam_vatt4k.server
or
ipython -i -m azcam_vatt4k.server
```
