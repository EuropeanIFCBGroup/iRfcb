import scipy.io

def read_mat_file(file_path):
    """
    Reads a MATLAB .mat file and returns a dictionary with the contents.
    Compatible with reticulate in R.
    
    Parameters:
    file_path (str): Path to the .mat file.
    
    Returns:
    dict: A dictionary with the MATLAB variables.
    """
    data = scipy.io.loadmat(file_path, squeeze_me=True, struct_as_record=False)
    
    # Remove MATLAB metadata keys
    data = {key: value for key, value in data.items() if not key.startswith('__')}
    
    return data

# R Function Wrapper
def r_read_mat_file(file_path):
    """
    Wrapper function to be used in R via reticulate.
    
    Parameters:
    file_path (str): Path to the .mat file.
    
    Returns:
    dict: A dictionary with MATLAB variables, converted for R compatibility.
    """
    return read_mat_file(file_path)
