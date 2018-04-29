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
ExecStep $xv_path/bin/xelab -wto 3fa6de3352c94b0e96ab29bf6d9ac279 -m64 --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot tanh_tb_behav xil_defaultlib.tanh_tb -log elaborate.log
