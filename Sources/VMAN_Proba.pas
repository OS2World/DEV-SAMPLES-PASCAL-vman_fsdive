
{
 2002.06.13.
 Fixed:
  - 'q' can quit now gently even when the application is in fullscreen mode
  - SRCBUFFERBPP was not really used, the BPP is determined by FourCC...
  - No more problem with minimizing/maximizing/restoring/resizing when the application is in fullscreen mode
  - Closing VMAN when the application closes
 Added:
  - more comments.:)
}

Program VMAN_Proba;
{$PMTYPE PM}
uses os2def, os2base, os2pmapi, os2mm, GRADD, PMGRE, FSDIVE;

var hmodVMAN:hmodule;            // Handle of loaded VMAN.DLL module
    VMIEntry:FNVMIENTRY;         // The entry of VMAN.DLL
    NumVideoModes:longint;       // Number of supported video modes
    ModeInfo:pGDDModeInfo;       // List of all supported video modes
    DesktopModeInfo:GDDModeInfo; // One video mode, that is used as desktop
    NewModeInfo:pGDDModeInfo;    // New video mode for fullscreen
    fInFullScreenNow:boolean;    // Flag to show if the Dive and the Desktop
                                 //   is in Fullscreen or windowed mode now

const AppTitle:pchar='VMAN and FSDIVE Test Application';
      FULLSCREENWIDTH:longint=640;      // Parameters of the fullscreen mode we want to use
      FULLSCREENHEIGHT:longint=480;
      FULLSCREENBPP:longint=32;
      SRCBUFFERWIDTH:longint=640;       // Parameters of the source buffer
      SRCBUFFERHEIGHT:longint=480;
      SRCBUFFERFOURCC:ulong=ord('L') +
                            ord('U') shl 8 +
                            ord('T') shl 16 +
                            ord('8') shl 24;

const ImageUpdateWait=30;     // Time in msec to wait between image updates

var ab:HAB;                   // Anchor block
    mq:HMQ;                   // Message queue
    msg:QMSG;                 // One message (used by main message loop)
    hFrame, hClient:HWND;     // Window handle of frame and client
    hDiveInst: hDive;         // Dive instance number
    ulImage:ulong;            // Handle of image buffer allocated by Dive
    fVRNDisabled:boolean;     // flag to show if VRN is disabled or not
    fFullScreenMode:boolean;  // Flag to show if the application is running in fullscreen mode or not.
                              // Note, that it doesn't mean that the desktop if in fullscreen mode now,
                              // because it only shows that when the application gets focus, it should
                              // run in fullscreen mode (or not).
                              // To check the actual mode, see fInFullscreenNow!

const TMR_DRAWING=1;          // ID of our timer, used to update screen


// ----------------------------------------- VMAN --------------------------------------

///////////////////////////////////////
// UnloadVMAN
//
// Unloads VMAN.DLL
//
function UnloadVMAN:boolean;
begin
  result:=(DosFreeModule(hmodVMAN)=no_error);
  Writeln('VMAN Unloaded!');
end;
///////////////////////////////////////
// LoadVMAN
//
// Loads VMAN.DLL and queries its entry
// point into VMIEntry variable
//
function LoadVMAN:boolean;
var rc:apiret;
begin
  rc:=DosLoadModule(Nil, 0, 'VMAN', hmodVMAN);                   // Load VMAN.DLL
  if rc<>no_error then
  begin  // No VMAN.DLL... Maybe no GRADD driver installed???
    writeln('Could not load VMAN! rc=',rc);
    result:=false;
    exit;
  end;
  rc:=DosQueryProcAddr(hmodVMAN, 0, 'VMIEntry', pfn(@VMIEntry)); // Query entry point address
  if rc<>no_error then
  begin
    writeln('Could not query VMIEntry address! rc=',rc);
    UnloadVMAN;
  end;
  result:=(rc=no_error);
end;

///////////////////////////////////////
// InitVMIEntry
//
// Sends a INITPROC command to VMAN, so
// informs VMAN that a new process is
// about to use its services
//
function InitVMIEntry:boolean;
var rc:apiret;
    ipo:INITPROCOUT;
begin
  rc:=VMIEntry(0, VMI_CMD_INITPROC, nil, @ipo);
  if rc<>no_error then
  begin
    writeln('VMI_CMD_INITPROC rc=',rc);
  end;
  fInFullScreenNow:=false;
  result:=rc=no_error;
