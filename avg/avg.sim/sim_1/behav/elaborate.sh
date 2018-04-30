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
ExecStep $xv_path/bin/xelab -wto e8833924969e4270952097afb4f68d10 -m64 --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot pooling_tb_behav xil_defaultlib.pooling_tb -log elaborate.log
