// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {MerkleTree} from "src/MerkleTree.sol";

import "forge-std/console.sol";

contract MerkleTreeTest is Test {
    // contracts
    MerkleTree public merkleTree;

    bytes32[] public hashRow;

    function setUp() public {
        merkleTree = new MerkleTree();
    }

    /// @dev visually show hashes in each row of the constructed merkle tree.
    function _printTree(uint256 hRow) internal {
        console.log("------------------------------------------------------------------");
        console.log("HASH ROW ", hRow);
        console.log("LENGTH: ", hashRow.length, "\n");
        for (uint256 k; k < hashRow.length; k++) {
            console.logBytes32(hashRow[k]);
        }
        hashRow = new bytes32[](0);
    }

    /// @dev generates and returns an arbitrary bytes32 array of length 256.
    function _getBytesArray() internal pure returns (bytes32[256] memory) {
        bytes32[256] memory bytesArray;

        for (uint256 i; i < bytesArray.length; i++) {
            bytesArray[i] = bytes32(i + 1);
        }

        return bytesArray;
    }

    /// @dev tests that tree was constructed properly.
    function test_BuildTree() public {
        // setup: get bytes32 array
        bytes32[256] memory leaves = _getBytesArray();

        // act: build tree
        merkleTree.buildTree(leaves);

        // assertions: traverse and print the tree:
        uint256 hashCount = leaves.length;
        for (uint256 hRow; hRow < 9; hRow++) {
            for (uint256 hIndex; hIndex <= hashCount; hIndex++) {
                bytes32 leafHash = merkleTree.tree(hRow, hIndex);
                if (hIndex == hashCount) {
                    // one too far: should be bytes32(0)
                    assertEq(leafHash, bytes32(0));
                } else {
                    hashRow.push(leafHash);
                    // within hash row: should not be bytes32(0)
                    assertNotEq(leafHash, bytes32(0));
                }
            }
            hashCount /= 2;
            _printTree(hRow);
        }
    }

    /// @dev tests that proof is generated properly.
    //  - the proof-dependent computed root hash should match the merkle tree's root hash.
    function test_generateMerkleProof(uint8 idx) public {
        // setup: construct merkle tree
        bytes32[256] memory leaves = _getBytesArray();
        merkleTree.buildTree(leaves);

        // expectation: get root hash from merkle tree
        bytes32 rootHash = merkleTree.tree(8, 0);

        // act: generate merkle proof
        bytes32[8] memory proof = merkleTree.generateMerkleProof(idx);

        // verify: compute root hash
        uint256 hIndex = uint256(idx);
        bytes32 computedHash = merkleTree.tree(0, uint256(idx)); // initialize to hash of idx
        for (uint256 pIndex; pIndex < proof.length; pIndex++) {
            if (hIndex % 2 == 0) {
                // proof index is right sibling
                computedHash = keccak256(abi.encodePacked(computedHash, proof[pIndex]));
            } else {
                // proof index is left sibling
                computedHash = keccak256(abi.encodePacked(proof[pIndex], computedHash));
            }
            // update hashIndex for next hashRow (towards root)
            hIndex /= 2;
        }

        // assertion: the computed root hash should match the root hash
        assertEq(computedHash, rootHash);
    }

    /// @dev tests that a proof for data membership is tree-version-dependent.
    //  - a merkle proof from an updated merkle tree should not work for a past tree version.
    function test_generateMerkleProofTreeDependence(uint8 idx, uint256 mutation) public {
        // setup: construct tree 1 with bytes array
        bytes32[256] memory leaves = _getBytesArray();
        merkleTree.buildTree(leaves);
        bytes32 rootHash_1 = merkleTree.tree(8, 0);

        // mutate: slightly modify data
        vm.assume(mutation > 256);
        leaves[255] = bytes32(mutation);

        // setup: construct tree 2 and generate proof 2 for a specific index
        merkleTree.buildTree(leaves);
        bytes32[8] memory proof_2 = merkleTree.generateMerkleProof(idx);

        // expectation: get root hash from merkle tree
        bytes32 rootHash_2 = merkleTree.tree(8, 0);

        // verify: compute root hash
        uint256 hIndex = uint256(idx);
        bytes32 computedHash = merkleTree.tree(0, uint256(idx)); // initialize to hash of idx
        for (uint256 pIndex; pIndex < proof_2.length; pIndex++) {
            if (hIndex % 2 == 0) {
                // proof index is right sibling
                computedHash = keccak256(abi.encodePacked(computedHash, proof_2[pIndex]));
            } else {
                // proof index is left sibling
                computedHash = keccak256(abi.encodePacked(proof_2[pIndex], computedHash));
            }
            // update hashIndex for next hashRow (towards root)
            hIndex /= 2;
        }

        // assertion: the computed root hash should match root hash 2, but not root hash 1
        assertEq(computedHash, rootHash_2);
        assertNotEq(computedHash, rootHash_1);
    }
}
