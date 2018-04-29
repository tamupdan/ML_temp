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
ExecStep $xv_path/bin/xelab -wto 9bdf61edbf7c441caced7c6c64fc2384 -m64 --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot conv_layer_tb_wo_sig_behav xil_defaultlib.conv_layer_tb_wo_sig -log elaborate.log
