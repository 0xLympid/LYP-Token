// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBurnMintERC20} from "../ERC20/IBurnMintERC20.sol";
import {IERC677} from "./IERC677.sol";
import {ERC677} from "./ERC677.sol";
import {OwnerIsCreator} from "../../access/OwnerIsCreator.sol";

/// @notice A basic ERC677 compatible token contract with burn and minting roles.
/// @dev The total supply can be limited during deployment.
contract BurnMintERC677 is IBurnMintERC20, ERC677, IERC165, OwnerIsCreator {
  using EnumerableSet for EnumerableSet.AddressSet;

  error SenderNotMinter(address sender);
  error SenderNotBurner(address sender);
  error MaxSupplyExceeded(uint256 supplyAfterMint);

  event MintAccessGranted(address indexed minter);
  event BurnAccessGranted(address indexed burner);
  event MintAccessRevoked(address indexed minter);
  event BurnAccessRevoked(address indexed burner);

  // @dev the allowed minter addresses
  EnumerableSet.AddressSet internal s_minters;
  // @dev the allowed burner addresses
  EnumerableSet.AddressSet internal s_burners;

  /// @dev The number of decimals for the token
  uint8 internal immutable i_decimals;

  /// @dev The maximum supply of the token, 0 if unlimited
  uint256 internal immutable i_maxSupply;

  constructor(string memory name, string memory symbol, uint8 decimals_, uint256 maxSupply_) ERC677(name, symbol) {
    i_decimals = decimals_;
    i_maxSupply = maxSupply_;
  }

  function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
    return
      interfaceId == type(IERC20).interfaceId ||
      interfaceId == type(IERC677).interfaceId ||
      interfaceId == type(IBurnMintERC20).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  // ================================================================
  // |                            ERC20                             |
  // ================================================================

  /// @dev Returns the number of decimals used in its user representation.
  function decimals() public view virtual override returns (uint8) {
    return i_decimals;
  }

  /// @dev Returns the max supply of the token, 0 if unlimited.
  function maxSupply() public view virtual returns (uint256) {
    return i_maxSupply;
  }

  /// @dev Overridden _update function to include validAddress logic.
  function _update(address from, address to, uint256 amount) internal virtual override {
    if (to == address(this)) revert();
    super._update(from, to, amount);
  }

  // ================================================================
  // |                      Burning & minting                       |
  // ================================================================

  
  /// @inheritdoc IBurnMintERC20
  /// @dev Decreases the total supply.
  function burn(uint256 amount) public override(IBurnMintERC20) onlyBurner {
    _burn(_msgSender(), amount);
  }

  /// @inheritdoc IBurnMintERC20
  /// @dev Uses OZ ERC20 _mint to disallow minting to address(0).
  /// @dev Disallows minting to address(this)
  /// @dev Increases the total supply.
  function mint(address account, uint256 amount) external override onlyMinter {
    if (i_maxSupply != 0 && totalSupply() + amount > i_maxSupply) revert MaxSupplyExceeded(totalSupply() + amount);

    _mint(account, amount);
  }

  // ================================================================
  // |                            Roles                             |
  // ================================================================

  /// @notice grants both mint and burn roles to `burnAndMinter`.
  /// @dev calls public functions so this function does not require
  /// access controls. This is handled in the inner functions.
  function grantMintAndBurnRoles(address burnAndMinter) external {
    grantMintRole(burnAndMinter);
    grantBurnRole(burnAndMinter);
  }

  /// @notice Grants mint role to the given address.
  /// @dev only the owner can call this function.
  function grantMintRole(address minter) public onlyOwner {
    if (s_minters.add(minter)) {
      emit MintAccessGranted(minter);
    }
  }

  /// @notice Grants burn role to the given address.
  /// @dev only the owner can call this function.
  function grantBurnRole(address burner) public onlyOwner {
    if (s_burners.add(burner)) {
      emit BurnAccessGranted(burner);
    }
  }

  /// @notice Revokes mint role for the given address.
  /// @dev only the owner can call this function.
  function revokeMintRole(address minter) public onlyOwner {
    if (s_minters.remove(minter)) {
      emit MintAccessRevoked(minter);
    }
  }

  /// @notice Revokes burn role from the given address.
  /// @dev only the owner can call this function
  function revokeBurnRole(address burner) public onlyOwner {
    if (s_burners.remove(burner)) {
      emit BurnAccessRevoked(burner);
    }
  }

  /// @notice Returns all permissioned minters
  function getMinters() public view returns (address[] memory) {
    return s_minters.values();
  }

  /// @notice Returns all permissioned burners
  function getBurners() public view returns (address[] memory) {
    return s_burners.values();
  }

  // ================================================================
  // |                            Access                            |
  // ================================================================

  /// @notice Checks whether a given address is a minter for this token.
  /// @return true if the address is allowed to mint.
  function isMinter(address minter) public view returns (bool) {
    return s_minters.contains(minter);
  }

  /// @notice Checks whether a given address is a burner for this token.
  /// @return true if the address is allowed to burn.
  function isBurner(address burner) public view returns (bool) {
    return s_burners.contains(burner);
  }

  /// @notice Checks whether the msg.sender is a permissioned minter for this token
  /// @dev Reverts with a SenderNotMinter if the check fails
  modifier onlyMinter() {
    if (!isMinter(msg.sender)) revert SenderNotMinter(msg.sender);
    _;
  }

  /// @notice Checks whether the msg.sender is a permissioned burner for this token
  /// @dev Reverts with a SenderNotBurner if the check fails
  modifier onlyBurner() {
    if (!isBurner(msg.sender)) revert SenderNotBurner(msg.sender);
    _;
  }
}