end;

///////////////////////////////////////
// UninitVMIEntry
//
// Sends a TERMPROC command to VMAN, so
// informs VMAN that this process has
// stopped using its services
//
function UninitVMIEntry:boolean;
var rc:apiret;
begin
  rc:=VMIEntry(0, VMI_CMD_TERMPROC, nil, nil);
  if rc<>no_error then
  begin
    writeln('VMI_CMD_TERMPROC rc=',rc);
  end;
  result:=rc=no_error;
end;

///////////////////////////////////////
// QueryModeInfo
//
// Queries the number of available video
// modes to NumVideoModes, allocates memory
// for information of all the video modes,
// and queries video mode informations into
// ModeInfo.
//
function QueryModeInfo:boolean;
var rc:apiret;
    ModeOperation:longint;
    OneModeInfo:pGDDModeInfo;
begin
  result:=false;

  ModeOperation:=QUERYMODE_NUM_MODES;
  rc:=VMIEntry(0, VMI_CMD_QUERYMODES, @ModeOperation, @NumVideoModes);
  if rc<>no_error then
  begin
    NumVideoModes:=0;
    writeln('VMI_CMD_QUERYMODES rc=',rc);
    exit;
  end;
  getmem(ModeInfo,NumVideoModes*sizeof(GDDModeInfo));
  if ModeInfo=Nil then
  begin
    Writeln('Could not allocate memory for ModeInfo list!');
    NumVideoModes:=0;
    exit;
  end;

  ModeOperation:=QUERYMODE_MODE_DATA;
  rc:=VMIEntry(0, VMI_CMD_QUERYMODES, @ModeOperation, ModeInfo);
  if rc<>no_error then
  begin
    writeln('Could not query ModeInfo list! rc=',rc);
    freemem(ModeInfo); ModeInfo:=Nil;
    NumVideoModes:=0;
    exit;
  end;
  result:=true;
end;

///////////////////////////////////////
// FreeModeInfo
//
// Frees the memory allocated by
// QueryModeInfo
//
function FreeModeInfo:boolean;
begin
  freemem(ModeInfo); ModeInfo:=Nil;
  NumVideoModes:=0;
  result:=true;
end;

////////////////////////////////////////
// Some helper functions/procedures
//
function FourCCToString(fcc:ulong):string;
begin
  if fcc=0 then result:='' else
  result:=chr((fcc and $FF))+
          chr((fcc and $FF00) shr 8)+
          chr((fcc and $FF0000) shr 16)+
          chr((fcc and $FF000000) shr 24);
end;

procedure WriteModeInfo(OneModeInfo:pGDDModeInfo);
begin
  with OneModeInfo^ do
  begin
    writeln('Mode ID: ',ulModeID);
    writeln('  ',ulHorizResolution,'x',ulVertResolution,'/',ulBpp,'  (',ulRefreshRate,' Hz)');
    writeln('  Num of colors: ',cColors,' FourCC: ',FourCCToString(fccColorEncoding));
  end;
end;

///////////////////////////////////////
// FindNewModeInfo
//
// Searches for
// FULLSCREENWIDTH x FULLSCREENHEIGHT x FULLSCREENBPP
// videomode in ModeInfo structure, and
// sets the NewModeInfo pointer to point
// to that part of ModeInfo, if found.
//
function FindNewModeInfo:boolean;
var l:longint;
    OneModeInfo:pGDDModeInfo;
begin
  result:=false;
//  writeln('Available GRADD Video Modes: ',NumVideoModes);
  NewModeInfo:=Nil;
  if ModeInfo=Nil then exit;
  OneModeInfo:=ModeInfo;
  for l:=1 to NumVideoModes do
  begin
//    WriteModeInfo(OneModeInfo);
    if (OneModeInfo^.ulHorizResolution=FULLSCREENWIDTH) and
       (OneModeInfo^.ulVertResolution=FULLSCREENHEIGHT) and
       (OneModeInfo^.ulBpp=FULLSCREENBPP) then NewModeInfo:=OneModeInfo;
    longint(OneModeInfo):=longint(OneModeInfo)+Sizeof(GDDModeInfo);
  end;
  result:=NewModeInfo<>nil;
end;

