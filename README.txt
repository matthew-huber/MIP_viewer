1. Put code and data in the same directory.
2. In command line, run run_MIP_viewer.sh. If permission denied,
try chmod +x run_MIP_viewer.sh 
3. Enter input file name, number of angles, Yes/No depth weighting, attenuation factor (for depth weighting),
and output file name as prompted, and press enter after each input.
4. Program will output a .gif showing the MIP and a .bin file which returns an
array with the dimensions 128 x # slices x # projection angles. Data is float32.
