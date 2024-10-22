from scipy.io import savemat
import numpy as np

# Defining a Python function to create a .mat file with the specified structure
def save_class2use_to_mat(filename, class2use, do_compression=True):
    # Preparing data structure
    data = {'class2use': np.array(class2use, dtype=object)}
    
    # Saving to .mat file with optional compression
    savemat(filename, data, do_compression=do_compression)