///////////////////////////////////////
// QueryCurrentMode
//
// Queries the current video mode, and
// stores it in DesktopModeInfo
//
function QueryCurrentMode:boolean;
var rc:apiret;
begin
  rc:=VMIEntry(0, VMI_CMD_QUERYCURRENTMODE, Nil, @DesktopModeInfo);
  if rc<>no_error then
  begin
    writeln('Could not query DesktopModeInfo! rc=',rc);
  end;
  result:=rc=no_error;
end;

///////////////////////////////////////
// KillPM
//
// Simulates a switching to fullscreen mode,
// from the PM's point of view
//
procedure KillPM;
var _hab:HAB;
    _hwnd:HWND;
    _hdc:HDC;
    rc:APIRET;
begin
  _hab:=WinQueryAnchorBlock(HWND_DESKTOP);
  _hwnd:=WinQueryDesktopWindow(_hab, 0);
  _hdc:=WinQueryWindowDC(_hwnd);                   // Get HDC of desktop
  WinLockWindowUpdate(HWND_DESKTOP, HWND_DESKTOP); // Don't let other applications write to screen anymore!
  rc:=GreDeath(_hdc);                              // This is the standard way to tell the graphical engine
                                                   // that a switching to full-screen mode is about to come!
                                                   // (see gradd.inf)
end;

///////////////////////////////////////
// RestorePM
//
// Simulates a switching back from fullscreen mode,
// from the PM's point of view
//
procedure RestorePM;
var _hab:HAB;
    _hwnd:HWND;
    _hdc:HDC;
    rc:APIRET;
begin
  _hab:=WinQueryAnchorBlock(HWND_DESKTOP);
  _hwnd:=WinQueryDesktopWindow(_hab, 0);
  _hdc:=WinQueryWindowDC(_hwnd);
  rc:=GreResurrection(_hdc, 0, nil);       // This is the standard way of telling the graphical engine
                                           // that somebody has switched back from a fullscreen session to PM.
  WinLockWindowUpdate(HWND_DESKTOP, 0);    // Let others write to the screen again...
  WinInvalidateRect(_hwnd, nil, true);     // Let everyone redraw itself! (Build the screen)
end;

///////////////////////////////////////
// SetPointerVisibility
//
// Shows/hides the mouse pointer
//
function SetPointerVisibility(fState:boolean):apiret;
var hwspi:HWSHOWPTRIN;
begin
  hwspi.ulLength:=sizeof(hwspi);
  hwspi.fShow:=fState;
  result:=VMIEntry(0, VMI_CMD_SHOWPTR, @hwspi, nil);
end;

///////////////////////////////////////
// SwitchToFullscreen
//
// Switches to fullscreen-mode
//
function SwitchToFullscreen(OneMode:pGDDModeInfo):boolean;
var ModeID:longint;
    rc:apiret;
    DIVEAperture:Aperture;
    DIVEfbinfo:FBINFO;
begin
  // Setup Aperture and FBINFO for FSDIVE
  fillchar(DIVEfbinfo, sizeof(FBINFO), 0);

  DIVEfbinfo.ulLength := sizeof(FBINFO);
  DIVEfbinfo.ulCaps := 0;
  DIVEfbinfo.ulBPP := OneMode^.ulBPP;
  DIVEfbinfo.ulXRes := OneMode^.ulHorizResolution;
  DIVEfbinfo.ulYRes := OneMode^.ulVertResolution;
  DIVEfbinfo.ulScanLineBytes := OneMode^.ulScanLineSize;
  DIVEfbinfo.ulNumENDIVEDrivers := 0; // unknown
  DIVEfbinfo.fccColorEncoding:= OneMode^.fccColorEncoding;

  DIVEaperture.ulPhysAddr := longint(OneMode^.pbVRAMPhys);
  DIVEaperture.ulApertureSize := OneMode^.ulApertureSize;
  DIVEaperture.ulScanLineSize := OneMode^.ulScanLineSize;
  DIVEaperture.rctlScreen.yBottom := OneMode^.ulVertResolution - 1;
  DIVEaperture.rctlScreen.xRight := OneMode^.ulHorizResolution - 1;
  DIVEaperture.rctlScreen.yTop := 0;
  DIVEaperture.rctlScreen.xLeft := 0;

  SetPointerVisibility(False);                     // Hide mouse
  KillPM;                                          // Tell PM that we're switching away!
  DosSleep(256);                                   // Give some time for it...
  ModeID:=OneMode^.ulModeID;
  rc:=VMIEntry(0, VMI_CMD_SETMODE, @ModeID, nil);  // Set new video mode
  if rc<>no_error then
  begin  // Rollback if something went wrong
    RestorePM;
    SetPointerVisibility(True);
  end else
  begin
    DiveFullScreenInit(@DIVEAperture, @DIVEfbinfo); // Tell DIVE that it can work in this
    fInFullScreenNow:=True;                         // fullscreen mode now!
  end;
  result:=rc=no_error;
