pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// we will add the interfaces here

interface IFakeNFTMarketplace {
  function getPrice() external view returns (uint256);

  function available(uint256 _tokenId) external view returns (bool);

  function purchase(uint256 _tokenId) external payable;
}

interface ICryptoDevsNFT{
  //need to know how many NFT each holder has
  function balanceOf(address owner) external view returns(uint256);

  //need to know the exact tokenId of the NFT to prevent repeat votes
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract CryptoDevsDAO is Ownable {
  // we will write contract code here\

  // create a struct named proposal containing all the relevant information
  struct Proposal {
    // nftTokenId - the tokenId of the NFT to purchase from FakeNFTMarketplace
    uint256 nftTokenId;
    // deadline - unix timestamp which the proposal is active
    uint256 deadline;
    // yayvotes
    uint256 yayVotes;
    // nayvotes
    uint256 nayVotes;
    // executed - whether this proposal has been executed
    bool executed;
    // voters - mapping of CryptoDevsNFT tokenIds to whether they have voted
    mapping(uint256 => bool) voters;
  }

  // create a mapping of ID to proposal
  mapping(uint256=>Proposal) public proposals

   // number of proposals that have been created
   uint256 public numProposals;

   IFakeNFTMarketplace nftMarketplace;
   ICryptoDevsNFT cryptoDevsNFT;

   // create a payable constructor which initializes the contract
   // payable allows this constructor to accept an ETH deposit when it is deployed
   constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
     nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
     cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
   }

   modifier nftHolderOnly() {
     require(cryptoDevsNFT.balanceOf(msg.sender > 0, "NOT_A_DAO_MEMBER"));
     _;
   }

   // @dev CreateProposal allows a cryptoDevsNFT holder to create a new proposal in the DAO
   // @return returns the proposal index for the newly created proposal
    function createProposal(uint256 _nftTokenId) external nftHolderOnly returns (uint256){
      require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
      Proposal storage proposal = proposals[numProposals];
      proposal.nftTokenId = _nftTokenId;
      proposal.deadline = block.timestamp + 5 minutes;

      numProposals++;

      return numProposals -1;
    }

    modifier activeProposalOnly(uint256 proposalIndex) {
      require(
        proposals[proposalIndex].deadline > block.timestamp,
        "DEADLINE_EXCEEDED"
        );
        _;
    }

    enum Vote {
      YAY, // YAY = 0
      NAY  // NAY = 1
    }

    function voteOnProposal (uint256 proposalIndex, Vote vote) external nftHolderOnly activeProposalOnly(proposalIndex) {
      Proposal storage proposal = proposals[proposalIndex];

      uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
      uint256 numVotes = 0;

      // calculate how many nfts are owned by the voter
      for (uint256 i=0; i<voterNFTBalance; i++){
        uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
        if(proposal.voters[tokenId] == false) {
          numVotes++;
          proposal.voters[tokenId] = true;
        }
      }
      require(numVotes >0 , "ALEADY_VOTED");

      if (vote == vote.YAY) {
        proposal.yayVotes += numVotes;
      } else {
        proposal.nayVotes += numVotes;
      }
    }


}
