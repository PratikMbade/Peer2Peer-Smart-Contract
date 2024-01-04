// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.11 < 0.9.10;




contract MultiLevelP2P{

    address public owner;
    bool contractInitialize;

    //capacity of each level 
    uint256[] public levelCapacities = [1,2,4,8,16,32];

    // store users address in list
    address[] public  userslist ;

    constructor(){
        owner = msg.sender;
        contractInitialize = false;
    }
    

    struct User{
        address referrer;
        uint8 level;
        bool isActive;
        uint256 indexInLevelList;
    }

    struct TreeNode{
        address  user;
        address leftChild;
        address rightChild;
    }

    // store a user along with there address 

    mapping(address => User) public users;

    // mapping to store users at each level;
    mapping(uint8 => address[]) public usersByLevel;

    //mapping to  store treeNode for each level
    mapping (uint8 => TreeNode[]) public  treeNodes;

    event Registratioin(address indexed  user,address indexed  referrer, uint level,uint indexInLevelist );

    event bonus(address indexed fromUser, address indexed  toUser,uint8 level, uint256 amount);


    modifier onlyOwner(){
        require(msg.sender == owner,"You're not owner , this function can only operate by owner");
        _;
    }
    

    fallback() external payable { }

    receive() external payable { }

    // To initialize contract

    function initializeContract() public   onlyOwner{
        require(contractInitialize == false,"Contract is already initialized");

        // very first user which is owner of Contract it store at level 0 which has only capacity 1;
        users[owner] = User({
            referrer : address(0),
             level : 0,
             isActive:true,
             indexInLevelList: usersByLevel[0].length
             
        });

        usersByLevel[0].push(owner);

        //now add owner  node as the root to the tree;
         treeNodes[1].push(TreeNode({
            user:owner,
            leftChild:address(0),
            rightChild:address(0)
         }));

         contractInitialize = true;

         emit Registratioin(owner,address(0),0,0);
        

    }
    

    // function to register  a  user  (the big bull)

    function register(address _referrer) external  payable {
        // check whether contract is initialized or not
        if(!contractInitialize){
            initializeContract();
        }
         
        uint256 RegistrationFee = 0.01 ether;     
        require(msg.value == RegistrationFee,"Pay 1$ (0.01 Ether) for Registration");
        require(!users[msg.sender].isActive, "You have already registered");
         

         //Now Check if  the contract is Initialized
         uint8 userLevel = users[_referrer].level;
         uint8 nextLevel = userLevel;

         // check if current  level capacity has been reawched
         if(getNumberOfUsersInLevel(userLevel) >= levelCapacities[userLevel - 1]){
             // current level has been reached;
             while(nextLevel < levelCapacities.length && getNumberOfUsersInLevel(nextLevel) >= levelCapacities[nextLevel - 1]){
                nextLevel ++;
             }

         }

         require(nextLevel <= levelCapacities.length,"All levels are at capacity");
           
            uint256 positionInLevel = usersByLevel[nextLevel].length;

         treeNodes[nextLevel].push(TreeNode({
            user:msg.sender,
            leftChild:address(0),
            rightChild:address(0)
         }));

         /// if hte user is not at root level ,update the parent's left or right

         if(nextLevel > 1){
            uint256 parentPosition = (positionInLevel - 1)/2;
             uint remainder = (positionInLevel - 1)%2;

             if(remainder == 0){
                treeNodes[nextLevel -1][parentPosition].leftChild = msg.sender;
             }
             else{
                treeNodes[nextLevel -1][parentPosition].rightChild = msg.sender;
             }
         }

         users[msg.sender] = User({
             referrer: _referrer,
             level :nextLevel,
             isActive:true,
             indexInLevelList:positionInLevel
         });
         
         usersByLevel[nextLevel].push(msg.sender);

         userslist.push(msg.sender);

         emit Registratioin(msg.sender,_referrer,nextLevel,positionInLevel);

         payable (_referrer).transfer(msg.value);
         

    }

    function getNumberOfUsersInLevel(uint8 _level)internal view returns (uint256){
    
    return  usersByLevel[_level].length;
    }

    function getAllUsers()external  view returns (address[] memory){
        return  userslist;
    }

    
      function payAmountForPackage() public payable {
        require(
            users[msg.sender].isActive == true,
            "You've not done registration,"
        );
        uint256 packageAmount = 0.1 ether;
        require(
            msg.value == packageAmount,
            "transaction due to you have not paid 10$"
        );


        distributedAmount(msg.sender,1,packageAmount* 20/100) ; //  level
        distributedAmount(msg.sender,2,packageAmount* 10/100) ;


    }

    function distributedAmount(address _sender,uint8 _level,uint256 _amount) internal   {
      
      address[]  storage levelUsers = usersByLevel[_level];

      require(levelUsers.length > 0,"No users present at specific level");

      uint256 bonusPerUser = _amount / levelUsers.length;

      for(uint256  i = 0; i<levelUsers.length;i++){
        address referre = users[levelUsers[i]].referrer;

        if(referre != address(0) && users[_sender].isActive){
             payable(referre).transfer(bonusPerUser);
            emit bonus(_sender, referre, _level, bonusPerUser);
        }
      } 

    }

    // ... (unchanged code)6

    // Event for logging contributions
    event Contribution(address indexed user, uint8 level, uint256 amount);

    
}