end;

///////////////////////////////////////
// SwitchBackToDesktop
//
// Switches back from fullscreen-mode
//
function SwitchBackToDesktop:boolean;
var ModeID:longint;
    rc:apiret;
begin
  ModeID:=DesktopModeInfo.ulModeID;
  rc:=VMIEntry(0, VMI_CMD_SETMODE, @ModeID, nil);   // Set old video mode
  DosSleep(256);
  DiveFullScreenTerm;                               // Tell DIVE that end of fullscreen mode
  RestorePM;                                        // Tell PM that we're switching back
  fInFullScreenNow:=false;
  SetPointerVisibility(True);                       // Restore mouse pointer
end;

///////////////////////////////////////
// VMANCleanUpExitProc
//
// ExitProc, to cleanup VMAN resources
// at application termination.
//
procedure VMANCleanUpExitProc;
begin
  // Restore desktop mode if the program left in FS mode!
  //
  // Note that in this case, there will be problems with future DIVE applications
  // until the desktop is restarted, because SwitchBackToDesktop uses
  // DiveFullScreenTerm, which must be called before closing Dive (and Dive is already
  // closed when the execution gets here), but at least the desktop will be in its
  // original video mode!
  //
  if fInFullScreenNow then SwitchBackToDesktop;

  FreeModeInfo;
  UninitVMIEntry;
  UnloadVMAN;
end;


// -------------------------------------- Window procedure -----------------------------

procedure RenderScene; forward;

function WndProc (Wnd: HWnd; Msg: ULong; Mp1, Mp2: MParam): MResult; cdecl;
var active:boolean;
    ps:HPS;
    _swp:SWP;
    rcl:RECTL;
    rgn:HRGN;
    rgnCtl:RGNRECT;
    pl:PointL;
    rcls:array[0..49] of RECTL;
    SetupBlitter:Setup_Blitter;
begin
   result:=0;
   case Msg of
     WM_CREATE: begin        // Window creation time
         WinStartTimer(WinQueryAnchorBlock(Wnd), wnd, TMR_DRAWING, ImageUpdateWait);
       end;
     WM_TIMER: begin         // Timer event
         if SHORT1FROMMP(mp1)=TMR_DRAWING then WinPostMsg(Wnd, WM_PAINT, 0, 0);
       end;
     WM_SIZE,                // Window resizing
     WM_MINMAXFRAME: begin   // Window minimize/maximize/restore
         if fFullscreenMode then
         begin               // do nothing if in fullscreen mode!
           result:=0; exit;
         end;                // else do the normal processing.
       end;
     WM_ACTIVATE: begin      // activation/deactivation of window

       active := Boolean(mp1);

       if not Active then
       begin // Switching away from the applicatoin
         if fInFullscreenNow then // Switching away from the application, that is in FS mode!
         begin
           SwitchBackToDesktop;
           WinShowWindow(hFrame, false);                // hide window
           WinSetVisibleRegionNotify( hClient, FALSE ); // turn VRN off
           WinPostMsg(Wnd, WM_VRNDISABLED, 0, 0);       // make sure dive turns off itself too
           WinSetCapture(HWND_DESKTOP, 0);              // release captured mouse
         end;
       end else
       begin // Switching to the application
         if fFullScreenMode then  // Switching to the application that should run in FS mode!
         begin
           WinShowWindow(hFrame, true);                 // make window visible
           WinSetVisibleRegionNotify( hClient, TRUE );  // turn on VRN
           WinPostMsg(Wnd, WM_VRNENABLED, 0, 0);        // setup dive
           WinSetCapture(HWND_DESKTOP, hClient);        // capture mouse
           SwitchToFullScreen(NewModeInfo);             // and do switching!
         end;
       end;

     end;

   WM_VRNDISABLED: begin // Visible region notification

      fVrnDisabled := TRUE;
      // Dive must be protected by mutex semaphore if it can be accessed
      // from another thread too. It cannot be in our case, so no need
      // for the mutex semaphore.
      //
