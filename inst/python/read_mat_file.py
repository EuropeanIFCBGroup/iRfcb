import numpy as np
import scipy.io

def convert_data(x):
    import numpy as np

    if isinstance(x, dict):
        return {k: convert_data(v) for k, v in x.items()}

    if isinstance(x, str):
        # Wrap plain strings in [[ ]] to mimic 1x1 character matrix in R
        return [[x]]

    if isinstance(x, np.ndarray):
        if np.issubdtype(x.dtype, np.integer):
            # Convert integers to float (R.matlab reads all numbers as numeric)
            x = x.astype(np.float64)
            if x.ndim == 1:
                x = x.reshape(-1, 1)  # Convert 1D array to column vector
            return x
        elif x.dtype == np.object_:
            flat = [str(item) for item in x.flat]
            return flat
        else:
            if x.ndim == 1:
                x = x.reshape(-1, 1)  # Convert 1D numeric arrays to column vector
            return x

    if isinstance(x, list):
        def flatten(lst):
            for item in lst:
                if isinstance(item, list):
                    yield from flatten(item)
                else:
                    yield item
        return [str(item) for item in flatten(x)]

    return x

def read_mat_file(file_path):
    """
    Reads a MATLAB .mat file and returns a dictionary with the contents.
    The function flattens MATLAB cell arrays to Python lists of strings
    for compatibility with the R version using R.matlab::readMat.
    
    Parameters:
      file_path (str): Path to the .mat file.
    
    Returns:
      dict: A dictionary with MATLAB variables.
    """
    # Load the .mat file; squeeze_me=True reduces singleton dimensions
    # and struct_as_record=False avoids converting MATLAB structs to record arrays.
    data = scipy.io.loadmat(file_path, squeeze_me=True, struct_as_record=False)
    
    # Remove MATLAB metadata keys (those starting with '__')
    data = {key: value for key, value in data.items() if not key.startswith('__')}
    
    # Convert list-like items to a list of strings (if applicable)
    data = {key: convert_data(value) for key, value in data.items()}
    
    return data

# R Function Wrapper for use with reticulate
def r_read_mat_file(file_path):
    """
    Wrapper function to be used in R via reticulate.
    
    Parameters:
      file_path (str): Path to the .mat file.
    
    Returns:
      dict: A dictionary with MATLAB variables, converted for R compatibility.
    """
    return read_mat_file(file_path)
