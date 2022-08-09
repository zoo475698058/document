pragma solidity ^0.4.20;

contract AntFamily {
  
  event NewAnt(uint indexed antId, string name, uint dna);
  event NewHouse(uint indexed houseId, string name, uint existGoods, uint maxGoods);
  event MoveResult(uint indexed antId, uint originHouseId, uint targetHouseId, bool prizeSuccess, bool moveResult);
  
  uint dnaDigits = 12;
  uint dnaModulus = 10 ** dnaDigits;
  
  uint randNonce = 0;
  uint moveGoodsFinishProbability = 70;
  
  struct Ant {
    string name;
    uint dna;
    uint level;
    uint moveCount;
  }
  
  struct House {
    string name;
    uint existGoods;
    uint maxGoods;
  }

  Ant[] public ants;
  House[] public houses;
  
  mapping (uint => identity) public antToOwner;
  mapping (identity => uint) ownerAntCount;
  mapping (uint => identity) houseToOwner;
  
  modifier moveCheck(uint _originHouseId, uint _targetHouseId) {
    require(_originHouseId != _targetHouseId, "不能在同一个房子来回搬东西");
    require(houses[_originHouseId].existGoods > 0, "没东西可以搬啦，换一个房子吧");
    require(houses[_targetHouseId].maxGoods > houses[_targetHouseId].existGoods, "这个房子放满啦，换一个房子吧");
    _;
  }
  
  function _createAnt(string _name, uint _dna) private {
    uint id = ants.push(Ant(_name, _dna, 1, 0)) - 1;
    antToOwner[id] = msg.sender;
    ownerAntCount[msg.sender]++;
    emit NewAnt(id, _name, _dna);
  }
  
  function createRandomAnt(string _name) public {
    require(ownerAntCount[msg.sender] == 0, "只能创建一只蚂蚁");
    uint rand = uint(keccak256(_name));
    uint randDna = rand % dnaModulus;
    _createAnt(_name, randDna);
  }
  
  function createHouse(string _houseName, uint _existGoods, uint _maxGoods) public {
    uint houseId = houses.push(House(_houseName, _existGoods, _maxGoods)) - 1;
    houseToOwner[houseId] = msg.sender;
    emit NewHouse(houseId, _houseName, _existGoods, _maxGoods);
  }
  
  function moveGoods(uint _antId, uint _originHouseId, uint _targetHouseId) public moveCheck(_originHouseId, _targetHouseId) {
    require(msg.sender == antToOwner[_antId], "只能用自己的蚂蚁搬东西");
    require(msg.sender == houseToOwner[_originHouseId], "只能给自己家搬东西");
    require(msg.sender == houseToOwner[_targetHouseId], "只能给自己家搬东西");

    House storage originHouse = houses[_originHouseId];
    House storage targetHouse = houses[_targetHouseId];
    
    uint rand = _randMod(100);
    if (rand <= moveGoodsFinishProbability) {
      originHouse.existGoods--;
      targetHouse.existGoods++;
      bool prizeSuccess = _prize(_antId);
      emit MoveResult(_antId, _originHouseId, _targetHouseId, prizeSuccess, true);
    } else {
      emit MoveResult(_antId, _originHouseId, _targetHouseId, false, false);
    }
  }
  
  function _prize(uint _antId) private returns(bool) {
    Ant storage myAnt = ants[_antId];
    myAnt.moveCount++;
    if (myAnt.moveCount % 5 == 0) {
      myAnt.level++;
      return true;
    } else {
      return false;
    }
  }
  
  function _randMod(uint _modulus) private returns(uint) {
    randNonce++;
    return uint(keccak256(now, msg.sender, randNonce)) % _modulus;
  }
  
}