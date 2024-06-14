import scipy.io
import numpy as np

def replace_nan_in_classlist(input_file, output_file, new_value, column_index=1):
    """
    Replaces NaN values in a specific column of the classlist with a new value.

    Parameters:
    - input_file: str, path to the input MATLAB file
    - output_file: str, path to the output MATLAB file
    - new_value: value to replace the NaN values with
    - column_index: int, the index of the column where the replacement should occur (0-based index)
    """
    # Load the MATLAB file
    mat_contents = scipy.io.loadmat(input_file)

    # Create a new dictionary to store the modified contents
    new_mat_contents = dict(mat_contents)

    # Access the classlist
    classlist = new_mat_contents['classlist']

    # Replace NaN values with new_value in the specified column
    nan_mask = np.isnan(classlist[:, column_index])
    classlist[nan_mask, column_index] = new_value

    # Write the modified contents to a new MATLAB file
    scipy.io.savemat(output_file, new_mat_contents)
