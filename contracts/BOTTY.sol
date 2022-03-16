// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract BOTTY is ERC721A, Ownable {
    enum Status {
        Waiting,
        Started,
        Finished
    }

    Status public status;
    string public baseURI;
    uint256 public constant MAX_MINT_PER_ADDR = 10;
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant PRICE = 0.002 * 10**18; // 0.002 ETH

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);

    constructor(string memory initBaseURI) ERC721A("BOTTY", "BOTTY") {
        baseURI = initBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(status == Status.Started, "BOTTY: Not started yet.");
        require(tx.origin == msg.sender, "BOTTY: Contract call not allowed.");
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
            "BOTTY: This is more than allowed."
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "BOTTY: Not enough quantity."
        );

        _safeMint(msg.sender, quantity);
        refundIfOver(PRICE * quantity);

        emit Minted(msg.sender, quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "BOTTY: Not enough ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "BOTTY: NFTs have been completely minted.");
    }
}
