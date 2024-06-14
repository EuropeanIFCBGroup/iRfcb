import scipy.io

def replace_value_in_classlist(input_file, output_file, target_value, new_value, column_index = 1):
    """
    Replaces specified target values in a specific column of the classlist with a new value.

    Parameters:
    - input_file: str, path to the input MATLAB file
    - output_file: str, path to the output MATLAB file
    - column_index: int, the index of the column where the replacement should occur (0-based index)
    - target_value: value to be replaced in the specified column of the classlist
    - new_value: value to replace the target value with
    """
    # Load the MATLAB file
    mat_contents = scipy.io.loadmat(input_file)

    # Create a new dictionary to store the modified contents
    new_mat_contents = dict(mat_contents)

    # Access the classlist
    classlist = new_mat_contents['classlist']

    # Replace target_value with new_value in the specified column
    mask = classlist[:, column_index] == target_value
    classlist[mask, column_index] = new_value

    # Write the modified contents to a new MATLAB file
    scipy.io.savemat(output_file, new_mat_contents)
