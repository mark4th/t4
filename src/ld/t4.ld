
OUTPUT_ARCH(arm)
ENTRY(origin)

SECTIONS
{
    PROVIDE (__executable_start = SEGMENT_START("text-segment", 0xa000));
    . = SEGMENT_START("text-segment", 0xa000) + SIZEOF_HEADERS;

    .text : ALIGN(4)
    {
      *(.text)
    }

    /*
     *  the _headers symbol below tells my application where
     *  the headers start within the process space at boot time
     *  this symbol is used to set the dictionary pointer
     *
     *  these headers are relocated up to head space at boot
     */

    .data  . : ALIGN(4)
    {
      _headers = ABSOLUTE(.);
      *(.data)
    }

    .bss : ALIGN(1)
    {
      *(.bss)
      . = . + 0x100000 - (SIZEOF(.text) + SIZEOF(.data));
    }
}
