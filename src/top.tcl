#NOTE: typical usage would be "vivado -mode tcl -source ./Desktop/simple1.tcl"
set verilogdir C:/Users/zhang/iverilog_testbench
set sourcedir C:/Users/zhang/fpga_hdlc/src
set outputdir C:/Users/zhang/fpga_hdlc/output
set ipdir C:/Users/zhang/manage_ip 

#STEP# 1: setup design sources and constraints 

read_verilog [glob $verilogdir/insert0.v]
read_verilog [glob $verilogdir/hdlctra.v]
read_verilog [glob $verilogdir/hdlcrev.v]
read_verilog [glob $verilogdir/insert0.v]
read_verilog [glob $verilogdir/flag_i0.v]
read_verilog [glob $verilogdir/dsp_hdlc_ctrl.v]
read_verilog [glob $verilogdir/cpld_top.v]
read_verilog [glob $verilogdir/emif_intf_z.v]
read_verilog [glob $verilogdir/gpio_intf.v]
read_verilog [glob $verilogdir/gpio_intr_gen.v]

read_verilog [glob $sourcedir/top.v]

read_xdc $sourcedir/top.xdc 
read_ip  $ipdir/clk_pn_100_25/clk_pn_100_25.xci
read_ip  $ipdir/ila_8_16384_1120/ila_8_16384_1120.xci
read_ip  $ipdir/flag_insert0_ram/flag_insert0_ram.xci
read_ip  $ipdir/hdlc_tx_ram/hdlc_tx_ram.xci
read_ip  $ipdir/insert0_ram/insert0_ram.xci																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																				
read_ip  $ipdir/hdlc_rx_ram/hdlc_rx_ram.xci

#STEP# 2: run synthesis, report utilization and timing estimates, write checkpoint  design 

set_param general.maxThreads 8

synth_design -top top -part xc7vx690tffg1930-2 -flatten rebuilt 
write_checkpoint -force $outputdir/post_synth
report_timing_summary -file $outputdir/post_synth_timing_summary.rpt
report_power -file $outputdir/post_synth_power.rpt

#STEP# 3: run placement and logic optimization, report utilization and timin  # estimates, write checkpoint design

opt_design
power_opt_design
place_design
phys_opt_design
write_checkpoint -force $outputdir/post_place
report_timing_summary -file $outputdir/post_place_timing_summary.rpt

#STEP# 4: run router, report actual utilization and timing, write checkpoint design,run drc, write verilog and xdc out 

route_design 
write_checkpoint -force $outputdir/post_route 
report_timing_summary -file $outputdir/post_route_timing_summary.rpt
report_timing -sort_by group -max_paths 100 -path_type summary -file $outputdir/post_route_timing.rpt
report_clock_utilization -file $outputdir/clock_util.rpt
report_utilization -file $outputdir/post_route_util.rpt
report_power -file $outputdir/post_route_power.rpt 
report_drc -file $outputdir/post_imp_drc.rpt 
write_verilog -force $outputdir/top_impl_netlist.v 
write_xdc -no_fixed_only -force $outputdir/top_impl.xdc 

#STEP# 5: generate a bitstream #
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
write_debug_probes -force $sourcedir/top.ltx 
write_bitstream -force -bin_file $sourcedir/top.bit

#STEP 6: write bit
# vivado -mode tcl 
open_hw

connect_hw_server

open_hw_target

set_property PROBES.FILE {C:/Users/zhang/fpga_hdlc/src/top.ltx} [get_hw_devices xc7vx690t_0]
set_property FULL_PROBES.FILE {C:/Users/zhang/fpga_hdlc/src/top.ltx} [get_hw_devices xc7vx690t_0]
set_property PROGRAM.FILE {C:/Users/zhang/fpga_hdlc/src/top.bit} [get_hw_devices xc7vx690t_0]

program_hw_devices [get_hw_devices xc7vx690t_0] 
refresh_hw_device [lindex [get_hw_devices xc7vx690t_0] 0]

start_gui

#step 7
write_hw_ila_data -force C:/Users/zhang/fpga_hdlc1109_ila_1 [upload_hw_ila_data hw_ila_1]
write_hw_ila_data -force C:/Users/zhang/fpga_hdlc1109_ila_2 [upload_hw_ila_data hw_ila_2]

#step 8
read_hw_ila_data C:/Users/zhang/fpga_hdlc/1109_ila_1.ila
display_hw_ila_data

read_hw_ila_data C:/Users/zhang/fpga_hdlc/1109_ila_2.ila
display_hw_ila_data