// ---------------------------------
//  Truncated and converted GRADD.H
// ---------------------------------
unit GRADD;

interface
uses os2def;
{&cdecl+}

  {
        Prototype declarations for low level driver function call table.
     }

  type

     CID = ULONG;
  { Chain ID  }

     GID = ULONG;
  { Gradd ID  }

  const
     GID_DONTCARE = $ffffffff;

  type FNHWCMD=function(_p1:pointer; _p2:pointer):ulong;
  type FNHWENTRY=function(_p1:GID; _p2:ULONG; _p3:pointer; _p4:pointer):ulong;
  type FNSDBITBLT=function(_p1:pointer; _p2:pointer):ulong;
  type FNSDLINE=function(_p1:pointer; _p2:pointer):ulong;

  type PFNHWENTRY = ^FNHWENTRY;
       PFNHWCMD   = ^FNHWCMD;
       PFNSDBITBLT = ^FNSDBITBLT;
       PFNSDLINE  = ^FNSDLINE;

    { gddmodeinfo  }
    { used to make SETMODE request      }
    { no of colors (bpp)                }
    { horizontal pels                   }
    { vertical scan lines               }
    { in Hz (0 if not available)        }
    { physical address of VRAM          }
    { Current bank size                 }
    { size (in bytes) of one scan line  }
    { Pel format (defines above         }
    { Total size of VRAM in bytes       }
    { Total number of colors            }

    type

       GDDMODEINFO = record
            ulLength : ULONG;
            ulModeId : ULONG;
            ulBpp : ULONG;
            ulHorizResolution : ULONG;
            ulVertResolution : ULONG;
            ulRefreshRate : ULONG;
            pbVRAMPhys : ^BYTE;
            ulApertureSize : ULONG;
            ulScanLineSize : ULONG;
            fccColorEncoding : ULONG;
            ulTotalVRAMSize : ULONG;
            cColors : ULONG;
         end;

       _GDDMODEINFO = GDDMODEINFO;

       PGDDMODEINFO = ^GDDMODEINFO;
    {
          Structure for HWEntry router, see gdddata.c for array.
       }
    { hwcmd  }
    { return code if pfnHWCmd is NULL  }
    { ring change otherwise            }

       HWCMD = record
            pfnHWCmd : PFNHWCMD;
            ulRc : ULONG;
         end;

       _HWCMD = HWCMD;

       PHWCMD = ^HWCMD;
    {
         Ring change codes
       }

    const
       DONTCARE = 0;
       RING2 = 2;

    {
          Graphics Hardware Interface (GHI) commands for
          the Base Function class.
       }

    const
       BASE_FUNCTION_CLASS = 'Base Function';
       GHI_CMD_INIT = 0;
       GHI_CMD_INITPROC = 1;
       GHI_CMD_TERM = 2;
       GHI_CMD_TERMPROC = 3;
       GHI_CMD_QUERYCAPS = 4;
       GHI_CMD_QUERYMODES = 5;
       GHI_CMD_SETMODE = 6;
       GHI_CMD_PALETTE = 7;
       GHI_CMD_BITBLT = 8;
       GHI_CMD_LINE = 9;
       GHI_CMD_MOVEPTR = 10;
       GHI_CMD_SETPTR = 11;
       GHI_CMD_SHOWPTR = 12;
       GHI_CMD_VRAM = 13;
       GHI_CMD_REQUESTHW = 14;
       GHI_CMD_EVENT = 15;
       GHI_CMD_EXTENSION = 16;
       GHI_CMD_BANK = 17;
       GHI_CMD_TEXT = 18;
       GHI_CMD_USERCAPS = 19;
       GHI_CMD_POLYGON = 20;
       GHI_CMD_MAX = 21;
    {
          Defines and structures for the GHI_CMD_INIT DDI
       }
    { gddinitin  }

    type

       GDDINITIN = record
            ulLength : ULONG;
            pfnChainedHWEntry : PFNHWENTRY;
         end;

       _GDDINITIN = GDDINITIN;

       PGDDINITIN = ^GDDINITIN;
    { gddinitout  }

       GDDINITOUT = record
            ulLength : ULONG;
            cFunctionClasses : ULONG;
         end;

       _GDDINITOUT = GDDINITOUT;

       PGDDINITOUT = ^GDDINITOUT;
    {
          Defines and structures for the GHI_CMD_INITPROC DDI
       }
    { initprocout  }

       INITPROCOUT = record
            ulLength : ULONG;
            ulVRAMVirt : ULONG;
         end;

       _INITPROCOUT = INITPROCOUT;

       PINITPROCOUT = ^INITPROCOUT;
    {
          Defines and structures for the GHI_CMD_QUERYCAPS DDI
       }
    { capsinfo  }
    { sizeof CAPSINFO structure       }
    { Name describing function set    }
    { Function class specific flags   }

       CAPSINFO = record
            ulLength : ULONG;
            pszFunctionClassID : pchar;
            ulFCFlags : ULONG;
         end;

       _CAPSINFO = CAPSINFO;

       PCAPSINFO = ^CAPSINFO;
    {
         Defines for ulFCFlags field of the CAPSINFO data structure
         NOTE: The flags below are GRADD Caps for the base function class.
       }
    { GRADD wants to see M2M blits }

    const
       GC_SEND_MEM_TO_MEM = $00000001;
    { GRADD wants to simulate 3way rops as sequence of 2way rops. }
       GC_SIM_SRC_PAT_ROPS = $00000002;
    {RESERVED - NOT USED NOW }
    { GRADD supports alpha blending rules and }
       GC_ALPHA_SUPPORT = $00000004;
    { ALPHABITBLTINFO. }
    { If this flag is not returned, }
    { VMAN will never call the Gradd for }
    { Alpha Blending. }
    { SHOULD match DS2_* in pmddi.h }
    { GRADD handles stretchblts }
       GC_SRC_STRETCH = $00000008;
    { GRADD can handle polygon(concave or convex) }
       GC_POLYGON_SIZE_ANY = $00000010;
    { of any size. }
    { GC_POLYGON_FILL must be set }
    { GRADD can handle single clip rect of }
       GC_CLIP = $00000020;
    { polygons for pfnPolygon and }
    { source bitmap for pfnBitblt with }
    { GC_SRC_STRETCH set. }
    { see GC_CLP_COMPLEX }
    { GRADD can handle clipping }
       GC_CLIP_COMPLEX = $00000040;
    { with more than one clip rect }
    { GC_CLIP must be set. }
    { following defines GC_  SHOULD match DS_  in pmddi.h  }
    { Downloadable Fonts }
       GC_TEXTBLT_DOWNLOADABLE = $00002000;
    { CLIPPABLE    Fonts }
       GC_TEXTBLT_CLIPABLE = $00004000;
    { Device has Hardware Fonts }
       GC_TEXTBLT_DS_DEVICE_FONTS = $00008000;
    { Device handles LINEINFO2. }
       GC_SIMPLE_LINES = $00800000;
    { For compatibility with old source code retain old definitions }
       TEXTBLT_DOWNLOADABLE = GC_TEXTBLT_DOWNLOADABLE;
       TEXTBLT_CLIPABLE = GC_TEXTBLT_CLIPABLE;
       TEXTBLT_DS_DEVICE_FONTS = GC_TEXTBLT_DS_DEVICE_FONTS;
{$ifndef DS_SIMPLE_LINES}

    const
       DS_SIMPLE_LINES = GC_SIMPLE_LINES;
{$endif}
    {RESERVED - NOT USED NOW }
    { send Device independent bitmaps }

    const
       GC_SRC_CONVERT = $02000000;
    { without converting to device internal format. }
    { Gradd will convert during blts or }
    { call softdraw to simulate. }
    { If not set, GRE will convert DIB in a temporary buffer. }
    { Gradd should set this based on performance. }
    { GRADD can handle polygon(triangle and quad) }
       GC_POLYGON_FILL = $08000000;
    { fills and POLYGONINFO. see GC_POLYGON_SIZE_ANY }
    { if set, Graphics Engine call pfnPolygon }
    { for fills instead of pfnBitBlt. }
    {
          Defines and structures for the GHI_CMD_QUERYMODES and GHI_CMD_SETMODE
       }
       QUERYMODE_NUM_MODES = $0001;
       QUERYMODE_MODE_DATA = $0002;
       QUERYMODE_VALID = QUERYMODE_NUM_MODES or QUERYMODE_MODE_DATA;
    {
          Defines and structures for the GHI_CMD_VRAM
       }
    { vramin  }

    type

       VRAMIN = record
            ulLength : ULONG;
            ulFunction : ULONG;
            pIn : Pointer;
         end;

       _VRAMIN = VRAMIN;

       PVRAMIN = ^VRAMIN;
    {
          Defines for the ulFunction field of the VRAMIN data structure.
       }

    const
       VRAM_ALLOCATE = 1;
       VRAM_DEALLOCATE = 2;
       VRAM_QUERY = 3;
       VRAM_REGISTER = 4;
       VRAM_DEREGISTER = 5;
    { vramregisterin  }
    { sizeof(VRAMREGISTERIN)  }
    { de-registering handle   }
    { Input flags             }

    type

       VRAMREGISTERIN = record
            ulLength : ULONG;
            ulHandle : ULONG;
            ulFlags : ULONG;
         end;

       _VRAMREGISTERIN = VRAMREGISTERIN;

       PVRAMREGISTERIN = ^VRAMREGISTERIN;
    {
          Defines for the ulFlags field of the VRAMREGISTERIN data structure.
       }
    { If this bit is set we have   }

    const
       VRAM_REGISTER_HANDLE = $0001;
    { a registration if it is off  }
    { we have a deregistration     }
    { If this flag is set the app  }
       VRAM_REGISTER_VRAMONLY = $1000;
    { is registering and telling   }
    { us that it does not intend   }
    { to use the accelerator       }
    { vramregisterout  }
    { Returned flags (currently none def)  }
    { Returned handle                      }

    type

       VRAMREGISTEROUT = record
            ulLength : ULONG;
            ulFlags : ULONG;
            ulHandle : ULONG;
         end;

       _VRAMREGISTEROUT = VRAMREGISTEROUT;

       PVRAMREGISTEROUT = ^VRAMREGISTEROUT;
    { vramallocin  }
    { Used for de-allocation  }

       VRAMALLOCIN = record
            ulLength : ULONG;
            ulFlags : ULONG;
            ulID : ULONG;
            ulFunction : ULONG;
            ulHandle : ULONG;
            ulSize : ULONG;
            ulWidth : ULONG;
            ulHeight : ULONG;
         end;

       _VRAMALLOCIN = VRAMALLOCIN;

       PVRAMALLOCIN = ^VRAMALLOCIN;
    {
          Defines for the ulFlags field of the VRAMALLOCIN data structure.
       }

    const
       VRAM_ALLOC_SHARED = $0001;
       VRAM_ALLOC_RECTANGLE = $0002;
       VRAM_ALLOC_WORKBUFFER = $0004;
       VRAM_ALLOC_STATIC = $1000;
    {
          Defines for the ulFunction field of the VRAMALLOCIN data structure.
       }
//       VRAM_ALLOCATE = 1;
//       VRAM_DEALLOCATE = 2;
//       VRAM_QUERY = 3;
    { vramallocout  }

    type

       VRAMALLOCOUT = record
            ulLength : ULONG;
            ulFlags : ULONG;
            ulID : ULONG;
            ptlStart : POINTL;
            ulSize : ULONG;
            ulScanLineBytes : ULONG;
         end;

       _VRAMALLOCOUT = VRAMALLOCOUT;

       PVRAMALLOCOUT = ^VRAMALLOCOUT;
    {
          Defines and structures for the GHI_CMD_EVENT command
       }
    { hweventin   }
    { Event type                      }
    { Pointer to event specific data  }

       HWEVENTIN = record
            ulLength : ULONG;
            ulEvent : ULONG;
            pEventData : Pointer;
         end;

       _HWEVENTIN = HWEVENTIN;

       PHWEVENTIN = ^HWEVENTIN;
    {
          Defines for the ulEvent field of the HWEVENTIN data structure.
       }

    const
       EVENT_FOREGROUND = 1;
       EVENT_BACKGROUND = 2;
       EVENT_NEWCHAININFO = 3;
    {
          Defines and structures for the GHI_CMD_EXTENSION command
       }
    { hwextension  }

    type

       HWEXTENSION = record
            ulLength : ULONG;
            ulXSubFunction : ULONG;
            cScrChangeRects : ULONG;
            arectlScreen : PRECTL;
            ulXFlags : ULONG;
            pXP1 : Pointer;
         end;

       _HWEXTENSION = HWEXTENSION;

       PHWEXTENSION = ^HWEXTENSION;
    {
          Defines for the ulXFlags field of the HWEXTENSION data structure.
       }

    const
       X_REQUESTHW = 1;
    {
         GRADD.SYS defines
       }
       GRADDPDD_IOCTL = $10;
       GRADDPDD_LOCK = 0;
       GRADDPDD_UNLOCK = 1;
       GRADDPDD_SETMTRR = 2;
    { Starting Physical address               }
    { Range to be enabled for WC              }
    { Flags as defined above. Bit 27 is       }
    { interrpreted as a Enable MTRR if set    }
    { and as a Disable MTRR if not set        }

    type

       MTRRIN = record
            ulPhysAddr : ULONG;
            ulLength : ULONG;
            ulFlags : ULONG;
         end;

       PMTRRIN = ^MTRRIN;

       _MTRRIN = MTRRIN;

    {
         The following are the possible values for the flags which are returned when
         calling GRADDPDD_SETMTRR these are also defined in GRADDSYS.H for use by
         GRADD.SYS please make sure any updates are kept in synch.

         The first(low order byte) is reserved for Processor Identification and is
         interpreted as a number.  The 2nd byte is reserved for future use. The
         3rd byte is interpreted as a set of flags indicating what support is
         available and the high order byte is interpreted as a number corresponding
         to the command passed in to the SetMTRR function.
       }

    const
       INTEL_PROCESSOR = $00000001;
       AMD_PROCESSOR = $00000002;
       CYRIX_PROCESSOR = $00000003;
       CPUID_SUPPORT = $00010000;
       MTRR_SUPPORT = $00020000;
       MTRR_ENABLED = $00040000;
       MTRR_AVAILABLE = $00080000;
       WC_ENABLED = $00100000;
       VENDOR_MASK = $000000FF;
       COMMAND_MASK = $FF000000;
    {
         Or one of the following into the ulFlags field of MTRRIN to
         enabled/disable WC
       }
       MTRR_DISABLE = $00000000;
       MTRR_ENABLE = $01000000;
       MTRR_QUERY = $02000000;
       MTRR_CMD_MAX = MTRR_QUERY;
    {
         End of GRADD.SYS defines
       }
    {
          Prototype declarations for Video Manager Interface (VMI)
       }
    type FNVMIENTRY=function(GraddID:GID; _p2:ULONG; _p3:Pointer; _p4:Pointer):ULONG;
         PFNVMIENTRY=^FNVMIENTRY;
    Const

    {
          VMI commands which map directly to GRADD commands
       }
       VMI_CMD_INIT = GHI_CMD_INIT;
       VMI_CMD_INITPROC = GHI_CMD_INITPROC;
       VMI_CMD_TERM = GHI_CMD_TERM;
       VMI_CMD_TERMPROC = GHI_CMD_TERMPROC;
       VMI_CMD_QUERYCAPS = GHI_CMD_QUERYCAPS;
       VMI_CMD_QUERYMODES = GHI_CMD_QUERYMODES;
       VMI_CMD_SETMODE = GHI_CMD_SETMODE;
       VMI_CMD_PALETTE = GHI_CMD_PALETTE;
       VMI_CMD_BITBLT = GHI_CMD_BITBLT;
       VMI_CMD_LINE = GHI_CMD_LINE;
       VMI_CMD_MOVEPTR = GHI_CMD_MOVEPTR;
       VMI_CMD_SETPTR = GHI_CMD_SETPTR;
       VMI_CMD_SHOWPTR = GHI_CMD_SHOWPTR;
       VMI_CMD_VRAM = GHI_CMD_VRAM;
       VMI_CMD_REQUESTHW = GHI_CMD_REQUESTHW;
       VMI_CMD_EVENT = GHI_CMD_EVENT;
       VMI_CMD_EXTENSION = GHI_CMD_EXTENSION;
       VMI_CMD_BANK = GHI_CMD_BANK;
       VMI_CMD_TEXT = GHI_CMD_TEXT;
       VMI_CMD_USERCAPS = GHI_CMD_USERCAPS;
       VMI_CMD_POLYGON = GHI_CMD_POLYGON;
    {
          VMI commands unique to the video manager
       }
       VMI_CMD_BASE = $1000;

       VMI_CMD_QUERYCHAININFO   = VMI_CMD_BASE + 0;
       VMI_CMD_QUERYCURRENTMODE = VMI_CMD_BASE + 1;
       VMI_CMD_EXCLUDEPTR       = VMI_CMD_BASE + 2;
       VMI_CMD_UPDATECHAININFO  = VMI_CMD_BASE + 3;
       VMI_CMD_MAX              = VMI_CMD_BASE + 4;
    {
          Defines and structures for VMI_CMD_QUERYCHAININFO
       }
    { graddinfo  }

    type
       PGRADDINFO = ^GRADDINFO;
       GRADDINFO = record
            gid : GID;
            pszGraddName : Pchar;
            pGraddEntry : PFNHWENTRY;
            pChainEntry : PFNHWENTRY;
            cModes : ULONG;
            pModeInfo : PGDDMODEINFO;
            pCapsInfo : PCAPSINFO;
            pNextGraddInfo : PGRADDINFO;
         end;

       _GRADDINFO = GRADDINFO;

    { chaininfo  }
       PCHAININFO = ^CHAININFO;
       CHAININFO = record
            cid : CID;
            pszChainName : Pchar;
            pChainHWEntry : PFNHWENTRY;
            pGraddList : PGRADDINFO;
            pNextChainInfo : PCHAININFO;
         end;

       _CHAININFO = CHAININFO;

    { vmiqci  }
    { Head of the GRADD chain       }

       VMIQCI = record
            ulLength : ULONG;
            pciHead : PCHAININFO;
         end;

       _VMIQCI = VMIQCI;

       PVMIQCI = ^VMIQCI;
    {
          Defines and structures for VMI_CMD_EXCLUDEPTR
       }
    { excludeptrin                     }
    { sizeof(EXCLUDEPTRIN)             }
    { TRUE - add, FASE - remove rects  }
    { count of exclude rectangles      }
    { array of exclude rectangles      }

       EXCLUDEPTRIN = record
            ulLength : ULONG;
            fAdd : BOOL;
            cExcludeRects : ULONG;
            apRectls : PRECTL;
         end;

       _EXCLUDEPTRIN = EXCLUDEPTRIN;

       PEXCLUDEPTRIN = ^EXCLUDEPTRIN;
    {
         Video Helper services exported by VMAN
       }
    { meminfo  }

       MEMINFO = record
            ulPhysAddr : ULONG;
            ulMemLen : ULONG;
            ulVirtAddr : ULONG;
            pNextMI : Pointer;
         end;

       _MEMINFO = MEMINFO;

       PMEMINFO = ^MEMINFO;

    { Defines for xxxxxx }

    const
       TRAPEZOID_COLLINEAR = $0000;
       TRAPEZOID_TRIANGLE = $0001;
       TRAPEZOID_TWO_TRIANGLES = $0002;
       TRAPEZOID_DIAMOND = $0004;
       TRAPEZOID_MINY_HORIZONTAL = $0010;
       TRAPEZOID_MAXY_HORIZONTAL = $0020;
       TRAPEZOID_LEFT_SPLIT = $0040;
       TRAPEZOID_RIGHT_SPLIT = $0080;
       TRAPEZOID_MIDY_HORIZONTAL = $0100;
       TRAPEZOID_SECOND_SPLIT_LEFT = $0200;
       TRAPEZOID_SECOND_SPLIT_RIGHT = $0400;
    {
          Defines for the ulFlags field of the HEADER data structure.
       }
       SERIALIZE_REQUIRED = $1;
       QUERYCAPS = 1;
       QUERYCAPSLIST = 2;
       SETCAP = 3;

    type

       USERCAPSIN = record
            ulLength : ULONG;
            ulFunction : ULONG;
            ulSize : ULONG;
         end;

       _USERCAPSIN = USERCAPSIN;

       PUSERCAPSIN = ^USERCAPSIN;

    {  Structure for VMI_CMD_SHOWPTR }
    type

       HWSHOWPTRIN = record
            ulLength : ULONG;
            fShow : BOOL;
         end;

       _HWSHOWPTRIN = HWSHOWPTRIN;

       PHWSHOWPTRIN = ^HWSHOWPTRIN;

implementation
end.
