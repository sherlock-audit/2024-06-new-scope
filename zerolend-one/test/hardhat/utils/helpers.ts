import { ethers } from 'ethers';

export function getPositionId(user: string, index: number): string {
  return ethers.solidityPackedKeccak256(['address', 'string', 'uint256'], [user, 'index', index]);
}
