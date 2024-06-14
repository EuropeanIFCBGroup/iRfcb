from PSD import Bin

'''''''''''''''''
To generate data about a dataset's PSD from feature and hdr files, use the following format.

(1) Create a Bin object using:
    feature_dir = The absolute path to a directory containing all of the feature files for the dataset
    hdr_dir = The absolute path to a directory containing all of the hdr files for the dataset

(2) Plot the PSD using:
    use_marker = A boolean indicating whether to show markers on the plot
    save_graphs = A boolean indicating whether to save graph images for each file
    *Warning* save_graphs should only be used for datasets with less than 100 files
    
(3) Save the data using:
    name = A string with the base file name to use (no path)
    r_sqr = The lower limit of acceptable R^2 values (any curves below it will be flagged). Default 0.5
    
    **** Optional Flags ****
    beads = The maximum multiplier for the curve fit. Any files with higher curve fit multipliers will be flagged as 
            bead runs. If this argument is included, files with "runBeads" marked as True in the header file will also 
            be flagged as a bead run.
    bubbles = The minimum difference between the starting ESD and the ESD with the most targets. Any files with a 
              difference higher than this threshold will be flagged as mostly bubbles. (use absolute value)
    incomplete = The minimum volume of cells (in c/L) AND the minimum mL analyzed for a complete run. Any files with 
                 values below these thresholds will be flagged as incomplete. Enter as a two values in a tuple (ex. 
                 incomplete=(1500, 0.7)
    missing_cells = The minimum image count to trigger count ratio. Any files with lower ratios will be flagged as 
                    incomplete runs.
    biomass = The minimum number of targets in the most populated ESD bin for any given run. Any files with fewer 
              targets will be flagged as having low biomass.
    bloom = The minimum difference between the starting ESD and the ESD with the most targets. Any files with a 
            difference less than this threshold will be flagged as a bloom. Will likely be lower than the bubbles 
            threshold. (use absolute value)
    humidity = The maximum percent humidity. Any files with higher values will be flagged as high humidity.
    
    
'''''''''''''''''

b = Bin(feature_dir='//winfs-utv/data/utv/ifcb/work/data/features/2021', hdr_dir='//winfs-utv/data/utv/ifcb/work/data/data/2021')
b.plot_PSD(use_marker=False, save_graphs=False, start_fit=13)
b.save_data('svea_2021',
            r_sqr=0.5,
            beads=10 ** 20,
            bubbles=150,
            incomplete=(1500, 3),
            missing_cells=0.7,
            biomass=1000,
            bloom=5
            )
