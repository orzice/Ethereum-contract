pragma solidity ^0.7.5;
 
library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        assert(b >=0);
        return a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
}

abstract contract ERC20Std {
    function totalSupply() public virtual returns (uint256);
    function balanceOf(address _owner) public virtual returns (uint256);
    function transfer(address _to, uint256 _value) public virtual;

    function transferFrom(address _from, address _to, uint256 _value) public virtual;

    function approve(address _spender, uint256 _value) public virtual;
    function allowance(address _owner, address _spender) public virtual returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*
1000000000, "HaSog Token", "HST"
*/
contract StdToken is ERC20Std {
    using SafeMath for uint256;
    string  public  name ;
    string  public symbol;
    uint8   public decimals;
    address payable public owner;
    uint256 private _totalSupply;
 
    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => uint256) public freezeOf;

    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    constructor() {
        uint256 _initialSupply = 1000000000;//发行数量 10亿
        string memory _tokenName = "HaSog Token";//token的名字 HaSog Token
        uint8 _decimalUnits = 18;//最小分割，小数点后面的尾数 1ether = 10** 18wei
        string memory _tokenSymbol = "HST"; //HST

        decimals = 18; //_decimalUnits;                     
        _balanceOf[msg.sender] = _initialSupply * 10 ** 18; 
        _totalSupply = _initialSupply * 10 ** 18;           
        name = _tokenName;                                  
        symbol = _tokenSymbol;                              
        owner = msg.sender;
    }
 
    modifier validDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this) );
        _;
    }
 
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
 
    function balanceOf(address _owner) public view override returns (uint256) {
        return _balanceOf[_owner];
    }
 
    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return _allowance[_owner][_spender];
    }
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) validDestination(_spender) public override {
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    /*send tokens */
    function transfer(address _to, uint256 _value) validDestination(_to) public override {
        require (_value > 0);
        require (_balanceOf[msg.sender] > _value);
        require (_balanceOf[_to] + _value > _balanceOf[_to]);
 
        _balanceOf[msg.sender] = _balanceOf[msg.sender].safeSub(_value);
        _balanceOf[_to] = _balanceOf[_to].safeAdd(_value);
        emit Transfer(msg.sender, _to, _value);
    }
    /* Approval somebody send tokens */
    function transferFrom(address _from, address _to, uint256 _value) validDestination(_from) validDestination(_to) public override {
        require (_value > 0);
        require (_balanceOf[_from] > _value);                 // Check if the sender has enough
        require (_balanceOf[_to] + _value > _balanceOf[_to]); // Check for overflows
        require (_value < _allowance[_from][msg.sender]);     // Check allowance
 
        _balanceOf[_from] = _balanceOf[_from].safeSub(_value); // Subtract from the sender
        _balanceOf[_to]   = _balanceOf[_to].safeAdd(_value);    // Add the same to the recipient
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].safeSub(_value);
        emit Transfer(_from, _to, _value);
    }
 
    function freeze(uint256 _value) public returns (bool) {
        require (_balanceOf[msg.sender] >= _value); // Check if the sender has enough
        require (_value > 0);
 
        _balanceOf[msg.sender] = _balanceOf[msg.sender].safeSub(_value); // Subtract from the sender
        freezeOf[msg.sender] = freezeOf[msg.sender].safeAdd(_value);   // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
    function unfreeze(uint256 _value) public returns (bool) {
        require (freezeOf[msg.sender] >= _value); // Check if the sender has enough
        require (_value > 0);
 
        freezeOf[msg.sender] = freezeOf[msg.sender].safeSub(_value);   // Subtract from the sender
        _balanceOf[msg.sender] = _balanceOf[msg.sender].safeAdd(_value); // Updates totalSupply
        emit Unfreeze(msg.sender, _value);
        return true;
    }
    function burn(uint256 _value) public returns (bool) {
        require (_balanceOf[msg.sender] >= _value); // Check if the sender has enough
        require (_value > 0);
 
        _balanceOf[msg.sender] = _balanceOf[msg.sender].safeSub(_value);
        _totalSupply = _totalSupply.safeSub(_value); // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    /* transfer balance to owner */
    function withdrawEther(uint256 amount) public {
        require (msg.sender == owner);
        owner.transfer(amount);
    }
    /* can accept ether */
    fallback() external {}
    receive() payable external {}
 
}