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
ExecStep $xv_path/bin/xelab -wto 61f125fa56c7458298673fff75303018 -m64 --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot cnn_tb_behav xil_defaultlib.cnn_tb -log elaborate.log
