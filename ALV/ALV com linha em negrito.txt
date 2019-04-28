TYPE-POOLS: abap.

TYPES : BEGIN OF ty_outtab,
        celltab TYPE lvc_t_styl.
        INCLUDE STRUCTURE qals.
TYPES   END   OF ty_outtab.

DATA  : gt_outtab  TYPE TABLE OF ty_outtab WITH HEADER LINE,
        gs_layout  TYPE lvc_s_layo,
        ls_celltab TYPE lvc_s_styl,
        lt_celltab TYPE lvc_t_styl.

SELECT * FROM qals INTO CORRESPONDING FIELDS OF TABLE gt_outtab UP TO 20 ROWS.

ls_celltab-style = '00000121'.

INSERT ls_celltab INTO lt_celltab INDEX 1.

READ TABLE gt_outtab INDEX 1.

gt_outtab-celltab = lt_celltab.

INSERT gt_outtab INDEX 1.

gs_layout-stylefname = 'CELLTAB'.

CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
  EXPORTING
    i_structure_name = 'QALS'
    is_layout_lvc    = gs_layout
  TABLES
    t_outtab         = gt_outtab
  EXCEPTIONS
    program_error    = 1
    OTHERS           = 2.