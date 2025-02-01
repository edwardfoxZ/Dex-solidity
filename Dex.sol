// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract Dex {
    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }

    mapping(bytes32 => Token) public tokens;
    mapping(bytes32 => mapping(address => uint)) public traderBalances;
    bytes32[] public tokenList;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function addToken(
        bytes32 _ticker,
        address _tokenAddress
    ) external onlyAdmin {
        tokens[_ticker] = Token(_ticker, _tokenAddress);
        tokenList.push(_ticker);
    }

    function deposit(
        bytes32 _ticker,
        uint _amount
    ) external tokenExists(_ticker) {
        IERC20(tokens[_ticker].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        traderBalances[_ticker][msg.sender] += _amount;
    }

    function withdraw(
        bytes32 _ticker,
        uint _amount
    ) external tokenExists(_ticker) {
        require(
            traderBalances[_ticker][msg.sender] >= _amount,
            "not enough token to withdraw"
        );
        IERC20(tokens[_ticker].tokenAddress).transfer(msg.sender, _amount);
        traderBalances[_ticker][msg.sender] -= _amount;
    }

    modifier tokenExists(bytes32 _ticker) {
        require(
            tokens[_ticker].tokenAddress != address(0),
            "token is not existed"
        );
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "only admin");
        _;
    }
}
