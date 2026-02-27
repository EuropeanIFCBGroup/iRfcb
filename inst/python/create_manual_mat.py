def create_and_save_mat_structure(classlist_length, class2use_manual, output_path, col2_value=1, do_compression=True):
    """
    Creates and saves a .mat structure with a specified classlist length, class2use_manual content,
    and a customizable second column (either a single value or a list/array of the same length).
    """
    import numpy as np
    from scipy.io import savemat

    # Ensure col2_value is an array with the correct length
    if np.isscalar(col2_value):
        col2_value = np.full(classlist_length, col2_value)  # Broadcast single value
    elif isinstance(col2_value, (list, np.ndarray)):
        if len(col2_value) != classlist_length:
            raise ValueError("Length of col2_value must match classlist_length.")
        col2_value = np.array(col2_value)  # Convert to NumPy array if it's a list
    else:
        raise TypeError("col2_value must be a scalar, list, or NumPy array.")

    # Construct the classlist
    classlist = np.column_stack((
        np.arange(1, classlist_length + 1),  # ROI numbers
        col2_value,  # Custom/manual classification values
        np.full(classlist_length, np.nan)  # Auto classification (NaNs)
    ))

    # Create an empty class2use_auto array
    class2use_auto = np.array([], dtype=float).reshape(0, 0)

    # Create the dictionary structure for the .mat file
    mat_structure = {
        'class2use_manual': np.array([class2use_manual], dtype=object),
        'class2use_auto': class2use_auto,
        'classlist': classlist,
        'list_titles': np.array([["roi number", "manual", "auto"]], dtype=object),
        'default_class_original': np.array([["unclassified"]], dtype=object)
    }

    # Save to .mat file
    savemat(output_path, mat_structure, do_compression=do_compression)