//      DosRequestMutexSem (hmtxDiveMutex, -1L);
      DiveSetupBlitter (hDiveInst, Nil);
//      DosReleaseMutexSem (hmtxDiveMutex);
     end;

   WM_VRNENABLED: begin  // Visible region notification
      ps := WinGetPS (wnd);
      rgn := GpiCreateRegion (ps, 0, NIL);

      WinQueryVisibleRegion (wnd, rgn);

      rgnCtl.ircStart := 1;
      rgnCtl.crc := 50;
      rgnCtl.ulDirection := 1;

      // Get the all ORed rectangles

      GpiQueryRegionRects (ps, rgn, NIL, rgnCtl, rcls[0]);

      GpiDestroyRegion (ps, rgn);

      WinReleasePS (ps);

      // Now find the window position and size, relative to parent.

      WinQueryWindowPos ( wnd, _swp );

      // Convert the point to offset from desktop lower left.

      pl.x := _swp.x;
      pl.y := _swp.y;

      WinMapWindowPoints ( hFrame, HWND_DESKTOP, pl, 1 );

      // Tell DIVE about the new settings.

      SetupBlitter.ulStructLen       := sizeof( SETUP_BLITTER );
      SetupBlitter.fccSrcColorFormat := SRCBUFFERFOURCC;
      SetupBlitter.ulSrcWidth        := SRCBUFFERWIDTH;
      SetupBlitter.ulSrcHeight       := SRCBUFFERHEIGHT;
      SetupBlitter.ulSrcPosX         := 0;
      SetupBlitter.ulSrcPosY         := 0;
      SetupBlitter.fInvert           := TRUE; // Invert, so the first line of buffer is the bottom-most line of image
      SetupBlitter.ulDitherType      := 1;

      SetupBlitter.fccDstColorFormat := 0;    // = FOURCC_SCRN constant in C;
      SetupBlitter.lDstPosX          := 0;
      SetupBlitter.lDstPosY          := 0;
      if (not fFullScreenMode) then
      begin
         SetupBlitter.ulDstWidth        := _swp.cx;
         SetupBlitter.ulDstHeight       := _swp.cy;

         SetupBlitter.lScreenPosX       := pl.x;
         SetupBlitter.lScreenPosY       := pl.y;

         SetupBlitter.ulNumDstRects     := rgnCtl.crcReturned;
         SetupBlitter.pVisDstRects      := @rcls;
      end
      else
      begin
         SetupBlitter.ulDstWidth        := FULLSCREENWIDTH;
         SetupBlitter.ulDstHeight       := FULLSCREENHEIGHT;

         SetupBlitter.lScreenPosX       := 0;
         SetupBlitter.lScreenPosY       := 0;

         SetupBlitter.ulNumDstRects     := DIVE_FULLY_VISIBLE;
         SetupBlitter.pVisDstRects      := NIL;
      end;

//      DosRequestMutexSem(hmtxDiveMutex, -1L);
      DiveSetupBlitter ( hDiveInst, @SetupBlitter );
//      DosReleaseMutexSem(hmtxDiveMutex);
      fVrnDisabled := FALSE;
     end;

   WM_CHAR: begin  // Keypress notification

      if(SHORT1FROMMP ( mp2 ) = ord('f')) then
      begin
        if fFullScreenMode then
        begin // Switch to windowed
          SwitchBackToDesktop;
          WinSetCapture(HWND_DESKTOP, 0);
        end else
        begin // Switch to full screen
          SwitchToFullscreen(NewModeInfo);
          WinSetCapture(HWND_DESKTOP, hClient);
        end;
        WinShowWindow(hFrame, true);
        WinSetVisibleRegionNotify( hClient, TRUE );
        WinPostMsg(Wnd, WM_VRNENABLED, 0, 0);
        fFullScreenMode:=fInFullScreenNow;

      end;

      if(SHORT1FROMMP ( mp2 ) = ord('q')) then WinPostMsg(wnd, WM_CLOSE, 0, 0);

      result:=0;
      exit;
   end;

   WM_PAINT: begin  // Window redraw!
      ps := WinBeginPaint(wnd,0,@rcl);
      RenderScene;
      WinEndPaint(ps);
      result:=0;
      exit;
    end;

   WM_CLOSE: begin // Window close
      if fFullScreenMode then
      begin // Switch to windowed
        SwitchBackToDesktop;
        WinSetCapture(HWND_DESKTOP, 0);
        WinShowWindow(hFrame, true);
        WinSetVisibleRegionNotify( hClient, TRUE );
        WinPostMsg(Wnd, WM_VRNENABLED, 0, 0);
        fFullScreenMode:=fInFullScreenNow;
      end;
      WinPostMsg (wnd, WM_QUIT, 0, 0);
      result:=0;
     end;
  end;

  if result=0 then result:=WinDefWindowProc(Wnd, Msg, Mp1, Mp2);
