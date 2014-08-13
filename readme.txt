General info:

The keys usable in the application are still the same:
 q : quit
 f : switch to/from fullscreen mode

The source buffer's parameters (width/height/FourCC) and the parameters of the
fullscreen mode (width/height/bpp) can be given by command line parameters,
for example:
VMAN_Proba 640x400x32 640x480xR565


This program is still heavily based on the os2doom v1.10 sources.
(http://maddownload.chat.ru)

Doodle <kocsisp@dragon.klte.hu>


History:
 2002.06.13.:
  Fixed:
   - 'q' can quit now gently even when the application is in fullscreen mode
   - SRCBUFFERBPP was not really used, the BPP is determined by FourCC...
   - No more problem with minimizing/maximizing/restoring/resizing when the application is in fullscreen mode
   - Closing VMAN gently when the application closes
  Added:
   - more comments.:)
