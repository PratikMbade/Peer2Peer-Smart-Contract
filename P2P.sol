// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.11 < 0.9.10;



contract MultiLevelP2P {
    address public owner;
    uint256 public registrationFee = 0.01 ether;
    uint256 public contributionAmount =  0.1 ether;

    // Define the user structure
    struct User {
        address referrer;
        uint8 level;
        bool isActive;
    }

    // Mapping to store users
    mapping(address => User) public users;

    // Events for logging
    event Registration(address indexed user, address indexed referrer, uint8 level);

    // Modifier to ensure only the contract owner can execute certain functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Constructor to set the contract owner
    constructor() {
        owner = msg.sender;
    }

    // Function to register a new user
    function register(address _referrer) external payable {
        require(msg.value == registrationFee, "Incorrect registration fee");
        require(!users[msg.sender].isActive, "User already registered");

        // Set the referrer and level for the new user
        users[msg.sender] = User({
            referrer: _referrer,
            level: 1,
            isActive: true
        });

        emit Registration(msg.sender, _referrer, 1);

        // Pay the registration fee to the referrer
        payable(_referrer).transfer(msg.value);
    }

    // Function to make a contribution
    function contribute() external payable {
        require(users[msg.sender].isActive, "User not registered");
        require(msg.value == contributionAmount, "Incorrect contribution amount");

        uint8 userLevel = users[msg.sender].level;

        // Distribute the contribution to the referrer based on the level
        distributeContribution(msg.sender, userLevel, msg.value);

        // Move the user to the next level
        users[msg.sender].level++;

        // Emit an event to log the contribution
        emit Contribution(msg.sender, userLevel, msg.value);
    }

    // Internal function to distribute contribution to the referrer based on the level
    function distributeContribution(address _user, uint8 _level, uint256 _amount) internal {
        address referrer = users[_user].referrer;

        for (uint8 i = 1; i <= _level; i++) {
            uint256 bonusPercentage = getBonusPercentage(i);
            uint256 bonusAmount = (_amount * bonusPercentage) / 100;

            if (referrer != address(0) && users[referrer].isActive) {
                payable(referrer).transfer(bonusAmount);
                emit Bonus(_user, referrer, i, bonusAmount);
                referrer = users[referrer].referrer;
            } else {
                // If there is no referrer or the referrer is not active, stop the distribution
                break;
            }
        }
    }

    // Function to get the bonus percentage based on the level
    function getBonusPercentage(uint8 _level) internal pure returns (uint256) {
        if (_level == 1) {
            return 20;
        } else if (_level == 2) {
            return 10;
        } else if (_level == 3) {
            return 15;
        } else if (_level == 4) {
            return 25;
        } else if (_level == 5) {
            return 30;
        } else {
            return 0;
        }
    }

    

    // Event for logging contributions
    event Contribution(address indexed user, uint8 level, uint256 amount);

    // Event for logging bonuses
    event Bonus(address indexed fromUser, address indexed toUser, uint8 level, uint256 amount);
}