end;

// ------------------------ Procedures for simple PM usage -----------------------------

///////////////////////////////////////
// InitPM
//
// Initializes PM, creates a message queue,
// and creates the main window.
//
procedure InitPM;
var fcf:ulong;
begin
  ab:=WinInitialize(0);
  mq:=WinCreateMsgQueue(ab,0);
  if mq=0 then
  begin
    Writeln('Could not create message queue!');
  end;
  WinRegisterClass( ab, 'MainDIVEWindowClass', WndProc, CS_SIZEREDRAW, 0);
  fcf:=FCF_TITLEBAR or
       FCF_SYSMENU or
       FCF_MINBUTTON or
       FCF_MAXBUTTON or
       FCF_SIZEBORDER or
       FCF_TASKLIST;
  hFrame:=WinCreateStdWindow( HWND_DESKTOP, 0, fcf,
                              'MainDIVEWindowClass', AppTitle, 0,//WS_CLIPCHILDREN or WS_CLIPSIBLINGS,
                              0, 0, @hClient);

  fFullScreenMode:=false;
end;

///////////////////////////////////////
// SetupMainWindow
//
// Sets the size/position of the main window,
// and makes it visible.
//
procedure SetupMainWindow;
begin
  WinSetWindowPos( hFrame,
                   HWND_TOP,
                   (WinQuerySysValue (HWND_DESKTOP, SV_CXSCREEN) - SRCBUFFERWIDTH) div 2,
                   (WinQuerySysValue (HWND_DESKTOP, SV_CYSCREEN) - SRCBUFFERHEIGHT) div 2,
                   SRCBUFFERWIDTH,
                   SRCBUFFERHEIGHT + WinQuerySysValue (HWND_DESKTOP, SV_CYTITLEBAR)
                                   + WinQuerySysValue (HWND_DESKTOP, SV_CYDLGFRAME)*2
                                   + 1,
                   SWP_SIZE or SWP_ACTIVATE or SWP_SHOW or SWP_MOVE);
end;

///////////////////////////////////////
// UninitPM
//
// Destroys main window, and uninitializes
// PM.
//
procedure UninitPM;
begin
  WinDestroyWindow(hFrame);
  WinDestroyMsgQueue(mq);
  WinTerminate(ab);
end;

// -------------------------------------------------- DIVE -----------------------------

///////////////////////////////////////
// ShutdownDIVE
//
// Switches back to Windowed mode if
// necessary, then frees allocated
// image buffer, and closes Dive.
//
procedure ShutdownDIVE;
begin
  // We must switch back to windowed mode before closing Dive!
  // (Because switching uses Dive too!)
  if fInFullscreenNow then
    SwitchBackToDesktop;

  WinSetVisibleRegionNotify( hClient, false );

  DiveFreeImageBuffer( hDiveInst, ulImage );
  DiveClose( hDiveInst );
end;

///////////////////////////////////////
// SetupDIVE
//
// Opens Dive, allocates image buffer,
// and sets VRN, and sets up Dive for
// the first time (WM_VRNENABLED msg.)
//
procedure SetupDIVE;
var pFrameBuffer:pointer;
begin
  fVrnDisabled := TRUE;

  DiveOpen( hDiveInst, FALSE, pFrameBuffer );

  DiveAllocImageBuffer( hDiveInst, ulImage, SRCBUFFERFOURCC, SRCBUFFERWIDTH, SRCBUFFERHEIGHT, 0, nil) ;

  WinSetVisibleRegionNotify( hClient, TRUE );

  WinPostMsg( hFrame, WM_VRNENABLED, 0, 0 );
end;


