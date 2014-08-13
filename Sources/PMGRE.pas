// ------------------------------------
//  Some Gre* functions from PMGRE.DLL
// ------------------------------------
unit PMGRE;
interface
uses os2def;

function GreDeath(_hdc:HDC):ulong;
function GreResurrection(_hdc:HDC; b:long; c:pointer):ulong;

implementation

{&cdecl+}
function Gre32Entry3(a:ulong; b:ulong; c:ulong):ulong;                   external 'PMGRE' index 63;
function Gre32Entry5(a:ulong; b:ulong; c:ulong; d:ulong; e:ulong):ulong; external 'PMGRE' index 65;
{&cdecl-}

function GreDeath(_hdc:HDC):ulong;
begin
  result:=Gre32Entry3(ulong(_hdc), 0, $000040B7);
end;

function GreResurrection(_hdc:HDC; b:long; c:pointer):ulong;
begin
  result:=Gre32Entry5(ulong(_hdc), ulong(b), ulong(c), 0, $000040B8);
end;

end.
