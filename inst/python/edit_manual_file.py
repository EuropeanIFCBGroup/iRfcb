import scipy.io

def edit_manual_file(input_file, output_file, row_numbers, new_value):
    # Load the MATLAB file
    mat_contents = scipy.io.loadmat(input_file)

    # Create a new dictionary to store the modified contents
    new_mat_contents = dict(mat_contents)

    # Modify the classlist for each row number
    classlist = new_mat_contents['classlist']
    for row_number in row_numbers:
        classlist[row_number - 1, 1] = new_value

    # Write the modified contents to a new MATLAB file
    scipy.io.savemat(output_file, new_mat_contents)