// ------------------------------------
//  Missing FSDIVE calls from DIVE.DLL
// ------------------------------------
unit FSDIVE;
interface
uses os2def;
{&cdecl+}
type pFBINFO=^FBINFO;
     FBINFO=record
       ulLength : ULONG;          //*  Length of FBINFO data structure, in bytes. */
       ulCaps   : ULONG;          //*  Specifies the PM Driver capabilities. */
       ulBPP    : ULONG;          //*  Screen bits per pel. */
       ulXRes   : ULONG;          //*  Number of screen X pels. */
       ulYRes   : ULONG;          //*  Number of screen Y pels. */
       ulScanLineBytes : ULONG;   //*  Number of bytes per scanline. */
       fccColorEncoding : ULONG;  //*  Screen color encoding. */
       ulNumENDIVEDrivers : ULONG;//*  Number of pluggable EnDIVE drivers.  */
     end;

type pAperture=^APERTURE;
     APERTURE=record              //* aperture */
       ulPhysAddr     : ULONG;    //* physical address */
       ulApertureSize : ULONG;    //* 1 Meg, 4 Meg or 64k */
       ulScanLineSize : ULONG;    //* this is >= the screen width */
       rctlScreen     : RECTL;    //* device independant co-ordinates */
     end;

const DIVE_FULLY_VISIBLE = $ffffffff;  // Missing from os2mm.pas!

procedure DiveFullScreenInit(pNewAperture:pAPERTURE; pNewframeBuffer:pFBINFO);
procedure DiveFullScreenTerm;

implementation

procedure DiveFullScreenInit(pNewAperture:pAPERTURE; pNewframeBuffer:pFBINFO); external 'DIVE' index 16;
procedure DiveFullScreenTerm;                                                  external 'DIVE' index 17;

end.
