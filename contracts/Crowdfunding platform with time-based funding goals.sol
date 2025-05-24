// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TimedCrowdfunding
 * @dev A crowdfunding platform with time-based funding goals
 */
contract TimedCrowdfunding {
    struct Campaign {
        address creator;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 deadline;
        uint256 amountRaised;
        bool finalized;
        bool goalReached;
    }
    
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    
    uint256 public campaignCount;
    
    event CampaignCreated(uint256 indexed campaignId, address indexed creator, string title, uint256 fundingGoal, uint256 deadline);
    event ContributionReceived(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event CampaignFinalized(uint256 indexed campaignId, bool goalReached, uint256 amountRaised);
    event FundsWithdrawn(uint256 indexed campaignId, address indexed recipient, uint256 amount);
    event RefundIssued(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    
    /**
     * @dev Create a new crowdfunding campaign
     * @param _title Campaign title
     * @param _description Campaign description
     * @param _fundingGoal Amount to raise in wei
     * @param _durationInDays Campaign duration in days
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        uint256 _durationInDays
    ) public {
        require(_fundingGoal > 0, "Funding goal must be greater than zero");
        require(_durationInDays > 0, "Duration must be greater than zero");
        
        uint256 deadline = block.timestamp + (_durationInDays * 1 days);
        
        campaignCount++;
        
        campaigns[campaignCount] = Campaign({
            creator: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            deadline: deadline,
            amountRaised: 0,
            finalized: false,
            goalReached: false
        });
        
        emit CampaignCreated(campaignCount, msg.sender, _title, _fundingGoal, deadline);
    }
    
    /**
     * @dev Contribute funds to a campaign
     * @param _campaignId ID of the campaign to contribute to
     */
    function contribute(uint256 _campaignId) public payable {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(campaign.creator != address(0), "Campaign does not exist");
        require(!campaign.finalized, "Campaign has been finalized");
        require(block.timestamp < campaign.deadline, "Campaign deadline has passed");
        require(msg.value > 0, "Contribution must be greater than zero");
        
        campaign.amountRaised += msg.value;
        contributions[_campaignId][msg.sender] += msg.value;
        
        emit ContributionReceived(_campaignId, msg.sender, msg.value);
    }
    
    /**
     * @dev Finalize a campaign and either release funds or enable refunds
     * @param _campaignId ID of the campaign to finalize
     */
    function finalizeCampaign(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(campaign.creator != address(0), "Campaign does not exist");
        require(!campaign.finalized, "Campaign already finalized");
        require(
            msg.sender == campaign.creator || block.timestamp >= campaign.deadline,
            "Only creator can finalize before deadline"
        );
        
        campaign.finalized = true;
        campaign.goalReached = campaign.amountRaised >= campaign.fundingGoal;
        
        emit CampaignFinalized(_campaignId, campaign.goalReached, campaign.amountRaised);
    }
    
    /**
     * @dev Creator withdraws funds if goal was reached
     * @param _campaignId ID of the campaign
     */
    function withdrawFunds(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(campaign.creator == msg.sender, "Only campaign creator can withdraw");
        require(campaign.finalized, "Campaign must be finalized");
        require(campaign.goalReached, "Funding goal was not reached");
        
        uint256 amount = campaign.amountRaised;
        campaign.amountRaised = 0;
        
        payable(campaign.creator).transfer(amount);
        
        emit FundsWithdrawn(_campaignId, campaign.creator, amount);
    }
    
    /**
     * @dev Contributor claims refund if goal was not reached
     * @param _campaignId ID of the campaign
     */
    function claimRefund(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(campaign.finalized, "Campaign must be finalized");
        require(!campaign.goalReached, "Funding goal was reached, no refunds");
        
        uint256 amount = contributions[_campaignId][msg.sender];
        require(amount > 0, "No contribution found");
        
        contributions[_campaignId][msg.sender] = 0;
        
        payable(msg.sender).transfer(amount);
        
        emit RefundIssued(_campaignId, msg.sender, amount);
    }
}