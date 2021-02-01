// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.1;

import '../interfaces/IQuickSwapFactory.sol';
import '../QuickSwapPair.sol';
import * as util from '../libraries/Util.sol';
// qssf == quickswap storage file
import * as qssf from '../storage/QuickSwapStorage.sol';

contract QuickSwapFactory is IQuickSwapFactory {   

    function mintQuickSwap(address tokenA, address tokenB, address _to, uint _value) external override {
        require(qssf.quickSwapStorage().getPair[tokenA][tokenB] == msg.sender, 'SpiritSwap: Not a pair');
        util.mintGovernanceTokens(_to, _value); 
    }

    function allPairsLength() external view override returns (uint) {
        return qssf.quickSwapStorage().allPairs.length;
    }

    function feeTo() external view override returns (address to) {
        to = qssf.quickSwapStorage().feeTo;
    }

    function feeToSetter() external view override returns (address to) {
        to = qssf.quickSwapStorage().feeToSetter;
    }

    function getPair(address tokenA, address tokenB) external view override returns (address pair) {
        pair = qssf.quickSwapStorage().getPair[tokenA][tokenB];
    }

    function allPairs(uint index) external view override returns (address pair) {
        pair = qssf.quickSwapStorage().allPairs[index];
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        qssf.QuickSwapStorage storage qss = qssf.quickSwapStorage();
        require(tokenA != tokenB, 'SpiritSwap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SpiritSwap: ZERO_ADDRESS');
        require(qss.getPair[token0][token1] == address(0), 'SpiritSwap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(QuickSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IQuickSwapPair(pair).initialize(token0, token1);
        qss.getPair[token0][token1] = pair;
        qss.getPair[token1][token0] = pair; // populate mapping in the reverse direction
        qss.allPairs.push(pair);
        emit PairCreated(token0, token1, pair, qss.allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        qssf.QuickSwapStorage storage qss = qssf.quickSwapStorage();
        require(msg.sender == qss.feeToSetter, 'SpiritSwap: FORBIDDEN');
        qss.feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        qssf.QuickSwapStorage storage qss = qssf.quickSwapStorage();
        require(msg.sender == qss.feeToSetter, 'SpiritSwap: FORBIDDEN');
        qss.feeToSetter = _feeToSetter;
    }
}
