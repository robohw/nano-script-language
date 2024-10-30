program nano;  // 24.10.28 v1.1 FINAL - KeyWords: INP, IF, JMP, RET, PRN, TRC  
{$MODE FPC}    // RET re-implanted, Arr.limit = 32767, 
 uses SysUtils;  
     
 type                            // Proto, for LABELs. 
   TLabel = record
     Name: string;               // name, and 
     Addr: Word;                 // address (line number)
 end;
   
 const
 ArMAX  = 32767;                 // upper limit of builtin array (Ar)
 CNTMAX = 2000000;               // avoid infinitive loops

 var {global}
   Code   : array of string;     // TEMP of the runnable nano code. Max. 65535 lines
   tokens : array of string;     // TEMP of the running line content, in tokenised form
   Labels : array of TLabel;     // list of labels
   Vars   : array['B'..'R'] of LongInt;
   Varb   : array['S'..'T'] of byte; 
   Varstr : array['U'..'Z'] of string;   
   Ar     : array of LongInt;    // builtin longint array with 32k capacity
   LineNum: Word = 0;            // program counter 
   Stack  : Word = 0;            // pseudo stack (for RET(urn))
   Trace  : Boolean = False;     // Tracer, default OFF 
   Counter: LongInt = 0;         // loop counter for ENDLESS loops 
   InFile,OutFile : text;        // incoming (nano script) outgoing (result file)
 
 procedure Error(const Msg: string);
 begin
   Writeln(OutFile,'ERROR (line ', LineNum, '): ', Msg);
   Writeln(OutFile,'Code: ', Code[LineNum-1]);
   close(OutFile);
   Halt(1);
 end;

 procedure Split(Line: string); // split a line to token(s)
 var
   i: Integer;
   InQuotes: Boolean;
   Curr: string;
 begin
   SetLength(Tokens, 0);
   InQuotes := False;
   Curr := '';
   for i := 1 to Length(Line) do
   begin
     if Line[i] = '"' then InQuotes := not InQuotes;
     if (Line[i] = ' ') and not InQuotes then
     begin
       if Curr <> '' then
       begin
         SetLength(Tokens, Length(Tokens) + 1);
         Tokens[High(Tokens)] := Curr;
         Curr := '';
       end;
     end
     else Curr := Curr + Line[i];
   end;
   if Curr <> '' then
   begin
     SetLength(Tokens, Length(Tokens) + 1);
     Tokens[High(Tokens)] := Curr;
   end;
 end;
 
 procedure SetLabelAddr(const Name: string; Addr: Word); // SET a LABEL and its ADDRESS
 var
   i: Integer;
 begin
   for i := 2 to length(name) do
     if not (name[i] in ['A'..'Z','_']) then error('illegal char in LABEL '+name);   
   for i := 0 to High(Labels) do
     if Labels[i].Name = Name then Error('Label "' + Name + '" already exists.');
   SetLength(Labels, Length(Labels) + 1);
   Labels[High(Labels)].Name := Name;
   Labels[High(Labels)].Addr := Addr;
 end;
 
 function GetLabelAddr(const Name: string): Word; // GET the ADDRESS of a LABEL
 var
   i: Integer;
 begin
   if(Name[1] <> '.') then Error('missing dot (label)');
   GetLabelAddr := 0;  
   for i := 0 to High(Labels) do if Labels[i].Name = Name then Exit(Labels[i].Addr);
   Error('Label not found: ' + Name);
 end;

 function ExtractIndex(s: string): word;  // for PRN instruction
 var
  i: Word;
 begin
  s := Copy(s, 3, Length(s) - 2);  
  if (Length(s) = 1) and (s[1] in ['B'..'Z']) then i := Vars[s[1]] else i := StrToIntDef(s, -1);  
  if (i > ArMax) then Error('too small/big (or A) index: ' + s);
  ExtractIndex := i;
 end;

 function GetIndex(s: string): word;
 var
   i: Word;
 begin
   i := ExtractIndex(s);
   if (i >= Length(Ar)) then SetLength(Ar, i + 1); 
   GetIndex := i;
 end;

 function GetVal(n: Byte): LongInt;   // GET VALUE of a VAR
 var
   i: LongInt;
 begin   
   if (tokens[n][1] in ['B'..'Z'])and(Length(tokens[n])>1)then Error('Invalid ID: '+tokens[n]);
   if (tokens[n][1] in ['-','0'..'9']) then
       if not TryStrToInt(tokens[n],i) then Error('Invalid numeric value ' + tokens[n]);  
   if (tokens[n][1] = 'A') and ((Length(tokens[n])< 3) or (tokens[n][2] <> '.')) then
       Error('invalid A.index: '+tokens[n]); 
   case tokens[n][1] of
     'B'..'Q': Exit(Vars[tokens[n][1]]); 
     'S','T' : Exit(Varb[tokens[n][1]]);
     'A': Exit(Ar[GetIndex(tokens[n])]);  
     'R': Exit(Random(Vars['R']));
     else i := StrToIntDef(tokens[n], Low(LongInt));
     if i = Low(LongInt) then Error('Invalid value: ' + tokens[n]);
     GetVal := i;
   end; // case
 end;
 
 function GetSVal(n: Byte): string;  // GET STRING VALUE of a VAR
 begin
   if (tokens[n][1] in ['U'..'Z']) and (Length(tokens[n])>1)then Error('Invalid ID: '+tokens[n]);
    if (tokens[n][1] in ['U'..'Z']) then Exit(Varstr[tokens[n][1]]) else
      GetSval:= tokens[n]; 
 end;
 
 function Calculate(op1, op2: Integer; oper: Char): Integer;
 begin
   case oper of
     '+': Calculate := op1 + op2;
     '-': Calculate := op1 - op2;
     '*': Calculate := op1 * op2;
     '/': if (op2=0) then Error('Div by 0') else Calculate := op1 div op2;
     '%': if (op2=0) then Error('Mod by 0') else Calculate := op1 mod op2;
   else
     Error('Invalid operator: ' + oper);  
   end;
 end; 

 function Input(n: byte): longint;   // INPUT
 var
 inStr: string;
 begin
   repeat
     write(tokens[n],': ');
     inStr:= '';
     readln(inStr);    
   until Trystrtoint(inStr,Input);
 end;
 
 procedure SetVal(n: Byte);   // SET VARIABLE VALUE
 var
  value: LongInt;
  SValue: string;
  i: Integer;
 begin
  if not (tokens[n][1]   in ['A'..'Z'])    then Error('Invalid var ID: ' + tokens[n]);
  if not (tokens[n+1][1] in ['=','+','-']) then Error('syntax error: ' + tokens[n+1]);
  if (tokens[n+1] = '=') and (length(tokens) < 3) then error('missing value/var ID');   
  if tokens[n+2] = 'INP' then Value := Input(n) else 
  if tokens[n+1] = '+'   then value := GetVal(n) + 1 else 
  if tokens[n+1] = '-'   then value := GetVal(n) - 1  else
  begin
  if (tokens[n][1] in ['U'..'Z']) then 
  begin
   case Length(tokens) of 3, 7: SValue := GetSVal(n + 2);
    else
      Error('Invalid (sLET) syntax');
    end;  // case
  end 
  else
    case Length(tokens) of
      3, 7: value := GetVal(n + 2);
      5, 9: value := Calculate(GetVal(n + 2), GetVal(n + 4), tokens[n + 3][1]);
    else
      Error('Invalid (LET) syntax');
    end;  // case
  end;

  if tokens[n][1] = 'A' then
  begin
    i := GetIndex(tokens[n]);
    Ar[i] := value;
  end
  else 
  if (tokens[n][1] in ['B'..'R']) then Vars[tokens[n][1]] := value else
  if (tokens[n][1] in ['S','T']) then Varb[tokens[n][1]] := value else
  if (tokens[n][1] in ['U'..'Z']) then Varstr[tokens[n][1]] := SValue;  
 end;

 procedure Printer(n: byte);  // --- PRN ------------------------------------ 
 var i: longInt; 
     Tmp: string;  
 begin
 for i := n to High(tokens) do
     if tokens[i][1] = 'A' then Write(OutFile,Ar[ExtractIndex(tokens[i])])else
     if tokens[i][1] in ['B'..'R'] then Write(OutFile,Vars[tokens[i][1]]) else
     if tokens[i][1] in ['U'..'Z'] then 
     begin
     Tmp := Varstr[tokens[i][1]];
     Tmp := copy(Tmp,2,length(Tmp)-2);
     Write(OutFile,Tmp)
     end else 
     Write(OutFile,Chr(Varb[tokens[i][1]]));
 end;
 
 procedure Jumper(n: byte); // For JMP
 begin
   Stack   := linenum;   
   LineNum := GetLabelAddr(tokens[n]); 
 end;
 
 procedure ExecuteMe;   // EXECUTE a line
 begin
   LineNum := 1;
   while (LineNum <= High(Code)) do
   begin
     Split(Code[LineNum]);
     Inc(LineNum);
     case tokens[0] of
       'IF':begin
             if (length(tokens[2])>1) or not (tokens[2][1] in ['<','>','=']) 
                then Error('unknown LogOp: '+tokens[2]);
             if ((tokens[2][1]='<') and (GetVal(1) < GetVal(3))) or                
                ((tokens[2][1]='>') and (GetVal(1) > GetVal(3))) or
                ((tokens[2][1]='=') and (GetVal(1) = GetVal(3))) then
              begin
                case tokens[4] of
                  'JMP': Jumper(5);
                  'PRN': Printer(5);
                  'RET': if Stack = 0 then Error('No return(R)') else LineNum := Stack;
                  else SetVal(4);
                end; // case
              end; // if
            end; // 'IF:'
       'JMP': Jumper(1);
       'RET': if Stack = 0 then Error('No return address found') else LineNum := Stack;
       'NOP': ; // No operation
       'PRN': Printer(1);
     else SetVal(0);
     end;
     if Counter > CNTMAX then Error('infinite loop detected') else Inc(Counter);
   end;
 end;
 
 procedure Init; 
 var
   i: byte;
 begin
   for i:= Ord('B') to Ord('Q') do vars[Chr(i)]:= -2147483648;  // int
   for i:= Ord('U') to Ord('Z') do varstr[Chr(i)]:= '.';        // string
   varb['S'] := 32; varb['T'] := 10;                            // char   
   Randomize;
   Vars['R'] := 100;           // Range for random numbers: 0..99   
   SetLength(Code, 0);
   SetLength(Labels, 0);
   SetLength(Ar, 1); 
 end;

 procedure LoadProgram;  // load a script 
 var 
  line: string;
 begin 
   init;
   LineNum := 0;   
   while not Eof(InFile) do
   begin
     ReadLn(InFile,Line);
     Line := UpperCase(Trim(Copy(Line, 1, Pos(';', Line + ';') - 1))); // Comment filter
     if Line = ''     then Continue;    
     if Line = 'TRC'  then Trace := True else
     if Line[1] = '.' then SetLabelAddr(Line, LineNum + 1)
     else
     begin
       Inc(LineNum);
       SetLength(Code, LineNum + 1);
       Code[LineNum] := Line;
     end;
   end;
   close(InFile);
 end;
 
 procedure PrintState;  // for TRACE 
 var
   i: Integer;
 begin
   Writeln(OutFile);
   Writeln(OutFile,'-------------- (', Counter, ' lines done) - Code:');
   for i := 1 to length(Code)-1 do
     if i < 10 then Writeln(OutFile,' ',i,'  ', Code[i]) else Writeln(OutFile,i,'  ', Code[i]);
   if Length(Labels) > 0 then
   begin
     Writeln(OutFile); Writeln(OutFile,'-------------- Label(s):');
     for i := 0 to length(Labels)-1 do Writeln(OutFile,Labels[i].Name, #9, Labels[i].Addr);
   end;  
   Writeln(OutFile); Writeln(OutFile,'-------------- Vars (B..Z):');
   for i := Ord('B') to Ord('R') do
       if Vars[Chr(i)] > -2147483648 then Writeln(OutFile,Chr(i), ' ', Vars[Chr(i)]); 
       Writeln(OutFile,'S', ' ', Varb['S']); 
       Writeln(OutFile,'T', ' ', Varb['T']); 
   for i := Ord('U') to Ord('Z') do
       if Varstr[Chr(i)] <> '.' then Writeln(OutFile,Chr(i), ' ', Varstr[Chr(i)]);         
   writeln(outfile); Writeln(OutFile,'-------------- Array element(s):');
   for i := 0 to length(Ar)-1 do Writeln(OutFile,'A.', i, ' = ', Ar[i]);
 end;
 
 begin // ------------------------- main
   if paramstr(1) <> '' then
   begin
    assign(InFile,paramstr(1));
    reset(InFile);
    assign(OutFile,paramstr(1)+'.out');
    rewrite(OutFile);  
   end   
   else 
   begin
    writeln(' no input file. Try: nano.exe your_script'); halt(1); 
   end;
    
   LoadProgram;  
   ExecuteMe;
   if Trace then PrintState;
   close(OutFile)
 end.
