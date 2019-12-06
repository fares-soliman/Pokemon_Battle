# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in mux.v to working dir
# could also have multiple verilog files
vlog PokemonSelect.v
vlog bulb.v
vlog squir.v
vlog char.v
vlog gameStart.v
vlog player1select.v
vlog player2.v
vlog battle_background.v
vlog selectPokemon.v
vlog vga_adapter.v
vlog vga_controller.v
vlog vga_pll.v
vlog vga_address_translator.v

#load simulation using mux as the top level simulation module
vsim -L altera_mf_ver -L altera_mf dataAndControl

#log all signals and add some signals to waveform window
log {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}


force {clk} 1 0ns , 0 {10ns} -r 20ns

force {resetn} 0
run 10ns

force {resetn} 1
run 10ns

force {select1} 1
force {select2} 0
force {select3} 0
run 20ns

force {go} 1
run 20ns
force {go} 0
run 20ns


force {select1} 0
force {select2} 1
force {select3} 0
run 20ns

force {go} 1
run 20ns
force {go} 0
run 20ns

force {go} 1
run 20ns
force {go} 0
run 20ns

force {go} 1
run 20ns
force {go} 0
run 20ns



