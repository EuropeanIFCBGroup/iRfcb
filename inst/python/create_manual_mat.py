import numpy as np
from scipy.io import savemat

def create_and_save_mat_structure(classlist_length, class2use_manual, output_path, col2_value=1, do_compression=True):
    """
    Creates a .mat structure with a specified classlist length, class2use_manual content,
    and a customizable value for column 2, then saves it to the provided output path.
    
    Parameters:
    - classlist_length: int, number of rows in the classlist.
    - class2use_manual: list of strings, representing class names.
    - output_path: str, path to save the .mat file.
    - col2_value: int or float, value to fill in the second column of the classlist. Default is 1.
    - do_compression: bool, whether to compress the .mat file. Default is False.
    
    Returns:
    - None, saves the structure as a .mat file at the specified path.
    """
    # Construct the classlist with three columns
    classlist = np.column_stack((
        np.arange(1, classlist_length + 1),  # Row numbers (1 to classlist_length)
        np.full(classlist_length, col2_value),  # Column 2: Filled with specified value
        np.full(classlist_length, np.nan)    # Column 3: NaNs
    ))
    
    # Create the empty class2use_auto to match the original structure
    class2use_auto = np.array([], dtype=object).reshape(0, 0)
    
    # Create the dictionary structure
    mat_structure = {
        'class2use_manual': np.array([class2use_manual], dtype=object),
        'class2use_auto': class2use_auto,  # Empty array for class2use_auto
        'classlist': classlist,
        'list_titles': np.array([["roi number", "manual", "auto"]], dtype=object),
        'default_class_original': np.array([["unclassified"]], dtype=object)
    }
    
    # Save the structure to the specified output path with or without compression
    savemat(output_path, mat_structure, do_compression=do_compression)
