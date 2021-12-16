// SPDC License-Identifier: MIT

pragma solidity ^0.8.4;

contract Multisig {

  address public user_0;
  address public user_1;
  address public user_2;

  bool unlocked;
  int public votesInFavor;

  uint256 public number;

  mapping(address => bool) public voteCasted;
  
  event Voted(address, bool);
  event ResetVotes(bool);

  modifier onlyMultisigs {
    require(msg.sender == user_0 || msg.sender == user_1 || msg.sender == user_2, "you are not part of the multisig");
    _;
  } 

  modifier isUnlocked{
    require(unlocked == true, "majority did not approve");
    _;
  }


  constructor(address _user0, address _user1, address _user2){
    user_0 = _user0;
    user_1 = _user1;
    user_2 = _user2; 
  }

  function voting(bool choice) external onlyMultisigs{
    // check if user has already voted before
    require(voteCasted[msg.sender] == false, "You have already voted, can't vote twice");
    
    // if user can vote and votes true, increment vote by 1
    if(choice == true){
      votesInFavor += 1;
    }

    // if vote is 2 or bigger, it means the majority has won. 
    if(votesInFavor >= 2){
      unlocked = true;
    }

    // vote did not pass
    else{
      unlocked = false;
    }

    emit Voted(msg.sender, choice);
    // keep track of users that voted
    voteCasted[msg.sender] = true;
  }


  function setInteger(uint256 _num) external onlyMultisigs isUnlocked{
    number = _num;

    // after changes have been made, reset voting variables
    reset();
  }

  function reset() internal {
    unlocked = false;
    votesInFavor = 0;
    voteCasted[user_0] = false;
    voteCasted[user_1] = false;
    voteCasted[user_2] = false;
    emit ResetVotes(true);
    
  }

}
