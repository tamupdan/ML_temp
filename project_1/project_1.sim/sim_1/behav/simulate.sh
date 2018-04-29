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
ExecStep $xv_path/bin/xsim conv_layer_tb_wo_sig_behav -key {Behavioral:sim_1:Functional:conv_layer_tb_wo_sig} -tclbatch conv_layer_tb_wo_sig.tcl -log simulate.log