///////////////////////////////////////
// RenderScene
//
// Updates the image buffer, then
// blits it using Dive.
//
var basecolor:byte;
procedure RenderScene;
var pbBuffer: pointer;
    i,j:longint;
    ulScanLineBytes, ulScanLines:ulong;
    pC:^Byte;

begin
  if (ulImage=0) or
     (fVRNDisabled) then exit;

  DiveBeginImageBufferAccess(hDiveInst, ulImage, pbBuffer, ulScanLineBytes, ulScanLines);

  // Move image down:
  for j:=ulScanLines-2 downto 0 do
  begin
    move(mem[ulong(pbBuffer)+j*ulScanLineBytes], mem[ulong(pbBuffer)+(j+1)*ulScanLineBytes], ulScanLineBytes);
  end;
  // Create new firstline
  pc:=pbBuffer;
  inc(basecolor);
  for i:=0 to ulScanLineBytes-1 do
  begin
    if random(100)<10 then
      pc^:=random(256)
    else
      pc^:=BaseColor;
    ulong(pc):=ulong(pc)+1;
  end;
//  fillchar(mem[longint(pbBuffer)+(j-1)*ulScanLineBytes], ulScanLineBytes, random(256));
  DiveEndImageBufferAccess(hDiveInst, ulImage);
  DiveBlitImage(hDiveInst, ulImage, DIVE_BUFFER_SCREEN );
end;

// ------------------------------------------ General stuff ----------------------------

///////////////////////////////////////
// ProcessParams
//
// Processes command line parameters
//
procedure ProcessParams;
var s,s2:string;
    xpos:longint;
    code:longint;
begin
  if paramcount>0 then
  begin
    // First parameter: e.g. 1024x768x16  (fullscreen videomode)
    s:=paramstr(1);
    xpos:=pos('x',s);
    s2:=copy(s,1, xpos-1); val(s2,FULLSCREENWIDTH, code);
    delete(s,1, xpos);
    xpos:=pos('x',s);
    s2:=copy(s,1, xpos-1); val(s2,FULLSCREENHEIGHT, code);
    delete(s,1, xpos);
    val(s,FULLSCREENBPP, code);

    s2:=paramstr(2);
    if s2<>'' then
    begin // Second parameter: source buffer (1024x768xR565)
      s:=paramstr(2);
      xpos:=pos('x',s);
      s2:=copy(s,1, xpos-1); val(s2,SRCBUFFERWIDTH, code);
      delete(s,1, xpos);
      xpos:=pos('x',s);
      s2:=copy(s,1, xpos-1); val(s2,SRCBUFFERHEIGHT, code);
      delete(s,1, xpos);
      SRCBUFFERFOURCC:=mmioFourCC(s[1],s[2],s[3],s[4]);
    end;

  end;
end;

// ------------------------------------------------ Main -------------------------------


begin
  processparams;

  // ----------------------  VMAN initialization -----------------
  if not LoadVMAN then halt;  // Load VMAN
  if not InitVMIEntry then    // Send "Hi! New process is here!" info to VMAN
  begin
    UnloadVMAN;
    halt;
  end;
  if not QueryModeInfo then   // Query available video modes
  begin
    UninitVMIEntry;
    UnloadVMAN;
    halt;
  end;
  if not FindNewModeInfo then // Find the fullscreen video mode
  begin
    writeln('Could not find video mode: ',FULLSCREENWIDTH,' x ',FULLSCREENHEIGHT,' x ',FULLSCREENBPP,'bpp!');
    FreeModeInfo;
    UninitVMIEntry;
    UnloadVMAN;
    halt;
  end;
  if not QueryCurrentMode then // Save the actual (desktop) video mode
  begin
    FreeModeInfo;
    UninitVMIEntry;
    UnloadVMAN;
    halt;
  end;

  // Ok, VMAN has been initialized.
  AddExitProc(VMANCleanUpExitProc); // Setup VMAN cleanup-process

  // ----------------------  PM Initialization -------------------
  InitPM;

  // Setup DIVE
  SetupDIVE;

  // Setup and make visible the main window
  SetupMainWindow;
  // ----------------------  Main message loop -------------------

  while WinGetMsg(Ab, Msg, 0, 0, 0) do
      WinDispatchMsg(Ab, Msg);

  // Shut down DIVE
  ShutdownDIVE;

  // ----------------------  PM uninitialization -----------------
  UninitPM;

  // ----------------------  VMAN Uninitialization ---------------
  // Done by VMANCleanUpExitProc
end.
