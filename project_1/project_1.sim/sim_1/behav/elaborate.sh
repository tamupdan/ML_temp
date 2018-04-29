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
ExecStep $xv_path/bin/xelab -wto db17c739775247b4a40aec0d76575d4a -m64 --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot conv_layer_tb_wo_sig_behav xil_defaultlib.conv_layer_tb_wo_sig -log elaborate.log
