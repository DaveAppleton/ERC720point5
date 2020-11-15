// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;



contract erc720pointfive {
    
    struct oData {
        uint256 start;
        address owner;
        uint256 numTix;
    }

    uint numTokens;
    uint numBlocks;
    mapping(address => uint256[]) public tokensByOwner; 
    mapping(address => uint256) public numTokensByOwner;
    mapping(uint256 => oData[]) public tokenBlocks;
    
    function inBlock(uint256 thisBlock, uint tokenID) public view returns (address, bool) {
        oData[] memory tb = tokenBlocks[thisBlock];
        uint len = tb.length;
        for (uint pos =0; pos < len; pos++) {
            if ((tokenID >= tb[pos].start) && (tokenID < tb[pos].start + tb[pos].numTix)) {
                return (tb[pos].owner,true);
            }
        }
        return (address(0),false);
    }

    event doing(uint this);
    function ownerOf(uint256 tokenID) public view returns (uint256 pos, address addr) {
        bool ok;
        require(tokenID < numTokens,"invalid token ID");
        pos = (numBlocks)/2;
        uint size = pos;
        do {
            (addr,ok) = inBlock(pos, tokenID);
            if (ok) return (pos,addr);
            //emit doing(start);
            if (tokenBlocks[pos][0].start > tokenID) {
                pos -= size;
            } else {
                pos += size;
            }
            if (size == 0) {
                require(false,"cannot find the bugger");
            }
            size /= 2;
        } while (true);

    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < numTokens,"invalid token ID");
        return index;
    }

    function mint(address _owner, uint256 _numtokens) public {
        oData memory thisData = oData( numTokens,  _owner, _numtokens);
        uint pos = numBlocks++;
        tokenBlocks[pos].push(thisData);
        numTokens += _numtokens;
        tokensByOwner[_owner].push(pos);
        numTokensByOwner[_owner] += _numtokens;
    }
    
    function transfer(address to, uint tokenid) public returns (bool) {
         require(tokenid < numTokens,"invalid token ID");
         address  oldowner;
         uint256  pos;
         (pos,oldowner) = ownerOf(tokenid);
         require(msg.sender==oldowner,"token not owned by operator");
         changeOwner(tokenid,to);
         return true;
    }

    function changeOwner(uint256 tokenid, address newowner) public {
        require(tokenid < numTokens,"invalid token ID");
        uint256 pos;
        address oldowner;
        oData[] memory oa = tokenBlocks[pos]; // lower gas costs ?
        (pos,oldowner) = ownerOf(tokenid);
        if (oldowner == newowner) {
            return;
        }
        for (uint index = 0; index < oa.length; index++) {
            if (tokenid >= oa[index].start && tokenid < oa[index].start+oa[index].numTix) {
                if (oa[index].numTix == 1) {
                    tokenBlocks[pos][index].owner = newowner;
                    return;
                }
                if (tokenid == oa[index].start) {
                    tokenBlocks[pos][index].start++;
                } else if (tokenid == oa[index].start+oa[index].numTix-1) {
                    tokenBlocks[pos][index].numTix--;
                } else {
                    uint numTix = oa[index].numTix;
                    uint beforeT = tokenid - oa[index].start;
                    uint afterT = numTix - beforeT - 1;
                    tokenBlocks[pos][index].numTix = tokenid - tokenBlocks[pos][index].start;
                    tokenBlocks[pos].push(oData(tokenid+1,oldowner,afterT));
                }
                tokenBlocks[pos].push(oData(tokenid,newowner,1));
            }
        }
    }
}

