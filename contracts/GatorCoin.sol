pragma solidity ^0.4.12;

contract owned {

	address public owner;
	event ownershipTransfered(address old, address newOwner);

	modifier onlyOwner {
		if (msg.sender != owner) throw;
		_;
	}

	function owned() {
		owner = msg.sender;
	}

	function changeOwners(address newOwner) onlyOwner {
		ownershipTransfered(owner, newOwner);
		owner = newOwner;
	}

}

contract GatorCoin is owned {

	address[] public holders;
	mapping (address => uint256) public balanceOf;

	event DistributedCoins(uint256 value, address recipient);
	event SpentCoins(uint256 value, address spender);
	event WipedCoins();

	function distributeCoins(uint256 value, address recipient) onlyOwner {

		balanceOf[recipient] += value;
		balanceOf[owner] -= value;

		// track those that have coins
		holders.push(recipient);

		DistributedCoins(value, recipient);
	}

	function spendCoins(address from, uint256 value) returns (bool success) {
		if (balanceOf[from] < value) throw;
		balanceOf[from] -= value;
		balanceOf[owner] += value;

		SpentCoins(value, from);
		return true;
	}

	function clearCoins() onlyOwner {

		for (uint i=0; i < holders.length; i++) {
			balanceOf[holders[i]] = 0;
		}

		delete holders;

		WipedCoins();
	}

}

contract tokenRecipient {
	event ReceivedTokens(address from, uint256 value, address token);

	function receiveApproval(address from, uint256 value, address token) returns (bool success) {
		GatorCoin g = GatorCoin(token);
		if (!g.spendCoins(from, value)) throw;
		ReceivedTokens(from, value, token);

		return true;
	}
}

contract Governance is owned, tokenRecipient {

	address public token;
	uint public numProposals;
	Proposal[] public proposals;
	mapping (address => uint) public memberId;
	Member[] public members;

	event ProposalAdded(uint proposalId, address creator, uint threshold, uint maxAmount, string description);
	event VoteTransparent(uint proposalId, bool position, address voter, string comment, uint amount);
	event VoteAnonymous(uint proposalId, bool position, uint amount);
	event MembershipChanged(address member, bool isMember);

	struct Proposal {
		address creator;
		string description;
		uint maxAmount;
		uint minAmount;
		bool passed;
		uint currentAmount;
		uint deadline;
		bool anonymous;
		Vote[] votes;
	}

	struct Member {
		address member;
		string name;
		uint memberSince;
	}

	struct Vote {
		bool inSupport;
		address voter;
		uint amount;
		string comment;
	}

	modifier onlyMembers {
		if (memberId[msg.sender] == 0) throw;
		_;
	}

	function Governanace(address head, address coin) {
		if (head != 0) owner = head;
		addMember(0, '');
		token = coin;
	}

	function addMember(address target, string memberName) onlyOwner {
		uint id;
		if (memberId[target] == 0) {
			memberId[target] = members.length;
			id = members.length++;
			members[id] = Member({ member: target, name: memberName, memberSince: now});
			MembershipChanged(target, true);
		}
		else {
			id = memberId[target];
			Member m = members[id];
		}
	}

	function removeMember(address target) onlyOwner {
		if (memberId[target] == 0) throw;

		for (uint i = memberId[target]; i < members.length-1; i++) {
			members[i] = members[i+1];
		}
		delete members[members.length-1];
		members.length--;

		MembershipChanged(target, false);
	}

	function newProposal (
		address creator, string description, 
		uint threshold, uint max, bool anon,
		uint timeToVoteInSeconds
	) 
	  onlyMembers returns (uint proposalId)
	{

		proposalId = proposals.length++;
		Proposal p = proposals[proposalId];
		p.creator = creator;
		p.deadline = now + timeToVoteInSeconds;
		p.passed = false;
		p.currentAmount = 0;
		ProposalAdded(proposalId, creator, threshold, max, description);
		numProposals = proposalId + 1;

		return proposalId;
	}

	function vote (
		uint proposalNumber, bool support,
		string comment, uint amount
	) 
		onlyMembers returns (bool success)
	{
		Proposal p = proposals[proposalNumber];
		if (!receiveApproval(msg.sender, amount, token)) throw;

		if (support) {
			if (p.currentAmount + amount > p.maxAmount) throw;
			p.currentAmount += amount;
		}
		else {
			if (p.currentAmount - amount < 0) throw;
			p.currentAmount -= amount;
		}


	}

}