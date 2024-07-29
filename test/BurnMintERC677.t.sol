// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../src/token/ERC677/BurnMintERC677.sol";

contract BurnMintERC677Test is Test {
    BurnMintERC677 token;
    address public owner;
    address public minter;
    address public burner;
    address public user;

    function setUp() public {
        owner = address(this);
        minter = address(0x123);
        burner = address(0x456);
        user = address(0x789);

        uint8 decimals = 18;
        uint256 maxSupply = 100_000_000 * 10**18;

        token = new BurnMintERC677("Lympid", "LYP", decimals, maxSupply);
    }

    function testMinting() public {
        vm.startPrank(owner);
        token.grantMintRole(minter);
        vm.stopPrank();

        vm.startPrank(minter);
        token.mint(user, 100 * 10**18);
        vm.stopPrank();

        assertEq(token.totalSupply(), 100 * 10**18);
        assertEq(token.balanceOf(user), 100 * 10**18);
    }

    function testMintingExceedingMaxSupply() public {
        vm.startPrank(owner);
        token.grantMintRole(minter);
        vm.stopPrank();

        vm.startPrank(minter);
        vm.expectRevert(abi.encodeWithSelector(BurnMintERC677.MaxSupplyExceeded.selector, 200_000_000 * 10**18));
        token.mint(user, 200_000_000 * 10**18);
        vm.stopPrank();
    }

    function testBurning() public {
        vm.startPrank(owner);
        token.grantMintRole(minter);
        token.grantBurnRole(burner);
        vm.stopPrank();

        vm.startPrank(minter);
        token.mint(user, 100 * 10**18);
        vm.stopPrank();

        vm.startPrank(user);
        token.approve(burner, 50 * 10**18);
        vm.stopPrank();

        vm.startPrank(burner);
        token.transferFrom(user, burner, 50 * 10**18);
        token.burn(50 * 10**18);
        vm.stopPrank();

        assertEq(token.totalSupply(), 50 * 10**18);
        assertEq(token.balanceOf(burner), 0);
    }

    function testGrantAndRevokeRoles() public {
        vm.startPrank(owner);
        token.grantMintRole(minter);
        token.grantBurnRole(burner);
        vm.stopPrank();

        assertTrue(token.isMinter(minter));
        assertTrue(token.isBurner(burner));

        vm.startPrank(owner);
        token.revokeMintRole(minter);
        token.revokeBurnRole(burner);
        vm.stopPrank();

        assertFalse(token.isMinter(minter));
        assertFalse(token.isBurner(burner));
    }

    function testTransferValidation() public {
        vm.startPrank(owner);
        token.grantMintRole(minter);
        vm.stopPrank();

        vm.startPrank(minter);
        token.mint(owner, 100 * 10**18);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert();
        token.transfer(address(token), 10 * 10**18);
        vm.stopPrank();
    }
}
