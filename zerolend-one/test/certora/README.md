This folder contains the verification of the ZeroLend One protocol using CVL, Certora's Verification Language.

We first give a high-level description of the verification and then describe the folder and file structure of the specification files.

# High-level description

The ZeroLend protocol allows users to take out over-collateralized loans for ERC20 tokens. Unlike single asset isolated pools, users can take out multiple loans for an individual asset.

## ERC20 tokens and transfers

## Pool Supply Invariant Tests

Here we test invariant checks on the supply and withdraw functions of the Pool contract. Whenever a user supplies an asset, we ensure that we are crediting the user properly. And at the same time whenever a user tries to withdraw a certain number of assets, they have enough supply to do so.

# Getting started

Install `certora-cli` package with `pip install certora-cli`. We recommend using a python virtual environment such as `virtualenv`.
To verify specification files, pass to `certoraRun` the corresponding configuration file in the [`test/certora/confs`](confs) folder.
It requires having set the `CERTORAKEY` environment variable to a valid Certora key. You can also pass additional arguments, notably to verify a specific rule.
For example, at the root of the repository:

```
certoraRun test/certora/confs/ERC20.conf --rule transferFromSpec
```

The `certora-cli` package also includes a `certoraMutate` binary.
The file [`gambit.conf`](gambit.conf) provides a default configuration of the mutations.
You can test to mutate the code and check it against a particular specification.
For example, at the root of the repository:

```
certoraMutate --prover_conf test/certora/confs/ERC20.conf --mutation_conf test/certora/gambit.conf
```

# todo

check if there's any way where pool can have it's liquidity index less than 1 ray
ensure that indexes and rates are always increasing
ensure that total virtual supply is always equal to erc20 token supply
a full repay should incur no interest (debt rate is 0)
