// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ███████╗███████╗██████╗  ██████╗
// ╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
//   ███╔╝ █████╗  ██████╔╝██║   ██║
//  ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
// ███████╗███████╗██║  ██║╚██████╔╝
// ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝

// Website: https://zerolend.xyz
// Discord: https://discord.gg/zerolend
// Twitter: https://twitter.com/zerolendxyz
// Telegram: https://t.me/zerolendxyz

import {Governor, IGovernor} from '@openzeppelin/contracts/governance/Governor.sol';

import {TimelockController} from '@openzeppelin/contracts/governance/TimelockController.sol';
import {GovernorCountingSimple} from '@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol';
import {GovernorSettings} from '@openzeppelin/contracts/governance/extensions/GovernorSettings.sol';
import {GovernorTimelockControl} from '@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol';
import {GovernorVotes} from '@openzeppelin/contracts/governance/extensions/GovernorVotes.sol';
import {GovernorVotesQuorumFraction} from '@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol';
import {IVotes} from '@openzeppelin/contracts/governance/utils/IVotes.sol';

contract ZeroLendGovernor is
  Governor,
  GovernorSettings,
  GovernorCountingSimple,
  GovernorVotes,
  GovernorVotesQuorumFraction,
  GovernorTimelockControl
{
  constructor(
    IVotes _token,
    TimelockController _timelock
  )
    Governor('ZeroLend Governor')
    GovernorSettings(7200, /* 1 day */ 50_400, /* 1 week */ 10_000_000e18)
    GovernorVotes(_token)
    GovernorVotesQuorumFraction(40)
    GovernorTimelockControl(_timelock)
  {}

  function votingDelay() public view override (GovernorSettings, IGovernor) returns (uint256) {
    return super.votingDelay();
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override (Governor, GovernorTimelockControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function votingPeriod() public view override (IGovernor, GovernorSettings) returns (uint256) {
    return super.votingPeriod();
  }

  function quorum(uint256 blockNumber) public view override (IGovernor, GovernorVotesQuorumFraction) returns (uint256) {
    return super.quorum(blockNumber);
  }

  function state(uint256 proposalId) public view override (Governor, GovernorTimelockControl) returns (ProposalState) {
    return super.state(proposalId);
  }

  function proposalThreshold() public view override (Governor, GovernorSettings) returns (uint256) {
    return super.proposalThreshold();
  }

  function _cancel(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override (Governor, GovernorTimelockControl) returns (uint256) {
    return super._cancel(targets, values, calldatas, descriptionHash);
  }

  function _executor() internal view override (Governor, GovernorTimelockControl) returns (address) {
    return super._executor();
  }

  function _execute(
    uint256 id,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal virtual override (Governor, GovernorTimelockControl) {
    super._execute(id, targets, values, calldatas, descriptionHash);
  }
}
