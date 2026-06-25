set project_name "riscv_processor"
set project_dir "./vivado_proj"

create_project -force $project_name $project_dir -part xc7a35tcpg236-1

read_verilog -sv [glob ./rtl/include/*.sv]
read_verilog -sv [glob ./rtl/core/*.sv]
read_verilog -sv [glob ./rtl/mem/*.sv]

if {[file exists "./firmware.mem"]} {
    add_files -norecurse ./firmware.mem
    set_property file_type MemoryFile [get_files ./firmware.mem]
} else {
    puts "WARNING: firmware.mem not found. Make sure to compile your C/Assembly code first using 'make firmware.mem'."
}

set_property include_dirs ./rtl/include [current_fileset]

set_property top top [current_fileset]
update_compile_order -fileset sources_1

puts "INFO: Vivado project created successfully in $project_dir"
puts "INFO: Open it using: vivado $project_dir/$project_name.xpr"
