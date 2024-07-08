/* пример простого контракта ICO, который будет переводить со своего счёта токены всем,
кто отправит на него эфир. При деплое контракта нужно указать адрес токена. */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// Интерфейс для токена ERC20
interface ERC20Token {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

contract PlainICO {
    ERC20Token public token;
    address public owner;
    uint256 public tokenPrice; // Цена за 1 токен в Wei

    event TokenPurchased(address indexed buyer, uint256 amount);
    event Withdrawal(address indexed owner, uint256 amount);
    event TokenPriceUpdated(uint256 newPrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owners can call this function");
        _;
    }

    constructor(address tokenAddress, uint256 initialPrice) {
        token = ERC20Token(tokenAddress);
        owner = msg.sender;
        tokenPrice = initialPrice;
    }

    receive() external payable {
        buyTokens();
    }

    function buyTokens() public payable {
        require(msg.value > 0, "Ether value must be greater than 0");

        uint256 tokenAmount = msg.value / tokenPrice;
        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens available");

        bool success = token.transfer(msg.sender, tokenAmount);
        require(success, "Token transfer failed");

        emit TokenPurchased(msg.sender, tokenAmount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);

        emit Withdrawal(msg.sender, balance);
    }

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Token price must be greater than 0");
        tokenPrice = newPrice;

        emit TokenPriceUpdated(newPrice);
    }
}

/*При отправке на контракт эфира вызовется обработчик receive(), который выполнит
метод buyTokens(). Метод buyTokens считает количество отправленного эфира в wei,
считает адрес отправителя транзакции и вызовет функцию transfer() токена ERC20.
Весь эфир, лежащий на смарт-контракте, владелец смарт-контракта сможет
забрать, вызвав функцию withdraw().*/