pragma solidity ^0.4.0;

contract zhongchou{

	struct funder{
		address funderaddress;
		uint256 tomoney;
	}
	//结构体
	struct needer{
		address neederaddress;
		uint256 goal;
		uint256 amount;
		uint256 funderacoount;
		mapping(uint => funder) map;
	}
	uint neederamoutcount;
	mapping(uint => needer) needmap;

	//创建众筹池
	function Newneeder(address _Neederaddress, uint256 _goal){
		neederamoutcount++;
		needmap[neederamoutcount] = needer(_Neederaddress,_goal,0,0);
	}
	//给众筹池支付
	function contribute(address _address,uint256 _neederamount) payable{
		needer storage _needer = needmap[_neederamount];
		_needer.amount += msg.value;
		_needer.funderacoount++;
		if(_needer.amount <= _needer.goal){
			revert();
		}

		_needer.map[_needer.funderacoount] = funder(_address,msg.value);
	}
	//众筹完毕 给用户打款
	function iscopelete(uint256 _id){
		needer storage _needer = needmap[_id];
		if(_needer.amount >= _needer.goal){
			_needer.neederaddress.transfer(_needer.amount);
		}
	}
	function test(uint256 _id) returns(address,uint256,uint256,uint256){

		return (needmap[_id].neederaddress,needmap[_id].goal,needmap[_id].amount,needmap[_id].funderacoount);

	}

}