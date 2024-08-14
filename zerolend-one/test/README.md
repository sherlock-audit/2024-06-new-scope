# ZeroLend One - Unit Tests

This folder contains all the various unit tests for the entire protocol. There are three kinds of unit tests written up.

- [Hardhat](./hardhat) - Hardhat is used for all various kinds of feature tests. We test basic functionalities such as supply/borrow, creation of vaults etc.. and basic rules using hardhat tests.
- [Foundry](./forge) - Foundry is used to conduct various fuzzing and invariant tests.
- [Certora](./certora) - Certora is used to conduct all kinds of formal verification tests. This is more in-depth than the foundry tests but run a lot slower.

## Running Hardhat Tests

To run hardhat tests, simply run the following commands from the project root.

```
yarn
yarn test:hardhat
```

## Running Foundry Tests

To run foundry tests, you need to make sure that `forge` is installed first (Visit [getfoundry.sh](https://getfoundry.sh/) for more info). With `forge` available simply run the following commands from the project root.

```
yarn
yarn test:forge
```

## Running Certora Tests

To run certora, you need to make sure that the `certora-cli` and `solc` binaries are locally installed. To do that we recommend spinning up a `virtualenv` and running the following commands from the project root.

```
virtualenv venv
pip3 install solc-select certora-cli
solc-select install 0.8.19
solc-select use 0.8.19

# add certora key here
export CERTORAKEY=

# run certora tests
sh ./certora.sh
```
