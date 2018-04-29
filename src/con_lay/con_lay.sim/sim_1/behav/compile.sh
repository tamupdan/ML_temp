#!/bin/sh -f
xv_path="/softwares/Linux/xilinx/Vivado/2015.2"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
echo "xvhdl -m64 --relax -prj conv_layer_tb_wo_sig_vhdl.prj"
ExecStep $xv_path/bin/xvhdl -m64 --relax -prj conv_layer_tb_wo_sig_vhdl.prj 2>&1 | tee -a compile.log
