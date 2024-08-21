This folder contains the verification of the ZeroLend One protocol using Halmos, the formal verification tool by a16z

We first give a high-level description of the verification and then describe the folder and file structure of the specification files.

# Getting started

Install `halmos` package with `pip install halmos`. We recommend using a python virtual environment such as `virtualenv`.

# todo

check if there's any way where pool can have it's liquidity index less than 1 ray
ensure that indexes and rates are always increasing
ensure that total virtual supply is always equal to erc20 token supply
a full repay should incur no interest (debt rate is 0)
