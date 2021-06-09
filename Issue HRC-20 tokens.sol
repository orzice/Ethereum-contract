pragma solidity ^0.4.25;
/*
1000000, "ShieldCoin", "SC"

发行币名，ShieldCoin，符号，SC，发行量 100万

单位：wei, 最小分割，小数点后面的尾数 1ether = 10** 18wei
*/
/**
 * Math operations with safety checks
 */
contract SafeMath {
  //internal > private 
    //internal < public
    //修饰的函数只能在合约的内部或者子合约中使用
    //乘法
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    //assert断言函数，需要保证函数参数返回值是true，否则抛异常
    assert(a == 0 || c / a == b);
    return c;
  }
//除法
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
 
    //减法
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    assert(b >=0);
    return a - b;
  }
 
  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}
 
 
contract ShieldCoin is SafeMath{
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    //发行者
	  address public owner;
 
    /* 这将创建一个包含所有余额的数组 */
    mapping (address => uint256) public balanceOf;
    
    
    //key:授权人                key:被授权人  value: 配额
    mapping (address => mapping (address => uint256)) public allowance;
    
    mapping (address => uint256) public freezeOf;
 
    /* 这会在区块链上生成一个公共事件，通知客户端 */
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    /* 这会通知客户燃烧的量 */
    event Burn(address indexed from, uint256 value);
	
	/* 这将通知客户端冻结的金额 */
    event Freeze(address indexed from, uint256 value);
	
	/* 这将通知客户端解冻的金额 */
    event Unfreeze(address indexed from, uint256 value);
 
    /* 使用初始供应令牌初始化合同给合同的创建者 */
    
    //1000000, "ShieldCoin", "SC"
     constructor() public {
        uint256 _initialSupply = 1000000;//发行数量
        string memory _tokenName = "ShieldCoin";//token的名字 SCoin
        uint8 _decimalUnits = 18;//最小分割，小数点后面的尾数 1ether = 10** 18wei
        string memory _tokenSymbol = "SC"; //SC
            
        decimals = 18;//_decimalUnits;                           // 用于显示的小数量
        balanceOf[msg.sender] = _initialSupply * 10 ** 18;              // 给创造者所有初始标记
        totalSupply = _initialSupply * 10 ** 18;                        // 更新总供应量
        name = _tokenName;                                   // 为代币设置名称
        symbol = _tokenSymbol;                               // 为代币设置符号

		    owner = msg.sender;
    }
 
    /* 投币 */
    //某个人花费自己的币
    function transfer(address _to, uint256 _value) public {
        require (_to == 0x0);                               // 阻止传输到0x0地址。改为使用Use burn（）
		    require (_value <= 0); 
        require (balanceOf[msg.sender] < _value);           // 检查发送者是否有足够的
        require (balanceOf[_to] + _value < balanceOf[_to]); // 检查溢流
        
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // 从发送者中减去
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // 将其添加到收件人
        emit Transfer(msg.sender, _to, _value);                   // 通知任何监听此传输的人
    }
    /* 允许另一个合同为您花费一些代币 */
    //找一个人A帮你花费token，这部分钱并不打A的账户，只是对A进行花费的授权
    //A： 1万
    function approve(address _spender, uint256 _value) public returns (bool success) {
		    require (_value <= 0); 
        //allowance[管理员][A] = 1万
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       
    /* A 合同试图得到硬币 */
    function transferFrom(address _from /*管理员*/, address _to, uint256 _value) public returns (bool success) {
        require (_to == 0x0);                               // 阻止传输到0x0地址。改为使用Use burn（）
        require (_value <= 0); 
        require (balanceOf[_from] < _value);                 // 检查发送者是否有足够的
        
        require (balanceOf[_to] + _value < balanceOf[_to]);  // 检查溢流
        
        require (_value > allowance[_from][msg.sender]);     // 支票津贴
           // mapping (address => mapping (address => uint256)) 公共津贴
       
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // 从发送者中减去
        
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // 将其添加到收件人
       
        //allowance[管理员][A] = 1万-五千 = 五千
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);                  // 通知任何监听此传输的人
        return true;
    }
 
    function burn(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] < _value);            // 阻止传输到0x0地址。改为使用Use burn（）
		    require (_value <= 0); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // 检查发送者是否有足够的
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // 全部更新
        emit Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] < _value);            // 检查发送者是否有足够的
		    require (_value <= 0); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // 从发送者中减去
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // 全部更新
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) public returns (bool success) {
        require (freezeOf[msg.sender] < _value);            // 检查发送者是否有足够的
		require (_value <= 0); 
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // 从发送者中减去
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
	
	// 将余额转移给所有者
	function withdrawEther(uint256 amount) public {
		require (msg.sender != owner);
		owner.transfer(amount);
	}
	
	// can accept ether
	function() public payable {
    }
}