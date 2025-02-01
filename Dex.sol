// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract Dex {
    enum Side {
        BUY,
        SELL
    }

    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }

    struct Order {
        uint id;
        bytes32 ticker;
        uint amount;
        Side side;
        uint filled;
        uint price;
        uint date;
    }

    mapping(bytes32 => Token) public tokens;
    mapping(bytes32 => mapping(address => uint)) public traderBalances;
    mapping(bytes32 => mapping(uint => Order[])) public orderBooks;
    bytes32[] public tokenList;
    address public admin;
    uint public nextOrderId;
    bytes32 public DAI = bytes32("Dai");

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

    function orderLimit(
        bytes32 _ticker,
        Side _side,
        uint _amount,
        uint _price
    ) external tokenExists(_ticker) {
        require(_ticker != DAI, "ticker token must not be dai");
        if (_side == Side.SELL) {
            require(
                traderBalances[_ticker][msg.sender] >= _amount,
                "not enough tokens to sell order"
            );
        } else {
            require(
                traderBalances[DAI][msg.sender] >= _price * _amount,
                "not enough dai to buy order"
            );
        }
        Order[] memory orders = orderBooks[_ticker][_side];
        orders.push(
            nextOrderId,
            _ticker,
            _amount,
            _side,
            0,
            _price,
            block.timestamp
        );

        uint i = orders.length - 1;
        while (i > 0) {
            if (_side == Side.BUY && orders[i - 1].price > orders[i].price) {
                break;
            }
            if (_side == Side.SELL && orders[i - 1].price < orders[i].price) {
                break;
            }
            Order memory order = orders[i - 1];
            orders[i - 1] = orders[i];
            orders[i] = order;
            i--;
        }
        nextOrderId++;
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
