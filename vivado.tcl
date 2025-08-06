
set project_name [lindex $argv 0]
set bd_tcl_filename [lindex $argv 1]

# start_gui

create_project acorn $project_name/ -part xc7a100tfgg484

# add_files -norecurse {}
# set_property file_type {Memory File} [get_files -all]

add_files -norecurse {
    ../axi_const_rd.v
    ../axi_mm2s_test.v
}

add_files -fileset constrs_1 -norecurse {
 ../sqrl_acorn.xdc
}
set_property PROCESSING_ORDER EARLY [get_files -of_objects [get_filesets constrs_1]]

create_bd_design "design_1"
source ../$bd_tcl_filename
save_bd_design
make_wrapper -files [get_files design_1.bd] -top -import
set_property top design_1_wrapper [current_fileset]

set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE PerformanceOptimized [get_runs synth_1]
launch_runs synth_1 -jobs [exec nproc]
wait_on_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs [exec nproc]
wait_on_run impl_1

exit
