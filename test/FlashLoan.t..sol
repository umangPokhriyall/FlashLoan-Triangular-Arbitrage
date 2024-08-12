// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/FlashLoan.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FlashLoanTest is Test {
    FlashLoan public flashLoan;
    IERC20 public busd;
    IERC20 public wbnb;
    IERC20 public crox;
    IERC20 public cake;

    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant CROX = 0x2c094F5A7D1146BB93850f629501eB749f6Ed491;
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;

    address private constant PANCAKE_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address private constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address private busdHolder = 0x85FAac652b707FDf6907EF726751087F9E0b6687; // Ensure this address is checksummed

    function setUp() public {
    vm.createFork("https://bsc-dataseed.binance.org/");
    vm.selectFork(0);

    flashLoan = new FlashLoan();
    busd = IERC20(BUSD);
    crox = IERC20(CROX);
    cake = IERC20(CAKE);
    wbnb = IERC20(WBNB);

    // Verify BUSD balance of the busdHolder
    uint256 holderBalance = busd.balanceOf(busdHolder);
    console.log("BUSD Holder Balance:", holderBalance);

    uint256 transferAmount = 5 * 10 ** 18; // Adjusted transfer amount
    require(holderBalance >= transferAmount, "Insufficient balance in busdHolder");

    uint256 contractBalanceBefore = busd.balanceOf(address(this));
    console.log("Contract BUSD Balance Before Transfer:", contractBalanceBefore);

    // Prank the busdHolder to transfer BUSD to this contract
    vm.prank(busdHolder);
    bool success = busd.transfer(address(this), transferAmount);
    assertTrue(success, "Transfer failed");

    // Verify contract's balance after transfer
    uint256 contractBalance = busd.balanceOf(address(this));
    console.log("Contract BUSD Balance After Transfer:", contractBalance);
}

function testInitialArbitrage() public {
    uint256 initialBalance = busd.balanceOf(address(this));
    console.log("Initial BUSD Balance in Test Contract:", initialBalance);
    assertEq(initialBalance, 5 * 10 ** 18, "Initial BUSD balance should be 5 in Test Contract");

    // Transfer BUSD from the test contract to the FlashLoan contract
    busd.transfer(address(flashLoan), initialBalance);

    // Now check the balance in the FlashLoan contract
    uint256 flashLoanBalance = busd.balanceOf(address(flashLoan));
    console.log("Initial BUSD Balance in FlashLoan Contract:", flashLoanBalance);
    assertEq(flashLoanBalance, 5 * 10 ** 18, "Initial BUSD balance should be 5 in FlashLoan Contract");

    uint256 loanAmount = 2 * 10 ** 18; // Adjusted loan amount for test
    flashLoan.initiateArbitrage(BUSD, loanAmount);
    uint256 finalBalance = busd.balanceOf(address(flashLoan));

    console.log("Final BUSD Balance in FlashLoan Contract:", finalBalance);
    assertGt(finalBalance, flashLoanBalance, "Final BUSD balance should be greater than initial after arbitrage");
}


    

}
