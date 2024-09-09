// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {ERC20} from "../src/ERC20.sol";

contract ERC20ContractTest is Test {
    ERC20 public erc20Contract;
    address ownerAddress = address(0x0101);
    address randomAddress = address(0x3892);

    error InvalidRecipient();

    function setUp() public {
        vm.prank(ownerAddress);
        erc20Contract = new ERC20("My Token", "MTK", 0);
    }

    function test_ContractWasDeployedSuccessfully() public view {
        assertEq(erc20Contract.name(), "My Token");
        assertEq(erc20Contract.symbol(), "MTK");
        assertEq(erc20Contract.decimals(), 0);
    }

    function test_OwnerisSetCorrectly() public view {
        assertEq(
            erc20Contract.owner(),
            ownerAddress,
            "owner address not set correctly"
        );
    }

    function test_MintWillRevertWhenMintFromUnauthorizedAddress() public {
        address scammer = address(0x5555);
        vm.startPrank(scammer);
        vm.expectRevert("Unauthorized");
        erc20Contract.mint(scammer, 1000);
        vm.stopPrank();
    }

    function test_MintWillRevertWhenMintToZeroAddress() public {
        // Set msg.sender to `ownerAddress`
        vm.prank(ownerAddress);
        // Expect function call to revert
        vm.expectRevert(InvalidRecipient.selector);
        // Mint 1000 tokens to zero address
        erc20Contract.mint(address(0), 1000);
    }

    function test_MintWasSuccessful() public {
        uint256 totalSupplyBeforeMint = erc20Contract.totalSupply();
        uint256 mintAmount = 1000;
        // Check balance before mint
        assertEq(
            erc20Contract.balanceOf(randomAddress),
            0,
            "expected random address balance to be 0"
        );
        // Set msg.sender to `ownerAddress`
        vm.prank(ownerAddress);
        // Mint 1000 tokens to random address
        erc20Contract.mint(randomAddress, mintAmount);
        uint256 totalSupplyAfterMint = erc20Contract.totalSupply();
        // Verify mint was successful
        assertEq(
            erc20Contract.balanceOf(randomAddress),
            mintAmount,
            "incorrect mint amount"
        );
        assertEq(totalSupplyBeforeMint + mintAmount, totalSupplyAfterMint);
    }

    function test_TransferFrom() public {
        address recipient = address(0x2938);
        address caller = address(0x2373);
        uint256 amount = 500;

        // set msg.sender to owner address
        vm.startPrank(ownerAddress);
        // Mint 500 tokens to random address
        erc20Contract.mint(randomAddress, amount);
        // Verify tokens was minted successfully
        assertEq(erc20Contract.balanceOf(randomAddress), amount);
        // Stop prank
        vm.stopPrank();

        // Set msg.sender to random address
        vm.startPrank(randomAddress);
        // random address approves caller to spend `amount` tokens
        erc20Contract.approve(caller, amount);
        // Stop prank
        vm.stopPrank();

        assertEq(erc20Contract.balanceOf(recipient), 0);

        uint256 balanceOfSenderBeforeTransfer = erc20Contract.balanceOf(
            randomAddress
        );
        uint256 allowanceOfCallerBeforeTransfer = erc20Contract.allowance(
            randomAddress,
            caller
        );

        vm.startPrank(caller);
        erc20Contract.transferFrom(randomAddress, recipient, amount);

        // recipient balance increased accordingly
        assertEq(erc20Contract.balanceOf(recipient), amount);
        // sender balance decrease accordingly
        uint256 balanceOfSenderAfterTransfer = erc20Contract.balanceOf(
            randomAddress
        );
        assertEq(
            balanceOfSenderBeforeTransfer - amount,
            balanceOfSenderAfterTransfer
        );

        uint256 allowanceOfCallerAfterTransfer = erc20Contract.allowance(
            randomAddress,
            caller
        );

        assertEq(
            allowanceOfCallerBeforeTransfer - amount,
            allowanceOfCallerAfterTransfer
        );
    }
}
