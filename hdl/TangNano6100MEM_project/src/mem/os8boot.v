// RK Disk Bootstrap

initial
begin
   mem['o0023]='o6007; // CAF    ; 
   mem['o0024]='o6744; // DLCA   ; addr = 0
   mem['o0025]='o1032; // TAD(32); unit no
   mem['o0026]='o6746; // DLDC   ; command, unit
   mem['o0027]='o6743; // DLAG   ; disk addr, go
   mem['o0030]='o1032; // TAD(32); unit no, for OS
   mem['o0031]='o5031; // JMP .  ;
   mem['o0032]='o0000; //        ; unit 0 (bit<9:10>)
   //
//   mem['o7776]='o0023;
   mem['o7776]='o7777;
   mem['o7777]='o5776; // JMP(7776)=0023
end
