// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface ERC20Mintable is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface IProxyRegistry {
    function proxies(address owner) external view returns (address);
}

contract BorrowingBonus is Ownable, Pausable {
    uint256 public           batch;
    address public immutable token;
    address public immutable proxyRegistry;
    bytes32 public           merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    event Claimed(uint256 batch, uint256 index, address account, uint256 amount);

    constructor(address token_, address proxyRegistry_) {
        token = token_;
        proxyRegistry = proxyRegistry_;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function upateBonusAndUnpause(uint256 batch_, bytes32 merkleRoot_) external onlyOwner whenPaused {
        require(batch_ > batch, 'BorrowingBonus: Invalid batch.');

        batch = batch_;
        merkleRoot = merkleRoot_;

        _unpause();
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[batch][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[batch][claimedWordIndex] = claimedBitMap[batch][claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external whenNotPaused {
        require(!isClaimed(index), 'BorrowingBonus: Drop already claimed.');

        address proxy = IProxyRegistry(proxyRegistry).proxies(_msgSender());
        require(proxy == account, 'BorrowingBonus: Non ds-proxy owner.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'BorrowingBonus: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        ERC20Mintable(token).mint(_msgSender(), amount);

        emit Claimed(batch, index, account, amount);
    }
}