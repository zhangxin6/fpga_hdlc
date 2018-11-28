#A Vivado script that demonstrates a very simple RTL-to-bitstream batch flow 
# 
#NOTE: typical usage would be "vivado -mode tcl -source ./Desktop/simple1.tcl"
# 
#STEP #0: define output directory area.
set outputDir D:/git_repos/fpga_repos/fpga_hdlc_v7/src
set ipdir D:/git_repos/manage_ip 
file mkdir $outputDir
# 
#STEP# 1: setup design sources and constraints 
# 
read_verilog [glob $outputDir/*.v]

 
read_xdc $outputDir/top.xdc 
read_ip  $ipdir/clk_pn_100_25/clk_pn_100_25.xci
read_ip  $ipdir/ila_8_16384_1120/ila_8_16384_1120.xci
read_ip  $ipdir/flag_insert0_ram/flag_insert0_ram.xci
read_ip  $ipdir/hdlc_tx_ram/hdlc_tx_ram.xci
read_ip  $ipdir/insert0_ram/insert0_ram.xci
read_ip  $ipdir/hdlc_rx_ram/hdlc_rx_ram.xci

#STEP# 2: run synthesis, report utilization and timing estimates, write checkpoint  design 
# 
set_param general.maxThreads 8

synth_design -top top -part xc7vx690tffg1930-2 -flatten rebuilt 
write_checkpoint -force $outputDir/post_synth
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
report_power -file $outputDir/post_synth_power.rpt
# 
#STEP# 3: run placement and logic optimization, report utilization and timing
# estimates, write checkpoint design
#
opt_design
power_opt_design
place_design
phys_opt_design
write_checkpoint -force $outputDir/post_place
report_timing_summary -file $outputDir/post_place_timing_summary.rpt
# 
#STEP# 4: run router, report actual utilization and timing, write checkpoint design,run drc, write verilog and xdc out 
# 
route_design 
write_checkpoint -force $outputDir/post_route 
report_timing_summary -file $outputDir/post_route_timing_summary.rpt
report_timing -sort_by group -max_paths 100 -path_type summary -file $outputDir/post_route_timing.rpt
report_clock_utilization -file $outputDir/clock_util.rpt
report_utilization -file $outputDir/post_route_util.rpt
report_power -file $outputDir/post_route_power.rpt 
report_drc -file $outputDir/post_imp_drc.rpt 
write_verilog -force $outputDir/top_impl_netlist.v 
write_xdc -no_fixed_only -force $outputDir/top_impl.xdc 
# 
#STEP# 5: generate a bitstream #
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
write_debug_probes -force $outputDir/top.ltx 
write_bitstream -force -bin_file $outputDir/top.bit
#STEP 6: write bit
# vivado -mode tcl 
open_hw

connect_hw_server

open_hw_target

set_property PROBES.FILE {./Desktop/vivado_example/hdlc_v7/top.ltx} [get_hw_devices xc7vx690t_0]
set_property FULL_PROBES.FILE {./Desktop/vivado_example/hdlc_v7/top.ltx} [get_hw_devices xc7vx690t_0]
set_property PROGRAM.FILE {./Desktop/vivado_example/hdlc_v7/top.bit} [get_hw_devices xc7vx690t_0]

program_hw_devices [get_hw_devices xc7vx690t_0] 
refresh_hw_device [lindex [get_hw_devices xc7vx690t_0] 0]

start_gui

#step 7
write_hw_ila_data -force ./Desktop/vivado_example/simple1/1109_ila_1 [upload_hw_ila_data hw_ila_1]
write_hw_ila_data -force ./Desktop/vivado_example/simple1/1109_ila_2 [upload_hw_ila_data hw_ila_2]

#step 8
read_hw_ila_data ./Desktop/vivado_example/simple1/1109_ila_1.ila
display_hw_ila_data

read_hw_ila_data ./Desktop/vivado_example/simple1/1109_ila_2.ila
display_hw_ila_data

