def save_classification_mat(score_matrix, class_labels, roi_numbers, winning_class, class_above_threshold, model_name, output_path):
    """
    Save classification results in IFCB Dashboard v1 .mat format.

    Uses the TreeBagger field names expected by pyifcb's _class_scores_v1:
    - class2useTB: object array of class labels + "unclassified" appended
    - TBscores: float64 matrix (N x C)
    - roinum: uint16 array of ROI numbers
    - TBclass: object array of winning class per ROI
    - TBclass_above_threshold: object array with threshold-applied classes
    - classifierName: string
    """
    import numpy as np
    from scipy.io import savemat

    n_rois = len(roi_numbers)
    n_classes = len(class_labels)

    # class2useTB: object array of class labels with "unclassified" appended
    class2use_tb = np.empty(n_classes + 1, dtype=object)
    for i, label in enumerate(class_labels):
        class2use_tb[i] = label
    class2use_tb[n_classes] = "unclassified"

    # TBscores: float64 matrix (N x C)
    tb_scores = np.array(score_matrix, dtype=np.float64)

    # roinum: uint16 column vector
    roinum = np.array(roi_numbers, dtype=np.uint16).reshape(-1, 1)

    # TBclass: object array of winning class per ROI (column vector)
    tb_class = np.empty((n_rois, 1), dtype=object)
    for i, cls in enumerate(winning_class):
        tb_class[i, 0] = cls

    # TBclass_above_threshold: object array (column vector)
    tb_class_above = np.empty((n_rois, 1), dtype=object)
    for i, cls in enumerate(class_above_threshold):
        tb_class_above[i, 0] = cls

    mat_structure = {
        "class2useTB": class2use_tb.reshape(1, -1),
        "TBscores": tb_scores,
        "roinum": roinum,
        "TBclass": tb_class,
        "TBclass_above_threshold": tb_class_above,
        "classifierName": np.array([model_name], dtype=object)
    }

    savemat(output_path, mat_structure, do_compression=True)
