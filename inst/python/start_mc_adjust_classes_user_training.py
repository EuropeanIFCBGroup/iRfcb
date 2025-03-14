import os
import scipy.io
import warnings
from scipy.io.matlab._miobase import MatReadError

def start_mc_adjust_classes_user_training(class2use_name, manual_path, do_compression=True):
    # Load class2use from the .mat file
    class2use_data = scipy.io.loadmat(f"{class2use_name}.mat")
    class2use = class2use_data['class2use']

    # Iterate through the manual directory
    for filename in os.listdir(manual_path):
        if filename.startswith('D'):
            manual_file_path = os.path.join(manual_path, filename)
            
            try:
                # Attempt to load the manual data
                manual_data = scipy.io.loadmat(manual_file_path)
            except MatReadError:
                warnings.warn(f"Warning: The manual file {filename} is empty or corrupted.", UserWarning)
                continue  # Skip processing this file
            
            # Adjust the manual file's class2use fields
            manual_data['class2use_manual'] = class2use
            
            if 'class2use_auto' in manual_data:
                manual_data['class2use_auto'] = class2use.T
            
            # Save the modified manual data back to the file
            scipy.io.savemat(manual_file_path, manual_data, do_compression=do_compression)
            
