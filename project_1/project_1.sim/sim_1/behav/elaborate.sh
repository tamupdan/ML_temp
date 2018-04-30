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
ExecStep $xv_path/bin/xelab -wto 720b0304ed4243a884da9a7329c398cd -m64 --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot cnn_tb_behav xil_defaultlib.cnn_tb -log elaborate.log
