   // SPDX-License-Identifier: MIT


   // The function below will never work, because you can't loop through a mapping
   // The solution to getting the total amount of DSCMinted is:
 // 1. Maintain a separate variable to keep track of the total supply of DSC whenever a new DSC is minted.
// 2. Update the total supply variable whenever a new DSC is minted or burned
       ///// see way below the proper code
       //I suspect the openzeppelin-contracts library has a this in their internal _mint
    //  and _burn functions, but so far I have not been able to find it.
pragma solidity ^0.8.18;

contract BigBagBoogyWhatILearned {
    mapping(address user => uint256 amount) private s_DSCMinted;


    function getTotalDSCSupply() external view returns (uint256) {
        // so we have to loop through the s_DSCMinted mapping, and get the total amount of DSCMinted
        uint totalDSCSupply;
        for (uint256 i = 0; i < s_DSCMinted.length; i++) {
             totalDSCSupply += s_DSCMinted[i];
        }
        return totalDSCSupply;  

    }

// Existing mapping to store the DSC minted for each user
mapping(address => uint256) private s_DSCMinted;

// Additional variable to store the total DSC supply
uint256 private totalDSCSupply;

// Function to mint DSC
function mintDsc(uint256 amountDscToMint) public (amountDscToMint) nonReentrant {
    s_DSCMinted[msg.sender] += amountDscToMint;
    totalDSCSupply += amountDscToMint;
    // rest of the function logic
}

// Function to burn DSC
function burnDsc(uint256 amount) public (amount) {
    _burnDsc(amount, msg.sender, msg.sender);
    totalDSCSupply -= amount;
    // rest of the function logic
}

// Function to get the total DSC supply
function getTotalDSCSupply() external view returns (uint256) {
    return totalDSCSupply;
}





}