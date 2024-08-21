import { ContractTransactionResponse } from 'ethers';

export const waitForTx = async (tx: ContractTransactionResponse) => {
  const t = await tx.wait(1);
  console.log('waiting for', t?.hash);
  return t;
};
