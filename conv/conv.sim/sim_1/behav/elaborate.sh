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
ExecStep $xv_path/bin/xelab -wto db10b24df305406ebb1925b1018b60e2 -m64 --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot convolution_tb_behav xil_defaultlib.convolution_tb -log elaborate.log
