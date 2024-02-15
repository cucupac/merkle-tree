// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

contract MerkleTree {
    // storage
    // tree[hashRow][hashIndex] = leafHash
    mapping(uint256 => mapping(uint256 => bytes32)) public tree;
    // indexLookup[dataHash] = hashIndex for hashRow 0
    mapping(bytes32 => uint256) public indexLookup;

    /// @dev constructs a merkle tree given a bytes32 array of length 256.
    //  - assumes input data is not already hashed.
    function buildTree(bytes32[256] memory leaves) public returns (bool) {
        uint256 hashRowLength = leaves.length;

        for (uint256 hRow; hRow < 9; hRow++) {
            if (hRow == 0) {
                // populate initial row of hashes: length: 256
                for (uint256 hIndex; hIndex < hashRowLength; hIndex++) {
                    bytes32 dataHash = keccak256(abi.encodePacked(leaves[hIndex]));
                    tree[hRow][hIndex] = dataHash;
                    indexLookup[dataHash] = hIndex; // assumes input data elements are unique
                }
            } else {
                // execute hash on even indexes: lengths: 256, 128, 64, 32, 16, 8, 4, 2
                uint256 i;
                for (uint256 hIndex; hIndex < hashRowLength; hIndex++) {
                    if (hIndex % 2 == 0) {
                        // even: compute the hash with CURRENT leaf and RIGHT sibling leaf of previous hash row
                        tree[hRow][i] = keccak256(abi.encodePacked(tree[hRow - 1][hIndex], tree[hRow - 1][hIndex + 1]));
                        i++;
                    }
                }
                hashRowLength /= 2;
            }
        }
        return true;
    }

    /// @dev generates merkle proof given a specific leaf index.
    function generateMerkleProof(uint8 idx) public view returns (bytes32[8] memory) {
        bytes32[8] memory merkleProof;
        uint256 hIndex = uint256(idx); // initialize to idx
        for (uint256 hRow; hRow < merkleProof.length; hRow++) {
            if (hIndex % 2 == 0) {
                // even: get right sibling
                merkleProof[hRow] = tree[hRow][hIndex + 1];
            } else {
                // odd: get left sibling
                merkleProof[hRow] = tree[hRow][hIndex - 1];
            }
            // update hIndex for next row of hashes (towards root)
            hIndex /= 2;
        }
        return merkleProof;
    }
}

/* 
EXAMPLE MERKLE TREE:

                                             hashRow4[0]
                    hashRow3[0]                                         hashRow3[1]
       hashRow2[0]                hashRow2[1]              hashRow2[2]              hashRow2[3]
hashRow1[0], hashRow1[1], hashRow1[2], hashRow1[3], hashRow1[4], hashRow1[5], hashRow1[6], hashRow1[7]
*/
