// import
import { ZeroAddress, ethers } from 'ethers';
import { getCreate2Address } from './create2';

// declare deployment parameters
import contractArtifact from '../artifacts/contracts/core/factory/Factory.sol/Factory.json';
const constructorTypes = contractArtifact.abi
  .find((v) => v.type === 'constructor')
  ?.inputs.map((t) => t.type);

const constructorArgs: any[] = [ZeroAddress];
const factoryAddress = '0x4a27c059FD7E383854Ea7DE6Be9c390a795f6eE3';

console.log('constructor parameters', constructorTypes, constructorArgs);

const job = () => {
  let i = 0;

  while (true) {
    const salt = ethers.id('' + i);
    // Calculate contract address
    const computedAddress = getCreate2Address({
      salt: salt,

      factoryAddress,
      contractBytecode: contractArtifact.bytecode,
      constructorTypes: constructorTypes,
      constructorArgs: constructorArgs,
    });

    if (computedAddress.startsWith('0x00000000000')) {
      console.log('found the right salt hash');
      console.log('salt', salt, computedAddress);
      break;
    }

    if (i % 100000 == 0) console.log(i, 'salt', salt, computedAddress);
    i++;
  }
};

job();
